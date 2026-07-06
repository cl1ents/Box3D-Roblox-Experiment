local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Box3D = require(ReplicatedStorage.Shared.Box3D)

local existing = workspace:FindFirstChild("Box3D Cradle Demo")
if existing then
	existing:Destroy()
end

local model = Instance.new("Model")
model.Name = "Box3D Cradle Demo"
model.Parent = workspace

local function makePart(name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

local function makeBall(name, radius, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
	part.Color = color
	part.Material = Enum.Material.Metal
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

local function rodCFrame(a, b)
	local delta = b - a
	return CFrame.lookAt(a + delta * 0.5, b)
end

local t = os.clock()
local world = Box3D.World.create(Vector3.new(0, -60, 0))
Box3D.World.setRestitutionThreshold(world, 0.05)
Box3D.World.setContactTuning(world, 240, 0.15, 1)

local ballCount = 5
local radius = 1.15
local spacing = radius * 2.02
local ropeLength = 11
local pivotHeight = 17
local z = 0
local startX = -((ballCount - 1) * spacing) * 0.5
local pullAngle = math.rad(42)

local frameColor = Color3.fromRGB(35, 42, 54)
local rodColor = Color3.fromRGB(180, 190, 205)
local ballColor = Color3.fromRGB(235, 239, 245)
local activeColor = Color3.fromRGB(255, 168, 72)

makePart("Base", Vector3.new(18, 0.6, 8), CFrame.new(0, 0, 0), Color3.fromRGB(45, 50, 60), Enum.Material.Slate)
makePart("Top Beam", Vector3.new(18, 0.45, 0.45), CFrame.new(0, pivotHeight + 0.35, z), frameColor, Enum.Material.Metal)
makePart("Left Upright", Vector3.new(0.45, pivotHeight, 0.45), CFrame.new(-9, pivotHeight * 0.5, z), frameColor, Enum.Material.Metal)
makePart("Right Upright", Vector3.new(0.45, pivotHeight, 0.45), CFrame.new(9, pivotHeight * 0.5, z), frameColor, Enum.Material.Metal)

local bodies = {}
local balls = {}
local rods = {}
local pivots = {}

for i = 1, ballCount do
	local x = startX + (i - 1) * spacing
	local pivot = Vector3.new(x, pivotHeight, z)
	local position = pivot + Vector3.new(0, -ropeLength, 0)

	if i == 1 then
		position = pivot + Vector3.new(-math.sin(pullAngle) * ropeLength, -math.cos(pullAngle) * ropeLength, 0)
	end

	local pivotBody = Box3D.Body.create(world, {
		bodyType = Box3D.BodyType.Static,
		position = pivot,
	})

	local ballBody = Box3D.Body.create(world, {
		bodyType = Box3D.BodyType.Dynamic,
		position = position,
	})
	Box3D.Shape.createSphere(ballBody, radius, {
		density = 6,
		friction = 0.03,
		restitution = 0.98,
	})
	Box3D.Body.setLinearDamping(ballBody, 0.01)
	Box3D.Body.setAngularDamping(ballBody, 0.02)
	Box3D.Joint.createDistance(world, pivotBody, ballBody, Vector3.zero, Vector3.zero, ropeLength)

	pivots[i] = pivot
	bodies[i] = ballBody
	balls[i] = makeBall(`Bob {i}`, radius, if i == 1 then activeColor else ballColor)
	rods[i] = makePart(`Rod {i}`, Vector3.new(0.08, 0.08, ropeLength), CFrame.new(), rodColor, Enum.Material.Metal)
end

local accumulator = 0
local step = 1 / 60
local samples = 0
local totalStepTime = 0

print(`Cradle setup took {(os.clock() - t) * 1000}ms`)

RunService.Heartbeat:Connect(function(deltaTime)
	accumulator += math.min(deltaTime, 0.1)

	while accumulator >= step do
		local t0 = os.clock()
		Box3D.World.step(world, step, 8)
		totalStepTime += os.clock() - t0
		accumulator -= step

		samples += 1
		if samples % 120 == 0 then
			print(`Box3D cradle avg step: {(totalStepTime / samples) * 1000} ms`)
		end
	end

	for i = 1, ballCount do
		local ballCFrame = Box3D.Body.getCFrame(bodies[i])
		local bobPosition = ballCFrame.Position
		local pivot = pivots[i]
		local rodLength = (bobPosition - pivot).Magnitude

		balls[i].CFrame = ballCFrame
		rods[i].Size = Vector3.new(0.08, 0.08, rodLength)
		rods[i].CFrame = rodCFrame(pivot, bobPosition)
	end
end)
