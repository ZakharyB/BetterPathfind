# BetterPathfind

BetterPathfind is a custom Roblox/Luau A* framework. It samples the world lazily, caches samples in a spatial hash, checks the agent's complete volume with blockcasts, supports weighted materials/modifiers, time-slices searches, smooths paths, and can drive Humanoid NPCs. It never calls `PathfindingService`.

Place `init.luau` and its `src` child folder in a ModuleScript package (Rojo users can map the repository directly).

```luau
local BetterPathfind = require(game.ReplicatedStorage.BetterPathfind)

local path = BetterPathfind.new({
	AgentRadius = 2.5,
	AgentHeight = 6,
	SearchMode = "Quality", -- Quality, Efficient (weighted A*), or Fastest
	CellSize = 2,
	Costs = { Water = 8, Lava = math.huge, Mud = 3 },
})

if path:ComputeAsync(workspace.NPC.HumanoidRootPart.Position, workspace.Goal.Position) == "Success" then
	for _, waypoint in path:GetWaypoints() do
		print(waypoint.Position, waypoint.Action)
	end
end

local agent = BetterPathfind.CreateAgent(workspace.NPC, { AgentRadius = 2 }, {
	RepathDistance = 5,
	MoveTimeout = 4,
})
agent.Failed:Connect(warn)
agent:GoTo(workspace.MovingTarget)
```

`CreateAgent` automatically excludes the NPC model from navigation queries. When using `new` directly from inside a character, pass exclusion-based `RaycastParams` containing that character; ground probes also defensively skip Humanoid models they encounter.

Costs can use `Enum.Material` names, a `PathfindingModifier.Label`, or a CollectionService tag consisting of `ModifierTag .. label` (by default, `PathCost_Mud`). A cost of `math.huge` makes a surface impassable. Custom `RaycastParams` can exclude the NPC and other non-navigation geometry.

## Performance modes

- **Quality** uses admissible Euclidean A* for the strongest path-quality guarantee.
- **Efficient** uses weighted A* and is the recommended general-purpose balance.
- **Fastest** uses a cheap grid heuristic and favors search throughput.

No navigation method can universally outperform Roblox's baked navigation mesh. Tune `CellSize`, iteration limits, costs, and raycast filters for your world; smaller cells resolve tighter geometry but require more queries.
