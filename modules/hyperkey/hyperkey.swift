import Cocoa
import Carbon
import Foundation
import IOKit.hid

class HyperKey {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var normalQuickPress: Bool
    private var includeShift: Bool
    private var lastKeyDown: Date?
    private var f18Down = false
    private var quickPressHandled = false

    init(normalQuickPress: Bool, includeShift: Bool) {
        self.normalQuickPress = normalQuickPress
        self.includeShift = includeShift
        setupEventTap()
    }

    deinit {
        if let eventTap = eventTap {
            CFMachPortInvalidate(eventTap)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
    }

    private func setupEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | 
                        (1 << CGEventType.keyUp.rawValue) | 
                        (1 << CGEventType.flagsChanged.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passUnretained(event)
                }
                let hyperKey = Unmanaged<HyperKey>.fromOpaque(refcon).takeUnretainedValue()
                return hyperKey.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            NSLog("Failed to create event tap. Enable Input Monitoring permissions!")
            return
        }

        self.eventTap = eventTap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    private func handleEvent(proxy: CGEventTapProxy?, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .keyDown || type == .keyUp {
            let keycode = event.getIntegerValueField(.keyboardEventKeycode)
            if keycode == UInt32(kVK_F18) { // F18 keycode
                if type == .keyDown {
                    // print("Key down")
                    f18Down = true
                    lastKeyDown = Date()
                    quickPressHandled = false
                    return nil // Suppress F18 key down
                } else {
                    // print("Key up")
                    f18Down = false
                    handleQuickPress()
                    return nil // Suppress F18 key up
                }
            }
        }
        
        if f18Down {
            var modifiers: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate]
            if includeShift {
                modifiers.insert(.maskShift)
            }
            event.flags = modifiers
            quickPressHandled = true
        }
        
        return Unmanaged.passUnretained(event)
    }

    private func handleQuickPress() {
        let date = Date().timeIntervalSince(lastKeyDown!)
        print("\(date)")
        guard normalQuickPress, let lastKeyDown = lastKeyDown, Date().timeIntervalSince(lastKeyDown) > 0.05, !quickPressHandled else { return }
        //TODO: impelement caps lock toggle
    }


}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var hyperKey: HyperKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = CommandLine.arguments
        var normalQuickPress = true
        var includeShift = false

        for i in 1..<args.count {
            if args[i] == "--no-quick-press" {
                normalQuickPress = false
            } else if args[i] == "--include-shift" {
                includeShift = true
            }
        }

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if !AXIsProcessTrustedWithOptions(options) {
            NSLog("Enable Accessibility in System Settings → Privacy → Accessibility")
        }

        hyperKey = HyperKey(normalQuickPress: normalQuickPress, includeShift: includeShift)

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "HyperKey")
            button.title = "⌘⌃⌥" + (includeShift ? "⇧" : "")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "HyperKey Active", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
}

// Strong reference to retain delegate
let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
