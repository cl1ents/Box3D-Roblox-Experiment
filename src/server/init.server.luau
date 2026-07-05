local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Box3D = require(ReplicatedStorage:WaitForChild("Box3D"))

task.wait(5)

Box3D._initialize()

local memory = Box3D.memory[1]
local transformPtr = 1024 * 1024

local world = Box3D.b3d_create_world(0, -50, 0)
local rampAngle = math.rad(18)
local rampQz = math.sin(rampAngle / 2)
local rampQw = math.cos(rampAngle / 2)

local groundBody = Box3D.b3d_create_body(world, 0, 0, -1, 0, 0, 0, 0, 1)
Box3D.b3d_create_box(groundBody, 32, 1, 32, 0, 0.5, 0)

local rampBody = Box3D.b3d_create_body(world, 0, -8, 4, 0, 0, 0, rampQz, rampQw)
Box3D.b3d_create_box(rampBody, 14, 1, 8, 0, 0.65, 0)

local ballBody = Box3D.b3d_create_body(world, 2, -16, 18, 0, 0, 0, 0, 1)
Box3D.b3d_create_sphere(ballBody, 2, 1, 0.5, 0.1)

local ground = Instance.new("Part")
ground.Name = "Box3D Ground"
ground.Anchored = true
ground.Size = Vector3.new(64, 2, 64)
ground.Position = Vector3.new(0, -1, 0)
ground.Color = Color3.fromRGB(74, 80, 92)
ground.Parent = workspace

local ramp = Instance.new("Part")
ramp.Name = "Box3D Ramp"
ramp.Anchored = true
ramp.Size = Vector3.new(28, 2, 16)
ramp.CFrame = CFrame.new(-8, 4, 0) * CFrame.Angles(0, 0, rampAngle)
ramp.Color = Color3.fromRGB(90, 138, 255)
ramp.Parent = workspace

local ball = Instance.new("Part")
ball.Name = "Box3D Sphere"
ball.Shape = Enum.PartType.Ball
ball.Anchored = true
ball.Size = Vector3.new(4, 4, 4)
ball.Color = Color3.fromRGB(255, 174, 66)
ball.Parent = workspace

local accumulator = 0
local step = 1 / 60

local function cframeFromQuaternion(
	x: number,
	y: number,
	z: number,
	qx: number,
	qy: number,
	qz: number,
	qw: number
): CFrame
	local xx = qx * qx
	local yy = qy * qy
	local zz = qz * qz
	local xy = qx * qy
	local xz = qx * qz
	local yz = qy * qz
	local wx = qw * qx
	local wy = qw * qy
	local wz = qw * qz

	return CFrame.new(
		x,
		y,
		z,
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

RunService.Heartbeat:Connect(function(deltaTime)
	accumulator += math.min(deltaTime, 0.1)

	while accumulator >= step do
		Box3D.b3d_step(world, step, 4)
		accumulator -= step
	end

	Box3D.b3d_get_body_transform(ballBody, transformPtr)

	local x = buffer.readf32(memory, transformPtr)
	local y = buffer.readf32(memory, transformPtr + 4)
	local z = buffer.readf32(memory, transformPtr + 8)
	local qx = buffer.readf32(memory, transformPtr + 12)
	local qy = buffer.readf32(memory, transformPtr + 16)
	local qz = buffer.readf32(memory, transformPtr + 20)
	local qw = buffer.readf32(memory, transformPtr + 24)

	ball.CFrame = cframeFromQuaternion(x, y, z, qx, qy, qz, qw)
end)
