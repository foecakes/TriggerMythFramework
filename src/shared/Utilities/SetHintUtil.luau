--[[
	SET HINT UTILITY
	Author: @FoeCakes

	DESCRIPTION:
		Sets the text of a Hint object in the Workspace, visible to all players.
		If no active Hint exists, one is created and parented to Workspace under
		the name "ActiveHint". Subsequent calls reuse the existing Hint.

	USAGE:
		local SetHint = require(path.to.SetHintUtil)
		SetHint("Hello, world!")

	PARAMETERS:
		nText (string): The text to display in the Hint.

	NOTES:
		Only one Hint is maintained at a time since a single instance handles all text.
		Passing a non-string value will raise an error.
]]

--!strict
return function(nText: string)
    assert(nText and type(nText) == "string",
        "HintUtil: Expected a string as the first argument. Received " .. typeof(nText))
    
    local activeHint: Hint? = workspace:FindFirstChild("ActiveHint")
    if not activeHint then
        local nHint = Instance.new("Hint")
        nHint.Name = "ActiveHint"
        nHint.Parent = workspace:FindFirstChild("Scriptables") or workspace

        activeHint = nHint
    end

    (activeHint :: Hint).Text = nText
end