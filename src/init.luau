--!strict

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Types = require(script.Types)
local PropertyUtil = require(script.Util.Property)
local PropUtil = require(script.Util.Prop)
local sigmoidEase = require(script.Util.sigmoidEase)
local resolveDynamic = require(script.Util.resolveDynamic)

type PropInstance = Types.PropInstance
type TargetInstance = Types.TargetInstance
type DynamicNumber = Types.DynamicNumber
type PropSettings = Types.PropSettings

local PropManager = {}

PropManager.Defaults = table.freeze({
	RemoveMagnitude = 1,
	AttractDuration = 1.5,
	AttractDelay = 3,
	CollisionGroup = "Props",
})

-- SoA (Structure of Arrays) flat, cache-friendly
local propCount = 0
local propInstances: { PropInstance } = {}
local moveParts: { BasePart } = {}
local targetInstances: { TargetInstance } = {}
local allSettings: { PropSettings } = {}
local spawnTimes: { number } = {}
local isAttracted: { boolean } = {}
local attractStartTimes: { number } = {}
local attractOrigins: { Vector3 } = {}
local groupIds: { string } = {}
local resolvedAttractDelays: { number } = {}
local resolvedAttractDurations: { number } = {}

-- Group tracking for OnAllRemoved
local groupCounts: { [string]: number } = {}
local groupOnAllRemoved: { [string]: (() -> ())? } = {}

-- Per-frame reusable buffers
local bulkParts: { BasePart } = {}
local bulkCFrames: { CFrame } = {}
local removeQueue: { number } = {}
local removeWasForced: { boolean? } = {}

local function reportCallbackError(err: string)
	warn(`[Dispense-Prop] user callback error:\n{debug.traceback(tostring(err), 2)}`)
end

local function swapRemoveAtIndex(i: number)
	local last = propCount

	if i ~= last then
		propInstances[i] = propInstances[last]
		moveParts[i] = moveParts[last]
		targetInstances[i] = targetInstances[last]
		allSettings[i] = allSettings[last]
		spawnTimes[i] = spawnTimes[last]
		isAttracted[i] = isAttracted[last]
		attractStartTimes[i] = attractStartTimes[last]
		attractOrigins[i] = attractOrigins[last]
		groupIds[i] = groupIds[last]
		resolvedAttractDelays[i] = resolvedAttractDelays[last]
		resolvedAttractDurations[i] = resolvedAttractDurations[last]
	end

	propInstances[last] = nil :: any
	moveParts[last] = nil :: any
	targetInstances[last] = nil :: any
	allSettings[last] = nil :: any
	spawnTimes[last] = nil :: any
	isAttracted[last] = nil :: any
	attractStartTimes[last] = nil :: any
	attractOrigins[last] = nil :: any
	groupIds[last] = nil :: any
	resolvedAttractDelays[last] = nil :: any
	resolvedAttractDurations[last] = nil :: any

	propCount -= 1
end

local function decrementGroup(groupId: string)
	local count = groupCounts[groupId]
	if not count then
		return
	end

	local remaining = count - 1

	if remaining <= 0 then
		groupCounts[groupId] = nil

		local cb = groupOnAllRemoved[groupId]
		groupOnAllRemoved[groupId] = nil
		if cb then
			xpcall(cb, reportCallbackError)
		end
	else
		groupCounts[groupId] = remaining
	end
end

-- Frame update three-phase pipeline
local targetPivotCache: { [TargetInstance]: Vector3 } = {}

