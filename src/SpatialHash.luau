--!strict

local SpatialHash = {}
SpatialHash.__index = SpatialHash

function SpatialHash.new(cellSize: number)
	return setmetatable({cellSize = cellSize, cells = {}}, SpatialHash)
end

function SpatialHash:Key(position: Vector3): string
	local s = self.cellSize
	return string.format("%d,%d,%d", math.floor(position.X / s + 0.5), math.floor(position.Y / s + 0.5), math.floor(position.Z / s + 0.5))
end

function SpatialHash:Get(position: Vector3)
	return self.cells[self:Key(position)]
end

function SpatialHash:Set(position: Vector3, value)
	self.cells[self:Key(position)] = value
end

function SpatialHash:Clear()
	table.clear(self.cells)
end

return SpatialHash
