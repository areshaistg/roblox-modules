-- StateHandler
-- State to track changes
export type StateHandler = {
	Value: any,

	Connections: {[number]: (val: any, oldVal: any) -> ()},

	Set: (self: StateHandler, newVal: any) -> (),
	Connect: (self: StateHandler, callback: (val: any, oldVal: any) -> ()) -> (),
}
local StateHandler = {}
StateHandler.__index = StateHandler

function StateHandler.new(defaultValue: any): StateHandler
	local self: StateHandler = setmetatable({}, StateHandler)

	self.Value = defaultValue
	self.Connections = {}

	return self
end

function StateHandler.Set<any>(self: StateHandler, newVal: any)
	local oldVal = self.Value
	self.Value = newVal

	for _, connection in ipairs(self.Connections) do
		connection(self.Value, oldVal)
	end
end

function StateHandler.Connect(self: StateHandler, callback: (val: any, oldVal: any) -> ())
	self.Connections[#self.Connections + 1] = callback;
end

return StateHandler :: { new: typeof(StateHandler.new) }
