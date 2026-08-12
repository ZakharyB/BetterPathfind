--!strict
-- BetterPathfind: a lazy, clearance-aware A* pathfinder. It does not call PathfindingService.

local AStar = require(script.src.AStar)
local Agent = require(script.src.Agent)
local Path = require(script.src.Path)
local SpatialHash = require(script.src.SpatialHash)
local WorldQuery = require(script.src.WorldQuery)

local BetterPathfind = {}

local DEFAULTS = {
	AgentRadius = 2,
	AgentHeight = 5,
	AgentCanJump = true,
	AgentCanClimb = false,
	WaypointSpacing = 4,
	CellSize = 3,
	MaxStepHeight = 2,
	MaxDropHeight = 6,
	MaxJumpHeight = 7,
	MaxSlopeAngle = 45,
	SearchMode = "Efficient",
	MaxIterations = 12000,
	ComputeBudget = 0.004,
	GoalTolerance = 3,
	AllowDiagonal = true,
	SmoothPath = true,
	Costs = {},
	ModifierTag = "PathCost_",
	IgnoreWater = false,
}

local function merge(options)
	local config = table.clone(DEFAULTS)
	for key, value in options or {} do
		assert(config[key] ~= nil, `Unknown BetterPathfind option: {key}`)
		config[key] = value
	end
	assert(config.AgentRadius > 0 and config.AgentHeight > 0 and config.CellSize > 0, "Agent and cell dimensions must be positive")
	assert(config.SearchMode == "Efficient" or config.SearchMode == "Fastest" or config.SearchMode == "Quality", "Invalid SearchMode")
	return config
end

local function smooth(waypoints, world)
	if #waypoints < 3 then return waypoints end
	local result = {waypoints[1]}
	local anchor = 1
	while anchor < #waypoints do
		local furthest = anchor + 1
		for candidate = #waypoints, anchor + 1, -1 do
			if world:HasLineOfSight(waypoints[anchor].Position, waypoints[candidate].Position) then furthest = candidate; break end
		end
		table.insert(result, waypoints[furthest])
		anchor = furthest
	end
	return result
end

function BetterPathfind.new(options)
	local config = merge(options)
	local cache = SpatialHash.new(config.CellSize)
	local world = WorldQuery.new(config, cache)
	return Path.new(config, function(origin, destination, cancelled)
		cache:Clear()
		local points, status, iterations = AStar.compute(origin, destination, config, world, cancelled)
		if points and config.SmoothPath then points = smooth(points, world) end
		return points, status, iterations
	end)
end

function BetterPathfind.CreateAgent(model: Model, pathOptions, agentOptions)
	-- A character's own body is normally collidable. Excluding it here prevents the
	-- ground probe from mistaking the head/torso for terrain and rejecting every path.
	local options = table.clone(pathOptions or {})
	local source = options.RaycastParams
	local raycastParams = RaycastParams.new()
	if source then
		raycastParams.FilterType = source.FilterType
		raycastParams.FilterDescendantsInstances = table.clone(source.FilterDescendantsInstances)
		raycastParams.CollisionGroup = source.CollisionGroup
		raycastParams.IgnoreWater = source.IgnoreWater
		raycastParams.RespectCanCollide = source.RespectCanCollide
	else
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.IgnoreWater = options.IgnoreWater == true
	end
	assert(raycastParams.FilterType == Enum.RaycastFilterType.Exclude, "CreateAgent requires exclusion-based RaycastParams")
	raycastParams:AddToFilter(model)
	options.RaycastParams = raycastParams
	return Agent.new(model, function() return BetterPathfind.new(options) end, agentOptions or {})
end

BetterPathfind.Defaults = table.freeze(table.clone(DEFAULTS))

return table.freeze(BetterPathfind)
