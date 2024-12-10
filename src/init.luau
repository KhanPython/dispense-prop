local RunService = game:GetService("RunService")

local Janitor = require(script.Parent.janitor)

local Util = script.Util
local PropertyUtil = require(Util.Property)

local CLEAR_DISTANCE = 3
local CLAIM_DELAY = 3

return function(params: {
	Amount: number,
	Origin: Vector3,
	TargetObject: Model | BasePart,
	PropInstance: Model,
	CollisionGroup: string?,
	ClearDistance: number?,
	ClaimDelay: number?,
	AutoDestroyTime: number?,
	AttractMagnitude: number?,
	AttractSpeed: number?,
	OnSpawn: (Model) -> ()?,
	OnCleared: () -> ()?,
	OnAllCleared: () -> ()?,
}): { Model }
	do
		assert(
			typeof(params.Amount) == "number" and params.Amount % 1 == 0,
			"Amount must be an integer number greater than or equal to 1"
		)
		assert(typeof(params.Origin) == "Vector3", "Origin must be a Vector3")
		assert(
			typeof(params.TargetObject) == "Instance"
				and (params.TargetObject:IsA("Model") or params.TargetObject:IsA("BasePart")),
			"TargetObject must be a Model or BasePart"
		)
		assert(
			typeof(params.PropInstance) == "Instance" and params.PropInstance:IsA("Model"),
			"PropInstance must be a Model"
		)
		assert(params.PropInstance.PrimaryPart, "PropInstance must have a PrimaryPart assigned!")
		assert(
			not params.CollisionGroup or typeof(params.CollisionGroup) == "string",
			"CollisionGroup must be a string"
		)
		assert(
			not params.ClearDistance or (typeof(params.ClearDistance) == "number" and params.ClearDistance > 0),
			"ClearDistance must be a positive number"
		)
		assert(
			not params.ClaimDelay or (typeof(params.ClaimDelay) == "number" and params.ClaimDelay > 0),
			"ClaimDelay must be a positive number"
		)
		assert(
			not params.AutoDestroyTime or (typeof(params.AutoDestroyTime) == "number" and params.AutoDestroyTime > 0),
			"AutoDestroyTime must be a positive number"
		)
		assert(
			not params.AttractMagnitude
				or (
					typeof(params.AttractMagnitude) == "number"
					and (typeof(params.AttractSpeed) == "number" and params.AttractSpeed > 0)
				),
			"AttractMagnitude must be a number. Must also reference AttractSpeed which expects a positive number."
		)
		assert(not params.OnSpawn or typeof(params.OnSpawn) == "function", "OnSpawn must be a function")
		assert(not params.OnCleared or typeof(params.OnCleared) == "function", "OnCleared must be a function")
		assert(not params.OnAllCleared or typeof(params.OnAllCleared) == "function", "OnAllCleared must be a function")
	end

	local propJanitorMap = {}
	local propList = {}
	local elapsed = os.time()
	local newJan = Janitor.new()

	params.ClearDistance = params.ClearDistance or CLEAR_DISTANCE
	params.ClaimDelay = params.ClaimDelay or CLAIM_DELAY

	newJan:Add(function()
		if params.OnAllCleared and typeof(params.OnAllCleared) == "function" then
			params.OnAllCleared()
		end
	end)

	newJan:Add(RunService.RenderStepped:Connect(function(dT)
		local currentTime = os.time()
		if currentTime - elapsed < params.ClaimDelay then
			return
		end

		if next(propJanitorMap) == nil then
			newJan:Destroy()
			return
		end

		if params.AutoDestroyTime and (currentTime - elapsed >= params.AutoDestroyTime) then
			newJan:Destroy()
			return
		end

		local targetPosition = params.TargetObject:GetPivot().Position
		local speed = params.AttractSpeed

		for prop, propJanitor in pairs(propJanitorMap) do
			local propPosition = prop:GetPivot().Position
			local direction = (targetPosition - propPosition).Unit
			local distance = (targetPosition - propPosition).Magnitude

			if distance <= params.ClearDistance then
				propJanitor:Cleanup()
			elseif params.AttractMagnitude and distance <= params.AttractMagnitude then
				PropertyUtil.SetProperty(prop, {
					Anchored = true,
					CanCollide = false,
				}):await()

				local moveDistance = math.min(speed * dT, distance)
				local newPosition = propPosition + direction * moveDistance

				prop:PivotTo(CFrame.new(newPosition))
			else
				PropertyUtil.SetProperty(prop, {
					Anchored = false,
				}):await()
			end
		end
	end))

	for _ = 1, params.Amount do
		local newProp = params.PropInstance:Clone()

		local propJanitor = Janitor.new()
		newJan:Add(propJanitor, "Destroy")
		propJanitor:Add(newProp, "Destroy")

		propJanitorMap[newProp] = propJanitor
		propList[newProp] = true

		propJanitor:Add(function()
			if newJan.CurrentlyCleaning then
				return
			end

			propJanitorMap[newProp] = nil
			propList[newProp] = nil

			if params.OnCleared and typeof(params.OnCleared) == "function" then
				params.OnCleared()
			end
		end)

		do
			PropertyUtil.SetProperty(newProp, {
				CanTouch = false,
				CanQuery = false,
				CanCollide = true,
				Anchored = false,
				Massless = false,
				CollisionGroup = params.CollisionGroup,
			}):await()
			newProp:PivotTo(CFrame.new(params.Origin))
		end

		if params.OnSpawn and typeof(params.OnSpawn) == "function" then
			params.OnSpawn(newProp)
		end
	end

	return propList
end
