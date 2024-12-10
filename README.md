<div align="center">
	<h1>Dispense Prop</h1>
    <p>A promise-based system for physically dispensing and attracting in-game props.</p>
</div>



## Features

- Spawn a customizable number of props from a specified origin.
- Automatic Cleanup: Optional auto-destroy timer to remove all props after a specific time.
- Option to 'attract' the props towards the target object.
- Initial dispense-behavior is physics driven, while the attract uses CFraming.
- Hooks for spawn, claim, and completion.
- Promise-based.


---

## Installation via wally

1. Ensure you have the [Wally package manager](https://github.com/UpliftGames/wally) installed on your system.
2. Add the following line to your `wally.toml` file under the `[dependencies]` section:
   ```toml
   dispense-prop = "khanpython/dispense-prop@2.2.1"
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

## Usage


#### Parameters
- `Amount` (number): Number of props to spawn. Must be an integer ≥ 1.
- `Origin` (Vector3): The starting position for the props.
- `TargetObject` (Model | BasePart): The object towards which props will be attracted.
- `PropInstance` (Model): A pre-configured model to use for each prop.
- `CollisionGroup` (string?): The collision group for the props.
- `AutoDestroyTime` (number?): Time in seconds before all props are destroyed automatically.
- `AttractDistance` (number?): The maximum distance for props to be attracted to the target.
- `OnDispense` (function?): Callback invoked when a prop is spawned. Receives the prop instance as an argument.
- `OnPropClaim` (function?): Callback invoked when a prop is claimed.
- `OnAllClaimed` (function?): Callback invoked when all props are claimed.

#### Returns
A Promise that resolves soon as the props are instantiated.

#### Example Usage
```lua
local DispenseProp = require(script.DispenseProp)

DispenseProp({
    Amount = 10,
    Origin = Vector3.new(0, 10, 0),
    TargetObject = workspace.Target,
    PropInstance = workspace.PropTemplate,
    CollisionGroup = "Props",
    AutoDestroyTime = 30,
    AttractDistance = 50,
    OnDispense = function(prop)
        print("Prop dispensed:", prop.Name)

        -- You will need to apply your own dispense logic
        prop.PrimaryPart:ApplyImpulse(Vector3.new(0, 10, 0))
    end,
    OnPropClaim = function()
        print("A prop has been claimed!")
    end,
    OnAllClaimed = function()
        print("All props have been claimed!")
    end,
}):await()
