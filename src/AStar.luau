--!strict

local Heap = require(script.Parent.BinaryHeap)

local AStar = {}

local CARDINAL = {
	Vector2.new(1, 0), Vector2.new(-1, 0), Vector2.new(0, 1), Vector2.new(0, -1),
}
local DIAGONAL = {
	Vector2.new(1, 1), Vector2.new(1, -1), Vector2.new(-1, 1), Vector2.new(-1, -1),
}

local function heuristic(a: Vector3, b: Vector3, mode: string): number
	local d = b - a
	if mode == "Fastest" then return math.max(math.abs(d.X), math.abs(d.Z)) + math.abs(d.Y) end
	local weight = if mode == "Efficient" then 1.12 else 1
	return d.Magnitude * weight
end

local function reconstruct(node)
	local result = {}
	while node do
		table.insert(result, 1, {Position = node.position, Action = node.action, Cost = node.g})
		node = node.parent
	end
	return result
end

function AStar.compute(startPosition: Vector3, goalPosition: Vector3, config, world, cancelled)
	local startGround = world:GroundAt(startPosition)
	local goalGround = world:GroundAt(goalPosition)
	if not startGround or not goalGround then return nil, "NoPath", 0 end

	local open = Heap.new()
	local nodes = {}
	local startKey = world.cache:Key(startGround)
	local first = {key = startKey, position = startGround, g = 0, h = heuristic(startGround, goalGround, config.SearchMode), f = 0, parent = nil, action = "Walk", closed = false}
	first.f = first.h
	nodes[startKey] = first
	open:Push(first)
	local closest = first
	local iterations = 0
	local sliceStarted = os.clock()

	while not open:IsEmpty() and iterations < config.MaxIterations do
		if cancelled() then return nil, "Cancelled", iterations end
		local current = open:Pop()
		if current.closed then continue end
		current.closed = true
		iterations += 1
		if current.h < closest.h then closest = current end
		if (current.position - goalGround).Magnitude <= config.GoalTolerance then
			return reconstruct(current), "Success", iterations
		end

		local directions = table.clone(CARDINAL)
		if config.AllowDiagonal then for _, direction in DIAGONAL do table.insert(directions, direction) end end
		for _, direction in directions do
			local probe = current.position + Vector3.new(direction.X * config.CellSize, 0, direction.Y * config.CellSize)
			local position, floorPart = world:GroundAt(probe)
			if not position then continue end
			local vertical = position.Y - current.position.Y
			local action = "Walk"
			if vertical > config.MaxStepHeight then
				if not config.AgentCanJump or vertical > config.MaxJumpHeight then continue end
				action = "Jump"
			elseif vertical < -config.MaxDropHeight then continue end
			if not world:HasLineOfSight(current.position, position) then continue end
			local surfaceCost = world:Cost(floorPart)
			if surfaceCost == math.huge or surfaceCost < 0 then continue end
			local moveCost = (position - current.position).Magnitude * surfaceCost
			if action == "Jump" then moveCost += config.AgentHeight end
			local key = world.cache:Key(position)
			local candidate = current.g + moveCost
			local node = nodes[key]
			if not node or candidate < node.g then
				local h = heuristic(position, goalGround, config.SearchMode)
				node = {key = key, position = position, g = candidate, h = h, f = candidate + h, parent = current, action = action, closed = false}
				nodes[key] = node
				open:Push(node)
			end
		end

		if os.clock() - sliceStarted >= config.ComputeBudget then
			task.wait()
			sliceStarted = os.clock()
		end
	end
	if closest ~= first then return reconstruct(closest), "Closest", iterations end
	return nil, "NoPath", iterations
end

return AStar
