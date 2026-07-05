local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Box3D = require(ReplicatedStorage:WaitForChild("Box3D"))

local world = Box3D.createWorld(Vector3.new(0, -50, 0))
local rampAngle = math.rad(18)

local groundBody = Box3D.createBody(world, {
	bodyType = Box3D.BodyType.Static,
	position = Vector3.new(0, -1, 0),
})
Box3D.createBox(groundBody, Vector3.new(64, 2, 64), { density = 0, friction = 0.5 })

local rampCFrame = CFrame.new(-8, 4, 0) * CFrame.Angles(0, 0, rampAngle)
local rampBody = Box3D.createBody(world, {
	bodyType = Box3D.BodyType.Static,
	cframe = rampCFrame,
})
Box3D.createBox(rampBody, Vector3.new(28, 2, 16), { density = 0, friction = 0.65 })

local ballBody = Box3D.createBody(world, {
	bodyType = Box3D.BodyType.Dynamic,
	position = Vector3.new(-16, 18, 0),
})
Box3D.createSphere(ballBody, 2, { density = 1, friction = 0.5, restitution = 0.1 })

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
ramp.CFrame = rampCFrame
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

RunService.Heartbeat:Connect(function(deltaTime)
	accumulator += math.min(deltaTime, 0.1)

	while accumulator >= step do
		Box3D.step(world, step, 4)
		accumulator -= step
	end

	ball.CFrame = Box3D.getBodyCFrame(ballBody)
end)
