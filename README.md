<div align="center">
	<h1>Prop Dispenser</h1>
    <p>System for physically dispensing and attracting in-game props towards a target.</p>
     <img src="https://media.giphy.com/media/mt6Ct3gpcAOVzwk95i/giphy.gif" width="350" height="350" alt="Prop Dispenser Demo">
</div>


---

### Features:

- **Customizable Prop Spawning:** Spawn a specified number of props from a given origin with configurable settings.
- **Automatic Prop Removal:** Optionally remove props automatically after a configurable duration.
- **Sigmoid Attraction:** Props are attracted towards a target using a smooth sigmoid easing curve over a configurable duration.
- **Dynamic Timing:** `AttractDelay` and `AttractDuration` accept a fixed number, a `Vector2` range for per-prop randomization, or a custom function.
- **Batch Movement:** All attracted props are moved in a single `workspace:BulkMoveTo` call each frame for minimal overhead.
- **SoA Data Layout:** Internal state uses flat, cache-friendly Structure of Arrays instead of nested dictionaries.
- **Event Callbacks:** Attach custom logic to prop spawn, removal, and group completion events.

---

### Installation via Wally:

1. Ensure you have the [Wally package manager](https://github.com/UpliftGames/wally) installed on your system.
2. Add the following line to your `wally.toml` file under the `[dependencies]` section:
   ```toml
   dispense-prop = "khanpython/dispense-prop@5.1.0"
   ```
3. Run the Wally install command to download and integrate the package:
    ```bash
    wally install
    ```
4. The package will be placed in your Packages folder. Use the following code snippet to require it in your project:
    ```lua
    local PropManager = require(path-to-package)
    ```

---

### Parameters:

#### `PropManager:Start(amount, originCFrame, propTemplate, targetInstance, settings)`

| Parameter        | Type            | Description                                                                 |
|------------------|-----------------|-----------------------------------------------------------------------------|
| `amount`         | `number`        | The number of props to spawn. Must be an integer >= 1.                     |
| `originCFrame`   | `CFrame`        | The starting position for the props.                                       |
| `propTemplate`   | `Model or BasePart`| A template instance to clone for each prop.                                |
| `targetInstance` | `Model or BasePart`| The target instance towards which props may be attracted.                  |
| `settings`       | `table`         | A table of configuration options for the props. See details below.         |

#### `settings` Table

`DynamicNumber` = `number | Vector2 | (propIndex: number) -> number`

| Key               | Type             | Default      | Description                                                                 |
|--------------------|------------------|--------------|-----------------------------------------------------------------------------|
| `RemoveMagnitude` | `number?`        | `1`          | The distance within which a prop is removed (claimed).                      |
| `AttractMagnitude`| `number?`        | `nil`        | The range within which props begin attraction. `nil` means attract from any distance. |
| `AttractDuration` | `DynamicNumber?` | `1.5`        | How long (seconds) the sigmoid attraction takes to complete.                |
| `AttractDelay`    | `DynamicNumber?` | `3`          | Time delay before a prop becomes live and can be attracted/claimed.         |
| `AutoRemoveTime`  | `number?`        | `nil`        | Time in seconds before props are automatically removed.                     |
| `CollisionGroup`  | `string?`        | `Props`      | The collision group assigned to props.                                      |
| `OnSpawn`         | `function`       | required     | A function executed when a prop is spawned.                                 |
| `OnRemoved`       | `function?`      | `nil`        | A function executed when a prop is removed. Receives `true` if forced (auto-remove/external destroy). |
| `OnAllRemoved`    | `function?`      | `nil`        | A function executed when all props in a group are removed.                  |

#### DynamicNumber

`AttractDelay` and `AttractDuration` accept a `DynamicNumber`, which resolves per-prop at spawn time. This lets you stagger or randomize timing across a group.

| Form | Behavior | Example |
|------|----------|---------|
| `number` | Same value for every prop | `AttractDelay = 2` |
| `Vector2` | Random value in `[min, max]` (order doesn't matter) | `AttractDuration = Vector2.new(1, 3)` |
| `function` | Called with the prop's 1-based index in the group | `AttractDelay = function(i) return i * 0.15 end` |

```lua
-- Fixed: all props attract after 2 seconds
AttractDelay = 2

-- Random: each prop gets a random delay between 1 and 4 seconds
AttractDelay = Vector2.new(1, 4)

-- Staggered: prop 1 waits 0.15s, prop 2 waits 0.3s, etc.
AttractDelay = function(propIndex)
    return propIndex * 0.15
end
```

---

### Example Usage:

```lua
local PropDispenser = require(path-to-package)

local settings = {
    RemoveMagnitude = 2,
    AttractMagnitude = 20,
    AttractDuration = Vector2.new(1, 2), -- random 1-2s per prop
    AttractDelay = 3,
    AutoRemoveTime = 30,
    CollisionGroup = "Props",

    --! Important: Avoid yielding any of the callbacks. `OnSpawn` could be an exception, though it may lead to unexpected results.
    OnSpawn = function(prop)
        print("Spawned prop:", prop)

        -- You must manually parent the prop
        prop.Parent = workspace

        local randomX = math.random(-10, 10)
        local randomY = math.random(5, 10)
        local randomZ = math.random(-10, 10)

        -- Your `spill` logic
        task.defer(function()
            prop.PrimaryPart:ApplyImpulse(
                Vector3.new(randomX, randomY, randomZ)
            )
        end)
    end,
    OnRemoved = function(wasForced)
        print("Prop removed.")

        --[[
            * Triggered whenever a single prop is removed.
            * `wasForced` is `true` if the removal was due to auto-remove, external destruction,
              or the target leaving. It is `nil`/falsy when the prop was claimed normally.
        ]]
    end,
    OnAllRemoved = function()
        print("All props removed.")

        --[[
            * Triggered when every prop in the group has been removed,
              regardless of how each individual removal occurred.
        ]]
    end,
}

PropDispenser:Start(
    10, -- Number of props
    CFrame.new(0, 10, 0), -- Origin position
    workspace.PropTemplate, -- Template prop instance
    workspace.Target, -- Target instance
    settings -- Settings table
)
```
---
