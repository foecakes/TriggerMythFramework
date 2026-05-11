--[[
	CONSOLE TRIGGER ACTION
	Author: @FoeCakes

	DESCRIPTION:
		A trigger action that outputs formatted messages to the Roblox console
		when a player interacts with a configured trigger part.

	USAGE:
		Called by the TriggerMyth framework when a trigger part is configured
		to output a message. Not typically used for general codebase logging.

	PARAMETERS:
		Message (string): The message to output.
		OutputType (string?): The type of output (print, warn, log). Defaults to GeneralConfig.Console_DefaultOutputType.
		Throttle (number?): Delay in seconds between repeating the message.
		Amount (number?): Number of times to output the message.

	NOTES:
		Repeating the output (Amount > 1) yields the thread due to task.wait.
]]

--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")

--//Dependencies
local GeneralConfig = require(ReplicatedStorage.Shared.Constants.GeneralConfig)

--//Constructor
local ConsoleUtil = {}

--//Cache
local Handlers = {
    print = function(message) print(message) end,
    warn = function(message) warn(message) end,
    log = function(message) print(message) end,
    error = function(message) TestService:Error(message) end,
}

--//Public methods
function ConsoleUtil.OutputToConsole(Message: string, OutputType: string?, Throttle: number?, Amount: number?)

    local msg, throttle, outputType, amount, handler

    if type(Message) == "string" then
        msg = Message
    else 
        return
    end

    if type(OutputType) == "string" then
        outputType = string.lower(OutputType)
    else     
        outputType = GeneralConfig.Console_DefaultOutputType
    end

    handler = Handlers[outputType]

    if not handler then 
        outputType = GeneralConfig.Console_DefaultOutputType
        handler = Handlers[outputType]
    end

    if type(Throttle) == "number" and Throttle >= 0 then
        throttle = Throttle
    else
        throttle = GeneralConfig.Console_DefaultThrottle
    end

    if type(Amount) == "number" and Amount > 0 then
        amount = math.floor(Amount)
    else
        amount = GeneralConfig.Console_DefaultAmount
    end

    handler(msg)
    
    -->! task.wait yields the thread, meaning callers using Amount > 1 will be blocked
    -->! unless wrapped in a separate coroutine or task.spawn
    for i = 2, amount, 1 do 
        task.wait(throttle)
        handler(msg)
    end
end

--//Return
return ConsoleUtil