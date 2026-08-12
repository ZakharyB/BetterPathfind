--!strict

export type SearchMode = "Efficient" | "Fastest" | "Quality"

export type Config = {
	AgentRadius: number,
	AgentHeight: number,
	AgentCanJump: boolean,
	AgentCanClimb: boolean,
	WaypointSpacing: number,
	CellSize: number,
	MaxStepHeight: number,
	MaxDropHeight: number,
	MaxJumpHeight: number,
	MaxSlopeAngle: number,
	SearchMode: SearchMode,
	MaxIterations: number,
	ComputeBudget: number,
	GoalTolerance: number,
	AllowDiagonal: boolean,
	SmoothPath: boolean,
	Costs: {[string]: number},
	ModifierTag: string,
	IgnoreWater: boolean,
	RaycastParams: RaycastParams?,
}

export type WaypointAction = "Walk" | "Jump" | "Climb"
export type Waypoint = {Position: Vector3, Action: WaypointAction, Cost: number}
export type PathStatus = "NotComputed" | "Success" | "NoPath" | "Closest" | "Cancelled" | "Error"

export type Node = {
	key: string,
	position: Vector3,
	g: number,
	h: number,
	f: number,
	parent: Node?,
	action: WaypointAction,
	closed: boolean,
}

return {}
