-- Services
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Functions
local function lerp(a, b, t)
	return a + (b - a) * t
end

local function randomInv(fac)
	-- Random Inverted
	return fac * ( math.random() - 0.5 ) * 2
end

local function getRange(n: NumberRange)
	return lerp( n.Min, n.Max, math.random() )
end

-- Hit Impact Module
type HitImpact = {
	Parent: Instance,
	Color: Color3,
	Mesh: MeshPart,

	Angle: number,
	Scale: NumberRange,
	Lifetime: NumberRange,
	Speed: NumberRange,

	Cast: (self: HitImpact, cf: CFrame) -> (),
	AnimateOnce: (self: HitImpact, cf: CFrame) -> (),
}
local HitImpact = {}
HitImpact.__index = HitImpact

function HitImpact.new(): HitImpact
	local self: HitImpact = setmetatable({}, HitImpact)

	self.Parent = workspace:WaitForChild("VFX")
	self.Color = Color3.fromRGB(255, 255, 255)
	self.Mesh = script:WaitForChild("shockwaveMesh")

	self.Angle = 0.3 -- 1 = quarter circle 0 = straight
	self.Scale = NumberRange.new(0.4, 0.7)
	self.Lifetime = NumberRange.new(0.1, 0.3)
	self.Speed = NumberRange.new(3, 5)

	return self
end

function HitImpact.AnimateOnce(self: HitImpact, cf: CFrame)

	local mesh = self.Mesh:Clone()
	mesh.Color = self.Color
	mesh.CFrame = cf * CFrame.new(0, math.random() * 3, 0)
	mesh.Size *= getRange(self.Scale)
	mesh.Parent = self.Parent

	local lifetime = getRange(self.Lifetime)
	Debris:AddItem(mesh, lifetime)

	TweenService:Create(
		mesh,
		TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			CFrame = mesh.CFrame * CFrame.new(0, getRange(self.Speed), 0),
			Size = mesh.Size * Vector3.new(0.02, 1.3, 0.02),
			Transparency = 0.5
		}
	):Play()

end

function HitImpact.Cast(self: HitImpact, cf: CFrame)
	for _ = 1, 5 do
		local angle = math.pi * self.Angle
		local origin = cf * CFrame.Angles(-math.pi * 0.5, 0, 0) * CFrame.Angles(
			randomInv(angle), 0, 0
		) * CFrame.Angles(
			0, randomInv(angle), 0
		) * CFrame.Angles(
			0, 0, randomInv(angle)
		)

		self:AnimateOnce(origin)
	end
end

return HitImpact :: { new: typeof(HitImpact.new) }
