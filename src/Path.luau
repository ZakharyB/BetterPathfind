--!strict

local Signal = require(script.Parent.Signal)

local Path = {}
Path.__index = Path

function Path.new(config, computeCallback)
	return setmetatable({
		Status = "NotComputed",
		Waypoints = {},
		Iterations = 0,
		Blocked = Signal.new(),
		Completed = Signal.new(),
		_config = config,
		_compute = computeCallback,
		_cancelled = false,
	}, Path)
end

function Path:ComputeAsync(origin: Vector3, destination: Vector3): string
	self._cancelled = false
	local waypoints, status, iterations = self._compute(origin, destination, function() return self._cancelled end)
	self.Status = status
	self.Iterations = iterations
	self.Waypoints = waypoints or {}
	self.Completed:Fire(status)
	return status
end

function Path:GetWaypoints()
	return table.clone(self.Waypoints)
end

function Path:Cancel()
	self._cancelled = true
	self.Status = "Cancelled"
end

function Path:Destroy()
	self:Cancel()
	self.Blocked:Destroy()
	self.Completed:Destroy()
end

return Path
