--!strict
--!native
--!optimize 2

local STEEPNESS = 10

local function rawSigmoid(t: number): number
	return 1 / (1 + math.exp(-STEEPNESS * (t - 0.5)))
end

local MIN = rawSigmoid(0)
local RANGE = rawSigmoid(1) - MIN

local function sigmoidEase(t: number): number
	return (rawSigmoid(math.clamp(t, 0, 1)) - MIN) / RANGE
end

return sigmoidEase
