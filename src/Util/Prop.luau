--!strict
--!native
--!optimize 2

local Types = require(script.Parent.Parent.Types)
type PropInstance = Types.PropInstance

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
