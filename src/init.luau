local RunService = game:GetService("RunService")

local Promise = require(script.Parent.promise)
local Janitor = require(script.Parent.janitor)

local Util = script.Util
local PropertyUtil = require(Util.Property)

return function(params: {
	Amount: number,
	Origin: Vector3,
	TargetObject: Model | BasePart,
	PropInstance: Model,
	CollisionGroup: string?,
	AutoDestroyTime: number?,
	AttractDistance: number?,
	OnDispense: (Model) -> ()?,
	OnPropClaim: () -> ()?,
	OnAllClaimed: () -> ()?,
})
	return Promise.new(function(resolve, _reject)
		assert(
			typeof(params.Amount) == "number" and params.Amount % 1 == 0,
			"Amount must be an integer number greater than or equal to 1"
		)
		params.Amount = math.max(1, params.Amount)
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
			"CollisionGroup must be a string if provided"
		)
		assert(
			not params.AutoDestroyTime or typeof(params.AutoDestroyTime) == "number",
			"AutoDestroyTime must be a number if provided"
		)
		assert(
			not params.AttractDistance or typeof(params.AttractDistance) == "number",
			"AttractDistance must be a number if provided"
		)
		assert(
			not params.OnDispense or typeof(params.OnDispense) == "function",
			"OnDispense must be a function if provided"
		)
		assert(
			not params.OnPropClaim or typeof(params.OnPropClaim) == "function",
			"OnPropClaim must be a function if provided"
		)
		assert(
			not params.OnAllClaimed or typeof(params.OnAllClaimed) == "function",
			"OnAllClaimed must be a function if provided"
		)

		params.Amount = math.max(1, params.Amount)

		local propJanitorMap = {}
		local propList = {}
		local elapsed = os.time()
		local newJan = Janitor.new()

		newJan:Add(function()
			if params.OnAllClaimed and typeof(params.OnAllClaimed) == "function" then
				params.OnAllClaimed()
			end
		end)

		newJan:Add(RunService.RenderStepped:Connect(function(dT)
			local currentTime = os.time()
			if currentTime - elapsed < 1 then
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
			for prop, propJanitor in pairs(propJanitorMap) do
				local propPosition = prop:GetPivot().Position

				if (propPosition - targetPosition).Magnitude <= 3 then
					propJanitor:Cleanup()
				elseif (propPosition - targetPosition).Magnitude <= params.AttractDistance then
					PropertyUtil.SetProperty(prop, {
						Anchored = true,
					}):await()

					local currentCFrame = prop:GetPivot()
					local targetCFrame = CFrame.new(targetPosition)
					local lerpedCFrame = currentCFrame:Lerp(targetCFrame, math.clamp(0.2 * dT, 0, 1))

					prop:PivotTo(lerpedCFrame)
				else
					PropertyUtil.SetProperty(prop, {
						Anchored = false,
					}):await()
				end
			end
		end))

		for _ = 1, params.Amount do
			task.spawn(function()
				local newProp = params.PropInstance:Clone()

				do
					table.insert(propList, newProp)
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

				local propJanitor = Janitor.new()
				newJan:AddObject(propJanitor, "Destroy")
				propJanitorMap[newProp] = propJanitor

				propJanitor:Add(function()
					if newJan.CurrentlyCleaning then
						return
					end

					propJanitorMap[newProp] = nil

					if params.OnPropClaim and typeof(params.OnPropClaim) == "function" then
						params.OnPropClaim()
					end
				end)

				if params.OnDispense and typeof(params.OnDispense) == "function" then
					params.OnDispense(newProp)
				end
			end)
		end

		resolve()
	end)
end
