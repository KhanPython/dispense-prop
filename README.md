<div align="center">
	<h1>Dispense Prop</h1>
    <p>A system for physically dispensing and attracting in-game props.</p>
</div>



### Features

- Spawn a customizable number of props from a specified origin.
- Automatic Cleanup: Optional auto-destroy timer to remove all props after a specific time.
- Option to 'attract' the props towards the target object.
- Initial dispense-behavior is physics driven, while the attract uses CFraming.
- Hooks for spawn, claim, and completion.


---

### Installation via wally

1. Ensure you have the [Wally package manager](https://github.com/UpliftGames/wally) installed on your system.
2. Add the following line to your `wally.toml` file under the `[dependencies]` section:
   ```toml
   dispense-prop = "khanpython/dispense-prop@3.3.0"
   ```
3. Run the Wally install command to download and integrate the package:
    ```bash
    wally install
    ```
4. The package will be placed in your Packages folder. Use the following code snippet to require it in your project:
    ```lua
    local DispenseProp = require(path-to-package)
    ```

---

### Parameters

- **`Amount`**: The number of props to spawn. Must be an integer greater than or equal to 1.
- **`Origin`**: A `Vector3` representing the starting position of the props.
- **`TargetObject`**: The `Model` or `BasePart` towards which the props will be attracted.
- **`PropInstance`**: A `Model` that serves as the template for spawned props. Must have a `PrimaryPart` defined.
- **`CollisionGroup`** *(optional)*: A string specifying the collision group for the props.
- **`ClearDistance`** *(optional)*: The distance from the `TargetObject` at which a prop is considered "cleared." Defaults to 3.
- **`ClaimDelay`** *(optional)*: The time in seconds before props can start interacting with the target. Defaults to 3.
- **`AutoDestroyTime`** *(optional)*: The time in seconds after which all props are automatically destroyed. Defaults to none.
- **`AttractMagnitude`** *(optional)*: The distance from the target within which props start moving towards it. Defaults to none.
- **`AttractSpeed`** *(optional)*: The speed at which props move towards the target when attracted. Required if `AttractMagnitude` is defined.
- **`OnSpawn`** *(optional)*: A callback function triggered when a prop is spawned.
- **`OnPropCleared`** *(optional)*: A callback function triggered when a single prop is cleared.
- **`OnAllCleared`** *(optional)*: A callback function triggered when all props are cleared or destroyed.
  

---

### Example Usage
```lua
local DispenseProp = require(path-to-package)

local props = DispenseProp({
    Amount = 5,
    Origin = Vector3.new(0, 10, 0),
    TargetObject = workspace.Target,
    PropInstance = game.ReplicatedStorage.PropTemplate,
    CollisionGroup = "Props",
    ClearDistance = 2,
    ClaimDelay = 5,
    AutoDestroyTime = 60,
    AttractMagnitude = 15,
    AttractSpeed = 10,
    OnSpawn = function(prop)
        print("Prop spawned:", prop)
        -- You need to manually parent the prop and apply your own `spill` logic
        prop.Parent = workspace
        prop.PrimaryPart:ApplyImpulse(
            Vector3.new(math.random(-10, 10), math.random(5, 10), math.random(-10, 10))
        )
    end,
    OnCleared = function()
        print("A prop has been cleared!")
    end,
    OnAllCleared = function()
        print("All props have been cleared!")
    end,
})

print("Props in system:", props)
```
---

