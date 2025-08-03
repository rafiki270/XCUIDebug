# XCUIDebug

**GitHub:** https://github.com/rafiki270/XCUIDebug

`XCUIDebug` adds a `debug` namespace to your `XCTestCase` for inspecting your app’s accessibility hierarchy during UI tests.

---

## Features

- `debug.printTree()`  
  Dumps the on-screen UI tree of elements with accessibility identifiers in a clean, indented format.

- `debug.printTree(matching: "id")`  
  Only prints branches containing the specified identifier.

- `debug.printTree(matching: "id", type: .cell)`  
  Further filters by element type, such as `.cell` or `.button`.

- `debug.printPath(to: "id")`  
  Shows the full ancestor chain from the root down to the element with the given identifier.

---

## Installation

1. Copy `UIDebug.swift` into your UI-tests target.
2. Add it to **Compile Sources** of your UI Tests target in Xcode.
3. In your test files:
   ```swift
   import XCTest
   ```
4. Use the `debug` proxy in any `XCTestCase`:
   ```swift
   class MyUITests: XCTestCase {
     func testLoginFlow() {
       debug.printTree()
       debug.printTree(matching: "loginButton")
       debug.printTree(matching: "loginButton", type: .button)
       debug.printPath(to: "loginButton")
     }
   }
   ```

---

## Example Output

### `debug.printTree()`

```text
UI Tree (all identifiers):
• NavigationBar navigationBarView
   • Button leadingButton ✅🟢
   • StaticText titleLabel ✅🟢
• CollectionView vehicleList ✅🟢
   • Cell vehicleCell(“1234”) ✅🟢
   • Cell vehicleCell(“5678”) ⚠️🟢
-- Summary: total=5, hittable=4, enabled=5
Legend: ✅ hittable, ⚠️ not hittable, 🟢 enabled, 🔴 disabled
```

### `debug.printPath(to: "leadingButton")`

```text
🔗 Path to 'leadingButton': Application → Window → Other[navigationBarView] → Button[leadingButton]
Legend: 🔗 path, ❌ not found
```

---

## How It Works

1. Parses `XCUIApplication().debugDescription` to build the UI tree.
2. Maps `XCUIElement.ElementType` raw values to human-readable names (e.g. `12` → `CheckBox`).

---

## License

MIT © rafiki270
