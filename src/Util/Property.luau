local module = {}

function module.HasProperty(instance: Instance, propertyName: string): boolean
	local success = pcall(function()
		return instance[propertyName]
	end)

	return success
end

function module.SetProperty(instance: Instance, propertyTab: { [any]: any })
	for propertyName, propertyValue in pairs(propertyTab) do
		if module.HasProperty(instance, propertyName) then
			pcall(function()
				instance[propertyName] = propertyValue
			end)
		end
	end

	local children = instance:GetChildren()
	for _, child in children do
		module.SetProperty(child, propertyTab)
	end
end

return module
