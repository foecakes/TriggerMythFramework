# Trigger Myth Framework

```text
	_____           ____      _             
 |  ___|__   ___ / ___|__ _| | _____  ___ 
 | |_ / _ \ / _ \ |   / _` | |/ / _ \/ __|
 |  _| (_) |  __/ |__| (_| |   <  __/\__ \
 |_|  \___/ \___|\____\__,_|_|\_\___||___/
```

**Usage Guide v2.0**

Trigger Myth Framework is a Roblox framework built on Knit that lets you set up trigger-based events to reveal hidden Models and Folders in your game. Tag your unlockables, place trigger parts, and the framework handles the rest - staggered fade-in animations, collision toggling, and state tracking via attributes.

## No-Code Myth Creation for the Roblox Myth Community

## What is a Trigger Myth?
In the Roblox Myth community, "trigger myths" are games where the environment reacts to the player's actions. For example, stepping on a specific part might reveal a new area; typing a certain phrase in chat might make a door open, etc. These chain reactions build a narrative as the player explores and investigates.

## The Goal of this Framework
This framework was built with a very specific goal in mind: **to empower people to create myths without needing to write a single line of code.** 

By simply placing parts, assigning Roblox "Tags," and filling out a few "Attributes," you can create a myth game with ease!

---

## Core Concepts: Triggers and Actions

Before building, it's important to understand the two main pieces of this framework: **Triggers** and **Trigger Actions**.

### 1. Triggers (The "Cause")
A Trigger is simply a normal Roblox Part that waits for a player to interact with it. You can define *how* the player interacts with it:
- **Touch (`TriggerType = "Touch"`):** Activates as soon as a player's character physically collides with the trigger part.
- **Click (`TriggerType = "Click"`):** The framework automatically adds a `ClickDetector` to the part. The player must click the part with their mouse.
- **ProximityPrompt (`TriggerType = "ProximityPrompt"`):** The framework automatically adds a `ProximityPrompt` to the part. The player must hold down the interact key when near the part.
- **Chat (`TriggerType = "Chat"`):** Listens to what players say in chat. If they say the exact phrase (defined by the `ChatTrigger` attribute), the event activates.

### 2. Trigger Actions (The "Effect")
When a player activates a Trigger, it dictates what happens to the linked `UnlockableModel`. This is defined by the `TriggerAction` attribute:
- **Appear (`TriggerAction = "Appear"`):** Reveals an `UnlockableModel` that is currently invisible by making it slowly fade into view *(if `Model_AnimationsOn` is enabled)*. All parts inside the model are staggered so it looks like it's "forming" out of thin air *(if `Model_UseStaggeredAnimation` is enabled)*. Collision is restored once it finishes fading in.
- **Disappear (`TriggerAction = "Disappear"`):** Hides an `UnlockableModel` by making it slowly fade into nothing *(if `Model_AnimationsOn` is enabled)*. All parts inside the model are staggered so it looks like it's disappearing part-by-part *(if `Model_UseStaggeredAnimation` is enabled)*. Collision is disabled immediately so players can't stand on fading geometry.

### 3. Secondary Effects (Optional)
You can mix and match these additional standalone attributes on the same trigger part to create complex, multi-sensory scenes:
- **SetHint:** Briefly displays a text hint at the top of the screen.
- **PlaySound:** Plays a specific audio track or sound effect. If you place the `Sound` object inside the trigger part itself, it will play as **spatial audio** (meaning it sounds like it's coming from the part). If it can't find it there, it defaults to playing it globally from `SoundService`.
- **ConsoleOutput:** Prints a custom message to the F9 Developer Console. You can change the color of the text by setting the output type: `"print"` and `"log"` will display as standard white text, `"warn"` will display as yellow text, and `"error"` will display as red text. You can also specify how many times the message repeats and the delay between repetitions.


---

## Getting Started (No Coding Required!)

### Step 1: Tag Your Unlockables
1. Build the object or environment exactly how you want it to look in the game.
2. Group it into a **Model** or **Folder**.
3. Use the Roblox Studio **Tag Editor** (found in the View tab) to add the following tag to that Model/Folder:
   - `UnlockableModel`
   
*Note: Make sure your `UnlockableModel` has a **unique name** in the workspace. If you name two different models "SecretDoor", the framework will only trigger the first one it finds!*

*Note: The framework will automatically hide this model when the game starts. You don't need to make it invisible yourself!*

### Step 2: Create a Trigger
1. Create a basic Part in the workspace. This is the object the player will interact with.
2. Add the following tag to the part:
   - `TRIGGER_PART`

### Step 3: Configure Your Trigger (Attributes)
To tell the game *what* this trigger should do, we use **Attributes**. Select your trigger part, scroll down to the bottom of the Properties window to the Attributes section, and add which ones you want:

| Attribute Name | Type | What it does |
|---|---|---|
| `ModelToSummon` | **String** | The exact, unique Name of the `UnlockableModel` you want to affect. You can trigger multiple at once by using commas (e.g., `ModelA, ModelB`). |
| `TriggerType` | **String** | How the player activates it. Can be `"Touch"`, `"Click"`, or `"Chat"`. (Defaults to Touch). |
| `TriggerAction` | **String** | `"Appear"` (fades the model in) or `"Disappear"` (fades it out). |
| `SetHint` | **String** | Text to display as a hint at the top of the screen when triggered. |
| `PlaySound` | **String** | The name of a Sound to play. (If the sound is inside the trigger part, it plays from there. Otherwise, it searches `SoundService`). |
| `ConsoleOutput` | **String** | Text to print to the F9 Developer Console when triggered. |
| `ConsoleOutputType` | **String** | The type of output: `"print"`, `"warn"`, `"log"`, or `"error"`. (Defaults to `GeneralConfig.Console_DefaultOutputType`). |
| `ConsoleThrottle` | **Number** | Delay in seconds between repeated messages. (Defaults to `GeneralConfig.Console_DefaultThrottle`). |
| `ConsoleAmount` | **Number** | Number of times to repeat the message. (Defaults to `GeneralConfig.Console_DefaultAmount`). |
| `ChatTrigger` | **String** | If your `TriggerType` is set to `"Chat"`, this is the exact phrase the player needs to type. |
| `ShouldNormalise` | **Boolean** | If using `"Chat"`, set to `false` to require exact casing/spacing. (Defaults to `GeneralConfig.Chat_DefaultNormalisation`). |

### Chaining Triggers
Place a `TRIGGER_PART` *inside* an `UnlockableModel`. 
When the game starts, that second trigger is hidden along with the model. Once the player activates the first trigger, the model appears, bringing the second trigger into the world. This allows you to easily chain events!

---

## Technical Documentation (For Scripters)

For developers looking to extend the framework, the architecture is built on **Knit** and utilizes the `observers` package for robust CollectionService tag management. 

### Architecture Overview
The system is divided into strict service/controller boundaries:
- **`TriggerService` (Server):** The source of truth. It handles physical Touches, Clicks, and Chat listener bindings. If `Global_ReplicationMode` is set to `"Server"`, it directly runs the visual tweens for all players globally. Otherwise, it fires signals to the Client.
- **`TriggerController` (Client):** Listens to server signals (if running in `"Client"` ReplicationMode) and handles the visual animations natively on the player's machine, reducing server overhead.
- **`SummonModelUtil` (Shared):** A shared utility that handles the actual math and caching of parts. It manages the staggered fade-in animations, memory cleanup via weak-keyed tables, and StreamingEnabled chunk loading via `DescendantAdded`.

### Global Configuration (`GeneralConfig.luau`)
Configuration is centralized in `src/shared/Constants/GeneralConfig.luau`. You can open this file to modify global settings.

### Module API Reference (`SummonModelUtil`)

The framework exposes a public utility for programmatic control of models.

```lua
local SummonModelUtil = require(ReplicatedStorage.Shared.Utilities.SummonModelUtil)
```

#### `SummonModelUtil.Summon(modelName: string): Instance?`
Finds an `UnlockableModel` by name and forces it to appear using the framework's standard staggered animation. Skips execution if the model is already unlocked. Returns the Instance if found.

#### `SummonModelUtil.ExecuteAction(modelName: string, action: string): Instance?`
Forces a specific action on a model. Valid actions are `"Appear"` and `"Disappear"`. Returns the Instance if found.

#### `SummonModelUtil.InitModel(instance: Instance)`
*(Internal)* Caches the `Transparency` and `CanCollide` properties of all descendant parts, then immediately turns the model invisible. Connects observers for `StreamingEnabled` compatibility.

### Event & State Subscriptions
When a model appears or disappears, the framework writes a boolean attribute to it called `"Unlocked"`. This avoids tight coupling and allows external codebases to subscribe to framework events natively:

```lua
instance:GetAttributeChangedSignal("Unlocked"):Connect(function()
    local isVisible = instance:GetAttribute("Unlocked")
    -- Inject custom state logic here
end)
```

