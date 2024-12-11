local module = {}

function module.HasProperty(instance: Instance, propertyName: string): boolean
	local success = pcall(function()
		return instance[propertyName]
	end)

	return success
end

function module.SetProperty(instance: Instance, propertyTab: { [any]: any })
	for propertyName, propertyValue in pairs(propertyTab) do
		local success, hasProperty = pcall(function()
			return module.HasProperty(instance, propertyName)
		end)

		if success and hasProperty then
			pcall(function()
				instance[propertyName] = propertyValue
			end)
		end
	end

	if #instance:GetChildren() > 0 then
		for _, child in pairs(instance:GetChildren()) do
			module.SetProperty(child, propertyTab)
		end
	end
end

return module
