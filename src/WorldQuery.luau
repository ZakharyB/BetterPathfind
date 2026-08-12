--!strict

local CollectionService = game:GetService("CollectionService")

local WorldQuery = {}
WorldQuery.__index = WorldQuery

function WorldQuery.new(config, cache)
	local rayParams = config.RaycastParams or RaycastParams.new()
	if not config.RaycastParams then
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.IgnoreWater = config.IgnoreWater
		rayParams.RespectCanCollide = true
	end
	return setmetatable({config = config, cache = cache, rayParams = rayParams}, WorldQuery)
end

local function copyParams(source: RaycastParams): RaycastParams
	local result = RaycastParams.new()
	result.FilterType = source.FilterType
	result.FilterDescendantsInstances = table.clone(source.FilterDescendantsInstances)
	result.CollisionGroup = source.CollisionGroup
	result.IgnoreWater = source.IgnoreWater
	result.RespectCanCollide = source.RespectCanCollide
	return result
end

local function characterFrom(instance: Instance): Model?
	local model = instance:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildWhichIsA("Humanoid") then return model end
	return nil
end

function WorldQuery:GroundAt(probe: Vector3): (Vector3?, Instance?, Vector3?)
	local cached = self.cache:Get(probe)
	if cached ~= nil then
		if cached == false then return nil, nil, nil end
		return cached.position, cached.instance, cached.normal
	end
	local c = self.config
	local height = c.MaxJumpHeight + c.MaxDropHeight + c.AgentHeight + 4
	local origin = probe + Vector3.new(0, c.MaxJumpHeight + c.AgentHeight, 0)
	local direction = Vector3.new(0, -height, 0)
	local params = self.rayParams
	local result = workspace:Raycast(origin, direction, params)
	-- Direct Path usage does not know which NPC owns the origin. Transparently skip
	-- characters so their head, accessories, or torso cannot become the sampled floor.
	-- A copy keeps caller-owned RaycastParams immutable.
	for _ = 1, 8 do
		if not result then break end
		local character = characterFrom(result.Instance)
		if not character then break end
		if params == self.rayParams then params = copyParams(self.rayParams) end
		if params.FilterType ~= Enum.RaycastFilterType.Exclude then break end
		params:AddToFilter(character)
		result = workspace:Raycast(origin, direction, params)
	end
	if not result or math.deg(math.acos(math.clamp(result.Normal.Y, -1, 1))) > c.MaxSlopeAngle then
		self.cache:Set(probe, false)
		return nil, nil, nil
	end
	local floor = result.Position
	-- Blockcast the full body, slightly lifted so the floor itself does not collide.
	local bodySize = Vector3.new(c.AgentRadius * 2, math.max(0.1, c.AgentHeight - 0.1), c.AgentRadius * 2)
	local bodyCenter = floor + Vector3.new(0, c.AgentHeight / 2 + 0.06, 0)
	local obstruction = workspace:Blockcast(CFrame.new(bodyCenter), bodySize, Vector3.new(0, 0.05, 0), params)
	if obstruction then
		self.cache:Set(probe, false)
		return nil, nil, nil
	end
	local value = {position = floor, instance = result.Instance, normal = result.Normal}
	self.cache:Set(probe, value)
	return floor, result.Instance, result.Normal
end

function WorldQuery:Cost(part: Instance?): number
	if not part then return 1 end
	local costs = self.config.Costs
	local modifier = part:FindFirstChildWhichIsA("PathfindingModifier")
	if modifier and costs[modifier.Label] ~= nil then return costs[modifier.Label] end
	for label, cost in costs do
		if CollectionService:HasTag(part, self.config.ModifierTag .. label) then return cost end
	end
	if part:IsA("BasePart") then return costs[part.Material.Name] or 1 end
	return 1
end

function WorldQuery:HasLineOfSight(a: Vector3, b: Vector3): boolean
	local c = self.config
	local center = a + Vector3.new(0, c.AgentHeight / 2, 0)
	local delta = b - a
	local size = Vector3.new(c.AgentRadius * 2, math.max(0.1, c.AgentHeight - 0.1), c.AgentRadius * 2)
	-- Lift by a small skin width: without this, numerical contact with the floor can
	-- be returned as a wall and all neighbor edges are discarded.
	center += Vector3.new(0, 0.08, 0)
	return workspace:Blockcast(CFrame.new(center), size, delta, self.rayParams) == nil
end

return WorldQuery
