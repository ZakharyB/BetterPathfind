--!strict

local Signal = require(script.Parent.Signal)

local Agent = {}
Agent.__index = Agent

function Agent.new(model: Model, pathFactory, options)
	local humanoid = model:FindFirstChildWhichIsA("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	assert(humanoid and root and root:IsA("BasePart"), "Agent model requires a Humanoid and HumanoidRootPart")
	return setmetatable({
		Model = model,
		Humanoid = humanoid,
		Root = root,
		Reached = Signal.new(),
		Failed = Signal.new(),
		WaypointReached = Signal.new(),
		_pathFactory = pathFactory,
		_repathDistance = options.RepathDistance or 4,
		_moveTimeout = options.MoveTimeout or 5,
		_generation = 0,
	}, Agent)
end

local function resolveTarget(target): Vector3?
	if typeof(target) == "Vector3" then return target end
	if typeof(target) == "Instance" then
		if target:IsA("BasePart") then return target.Position end
		if target:IsA("Model") then return target:GetPivot().Position end
	end
	return nil
end

function Agent:Stop()
	self._generation += 1
	self.Humanoid:MoveTo(self.Root.Position)
end

function Agent:GoTo(target)
	self:Stop()
	local generation = self._generation
	task.spawn(function()
		while generation == self._generation do
			local destination = resolveTarget(target)
			if not destination then self.Failed:Fire("InvalidTarget"); return end
			local path = self._pathFactory()
			local status = path:ComputeAsync(self.Root.Position, destination)
			if status ~= "Success" then self.Failed:Fire(status); path:Destroy(); return end
			local shouldRepath = false
			for index, waypoint in path:GetWaypoints() do
				if generation ~= self._generation then path:Destroy(); return end
				local latest = resolveTarget(target)
				if latest and (latest - destination).Magnitude >= self._repathDistance then shouldRepath = true; break end
				if waypoint.Action == "Jump" then self.Humanoid.Jump = true end
				self.Humanoid:MoveTo(waypoint.Position)
				local done = false
				local reached = false
				local connection = self.Humanoid.MoveToFinished:Connect(function(ok) reached = ok; done = true end)
				local started = os.clock()
				while not done and os.clock() - started < self._moveTimeout and generation == self._generation do task.wait() end
				connection:Disconnect()
				if not reached then self.Failed:Fire("Blocked", index); path.Blocked:Fire(index); path:Destroy(); return end
				self.WaypointReached:Fire(index, waypoint)
			end
			path:Destroy()
			if not shouldRepath then self.Reached:Fire(destination); return end
		end
	end)
end

function Agent:Destroy()
	self:Stop()
	self.Reached:Destroy()
	self.Failed:Destroy()
	self.WaypointReached:Destroy()
end

return Agent
