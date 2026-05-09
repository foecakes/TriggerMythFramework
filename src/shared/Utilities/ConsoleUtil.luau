local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GeneralConfig = require(ReplicatedStorage.Shared.Constants.GeneralConfig)

local ConsoleUtil = {}

local Handlers = {
    print = function(message) print(message) end,
    warn = function(message) warn(message) end,
    log = function(message) print(message) end,
}


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
        outputType = GeneralConfig.DefaultOutputType
    end

    handler = Handlers[outputType]

    if not handler then 
        outputType = GeneralConfig.DefaultOutputType
        handler = Handlers[outputType]
    end

    if type(Throttle) == "number" and Throttle >= 0 then
        throttle = Throttle
    else
        throttle = GeneralConfig.DefaultConsoleThrottle
    end

    if type(Amount) == "number" and Amount > 0 then
        amount = math.floor(Amount)
    else
        amount = GeneralConfig.DefaultConsoleAmount
    end

    handler(msg)
    for i = 2, amount, 1 do 
        task.wait(throttle)
        handler(msg)
    end
end


return ConsoleUtil