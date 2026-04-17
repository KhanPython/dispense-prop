--!strict
--!native
--!optimize 2

local module = {}

local function trySet(instance: Instance, name: string, value: any)
	(instance :: any)[name] = value
end

-- Internal utility for applying BasePart-only properties across a tree.
-- Non-BasePart descendants (Attachments, Welds, ParticleEmitters, ...) are skipped.
function module.SetProperty(instance: Instance, propertyTab: { [string]: any })
	if instance:IsA("BasePart") then
		for name, value in propertyTab do
			pcall(trySet, instance, name, value)
		end
	end

	for _, child in instance:GetChildren() do
		module.SetProperty(child, propertyTab)
	end
end

return module
