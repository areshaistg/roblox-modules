-- Lightning Module

-- Functions
local function Lerp(a, b, t)
	return a + (b - a) * t
end

local function GetColor(Seq, Perc)
	local Min, Next = nil, nil;

	for i, v in pairs(Seq.Keypoints) do
		if (not Min) then
			Min, Next = v, Seq.Keypoints[i+1] or v;
		else
			if (v.Time > Min.Time and v.Time <= Perc) then
				Min, Next = v, Seq.Keypoints[i+1] or v;
			end
		end
	end
	local Diff = (Perc - Min.Time) / (Next.Time - Min.Time);

	return Min.Value:lerp(Next.Value, Diff);
end

function evalNS(ns, time)
	-- If we are at 0 or 1, return the first or last value respectively
	if time == 0 then return ns.Keypoints[1].Value end
	if time == 1 then return ns.Keypoints[#ns.Keypoints].Value end
	-- Step through each sequential pair of keypoints and see if alpha
	-- lies between the points' time values.
	for i = 1, #ns.Keypoints - 1 do
		local this = ns.Keypoints[i]
		local next = ns.Keypoints[i + 1]
		if time >= this.Time and time < next.Time then
			-- Calculate how far alpha lies between the points
			local alpha = (time - this.Time) / (next.Time - this.Time)
			-- Evaluate the real value between the points using alpha
			return (next.Value - this.Value) * alpha + this.Value
		end
	end
end

local function LinearTriangle(t)
	if t < 0.5 then
		return math.clamp(Lerp(0, 1, t * 2), 0, 1)
	end
	return math.clamp(Lerp(1, 0, (t - 0.5) * 2), 0, 1)
end

-- Lightning Instance
local Lightning: LightningInstance = {}
Lightning.__index = Lightning

type LightningInstance = {
	Color: ColorSequence;
	Transparency: NumberSequence;
	Highlight: Highlight?;
	Lifetime: NumberRange;
	Spread: Vector2;
	Frequency: number;
	Size: number;
	SparkLength: NumberRange;
	SparkSegments: number;
	SparkActive: NumberRange,

	BeamRate: number;
	BeamArc: number;
	Parent: Instance;

	create_part: (self: LightningInstance, p0: Vector3, p1: Vector3, s: number, c: Color3) -> ();
	spawn_particle: (self: LightningInstance, p0: Vector3, p1: Vector3) -> ();
	Spark: (self: LightningInstance, origin: CFrame, emitCount: number) -> ();
	Beam: (self: LightningInstance, p0: Vector3, p1: Vector3, lifetime: number) -> ();
}

function Lightning.new(): LightningInstance
	local self: LightningInstance = setmetatable({}, Lightning)

	self.Color = ColorSequence.new {
		ColorSequenceKeypoint.new(0, Color3.new(0.529412, 0.756863, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
	}
	self.Transparency = NumberSequence.new(0.75, 0)
	self.Highlight = nil
	self.Lifetime = NumberRange.new(0.05, 0.25)
	self.Spread = Vector2.new(50, 50)
	self.Frequency = 10
	self.Size = 0.4
	self.SparkLength = NumberRange.new(3, 13)
	self.SparkSegments = 10
	self.SparkActive = NumberRange.new(4, 5)
	self.BeamRate = 10
	self.BeamArc = 2
	self.Parent = workspace:WaitForChild("VFX")

	return self
end

function Lightning:create_part(p0, p1, s, c, t)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false

	p.Material = Enum.Material.Neon
	p.Color = c

	p.Transparency = t
	p.Size = Vector3.new(s, s, (p0 - p1).Magnitude + 0.1)
	p.CFrame = CFrame.new(p0:Lerp(p1, 0.5), p1)

	return p
end

function Lightning:spawn_particle(p0: Vector3, p1: Vector3, arc: number)
	local lifetime = Lerp(
		self.Lifetime.Min,
		self.Lifetime.Max,
		math.random()
	)

	local pos = {
		[1] = p0,
		[self.SparkSegments] = p1
	}

	local n = math.random() * 200
	for i = 2, self.SparkSegments - 1 do
		pos[i] = p0:Lerp(p1, i / self.SparkSegments) + Vector3.new(
			(math.noise(n+i/self.SparkSegments*self.Frequency)) * 2,
			(math.noise(0, n+i/self.SparkSegments*self.Frequency)) * 2,
			(math.noise(0, 0, n+i/self.SparkSegments*self.Frequency)) * 2
		) * LinearTriangle(i / self.SparkSegments) * arc
	end

	local active = Lerp(
		self.SparkActive.Min,
		self.SparkActive.Max,
		math.random()
	)

	local interval = lifetime / (self.SparkSegments - 1)

	local parts = Instance.new("Model")
	if self.Highlight then
		local hl = self.Highlight:Clone()
		hl.Adornee = parts
		hl.Parent = parts
	end
	parts.Parent = self.Parent

	for i = 1, active do

		for j = 1, i -1 do
			local _p0 = pos[j]
			local _p1 = pos[j + 1]

			local s = (
				(j + .5) / i - 1
			) * self.Size
			if active == 1 then
				s = 0.05
			end

			local c = GetColor(self.Color, (j + .5) / active)
			local t = math.clamp(
				evalNS(self.Transparency, (j + .5) / active),
				0, 1
			)

			self:create_part(_p0, _p1, s, c, t).Parent = parts
		end

		task.wait(interval)

		for _, part in ipairs(parts:GetChildren()) do
			if part:IsA("BasePart") then
				part:Destroy()
			end
		end

	end

	for i = 1, self.SparkSegments - 1 do
		local _active = math.min((active - 1), self.SparkSegments - 1 - i)

		for j = 0, _active do
			local _p0 = pos[i + j]
			local _p1 = pos[i + j + 1]

			local s = (
				(j + .5) / active
			) * self.Size
			if active == 1 then
				s = 0.05
			end

			local c = GetColor(self.Color, (j + .5) / active)
			local t = math.clamp(
				evalNS(self.Transparency, (j + .5) / active),
				0, 1
			)

			self:create_part(_p0, _p1, s, c, t).Parent = parts
		end

		task.wait(interval)

		for _, part in ipairs(parts:GetChildren()) do
			if part:IsA("BasePart") then
				part:Destroy()
			end
		end

	end

	parts:Destroy()
end

function Lightning:Spark(origin: CFrame, emitCount: number)
	local position = origin.Position
	for _ = 1, emitCount do
		local length = Lerp(
			self.SparkLength.Min,
			self.SparkLength.Max,
			math.random()
		)

		local p1 = position + (origin * CFrame.Angles(
			Lerp(
				-math.rad(self.Spread.X),
				math.rad(self.Spread.X),
				math.random()
			),
			Lerp(
				-math.rad(self.Spread.Y),
				math.rad(self.Spread.Y),
				math.random()
			),
			0
		)).LookVector * length

		task.spawn(self.spawn_particle, self, position, p1, 1.5)
	end
end

function Lightning:Beam(p0: Vector3, p1: Vector3, lifetime: number)
	local t = lifetime
	local rate = 1 / self.BeamRate

	task.spawn(function()
		while lifetime == 0 or t > 0 do
			if lifetime ~= 0 then
				t -= task.wait(rate)
			end
			task.spawn(self.spawn_particle, self, p0, p1, self.BeamArc)
		end
	end)
end

return Lightning :: { new: () -> (LightningInstance) }
