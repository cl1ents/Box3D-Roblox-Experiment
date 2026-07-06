local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Box3D = require(ReplicatedStorage.Shared.Box3D)
task.wait(5)

local t = os.clock()
local world = Box3D.World.create(Vector3.new(0, -50, 0))
local rampAngle = math.rad(18)

local groundBody = Box3D.Body.create(world, {
	bodyType = Box3D.BodyType.Static,
	position = Vector3.new(0, -1, 0),
})
Box3D.Shape.createBox(groundBody, Vector3.new(64, 2, 64), { density = 0, friction = 0.5 })

local rampCFrame = CFrame.new(-8, 4, 0) * CFrame.Angles(0, 0, rampAngle)
local rampBody = Box3D.Body.create(world, {
	bodyType = Box3D.BodyType.Static,
	cframe = rampCFrame,
})
Box3D.Shape.createBox(rampBody, Vector3.new(28, 2, 16), { density = 0, friction = 0.65 })

local ballBody = Box3D.Body.create(world, {
	bodyType = Box3D.BodyType.Dynamic,
	position = Vector3.new(-16, 18, 0),
})
Box3D.Shape.createSphere(ballBody, 2, { density = 1, friction = 0.5, restitution = 0.1 })

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

local samples = 0
local totalStepTime = 0
print(`Setup took {(os.clock() - t) * 1000}ms`)

RunService.Heartbeat:Connect(function(deltaTime)
	accumulator += math.min(deltaTime, 0.1)

	while accumulator >= step do
		local t0 = os.clock()
		Box3D.World.step(world, step, 4)
		local elapsed = os.clock() - t0
		accumulator -= step

		samples += 1
		totalStepTime += elapsed
		if samples % 120 == 0 then
			print(`Box3D avg step: {(totalStepTime / samples) * 1000} ms`)
		end
	end

	ball.CFrame = Box3D.Body.getCFrame(ballBody)
end)
