--!strict
--!native
--!optimize 2

type PropInstance = Model | BasePart

local module = {}

function module.GetPrimaryPart(prop: PropInstance): BasePart?
	if prop:IsA("Model") then
		return prop.PrimaryPart
	end
	return prop :: BasePart
end

function module.Destroy(prop: PropInstance)
	if typeof(prop) ~= "Instance" or not prop:IsDescendantOf(game) then
		return
	end
	pcall(prop.Destroy, prop)
end

return module
