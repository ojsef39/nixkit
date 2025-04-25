import Cocoa
import Carbon
import Foundation

class HyperKey {
    private var eventTap: CFMachPort?
        private var runLoopSource: CFRunLoopSource?
        private var normalQuickPress: Bool
        private var includeShift: Bool
        private var lastKeyDown: Date?
        private var capsLockDown = false
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
        if type == .flagsChanged {
            let keycode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.flags

                if keycode == 0x39 { // Caps Lock
                    if flags.contains(.maskAlphaShift) && !capsLockDown {
                        capsLockDown = true
                            lastKeyDown = Date()
                            quickPressHandled = false
                            return nil // Suppress Caps Lock
                    } else if !flags.contains(.maskAlphaShift) && capsLockDown {
                        capsLockDown = false
                            handleQuickPress()
                            return nil
                    }
                }
        } else if capsLockDown {
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
        guard normalQuickPress,
              let lastKeyDown = lastKeyDown,
              Date().timeIntervalSince(lastKeyDown) < 0.3,
              !quickPressHandled else { return }

        let src = CGEventSource(stateID: .combinedSessionState)
            let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 0x35, keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: src, virtualKey: 0x35, keyDown: false)
            keyDown?.post(tap: .cghidEventTap)
            keyUp?.post(tap: .cghidEventTap)
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
