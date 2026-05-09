# Trigger Myth Framework

```
	_____           ____      _             
 |  ___|__   ___ / ___|__ _| | _____  ___ 
 | |_ / _ \ / _ \ |   / _` | |/ / _ \/ __|
 |  _| (_) |  __/ |__| (_| |   <  __/\__ \
 |_|  \___/ \___|\____\__,_|_|\_\___||___/
```

**Usage Guide v2.0**

Trigger Myth Framework is a Roblox framework built on Knit that lets you set up trigger-based events to reveal hidden Models and Folders in your game. Tag your unlockables, place trigger parts, and the framework handles the rest - staggered fade-in animations, collision toggling, and state tracking via attributes.

## Dependencies

The framework expects the following packages inside `ReplicatedStorage.Packages`:

- **knit** - Knit framework (service/controller architecture)
- **observers** - observeTag utility for CollectionService observation

## Project Structure

```
src/
├── client/
│   ├── init.client.luau        -> Boots Knit on the client
│   └── TriggerController.luau  -> Client-side controller for triggers
├── server/
│   ├── init.server.luau        -> Boots Knit on the server
│   └── TriggerService.luau     -> Core service: observes triggers & unlockables
└── shared/
    ├── Constants/
    │   └── GeneralConfig.luau  -> Framework-wide settings
    └── Utilities/
        ├── ChatListenerUtil.luau    -> Chat event listener utility
        ├── ConsoleUtil.luau         -> Console output utility
        ├── SetHintUtil.luau         -> Hint display utility
        ├── SoundUtil.luau           -> Sound playback utility
        └── SummonModelUtil.luau     -> Animation & state utility for unlockables
```

## Quick Start

### 1. Tag Your Unlockables

In Studio, select any Model or Folder you want to reveal during gameplay and add the CollectionService tag:

```
"UnlockableModel"
```

Place them in the workspace with their FINAL visible appearance (correct transparency, materials, decals, etc). The framework will hide them automatically on server start.

### 2. Set Up a Trigger Part

Create a BasePart that will act as the trigger and add the CollectionService tag:

```
"TRIGGER_PART"    (or your GeneralConfig.TriggerPartTag)
```

Then set the following **ATTRIBUTES** on the part:

| Attribute | Type | Description |
|-----------|------|-------------|
| `ModelToSummon` | string | **REQUIRED.** Must match the `.Name` of a tagged Model/Folder. Use commas to target multiple: `"ModelA, ModelB, ModelC"` |
| `TriggerType` | string | **OPTIONAL.** `"Touch"` or `"Click"`. Defaults to `GeneralConfig.DefaultTriggerType` (`"Touch"`). |
| `TriggerAction` | string | **OPTIONAL.** `"Appear"` or `"Disappear"`. Defaults to `GeneralConfig.DefaultTriggerAction` (`"Appear"`). |
| `SetText` | string | **OPTIONAL.** When set, displays a Hint with the given text when the trigger fires. |
| `PlaySound` | string | **OPTIONAL.** Name of a Sound in SoundService to play when the trigger fires. |

### 3. Play

When a player touches (or clicks) the trigger part, all listed unlockables are affected based on the TriggerAction. `"Appear"` fades them in; `"Disappear"` fades them out.

## General Config

Located at: `shared/Constants/GeneralConfig.luau`

| Property | Default | Description |
|----------|---------|-------------|
| `AnimationsOn` | `true` | Whether to animate reveals |
| `ReplicationMode` | `"Server"` | `"Server"` or `"Client"` - where summons are executed |
| `DefaultTriggerType` | `"Touch"` | Fallback when TriggerType attribute is missing |
| `DefaultTriggerAction` | `"Appear"` | Fallback when TriggerAction attribute is missing |
| `TriggerPartTag` | `"TRIGGER_PART"` | CollectionService tag for trigger detection parts |
| `UnlockableTag` | `"UnlockableModel"` | CollectionService tag for unlockable models |
| `DefaultChatNormalisation` | `false` | Whether chat messages should be normalised before comparison |
| `DefaultOutputType` | `"print"` | Default output method for console messages |
| `DefaultConsoleThrottle` | `0` | Delay in seconds between repeated console output messages |
| `DefaultConsoleAmount` | `1` | Total number of times the message is output |

## Summon Model Util - Public API

Located at: `shared/Utilities/SummonModelUtil.luau`

- **InitModel(instance: Instance)**
	- Caches the original Transparency and CanCollide of every descendant BasePart, Decal, and Texture. Then immediately hides the instance (Transparency = 1, CanCollide = false) and sets the "Unlocked" attribute to false. Called automatically by TriggerService on startup.

- **FindUnlockable(name: string): Instance?**
	- Searches all "UnlockableModel"-tagged instances and returns the first one whose `.Name` matches the given name.

- **AppearModel(instance: Instance)**
	- Tweens the instance from hidden -> visible with a staggered per-part delay. CanCollide is restored AFTER the tween finishes (parts originally CanCollide = false stay false). Sets "Unlocked" = true.

- **DisappearModel(instance: Instance)**
	- Tweens the instance from visible -> hidden. CanCollide is disabled IMMEDIATELY to prevent interaction during fade-out. Sets "Unlocked" = false.

- **Summon(modelName: string): Instance?**
	- High-level method: finds the instance by name and plays AppearModel. Skips if already unlocked. Returns the instance.

- **ExecuteAction(modelName: string, action: string): Instance?**
	- Finds the instance by name and runs the given action: `"Appear"` calls AppearModel, `"Disappear"` calls DisappearModel. Skips if already in the target state. Returns the instance.

## Collision Behaviour

The framework respects original CanCollide values:

- A part with CanCollide = true in Studio will become collidable again after its appear tween finishes.
- A part with CanCollide = false in Studio will STAY non-collidable even after appearing.
- During disappear, ALL parts are set to CanCollide = false immediately, regardless of their original value.

## Attributes Set by the Framework

The framework writes the following attribute on tagged Models/Folders so external scripts can react to state changes:

**"Unlocked" (boolean)**
- `true` -> The instance has been summoned and is visible.
- `false` -> The instance is hidden (initial or re-locked).

You can listen for changes from other scripts:

```lua
instance:GetAttributeChangedSignal("Unlocked"):Connect(function()
	local isUnlocked = instance:GetAttribute("Unlocked")
	-- react to state change
end)
```

## Example Setup

```
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
```

When a player walks into TriggerZone, "SecretRoom" fades in with a staggered animation and becomes collidable.

```
  _____           ____      _             
 |  ___|__   ___ / ___|__ _| | _____  ___ 
 | |_ / _ \ / _ \ |   / _` | |/ / _ \/ __|
 |  _| (_) |  __/ |__| (_| |   <  __/\__ \
 |_|  \___/ \___|\____\__,_|_|\_\___||___/
```