--!strict

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({_event = Instance.new("BindableEvent")}, Signal)
end

function Signal:Connect(callback)
	return self._event.Event:Connect(callback)
end

function Signal:Once(callback)
	return self._event.Event:Once(callback)
end

function Signal:Wait()
	return self._event.Event:Wait()
end

function Signal:Fire(...)
	self._event:Fire(...)
end

function Signal:Destroy()
	self._event:Destroy()
end

return Signal