local function update()
	if propCount == 0 then
		return
	end

	debug.profilebegin("PropDispenser")

	local now = os.clock()
	local bulkN = 0
	local removeN = 0

	-- Phase 1: evaluate every prop, queue moves and removals
	for i = 1, propCount do
		local prop = propInstances[i]
		local target = targetInstances[i]
		local settings = allSettings[i]
		local part = moveParts[i]

		-- Prop or its move-part destroyed externally
		if not prop:IsDescendantOf(game) or not part:IsDescendantOf(game) then
			removeN += 1
			removeQueue[removeN] = i
			removeWasForced[removeN] = true
			continue
		end

		-- Target gone (character respawn, player left)
		if not target:IsDescendantOf(game) then
			removeN += 1
			removeQueue[removeN] = i
			removeWasForced[removeN] = true
			continue
		end

		local elapsed = now - spawnTimes[i]

		-- Auto-remove timer exceeded
		if settings.AutoRemoveTime and elapsed >= settings.AutoRemoveTime then
			removeN += 1
			removeQueue[removeN] = i
			removeWasForced[removeN] = true
			continue
		end

		local targetPos = targetPivotCache[target]
		if not targetPos then
			targetPos = target:GetPivot().Position
			targetPivotCache[target] = targetPos
		end
		local clearMag = settings.RemoveMagnitude or PropManager.Defaults.RemoveMagnitude

		-- Sigmoid attraction in progress
		if isAttracted[i] then
			local attractElapsed = now - attractStartTimes[i]
			local duration = resolvedAttractDurations[i]
			local alpha = sigmoidEase(attractElapsed / duration)

			local newPos = attractOrigins[i]:Lerp(targetPos, alpha)
			local dist = (targetPos - newPos).Magnitude

			if dist <= clearMag or alpha >= 1 then
				removeN += 1
				removeQueue[removeN] = i
				removeWasForced[removeN] = nil
			else
				bulkN += 1
				bulkParts[bulkN] = part
				-- Preserve current rotation (part is anchored since attract start, so stable).
				bulkCFrames[bulkN] = (part.CFrame - part.Position) + newPos
			end

			continue
		end

		-- Still in attract-delay window
		if elapsed < resolvedAttractDelays[i] then
			continue
		end

		local propPos = part.Position
		local dist = (targetPos - propPos).Magnitude

		-- Already at target
		if dist <= clearMag then
			removeN += 1
			removeQueue[removeN] = i
			removeWasForced[removeN] = nil
			continue
		end

		-- Begin attraction (nil magnitude = attract from any distance)
		if not settings.AttractMagnitude or dist <= settings.AttractMagnitude then
			part.Anchored = true
			part.CanCollide = false

			isAttracted[i] = true
			attractStartTimes[i] = now
			attractOrigins[i] = propPos
		end
	end

	-- Phase 2: always clear stale tail entries so we don't hold dead part refs between frames
	for j = bulkN + 1, #bulkParts do
		bulkParts[j] = nil :: any
		bulkCFrames[j] = nil :: any
	end

	-- Batch-move all attracted props in one engine call
	if bulkN > 0 then
		workspace:BulkMoveTo(bulkParts, bulkCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end

	-- Phase 3: remove props in descending index order (safe swap-remove)
	for j = removeN, 1, -1 do
		local idx = removeQueue[j]
		local prop = propInstances[idx]
		local settings = allSettings[idx]
		local groupId = groupIds[idx]
		local wasForced = removeWasForced[j]

		swapRemoveAtIndex(idx)
		PropUtil.Destroy(prop)

		if settings.OnRemoved then
			xpcall(settings.OnRemoved, reportCallbackError, wasForced)
		end

		decrementGroup(groupId)
	end

	-- Clear reusable buffers
	for j = 1, removeN do
		removeQueue[j] = nil :: any
		removeWasForced[j] = nil
	end

	table.clear(targetPivotCache)

	debug.profileend()
end

RunService.Heartbeat:Connect(update)

-- Public API
-- Note: uses `:` for call-site ergonomics (PropManager:Start) but does not read `self`.
function PropManager:Start(
	amount: number,
	originCFrame: CFrame,
	propTemplate: PropInstance,
	targetInstance: TargetInstance,
	settings: PropSettings
)
	do
		assert(typeof(amount) == "number" and amount % 1 == 0 and amount >= 1, "`amount` must be an integer >= 1")
		assert(
			typeof(propTemplate) == "Instance"
				and ((propTemplate:IsA("Model") and propTemplate.PrimaryPart) or propTemplate:IsA("BasePart")),
			"`propTemplate` must be a Model with a PrimaryPart or a BasePart"
		)
		assert(
			typeof(targetInstance) == "Instance" and (targetInstance:IsA("Model") or targetInstance:IsA("BasePart")),
			"`targetInstance` must be a Model or BasePart"
		)
		assert(typeof(settings) == "table", "`settings` must be a table")
		assert(typeof(originCFrame) == "CFrame", "`originCFrame` must be a CFrame")
		assert(
			not settings.CollisionGroup or typeof(settings.CollisionGroup) == "string",
			"`CollisionGroup` must be a string"
		)
		assert(
			not settings.RemoveMagnitude
				or (typeof(settings.RemoveMagnitude) == "number" and settings.RemoveMagnitude > 0),
			"`RemoveMagnitude` must be a positive number"
		)
		assert(
			not settings.AttractDelay
				or typeof(settings.AttractDelay) == "number"
				or typeof(settings.AttractDelay) == "Vector2"
				or typeof(settings.AttractDelay) == "function",
			"`AttractDelay` must be a number, Vector2 range, or function"
		)
		assert(
			not settings.AutoRemoveTime or (typeof(settings.AutoRemoveTime) == "number" and settings.AutoRemoveTime > 0),
			"`AutoRemoveTime` must be a positive number"
		)
		assert(
			not settings.AttractMagnitude
				or (typeof(settings.AttractMagnitude) == "number" and settings.AttractMagnitude > 0),
			"`AttractMagnitude` must be a positive number if specified."
		)
		assert(
			not settings.AttractDuration
				or typeof(settings.AttractDuration) == "number"
				or typeof(settings.AttractDuration) == "Vector2"
				or typeof(settings.AttractDuration) == "function",
			"`AttractDuration` must be a number, Vector2 range, or function"
		)
		assert(typeof(settings.OnSpawn) == "function", "`OnSpawn` must be a function")
		assert(not settings.OnRemoved or typeof(settings.OnRemoved) == "function", "`OnRemoved` must be a function")
		assert(
			not settings.OnAllRemoved or typeof(settings.OnAllRemoved) == "function",
			"`OnAllRemoved` must be a function"
		)
	end

	local groupId = HttpService:GenerateGUID(false)

	settings = table.clone(settings)

	groupCounts[groupId] = 0
	if settings.OnAllRemoved then
		groupOnAllRemoved[groupId] = settings.OnAllRemoved
	end

	local success, errMessage = pcall(function()
		for propIndex = 1, amount do
			local propInstance = propTemplate:Clone()

			-- Apply engine-side setup first so OnSpawn can override anything (e.g. Anchored).
			propInstance:PivotTo(originCFrame)
			PropertyUtil.SetProperty(propInstance, {
				CanTouch = false,
				CanQuery = false,
				CanCollide = true,
				Anchored = false,
				CollisionGroup = settings.CollisionGroup or PropManager.Defaults.CollisionGroup,
			})

			local spawnOk, spawnErr = pcall(settings.OnSpawn :: (...any) -> ...any, propInstance)

			if not spawnOk then
				PropUtil.Destroy(propInstance)
				error(`'OnSpawn' errored with: \n{spawnErr}`)
			end

			if not propInstance or not propInstance:IsDescendantOf(game) then
				error(
					"propInstance is not parented to the DataModel after OnSpawn (did you forget to set `.Parent` in OnSpawn?)"
				)
			end

			-- Re-check PrimaryPart in case OnSpawn cleared or replaced it.
			local primaryPart = PropUtil.GetPrimaryPart(propInstance)
			if not primaryPart then
				propInstance:Destroy()
				error("Model prop missing PrimaryPart after OnSpawn")
			end

			-- Append to SoA
			propCount += 1
			propInstances[propCount] = propInstance
			moveParts[propCount] = primaryPart
			targetInstances[propCount] = targetInstance
			allSettings[propCount] = settings
			spawnTimes[propCount] = os.clock()
			isAttracted[propCount] = false
			attractStartTimes[propCount] = 0
			attractOrigins[propCount] = Vector3.zero
			groupIds[propCount] = groupId
			resolvedAttractDelays[propCount] =
				resolveDynamic(settings.AttractDelay, PropManager.Defaults.AttractDelay, propIndex)
			resolvedAttractDurations[propCount] = math.max(
				0.001,
				resolveDynamic(settings.AttractDuration, PropManager.Defaults.AttractDuration, propIndex)
			)

			groupCounts[groupId] = (groupCounts[groupId] or 0) + 1
		end
	end)

	if not success then
		local hadSpawned = (groupCounts[groupId] or 0) > 0

		-- Stream-rollback: walk descending and swap-remove group members in place.
		-- Safe because swap-remove only pulls from `propCount`, which decreases monotonically.
		for i = propCount, 1, -1 do
			if groupIds[i] == groupId then
				local prop = propInstances[i]
				swapRemoveAtIndex(i)
				PropUtil.Destroy(prop)

				if settings.OnRemoved then
					xpcall(settings.OnRemoved, reportCallbackError, true)
				end
			end
		end

		groupCounts[groupId] = nil
		local cb = groupOnAllRemoved[groupId]
		groupOnAllRemoved[groupId] = nil

		-- Only fire OnAllRemoved if at least one prop ever made it into the group.
		if cb and hadSpawned then
			xpcall(cb, reportCallbackError)
		end

		error(`\n{errMessage}`, 3)
	end
end

return PropManager
