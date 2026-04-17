--!strict

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UserInputService = game:GetService("UserInputService")

local DispenseProp = require(ReplicatedFirst.DispenseProp)
local createPropTemplate = require(script.CreatePropTemplate)

local player = Players.LocalPlayer

local PROP_IMAGE = "rbxassetid://15993201893" -- Replace with your currency image
local PROP_AMOUNT = 100
local LAUNCH_KEY = Enum.KeyCode.Q

local propTemplate = createPropTemplate("Coin", PROP_IMAGE)

local function createAlignPosition(part: BasePart)
	local newAttachment0 = Instance.new("Attachment")
	local newAlignOrientation = Instance.new("AlignOrientation")
	newAlignOrientation.Enabled = true
	newAlignOrientation.Responsiveness = math.random(3, 10)
	newAlignOrientation.RigidityEnabled = false
	newAlignOrientation.ReactionTorqueEnabled = true
	newAlignOrientation.Attachment0 = newAttachment0

	newAlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	newAlignOrientation.Parent = part
	newAttachment0.Orientation = Vector3.new(0, math.random(90, 360), 0)
	newAttachment0.Parent = part

	task.defer(function()
		local spreadDirection = Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1).Unit

		local forceMagnitude = math.random(20, 40)
		local upward = Vector3.yAxis * math.random(20, 40)

		local impulse = (spreadDirection * forceMagnitude + upward) * part.AssemblyMass
		part:ApplyImpulse(impulse)
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode ~= LAUNCH_KEY then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoidRootPart then
		return
	end

	local originCFrame = humanoidRootPart.CFrame

	local spawnCount = 0
	local BATCH_SIZE = 10

	DispenseProp:Start(PROP_AMOUNT, originCFrame, propTemplate, humanoidRootPart, {
		AttractDelay = Vector2.new(0.3, 1.2),
		AttractDuration = Vector2.new(0.4, 0.8),
		CollisionGroup = "Props",

		OnSpawn = function(prop: Model | BasePart)
			local primaryPart: BasePart = (prop :: any):IsA("Model") and (prop :: Model).PrimaryPart or prop :: BasePart
			createAlignPosition(primaryPart)
			prop.Parent = workspace

			spawnCount += 1
			if spawnCount % BATCH_SIZE == 0 then
				task.wait()
			end
		end,

		OnAllRemoved = function()
			print("All props collected!")
		end,
	})
end)
