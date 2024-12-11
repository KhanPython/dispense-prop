--!strict
--!native
--!optimize 2

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local PropertyUtil = require(script.Util.Property)

export type PropInstance = Model | BasePart
export type TargetInstance = Model | BasePart
export type PropSettings = {
	RemoveMagnitude: number?,
	AttractSpeed: number?,
	AttractMagnitude: number?,
	AttractDelay: number?,
	AutoRemoveTime: number?,
	CollisionGroup: string?,
	OnSpawn: (PropInstance) -> (),
	OnRemoved: ((boolean?) -> ())?, -- returns a boolean, to indicate if the cleared has been the result of an automatic clean-up
	OnAllRemoved: (() -> ())?,
}
export type PropData = {
	Instance: PropInstance,
	Target: TargetInstance,
	SpawnTime: number,
	Settings: PropSettings,
	AncestryChanged: RBXScriptConnection,
}

local PropManager = {}

PropManager.ActiveProps = {}

PropManager.Defaults = {
	ClearMagnitude = 5,
	AttractSpeed = 10,
	AttractDelay = 1,
	CollisionGroup = "Default",
}

local function updateProp(propData: PropData, dT: number)
	local prop = propData.Instance
	local target = propData.Target
	local settings = propData.Settings
	local elapsedTime = os.clock() - propData.SpawnTime

	-- If `AutoDestroyTime` given and elapsed time exceeded, remove the prop
	if propData.Settings.AutoRemoveTime and elapsedTime >= propData.Settings.AutoRemoveTime then
		if settings.OnRemoved and typeof(settings.OnRemoved) == "function" then
			settings.OnRemoved(true)
		end

		PropManager:_RemoveProp(prop)
		return
	end

	-- Wait for the claim delay before processing logic
	if elapsedTime < (settings.AttractDelay or PropManager.Defaults.AttractDelay) then
		return
	end

	local targetPosition = target:GetPivot().Position
	local propPosition = prop:GetPivot().Position
	local distance = (targetPosition - propPosition).Magnitude

	-- Clear the prop if it's within the clear distance
	if distance <= (settings.RemoveMagnitude or PropManager.Defaults.ClearMagnitude) then
		if settings.OnRemoved and typeof(settings.OnRemoved) == "function" then
			settings.OnRemoved()
		end

		PropManager:_RemoveProp(prop)
		return
	end

	-- Start attraction if within the attract magnitude
	if settings.AttractMagnitude and distance <= settings.AttractMagnitude then
		PropertyUtil.SetProperty(prop, {
			Anchored = true,
			CanCollide = false,
		})

		local direction = (targetPosition - propPosition).Unit
		local moveDistance = math.min((settings.AttractSpeed or PropManager.Defaults.AttractSpeed) * dT, distance)
		local newPosition = propPosition + direction * moveDistance
		prop:PivotTo(CFrame.new(newPosition, targetPosition))
	else
		PropertyUtil.SetProperty(prop, {
			Anchored = false,
			CanCollide = true,
		})
	end
end

function PropManager:_AddProp(
	groupId: string,
	originCFrame: CFrame,
	propTemplate: PropInstance,
	targetInstance: TargetInstance,
	settings: PropSettings
)
	local propInstance = propTemplate:Clone()
	assert(self.ActiveProps[groupId], `Unable to find an Active Prop Group under: {groupId}`)

	if settings.OnSpawn and typeof(settings.OnSpawn) == "function" then
		local success, errMessage = pcall(function()
			settings.OnSpawn(propInstance)
		end)

		if not success then
			propInstance:Destroy()

			error(`OnSpawn error: {errMessage}`)
		end

		-- In-case the prop instance has been removed via OnSpawn
		if not propInstance or not propInstance:IsDescendantOf(game) then
			error("OnSpawn error: propInstance prematurely destroyed")
		end
	end

	local ancestryChangedConnection

	-- Clean-up logic
	ancestryChangedConnection = propInstance.AncestryChanged:Connect(function()
		if propInstance:IsDescendantOf(game) then
			return
		end

		if ancestryChangedConnection and typeof(ancestryChangedConnection) == "RBXScriptConnection" then
			ancestryChangedConnection:Disconnect()
		end

		self.ActiveProps[groupId][propInstance] = nil
		if next(self.ActiveProps[groupId]) == nil and settings.OnAllRemoved then
			settings.OnAllRemoved()
		end
	end)

	self.ActiveProps[groupId][propInstance] = {
		Instance = propInstance,
		Settings = settings,
		Target = targetInstance,
		SpawnTime = os.clock(),
		AncestryChanged = ancestryChangedConnection,
	} :: PropData

	propInstance:PivotTo(originCFrame)

	PropertyUtil.SetProperty(propInstance, {
		CanTouch = false,
		CanQuery = false,
		CanCollide = true,
		Anchored = false,
		CollisionGroup = settings.CollisionGroup or PropManager.Defaults.CollisionGroup,
	})
