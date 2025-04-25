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
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if let refcon = refcon {
                    let hyperKey = Unmanaged<HyperKey>.fromOpaque(refcon).takeUnretainedValue()
                    return hyperKey.handleEvent(proxy: proxy, type: type, event: event)
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            NSLog("Failed to create event tap")
            return
        }
        
        self.eventTap = eventTap
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        NSLog("HyperKey service started")
        NSLog("normalQuickPress: \(normalQuickPress)")
        NSLog("includeShift: \(includeShift)")
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .flagsChanged {
            let flags = event.flags
            let isCapsLockKey = event.getIntegerValueField(.keyboardEventKeycode) == 0x3A
            
            if isCapsLockKey {
                if !capsLockDown && flags.contains(.maskAlphaShift) {
                    // Caps Lock key down
                    capsLockDown = true
                    lastKeyDown = Date()
                    quickPressHandled = false
                    
                    // Suppress the original Caps Lock event
                    setHyperModifiers(event: event, down: true)
                    return nil
                } else if capsLockDown && !flags.contains(.maskAlphaShift) {
                    // Caps Lock key up
                    capsLockDown = false
                    
                    // If it was a quick press and that feature is enabled
                    if normalQuickPress && !quickPressHandled, 
                       let lastKeyDown = lastKeyDown, 
                       Date().timeIntervalSince(lastKeyDown) < 0.3 {
                        // Send Escape key
                        let escapeEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0x35, keyDown: true)
                        escapeEvent?.post(tap: .cghidEventTap)
                        
                        let escapeUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0x35, keyDown: false)
                        escapeUpEvent?.post(tap: .cghidEventTap)
                        
                        quickPressHandled = true
                    }
                    
                    // Remove hyper modifiers
                    setHyperModifiers(event: event, down: false)
                    return nil
                }
            }
        } else if capsLockDown {
            // Mark that we've handled a key while Caps Lock is down
            quickPressHandled = true
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private func setHyperModifiers(event: CGEvent, down: Bool) {
        var flags = event.flags
        
        // Remove caps lock flag
        flags.remove(.maskAlphaShift)
        
        if down {
            // Add hyper modifier flags
            flags.insert(.maskCommand)
            flags.insert(.maskControl)
            flags.insert(.maskAlternate)
            
            if includeShift {
                flags.insert(.maskShift)
            }
        } else {
            // Remove hyper modifier flags
            flags.remove(.maskCommand)
            flags.remove(.maskControl)
            flags.remove(.maskAlternate)
            
            if includeShift {
                flags.remove(.maskShift)
            }
        }
        
        // Create and post a synthetic flags changed event
        if let flagsEvent = CGEvent(source: nil) {
            flagsEvent.type = .flagsChanged
            flagsEvent.flags = flags
            flagsEvent.post(tap: .cghidEventTap)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var hyperKey: HyperKey?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = CommandLine.arguments
        var normalQuickPress = true
        var includeShift = false
        
        // Parse command line arguments
        for i in 1..<args.count {
            if args[i] == "--no-quick-press" {
                normalQuickPress = false
            } else if args[i] == "--include-shift" {
                includeShift = true
            }
        }
        
        // Request accessibility permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        if !AXIsProcessTrustedWithOptions(options) {
            NSLog("HyperKey requires accessibility permissions. Please grant them in System Preferences.")
        }
        
        hyperKey = HyperKey(normalQuickPress: normalQuickPress, includeShift: includeShift)
        
        // Add menu bar icon
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "HyperKey")
            button.title = "⌘⌃⌥"
            if includeShift {
                button.title! += "⇧"
            }
        }
        
        // Create menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "HyperKey Active", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
}

// Start the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
