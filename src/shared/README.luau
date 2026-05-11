--[[
    TRIGGER MYTH FRAMEWORK
    Usage Guide v2.0

    Trigger Myth Framework is a Roblox framework built on Knit that lets you set up 
    trigger-based events to reveal hidden Models and Folders in your game. Tag your 
    unlockables, place trigger parts, and the framework handles the rest - 
    fade-in animations, collision toggling, and state tracking via attributes.

    NO-CODE MYTH CREATION FOR THE ROBLOX MYTH COMMUNITY

    WHAT IS A TRIGGER MYTH?
    In the Roblox Myth community, "trigger myths" are games where the environment 
    reacts to the player's actions. For example, stepping on a specific part might 
    reveal a new area; typing a certain phrase in chat might make a door open, etc.

    THE GOAL OF THIS FRAMEWORK
    This framework was built to empower people to create myths without needing to 
    write a single line of code. By simply placing parts, assigning Roblox "Tags," 
    and filling out a few "Attributes," you can create a myth game with ease!

    ---------------------------------------------------------------------------

    CORE CONCEPTS: TRIGGERS AND ACTIONS

    1. TRIGGERS (The "Cause")
    A Trigger is a normal Roblox Part that waits for interaction:
    - Touch (TriggerType = "Touch"): Activates when a player collides with the part.
    - Click (TriggerType = "Click"): Automatically adds a ClickDetector to the part.
    - ProximityPrompt (TriggerType = "ProximityPrompt"): Automatically adds a ProximityPrompt.
    - Chat (TriggerType = "Chat"): Listens to chat for the exact phrase (ChatTrigger attribute).

    2. TRIGGER ACTIONS (The "Effect")
    Dictates what happens to the linked UnlockableModel (TriggerAction attribute):
    - Appear: Reveals an UnlockableModel, fading it into view.
    - Disappear: Hides an UnlockableModel, fading it out part-by-part. Collision is disabled.

    3. SECONDARY EFFECTS (Optional Attributes)
    - SetHint: Briefly displays a text hint at the top of the screen.
    - PlaySound: Plays a specific sound. Plays from the part if inside it, else SoundService.
    - ConsoleOutput: Prints a custom message to the F9 Developer Console.
    - ConsoleOutputType: "print", "warn", "log", or "error".
    - ConsoleThrottle: Delay in seconds between repeated messages.
    - ConsoleAmount: Number of times to repeat the message.

    ---------------------------------------------------------------------------

    GETTING STARTED (No Coding Required!)

    STEP 1: TAG YOUR UNLOCKABLES
    1. Group your object into a Model or Folder.
    2. Add the CollectionService tag "UnlockableModel" to it.
    *Note: It will be hidden automatically on start. Make sure its Name is unique!*

    STEP 2: CREATE A TRIGGER
    1. Create a Part in the workspace.
    2. Add the tag "TRIGGER_PART" to it.

    STEP 3: CONFIGURE YOUR TRIGGER (Attributes)
    Add these Attributes to your trigger part:
    - ModelToSummon (String): OPTIONAL. The exact Name of the UnlockableModel (e.g. "SecretDoor").
    - TriggerType (String): OPTIONAL. "Touch", "Click", "ProximityPrompt", or "Chat".
    - TriggerAction (String): OPTIONAL. "Appear" or "Disappear".
    - SetHint (String): OPTIONAL. Text hint to display.
    - PlaySound (String): OPTIONAL. Sound name to play.
    - ConsoleOutput (String): OPTIONAL. F9 Console message.
    - ConsoleOutputType (String): OPTIONAL. Console message type.
    - ConsoleThrottle (Number): OPTIONAL. Delay between repeated console messages.
    - ConsoleAmount (Number): OPTIONAL. Times to repeat console message.
    - ChatTrigger (String): OPTIONAL. Phrase to say if TriggerType is "Chat".
    - ShouldNormalise (Boolean): OPTIONAL. If false, requires exact casing for Chat.

    ---------------------------------------------------------------------------

    ADVANCED TRIGGERS: MULTIPLE ACTIONS
    
    You can make multiple models appear and disappear on a SINGLE trigger!
    There are two ways to do this:

    METHOD A: ADVANCED ATTRIBUTES
    - ModelsToAppear (String): Comma-separated names of models to show.
    - ModelsToDisappear (String): Comma-separated names of models to hide.
    (e.g. ModelsToAppear = "Bridge, Gate")

    METHOD B: OBJECT VALUES (Recommended)
    1. Inside your trigger part, create an "ObjectValue".
    2. Name it "AppearModel" or "DisappearModel".
    3. Set its "Value" property to the target Model/Folder in your Workspace.
    *Note: The framework searches all descendants, so you can nest these in Folders!*

    ---------------------------------------------------------------------------

    TECHNICAL DOCUMENTATION (For Scripters)

    ARCHITECTURE OVERVIEW
    - TriggerService (Server): Core observer. Handles Touches, Clicks, and Chat.
    - TriggerController (Client): Client-sided tweening listener.
    - SummonModelUtil (Shared): Handles staggering math, caching, and StreamingEnabled.

    GLOBAL CONFIGURATION
    Modify global settings in: src/shared/Constants/GeneralConfig.luau

    SUMMON MODEL UTIL (Public API)
    local SummonModelUtil = require(ReplicatedStorage.Shared.Utilities.SummonModelUtil)
    - SummonModelUtil.Summon(modelName: string): Instance?
    - SummonModelUtil.ExecuteAction(modelName: string, action: string): Instance?
    - SummonModelUtil.InitModel(instance: Instance)

    EVENT SUBSCRIPTIONS
    The framework writes an "Unlocked" boolean attribute when state changes:
    instance:GetAttributeChangedSignal("Unlocked"):Connect(function()
        local isVisible = instance:GetAttribute("Unlocked")
    end)
]]

return nil