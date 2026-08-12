--!strict

local Heap = {}
Heap.__index = Heap

function Heap.new()
	return setmetatable({items = {}}, Heap)
end

function Heap:IsEmpty(): boolean
	return #self.items == 0
end

function Heap:Push(value)
	local items = self.items
	table.insert(items, value)
	local index = #items
	while index > 1 do
		local parent = math.floor(index / 2)
		if items[parent].f <= value.f then break end
		items[index] = items[parent]
		index = parent
	end
	items[index] = value
end

function Heap:Pop()
	local items = self.items
	local root = items[1]
	local last = table.remove(items)
	if #items > 0 and last then
		local index = 1
		while index * 2 <= #items do
			local child = index * 2
			if child + 1 <= #items and items[child + 1].f < items[child].f then child += 1 end
			if items[child].f >= last.f then break end
			items[index] = items[child]
			index = child
		end
		items[index] = last
	end
	return root
end

return Heap
