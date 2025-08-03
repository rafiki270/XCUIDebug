import XCTest

/// A proxy for UI debugging methods exposed as `debug` on XCTestCase.
///
/// Usage:
///   debug.printTree()
///   debug.printTree(matching: "cell")
///   debug.printTree(matching: "cell", type: .cell)
///   debug.printPath(to: "leadingButton")
public struct DebugProxy {
    private let app: XCUIApplication
    
    /// Mapping of XCUIElementType raw values to readable names
    private let elementTypeNames: [UInt: String] = [
        0: "Any", 1: "Other", 2: "Application", 3: "Group", 4: "Window", 5: "Sheet", 6: "Drawer", 7: "Alert",
        8: "Dialog", 9: "Button", 10: "RadioButton", 11: "RadioGroup", 12: "CheckBox", 13: "DisclosureTriangle",
        14: "PopUpButton", 15: "ComboBox", 16: "MenuButton", 17: "ToolbarButton", 18: "Popover", 19: "Keyboard",
        20: "Key", 21: "NavigationBar", 22: "TabBar", 23: "TabGroup", 24: "Toolbar", 25: "StatusBar", 26: "Table",
        27: "TableRow", 28: "TableColumn", 29: "Outline", 30: "OutlineRow", 31: "Browser", 32: "CollectionView",
        33: "Slider", 34: "PageIndicator", 35: "ProgressIndicator", 36: "ActivityIndicator", 37: "SegmentedControl",
        38: "Picker", 39: "PickerWheel", 40: "Switch", 41: "Toggle", 42: "Link", 43: "Image", 44: "Icon",
        45: "SearchField", 46: "ScrollView", 47: "ScrollBar", 48: "StaticText", 49: "TextField", 50: "SecureTextField",
        51: "DatePicker", 52: "TextView", 53: "Menu", 54: "MenuItem", 55: "MenuBar", 56: "MenuBarItem", 57: "Map",
        58: "WebView", 59: "IncrementArrow", 60: "DecrementArrow", 61: "Timeline", 62: "RatingIndicator",
        63: "ValueIndicator", 64: "SplitGroup", 65: "Splitter", 66: "RelevanceIndicator", 67: "ColorWell",
        68: "HelpTag", 69: "Matte", 70: "DockItem", 71: "Ruler", 72: "RulerMarker", 73: "Grid", 74: "LevelIndicator",
        75: "Cell", 76: "LayoutArea", 77: "LayoutItem", 78: "Handle", 79: "Stepper", 80: "Tab", 81: "TouchBar",
        82: "StatusItem"
    ]
    
    /// Launches or attaches to the app under test.
    public init() {
        self.app = XCUIApplication()
        if !app.wait(for: .runningForeground, timeout: 1) {
            app.launch()
        }
    }
    
    /// Prints all elements with accessibility identifiers as a tree.
    public func printTree() {
        Swift.print(buildTree(filter: nil, type: nil))
    }
    
    /// Prints tree branches matching a specific identifier.
    public func printTree(matching identifier: String) {
        Swift.print(buildTree(filter: identifier, type: nil))
    }
    
    /// Prints tree branches matching a specific identifier and element type.
    public func printTree(matching identifier: String, type: XCUIElement.ElementType) {
        Swift.print(buildTree(filter: identifier, type: type))
    }
    
    /// Prints the ancestor path to elements with the given identifier.
    public func printPath(to identifier: String) {
        Swift.print(buildPath(to: identifier))
    }
    
    // MARK: - Internal Implementation
    
    private func humanName(of t: XCUIElement.ElementType) -> String {
        if let name = elementTypeNames[t.rawValue] {
            return name
        }
        return String(describing: t)
    }
    
    private func humanName(from string: String) -> String {
        if let num = UInt(string.replacingOccurrences(of: "XCUIElementType", with: "")),
           let name = elementTypeNames[num] {
            return name
        }
        return string
    }
    
    private func buildTree(filter: String?, type: XCUIElement.ElementType?) -> String {
        let raw = app.debugDescription
        
        struct Node {
            let level: Int
            let elementType: String
            let id: String?
            let label: String?
        }
        
        let nodes: [Node] = raw
            .split(separator: "\n")
            .compactMap { line in
                let text = String(line)
                let trimmed = text.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("Attributes:") || trimmed.hasPrefix("Element subtree:") {
                    return nil
                }
                let clean = trimmed.hasPrefix("→") ? String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces) : trimmed
                guard let commaIndex = clean.firstIndex(of: ",") else { return nil }
                let typeName = String(clean[..<commaIndex])
                let level = text.prefix(while: { $0 == " " }).count / 4
                func capture(_ pattern: String) -> String? {
                    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
                    let range = NSRange(clean.startIndex..., in: clean)
                    guard let match = regex.firstMatch(in: clean, range: range),
                          match.numberOfRanges > 1,
                          let r = Range(match.range(at: 1), in: clean) else { return nil }
                    return String(clean[r])
                }
                let idVal = capture("identifier: '([^']+)'" )
                let labelVal = capture("label: '([^']+)'" )
                return Node(level: level, elementType: typeName, id: idVal, label: labelVal)
            }
        
