--[[
	CHAT LISTENER UTILITY
	Author: @Kiceba

	DESCRIPTION:
		Provides a utility to bind a callback to specific chat messages sent by players.
		Leverages the observers package to handle player connections and cleanup.

	USAGE:
		local ChatListenerUtil = require(path.to.ChatListenerUtil)
		local disconnect = ChatListenerUtil.BindTrigger("hello", function(player, msg)
			print(player.Name, "said hello!")
		end)

	PARAMETERS:
		chatData (string): The trigger text to listen for.
		onMatched (function): Callback invoked when a player says the trigger text.
		shouldNormalise (boolean?): Defaults to true. If true, both the trigger and player message are lowercased and stripped of whitespace before comparison.

	NOTES:
		Returns an observer connection function that should be called when no longer needed to prevent memory leaks.
]]

--//Services
local _Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _TextChatService = game:GetService("TextChatService")

--//Dependencies
local observers = require(ReplicatedStorage.Packages.observers)

--//Constructor
local ChatListenerUtil = {}

--//Helpers
local function normaliseMessage(text: string): string
    -->! Normalising ensures consistent matching regardless of user casing or trailing spaces
    return text:lower():match("^%s*(.-)%s*$") or ""
end

--//Public methods
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

--//Return
return ChatListenerUtil