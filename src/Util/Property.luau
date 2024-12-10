local module = {}

local Promise = require(script.Parent.Parent.Parent.promise)

function module.HasProperty(instance: Instance, propertyName: string)
	return Promise.new(function(resolve, reject)
		assert(typeof(instance) == "Instance", "The 'instance' parameter must be a valid Instance!")
		assert(
			typeof(propertyName) == "string" and propertyName ~= "",
			"The 'propertyName' parameter must be a non-empty string!"
		)

		local success = pcall(function()
			return instance[propertyName]
		end)
		if success then
			resolve(true)
		else
			reject("Property does not exist or cannot be accessed.")
		end
	end)
end

function module.SetProperty(instance: Instance, propertyTab: { [any]: any })
	return Promise.new(function(resolve)
		assert(typeof(instance) == "Instance", "The 'instance' parameter must be a valid Instance!")
		assert(
			typeof(propertyTab) == "table" and next(propertyTab),
			"The 'propertyTab' parameter must be a non-empty table!"
		)

		for propertyName, propertyValue in pairs(propertyTab) do
			local success, hasProperty = pcall(function()
				return module.HasProperty(instance, propertyName):expect()
			end)

			if success and hasProperty then
				pcall(function()
					instance[propertyName] = propertyValue
				end)
			end
		end

		if #instance:GetChildren() > 0 then
			for _, child in pairs(instance:GetChildren()) do
				module.SetProperty(child, propertyTab):await()
			end
		end

		resolve()
	end)
end

return module
