--!strict

local CollectionService = game:GetService("CollectionService")

local WorldQuery = {}
WorldQuery.__index = WorldQuery

function WorldQuery.new(config, cache)
	local rayParams = config.RaycastParams or RaycastParams.new()
	if not config.RaycastParams then
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.IgnoreWater = config.IgnoreWater
	end
	return setmetatable({config = config, cache = cache, rayParams = rayParams}, WorldQuery)
end

function WorldQuery:GroundAt(probe: Vector3): (Vector3?, Instance?, Vector3?)
	local cached = self.cache:Get(probe)
	if cached ~= nil then
		if cached == false then return nil, nil, nil end
		return cached.position, cached.instance, cached.normal
	end
	local c = self.config
	local height = c.MaxJumpHeight + c.MaxDropHeight + c.AgentHeight + 4
	local result = workspace:Raycast(probe + Vector3.new(0, c.MaxJumpHeight + c.AgentHeight, 0), Vector3.new(0, -height, 0), self.rayParams)
	if not result or math.deg(math.acos(math.clamp(result.Normal.Y, -1, 1))) > c.MaxSlopeAngle then
		self.cache:Set(probe, false)
		return nil, nil, nil
	end
	local floor = result.Position
	-- Blockcast the full body, slightly lifted so the floor itself does not collide.
	local bodySize = Vector3.new(c.AgentRadius * 2, math.max(0.1, c.AgentHeight - 0.1), c.AgentRadius * 2)
	local bodyCenter = floor + Vector3.new(0, c.AgentHeight / 2 + 0.06, 0)
	local obstruction = workspace:Blockcast(CFrame.new(bodyCenter), bodySize, Vector3.new(0, 0.02, 0), self.rayParams)
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
	return workspace:Blockcast(CFrame.new(center), size, delta, self.rayParams) == nil
end

return WorldQuery