        if let f = filter, !nodes.contains(where: { $0.id == f }) {
            return "❌ No elements found with identifier '\(f)'\nLegend: ✅ hittable, ⚠️ not hittable, 🟢 enabled, 🔴 disabled"
        }
        
        if let f = filter, let t = type {
            let idMatches = nodes.filter { $0.id == f }
            if !idMatches.isEmpty && idMatches.allSatisfy({ $0.elementType != String(describing: t) }) {
                let available = Set(idMatches.map { humanName(from: $0.elementType) }).joined(separator: ", ")
                let tName = humanName(of: t)
                return "❌ Identifier '\(f)' found but not of type \(tName). Available: \(available)\nLegend: ✅ hittable, ⚠️ not hittable, 🟢 enabled, 🔴 disabled"
            }
        }
        
        let uniqueIDs = Set(nodes.compactMap { $0.id })
        var cache: [String: (hittable: Bool, enabled: Bool)] = [:]
        for id in uniqueIDs {
            let el = app.descendants(matching: .any).matching(identifier: id).firstMatch
            cache[id] = (el.isHittable, el.isEnabled)
        }
        
        var keep = Set<Int>()
        for (i, node) in nodes.enumerated() {
            guard let idVal = node.id else { continue }
            let matchesFilter = filter == nil || idVal == filter!
            let matchesType = type == nil || node.elementType == String(describing: type!)
            if matchesFilter && matchesType {
                keep.insert(i)
                var lvl = node.level
                var j = i - 1
                while j >= 0 && lvl > 0 {
                    if nodes[j].level < lvl {
                        keep.insert(j)
                        lvl = nodes[j].level
                    }
                    j -= 1
                }
            }
        }
        
        var out = ""
        let header: String
        if let f = filter, let t = type {
            header = "UI Tree (id='\(f)', type=\(t)):\n"
        } else if let f = filter {
            header = "UI Tree (matching '\(f)'):\n"
        } else {
            header = "UI Tree (all identifiers):\n"
        }
        out += header
        
        var total = 0, hitCount = 0, enCount = 0
        for i in nodes.indices where keep.contains(i) {
            let n = nodes[i]
            total += 1
            let state = n.id.flatMap { cache[$0] } ?? (false, false)
            if state.hittable { hitCount += 1 }
            if state.enabled  { enCount += 1 }
            
            let indent = String(repeating: "   ", count: n.level)
            let idText = n.id ?? "-"
            let lblText = n.label.map { "(\($0))" } ?? ""
            let hitFlag = state.hittable ? "✅" : "⚠️"
            let enFlag  = state.enabled  ? "🟢" : "🔴"
            out += "\(indent)• \(n.elementType) \(idText)\(lblText) \(hitFlag)\(enFlag)\n"
        }
        out += "-- Summary: total=\(total), hittable=\(hitCount), enabled=\(enCount)\n"
        out += "Legend: ✅ hittable, ⚠️ not hittable, 🟢 enabled, 🔴 disabled"
        return out
    }
    
    private func buildPath(to id: String) -> String {
        let raw = app.debugDescription
        struct PNode { let level: Int; let elementType: String; let id: String? }
        let nodes: [PNode] = raw
            .split(separator: "\n")
            .compactMap { line in
                let t = String(line).trimmingCharacters(in: .whitespaces)
                guard !t.hasPrefix("Attributes:"), !t.hasPrefix("Element subtree:") else { return nil }
                let clean = t.hasPrefix("→") ? String(t.dropFirst()).trimmingCharacters(in: .whitespaces) : t
                guard let commaIdx = clean.firstIndex(of: ",") else { return nil }
                let typeName = String(clean[..<commaIdx])
                let level = line.prefix(while: { $0 == " " }).count / 4
                let idVal: String? = {
                    guard let rx = try? NSRegularExpression(pattern: "identifier: '([^']+)'"),
                          let m = rx.firstMatch(in: clean, range: NSRange(clean.startIndex..., in: clean)),
                          m.numberOfRanges > 1,
                          let r = Range(m.range(at: 1), in: clean)
                    else { return nil }
                    return String(clean[r])
                }()
                return PNode(level: level, elementType: typeName, id: idVal)
            }
        var out = ""
        var found = false
        for (i, node) in nodes.enumerated() where node.id == id {
            found = true
            var path: [(Int, PNode)] = [(node.level, node)]
            var lvl = node.level
            var j = i - 1
            while j >= 0 && lvl > 0 {
                if nodes[j].level < lvl {
                    path.append((nodes[j].level, nodes[j]))
                    lvl = nodes[j].level
                }
                j -= 1
            }
            let segments = path.reversed().map { "\($0.1.elementType)[\($0.1.id ?? "-")]" }
            out += "🔗 Path to '\(id)': " + segments.joined(separator: " → ") + "\n"
        }
        if !found {
            out += "❌ No element found with identifier '\(id)'\n"
        }
        out += "Legend: 🔗 path, ❌ not found"
        return out
    }
}

public extension XCTestCase {
    /// `debug` namespace for UI tree inspection
    var debug: DebugProxy { DebugProxy() }
}
