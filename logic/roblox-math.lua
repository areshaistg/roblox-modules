local rbxMath = {}

-----------------------------------------------------------------------------------------
-- Random Functions
-----------------------------------------------------------------------------------------
function rbxMath.randomInv(fac)
	-- Random Inverted (automatically a float)
	return fac * ( math.random() - 0.5 ) * 2
end

function rbxMath.frandom(min, max)
	-- Float random
	return rbxMath.lerp(min, max, math.random())
end

-----------------------------------------------------------------------------------------
-- Interpolation
-----------------------------------------------------------------------------------------
function rbxMath.lerp(a, b, t)
	return a + (b - a) * t
end

function rbxMath.adjustedTriangle(h, t)
	if t < h then
		return math.clamp(t / h, 0, 1)
	else
		return math.clamp(((t-h)/(h-1)+1)^2, 0, 1)
	end
end

function rbxMath.linearTriangle(t)
	if t < 0.5 then
		return math.clamp(rbxMath.lerp(0, 1, t * 2), 0, 1)
	end
	return math.clamp(rbxMath.lerp(1, 0, (t - 0.5) * 2), 0, 1)
end

-----------------------------------------------------------------------------------------
-- Sequences and Ranges
-----------------------------------------------------------------------------------------
function rbxMath.getRange(n: NumberRange)
	return rbxMath.lerp( n.Min, n.Max, math.random() )
end

function rbxMath.evalColSeq(Seq, Perc)
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

function rbxMath.evalNumSeq(ns, time)
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

-----------------------------------------------------------------------------------------
return rbxMath
