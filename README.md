<div align="center">
	<h1>Prop Dispenser</h1>
    <p>System for physically dispensing and attracting in-game props towards a target.</p>
     <img src="https://media.giphy.com/media/mt6Ct3gpcAOVzwk95i/giphy.gif" width="350" height="350" alt="Prop Dispenser Demo">
</div>


---

### Features

- Customizable Prop Spawning: Spawn a specified number of props from a given origin with configurable settings.
- Automatic Prop Removal: Optionally remove props automatically after a configurable duration.
- Attraction Mechanism:  Move props toward a target object within a defined attraction distance, with optional physics-based motion.
- Physics-Based Dispensing: Simulate natural, physics-driven prop dispensing. The latter attraction works by per-frame positional changes using PivotTo.
- Event Callbacks: Attach custom logic to prop spawn, removal, and group completion events for added flexibility.

---

### Installation via Wally

1. Ensure you have the [Wally package manager](https://github.com/UpliftGames/wally) installed on your system.
2. Add the following line to your `wally.toml` file under the `[dependencies]` section:
   ```toml
   dispense-prop = "khanpython/dispense-prop@4.2.0"
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

### Parameters

#### `PropManager:Start(amount, originCFrame, propTemplate, targetInstance, settings)`

| Parameter        | Type            | Description                                                                 |
|------------------|-----------------|-----------------------------------------------------------------------------|
| `amount`         | `number`        | The number of props to spawn. Must be an integer.                          |
| `originCFrame`   | `CFrame`        | The starting position for the props.                                       |
| `propTemplate`   | `Model or BasePart`| A template instance to clone for each prop.                                |
| `targetInstance` | `Model or BasePart`| The target instance towards which props may be attracted.                  |
| `settings`       | `table`         | A table of configuration options for the props. See details below.         |

#### `settings` Table

| Key               | Type             | Default      | Description                                                                 |
|--------------------|------------------|--------------|-----------------------------------------------------------------------------|
| `RemoveMagnitude` | `number?`        | `5`          | The distance within which a prop is automatically removed.                  |
| `AttractSpeed`    | `number?`        | `10`         | The speed at which props move towards the target.                           |
| `AttractMagnitude`| `number?`        | `nil`        | The range within which props start moving towards the target.               |
| `AttractDelay`      | `number?`        | `1`          | Time delay before props become 'live' after spawning. Live implying that the prop can be attracted and claimed by the target Instance.                      |
| `AutoRemoveTime`  | `number?`        | `nil`        | Time in seconds before props are automatically removed.                     |
| `CollisionGroup`  | `string?`        | `Default`    | The collision group assigned to props.                                      |
| `OnSpawn`         | `function`       | `nil`        | A function executed when a prop is spawned.                                 |
| `OnRemoved`       | `function?`      | `nil`        | A function executed when a prop is removed.                                 |
| `OnAllRemoved`    | `function?`      | `nil`        | A function executed when all props in a group are removed.                  |

---

### Example Usage

```lua
local PropDispenser = require(path-to-package)

-- Define settings for the props
local settings = {
    RemoveMagnitude = 5,
    AttractSpeed = 15,
    AttractMagnitude = 20,
    AttractDelay = 3,
    AutoRemoveTime = 30,
    CollisionGroup = "CustomGroup",

    --! Imporant: Avoid yielding any of the callbacks v
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
    OnRemoved = function(byAutoRemove)
        print("Prop removed.")

        --[[
            * This hook is triggered whenever a single prop is removed. 
            * The `byAutoRemove` parameter indicates whether the removal was due to the automatic removal timer (`true`), or because the prop was cleared/claimed by the target (`false`).
            * For example, you could use this to send a message to the server to reward the player and update a pool of claimable rewards.
        ]]
    end,
    OnAllRemoved = function()
        print("All props removed.")

        --[[
            * This hook is triggered when all props in the current group have been removed, regardless of whether the removals occurred due to automatic removal or clearing/claiming by the target.
            * Use this to execute any logic that depends on the entire group being cleared, such as finalizing a reward process
        ]]
    end,
}

-- Start spawning props
PropDispenser:Start(
    10,                 -- Number of props
    CFrame.new(0, 10, 0), -- Origin position
    workspace.PropTemplate, -- Template prop instance
    workspace.Target,       -- Target instance
    settings                -- Settings table
)
```

