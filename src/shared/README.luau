--[[
    TRIGGER MYTH FRAMEWORK
    Usage Guide v2.0

    Trigger Myth Framework is a Roblox framework built on Knit that
    lets you set up trigger-based events to reveal hidden Models and
    Folders in your game. Tag your unlockables, place trigger parts,
    and the framework handles the rest: staggered fade-in animations,
    collision toggling, and state tracking via attributes.

    DEPENDENCIES
    The framework expects the following packages inside ReplicatedStorage.Packages:
    - knit: Knit framework (service/controller architecture)
    - observers: observeTag utility for CollectionService observation

    PROJECT STRUCTURE
    src/
    ├── client/
    │   └── init.client.luau        (Boots Knit on the client)
    ├── server/
    │   ├── init.server.luau        (Boots Knit on the server)
    │   └── TriggerService.luau     (Core service: observes triggers and unlockables)
    └── shared/
        ├── Constants/
        │   └── GeneralConfig.luau  (Framework-wide settings)
        ├── Utilities/
        │   └── SummonModelUtil.luau (Animation and state utility for unlockables)
        └── README.luau             (You are here!)

    QUICK START
    1. TAG YOUR UNLOCKABLES
    In Studio, select any Model or Folder you want to reveal
    during gameplay and add the CollectionService tag "UnlockableModel".
    Place them in the workspace with their FINAL visible
    appearance (correct transparency, materials, decals, etc).
    The framework will hide them automatically on server start.

    2. SET UP A TRIGGER PART
    Create a BasePart that will act as the trigger and add
    the CollectionService tag "TRIGGER_PART" (or your GeneralConfig.Trigger_PartTag).
    Then set the following ATTRIBUTES on the part:
    - ModelToSummon (string): REQUIRED. Must match the Name of a tagged Model/Folder. Use commas to target multiple (e.g., "ModelA, ModelB").
    - TriggerType (string): OPTIONAL. "Touch", "Click", "ProximityPrompt", or "Chat". Defaults to GeneralConfig.Trigger_DefaultType.
    - TriggerAction (string): OPTIONAL. "Appear" or "Disappear". Defaults to GeneralConfig.Trigger_DefaultAction.
    - SetHint (string): OPTIONAL. When set, displays a Hint with the given text when the trigger fires.
    - PlaySound (string): OPTIONAL. Name of a Sound in SoundService to play when the trigger fires.
    - ChatTrigger (string): OPTIONAL. When TriggerType is Chat, listens to this phrase to fire.

    3. PLAY
    When a player touches, clicks, or chats near the trigger part, all
    listed unlockables are affected based on the TriggerAction.
    "Appear" fades them in; "Disappear" fades them out.

    GENERAL CONFIG
    Located at: shared/Constants/GeneralConfig.luau
    - Model_AnimationsOn (true): Whether to animate reveals
    - Global_ReplicationMode ("Server"): "Server" or "Client" (where summons are executed)
    - Trigger_DefaultType ("Touch"): Fallback when TriggerType attribute is missing
    - Trigger_DefaultAction ("Appear"): Fallback when TriggerAction attribute is missing
    - Trigger_PartTag ("TRIGGER_PART"): CollectionService tag for trigger detection parts
    - Chat_DefaultNormalisation (false): Controls if chat triggers ignore casing and whitespace by default
    - Console_DefaultOutputType ("print"): Fallback console output method
    - Console_DefaultThrottle (0): Default wait time between repeated console outputs
    - Console_DefaultAmount (1): Default repeat count for console outputs

    SUMMON MODEL UTIL: PUBLIC API
    Located at: shared/Utilities/SummonModelUtil.luau
    - InitModel(instance: Instance): Caches the original Transparency and CanCollide of every descendant BasePart, Decal, and Texture. Immediately hides the instance and sets the "Unlocked" attribute to false.
    - FindUnlockable(name: string): Searches all "UnlockableModel"-tagged instances and returns the first one whose Name matches.
    - AppearModel(instance: Instance): Tweens the instance from hidden to visible with a staggered per-part delay. CanCollide is restored after the tween finishes. Sets "Unlocked" to true.
    - DisappearModel(instance: Instance): Tweens the instance from visible to hidden. CanCollide is disabled immediately to prevent interaction during fade-out. Sets "Unlocked" to false.
    - Summon(modelName: string): High-level method that finds the instance by name and plays AppearModel. Skips if already unlocked.
    - ExecuteAction(modelName: string, action: string): Finds the instance by name and runs the given action ("Appear" or "Disappear").

    COLLISION BEHAVIOUR
    The framework respects original CanCollide values:
    - A part with CanCollide true in Studio will become collidable again after its appear tween finishes.
    - A part with CanCollide false in Studio will stay non-collidable even after appearing.
    - During disappear, all parts are set to CanCollide false immediately, regardless of their original value.

    ATTRIBUTES SET BY THE FRAMEWORK
    The framework writes the following attribute on tagged Models/Folders so external scripts can react to state changes:
    - "Unlocked" (boolean): true when visible, false when hidden.

    EXAMPLE SETUP
    Workspace
    ├── SecretRoom                  (Model, tagged "UnlockableModel")
    │   ├── Floor                   (Part)
    │   ├── Wall1                   (Part)
    │   ├── Wall2                   (Part)
    │   └── Painting                (Part)
    │       └── FrontDecal          (Decal)
    │
    └── TriggerZone                 (Part, tagged "TRIGGER_PART")
            Attributes:
                ModelToSummon = "SecretRoom"
                TriggerType   = "Touch"

    When a player walks into TriggerZone, "SecretRoom" fades in
    with a staggered animation and becomes collidable.
]]