local _Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _TextChatService = game:GetService("TextChatService")
local observers = require(ReplicatedStorage.Packages.observers)

local ChatListenerUtil = {}

local function normaliseMessage(text: string): string
    return text:lower():match("^%s*(.-)%s*$") or ""
end

function ChatListenerUtil.BindTrigger(chatData: string, onMatched: (player: Player, msg: string) -> (), shouldNormalise: boolean?)
    local normalise = (shouldNormalise ~= false)
    local triggerText = normalise and normaliseMessage(chatData) or chatData

    return observers.observePlayer(function(player)
    local cCon: RBXScriptConnection? = player.Chatted:Connect(function(msg: string)
        local playerMsg = normalise and normaliseMessage(msg) or msg
        if playerMsg == triggerText then
            onMatched(player, msg)
        end
    
    end)
    

    return function(exitReason)
        if cCon then
            cCon:Disconnect()
            cCon = nil
            end
        end
    end)
end

return ChatListenerUtil