--[[
	SET HINT UTILITY - DOCUMENTATION & GUIDE
	Author: @FoeCakes

	DESCRIPTION:
		Sets the text of a Hint object in the Workspace, visible to all players.
		If no active Hint exists, one is created and parented to Workspace under
		the name "ActiveHint". Subsequent calls reuse the existing Hint.

	USAGE:
		local SetHint = require(path.to.SetHintUtil) -->! Requiring the utility function
		SetHint("Hello, world!") -->! Calling it

	PARAMETERS:
		nText (string) -- The text to display in the Hint.

	NOTES:
		- Only one Hint ("ActiveHint") is maintained at a time. (No need for multiple hints as you can't manipulate anything else other than the text anyways)
		- Passing a non-string value will raise an error.
]]

--!strict
return function(nText: string)
    assert(nText and type(nText) == "string",
        "HintUtil: Expected a string as the first argument. Received " .. typeof(nText))
    
	-->! Check to see if there is currently an active hint
    local activeHint: Hint? = workspace:FindFirstChild("ActiveHint")
    if not activeHint then
        local nHint = Instance.new("Hint")
        nHint.Name = "ActiveHint"
        nHint.Parent = workspace:FindFirstChild("Scriptables") or workspace

        activeHint = nHint
    end

	-->! Update text
    (activeHint :: Hint).Text = nText
end