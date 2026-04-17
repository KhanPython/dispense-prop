--!strict
--!native
--!optimize 2

local Types = require(script.Parent.Parent.Types)
type DynamicNumber = Types.DynamicNumber

-- Resolves a DynamicNumber to a concrete number.
-- number -> returned as-is, Vector2 -> random in [X, Y], function -> called with propIndex
local function resolveDynamic(value: DynamicNumber?, default: number, propIndex: number): number
	if value == nil then
		return default
	end
	if typeof(value) == "number" then
		return value
	end
	if typeof(value) == "Vector2" then
		local lo = math.min(value.X, value.Y)
		local hi = math.max(value.X, value.Y)
		return lo + math.random() * (hi - lo)
	end
	if typeof(value) == "function" then
		local result = (value :: (number) -> number)(propIndex)
		if typeof(result) == "number" then
			return result
		end
		warn(
			`[Dispense-Prop] DynamicNumber function returned {typeof(result)} (expected number); falling back to default {default}`
		)
		return default
	end
	return default
end

return resolveDynamic