end

function PropManager:_RemoveProp(propInstance: PropInstance)
	if not propInstance or typeof(propInstance) ~= "Instance" then
		return
	end

	if not propInstance:IsDescendantOf(game) then
		return
	end

	propInstance:Destroy()
end

function PropManager:_Update(dT: number)
	debug.profilebegin("PropDispenser")

	for groupId, groupData in pairs(self.ActiveProps) do
		for propInstance, propData in pairs(groupData) do
			updateProp(propData, dT)
		end
	end

	debug.profileend()
end

RunService.Heartbeat:Connect(function(dT: number)
	PropManager:_Update(dT)
end)

function PropManager:Start(
	amount: number,
	originCFrame: CFrame,
	propTemplate: PropInstance,
	targetInstance: TargetInstance,
	settings: PropSettings
)
	do
		assert(
			typeof(amount) == "number" and amount % 1 == 0,
			"amount must be an integer number greater than or equal to 1"
		)
		assert(
			typeof(propTemplate) == "Instance" and (propTemplate:IsA("Model") or propTemplate:IsA("BasePart")),
			"propTemplate must be a Model"
		)
		assert(
			typeof(targetInstance) == "Instance" and (targetInstance:IsA("Model") or targetInstance:IsA("BasePart")),
			"targetInstance must be a Model or BasePart"
		)
		assert(typeof(settings) == "table", "settings must be a table")
		assert(typeof(originCFrame) == "CFrame", "OriginCFrame must be a CFrame")

		---
		assert(
			not settings.CollisionGroup or typeof(settings.CollisionGroup) == "string",
			"CollisionGroup must be a string"
		)
		assert(
			not settings.RemoveMagnitude
				or (typeof(settings.RemoveMagnitude) == "number" and settings.RemoveMagnitude > 0),
			"RemoveMagnitude must be a positive number"
		)
		assert(
			not settings.AttractDelay or (typeof(settings.AttractDelay) == "number" and settings.AttractDelay > 0),
			"AttractDelay must be a positive number"
		)
		assert(
			not settings.AutoRemoveTime or (typeof(settings.AutoRemoveTime) == "number" and settings.AutoRemoveTime > 0),
			"AutoRemoveTime must be a positive number"
		)
		assert(
			not settings.AttractMagnitude
				or (
					(typeof(settings.AttractMagnitude) == "number" and settings.AttractMagnitude > 0)
					and (typeof(settings.AttractSpeed) == "number" and settings.AttractSpeed > 0)
				),
			"AttractMagnitude and AttractSpeed must be positive numbers if is specified."
		)
		assert(typeof(settings.OnSpawn) == "function", "OnSpawn must be a function")
		assert(not settings.OnRemoved or typeof(settings.OnRemoved) == "function", "OnRemoved must be a function")
		assert(
			not settings.OnAllRemoved or typeof(settings.OnAllRemoved) == "function",
			"OnAllRemoved must be a function"
		)
	end

	local groupId = HttpService:GenerateGUID(false)
	self.ActiveProps[groupId] = {}

	local success, errMessage = pcall(function()
		for i = 1, amount do
			PropManager:_AddProp(groupId, originCFrame, propTemplate, targetInstance, settings)
		end
	end)

	if not success then
		if self.ActiveProps[groupId] then
			self.ActiveProps[groupId] = nil
		end

		error(errMessage)
	end
end

return PropManager
