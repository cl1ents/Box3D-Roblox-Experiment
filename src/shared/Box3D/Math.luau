--!strict

export type Quaternion = {
	x: number,
	y: number,
	z: number,
	w: number,
}

local Math = {}

function Math.quaternionFromCFrame(cframe: CFrame): Quaternion
	local _, _, _, m00, m01, m02, m10, m11, m12, m20, m21, m22 = cframe:GetComponents()
	local trace = m00 + m11 + m22

	if trace > 0 then
		local s = math.sqrt(trace + 1) * 2
		return {
			x = (m21 - m12) / s,
			y = (m02 - m20) / s,
			z = (m10 - m01) / s,
			w = 0.25 * s,
		}
	elseif m00 > m11 and m00 > m22 then
		local s = math.sqrt(1 + m00 - m11 - m22) * 2
		return {
			x = 0.25 * s,
			y = (m01 + m10) / s,
			z = (m02 + m20) / s,
			w = (m21 - m12) / s,
		}
	elseif m11 > m22 then
		local s = math.sqrt(1 + m11 - m00 - m22) * 2
		return {
			x = (m01 + m10) / s,
			y = 0.25 * s,
			z = (m12 + m21) / s,
			w = (m02 - m20) / s,
		}
	else
		local s = math.sqrt(1 + m22 - m00 - m11) * 2
		return {
			x = (m02 + m20) / s,
			y = (m12 + m21) / s,
			z = 0.25 * s,
			w = (m10 - m01) / s,
		}
	end
end

function Math.cframeFromQuaternion(position: Vector3, q: Quaternion): CFrame
	local xx = q.x * q.x
	local yy = q.y * q.y
	local zz = q.z * q.z
	local xy = q.x * q.y
	local xz = q.x * q.z
	local yz = q.y * q.z
	local wx = q.w * q.x
	local wy = q.w * q.y
	local wz = q.w * q.z

	return CFrame.new(
		position.X,
		position.Y,
		position.Z,
		1 - 2 * (yy + zz),
		2 * (xy - wz),
		2 * (xz + wy),
		2 * (xy + wz),
		1 - 2 * (xx + zz),
		2 * (yz - wx),
		2 * (xz - wy),
		2 * (yz + wx),
		1 - 2 * (xx + yy)
	)
end

return Math
