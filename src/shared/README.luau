--[[
          _____           ____      _             
         |  ___|__   ___ / ___|__ _| | _____  ___ 
         | |_ / _ \ / _ \ |   / _` | |/ / _ \/ __|
         |  _| (_) |  __/ |__| (_| |   <  __/\__ \
         |_|  \___/ \___|\____\__,_|_|\_\___||___/
        
    ═══════════════════════════════════════════════════════════════
                    TRIGGER MYTH FRAMEWORK
                      Usage Guide v2.0
    ═══════════════════════════════════════════════════════════════

    Trigger Myth Framework is a Roblox framework built on Knit that
    lets you set up trigger-based events to reveal hidden Models and
    Folders in your game. Tag your unlockables, place trigger parts,
    and the framework handles the rest — staggered fade-in animations,
    collision toggling, and state tracking via attributes.

    ───────────────────────────────────────────────────────────────
     DEPENDENCIES
    ───────────────────────────────────────────────────────────────

    The framework expects the following packages inside
    ReplicatedStorage.Packages:

        -> knit          → Knit framework (service/controller architecture)
        -> observers     → observeTag utility for CollectionService observation


    ───────────────────────────────────────────────────────────────
     PROJECT STRUCTURE
    ───────────────────────────────────────────────────────────────

    src/
    ├── client/
    │   └── init.client.luau        → Boots Knit on the client
    ├── server/
    │   ├── init.server.luau        → Boots Knit on the server
    │   └── TriggerService.luau     → Core service: observes triggers & unlockables
    └── shared/
        ├── Constants/
        │   └── GeneralConfig.luau  → Framework-wide settings
        ├── Utilities/
        │   └── SummonModelUtil.luau → Animation & state utility for unlockables
        └── README.luau             → You are here!


    ───────────────────────────────────────────────────────────────
     QUICK START
    ───────────────────────────────────────────────────────────────

    1. TAG YOUR UNLOCKABLES

        In Studio, select any Model or Folder you want to reveal
        during gameplay and add the CollectionService tag:

            "UnlockableModel"

        Place them in the workspace with their FINAL visible
        appearance (correct transparency, materials, decals, etc).
        The framework will hide them automatically on server start.


    2. SET UP A TRIGGER PART

        Create a BasePart that will act as the trigger and add
        the CollectionService tag:

            "TRIGGER_PART"    (or your GeneralConfig.TriggerPartTag)

        Then set the following ATTRIBUTES on the part:

        ┌──────────────────┬──────────┬──────────────────────────────────┐
        │ Attribute        │ Type     │ Description                      │
        ├──────────────────┼──────────┼──────────────────────────────────┤
        │ ModelToSummon    │ string   │ REQUIRED. Must match the .Name   │
        │                  │          │ of a tagged Model/Folder. Use    │
        │                  │          │ commas to target multiple:       │
        │                  │          │ "ModelA, ModelB, ModelC"         │
        ├──────────────────┼──────────┼──────────────────────────────────┤
        │ TriggerType      │ string   │ OPTIONAL. "Touch" or "Click".    │
        │                  │          │ Defaults to GeneralConfig        │
        │                  │          │ .DefaultTriggerType ("Touch").   │
        ├──────────────────┼──────────┼──────────────────────────────────┤
        │ TriggerAction    │ string   │ OPTIONAL. "Appear" or            │
        │                  │          │ "Disappear". Defaults to         │
        │                  │          │ GeneralConfig                    │
        │                  │          │ .DefaultTriggerAction ("Appear")│
        ├──────────────────┼──────────┼──────────────────────────────────┤
        │ SetText          │ string   │ OPTIONAL. When set, displays a   │
        │                  │          │ Hint with the given text when    │
        │                  │          │ the trigger fires.               │
        ├──────────────────┼──────────┼──────────────────────────────────┤
        │ PlaySound        │ string   │ OPTIONAL. Name of a Sound in     │
        │                  │          │ SoundService to play when the    │
        │                  │          │ trigger fires.                   │
        └──────────────────┴──────────┴──────────────────────────────────┘

    3. PLAY

        When a player touches (or clicks) the trigger part, all
        listed unlockables are affected based on the TriggerAction.
        "Appear" fades them in; "Disappear" fades them out.


    ───────────────────────────────────────────────────────────────
     GENERAL CONFIG
    ───────────────────────────────────────────────────────────────

    Located at: shared/Constants/GeneralConfig.luau

    ┌──────────────────────┬────────────────┬─────────────────────────────┐
    │ Property             │ Default        │ Description                 │
    ├──────────────────────┼────────────────┼─────────────────────────────┤
    │ AnimationsOn         │ true           │ Whether to animate reveals  │
    ├──────────────────────┼────────────────┼─────────────────────────────┤
    │ ReplicationMode      │ "Server"       │ "Server" or "Client" —      │
    │                      │                │ where summons are executed  │
    ├──────────────────────┼────────────────┼─────────────────────────────┤
    │ DefaultTriggerType   │ "Touch"        │ Fallback when TriggerType   │
    │                      │                │ attribute is missing        │
    ├──────────────────────┼────────────────┼─────────────────────────────┤
    │ DefaultTriggerAction │ "Appear"       │ Fallback when TriggerAction │
    │                      │                │ attribute is missing        │
    ├──────────────────────┼────────────────┼─────────────────────────────┤
    │ TriggerPartTag       │ "TRIGGER_PART" │ CollectionService tag for   │
    │                      │                │ trigger detection parts     │
    └──────────────────────┴────────────────┴─────────────────────────────┘


    ───────────────────────────────────────────────────────────────
     SUMMON MODEL UTIL — PUBLIC API
    ───────────────────────────────────────────────────────────────

    Located at: shared/Utilities/SummonModelUtil.luau

    -> InitModel(instance: Instance)
        Caches the original Transparency and CanCollide of every
        descendant BasePart, Decal, and Texture. Then immediately
        hides the instance (Transparency = 1, CanCollide = false)
        and sets the "Unlocked" attribute to false.
        Called automatically by TriggerService on startup.

    -> FindUnlockable(name: string): Instance?
        Searches all "UnlockableModel"-tagged instances and returns
        the first one whose .Name matches the given name.

    -> AppearModel(instance: Instance)
        Tweens the instance from hidden → visible with a staggered
        per-part delay. CanCollide is restored AFTER the tween
        finishes (parts originally CanCollide = false stay false).
        Sets "Unlocked" = true.

    -> DisappearModel(instance: Instance)
        Tweens the instance from visible → hidden. CanCollide is
        disabled IMMEDIATELY to prevent interaction during fade-out.
        Sets "Unlocked" = false.

    -> Summon(modelName: string): Instance?
        High-level method: finds the instance by name and plays
        AppearModel. Skips if already unlocked. Returns the instance.

    -> ExecuteAction(modelName: string, action: string): Instance?
        Finds the instance by name and runs the given action:
        "Appear" calls AppearModel, "Disappear" calls DisappearModel.
        Skips if already in the target state. Returns the instance.


    ───────────────────────────────────────────────────────────────
     COLLISION BEHAVIOUR
    ───────────────────────────────────────────────────────────────

    The framework respects original CanCollide values:

        -> A part with CanCollide = true in Studio will become
          collidable again after its appear tween finishes.

        -> A part with CanCollide = false in Studio will STAY
          non-collidable even after appearing.

        -> During disappear, ALL parts are set to CanCollide = false
          immediately, regardless of their original value.


    ───────────────────────────────────────────────────────────────
     ATTRIBUTES SET BY THE FRAMEWORK
    ───────────────────────────────────────────────────────────────

    The framework writes the following attribute on tagged
    Models/Folders so external scripts can react to state changes:

        "Unlocked" (boolean)
            -> true  → The instance has been summoned and is visible.
            -> false → The instance is hidden (initial or re-locked).

    You can listen for changes from other scripts:

        instance:GetAttributeChangedSignal("Unlocked"):Connect(function()
            local isUnlocked = instance:GetAttribute("Unlocked")
            -- react to state change
        end)


    ───────────────────────────────────────────────────────────────
     EXAMPLE SETUP
    ───────────────────────────────────────────────────────────────

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

          _____           ____      _             
         |  ___|__   ___ / ___|__ _| | _____  ___ 
         | |_ / _ \ / _ \ |   / _` | |/ / _ \/ __|
         |  _| (_) |  __/ |__| (_| |   <  __/\__ \
         |_|  \___/ \___|\____\__,_|_|\_\___||___/
               
]]