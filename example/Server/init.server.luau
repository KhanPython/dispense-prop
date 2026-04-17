--!strict

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local PROPS_GROUP = "Props"
local PLAYER_GROUP = "Player"

PhysicsService:RegisterCollisionGroup(PROPS_GROUP)
PhysicsService:RegisterCollisionGroup(PLAYER_GROUP)
PhysicsService:CollisionGroupSetCollidable(PROPS_GROUP, PLAYER_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(PROPS_GROUP, PROPS_GROUP, false)

local function setCharacterCollisionGroup(character: Model)
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = PLAYER_GROUP
		end
	end

	character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = PLAYER_GROUP
		end
	end)
end

local function onPlayerAdded(player: Player)
	if player.Character then
		setCharacterCollisionGroup(player.Character)
	end
	player.CharacterAdded:Connect(setCharacterCollisionGroup)
end

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
