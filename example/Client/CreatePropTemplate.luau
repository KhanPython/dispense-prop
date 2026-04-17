--!strict

local propTemplateCache: { [string]: Model } = {}

local function createPropTemplate(currency: string, imageId: string): Model
	local cached = propTemplateCache[currency]
	if cached then
		return cached
	end

	local part = Instance.new("Part")
	part.Name = "Part"
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.TopSurface = Enum.SurfaceType.Smooth
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.AudioCanCollide = false
	part.EnableFluidForces = false
	part.Material = Enum.Material.SmoothPlastic
	part.Massless = true
	part.Size = Vector3.new(1.457, 1.457, 1.457)
	part.Transparency = 1

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BillboardGui"
	billboard.Active = true
	billboard.Brightness = 2
	billboard.ClipsDescendants = true
	billboard.LightInfluence = 0.2
	billboard.MaxDistance = 187.445
	billboard.ResetOnSpawn = false
	billboard.Size = UDim2.fromScale(1.95221, 1.95221)
	billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	billboard.Parent = part

	local glow = Instance.new("ImageLabel")
	glow.Name = "Glow"
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.BackgroundTransparency = 1
	glow.Image = "rbxassetid://7383350722"
	glow.Position = UDim2.fromScale(0.5, 0.5)
	glow.Size = UDim2.fromScale(1, 1)
	glow.Parent = billboard

	local icon = Instance.new("ImageLabel")
	icon.Name = "Currency"
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = imageId
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Size = UDim2.fromScale(0.7, 0.7)
	icon.ZIndex = 2
	icon.Parent = billboard

	local model = Instance.new("Model")
	model.Name = currency
	model.PrimaryPart = part
	part.Parent = model

	propTemplateCache[currency] = model

	return model
end

return createPropTemplate
