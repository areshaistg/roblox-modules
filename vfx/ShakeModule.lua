-- Services
local RunService = game:GetService("RunService")

-- Functions
local function lerp(a, b, t)
	return a + (b - a) * t
end

local function adjustedTriangle(h, t)
	if t < h then
		return math.clamp(t / h, 0, 1)
	else
		return math.clamp(((t-h)/(h-1)+1)^2, 0, 1)
	end
end

-- Shake Module
type Shake = {
	Callback: (any) -> (),
	NoiseOffset: number,
	Frequency: number,
	Strength: number,
	Active: boolean,
	Start: (self: Shake, lifetime: number) -> ()
}
local Shake = {}
Shake.__index = Shake

function Shake.new(): Shake
	local self: Shake = setmetatable({}, Shake)
	self.NoiseOffset = math.random() * 500
	self.Frequency = 2
	self.Strength = 2
	self.Active = false
	self.Callback = nil
	return self
end

function Shake.Start(self: Shake, lifetime: number)
	if not self.Callback then
		error("No callback found", 2)
	end
	if self.Active then
		return
	end

	self.Active = true

	self.NoiseOffset = math.random() * 500

	local t = 0
	while t <= lifetime do
		t += RunService.RenderStepped:Wait()

		local strength = adjustedTriangle(0.25, t / lifetime) * self.Strength

		local x = math.noise(self.NoiseOffset + (t * self.Frequency), 0, 0) * strength
		local y = math.noise(0, self.NoiseOffset + (t * self.Frequency), 0) * strength
		local z = math.noise(0, 0, self.NoiseOffset + (t * self.Frequency)) * strength

		local rx = math.noise(self.NoiseOffset + (t * self.Frequency), 0, 0) * strength
		local ry = math.noise(0, self.NoiseOffset + (t * self.Frequency), 0) * strength
		local rz = math.noise(0, 0, self.NoiseOffset + (t * self.Frequency)) * strength

		self.Callback(x, y, z, rx, ry, rz)
	end

	self.Active = false
end

-- Shake Helpers
local Helpers = {}

function Helpers.CFrame(callback): Shake
	local shake = Shake.new()

	shake.Callback = function(x, y, z, rx, ry, rz)
		callback(CFrame.new(
			x, y, z
			) * CFrame.Angles(
				math.rad(rx),
				math.rad(ry),
				math.rad(rz)
			))
	end

	return shake
end

function Helpers.Vector3(): Shake
	-- TODO: Implement this thing
	error("Not yet implemented", 1)
end

return Helpers
