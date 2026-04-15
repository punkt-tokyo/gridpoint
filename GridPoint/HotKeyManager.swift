import AppKit
import Carbon.HIToolbox

final class HotKeyManager {
    static let shared = HotKeyManager()

    private var refs: [UInt32: EventHotKeyRef] = [:]
    private var handlers: [UInt32: () -> Void] = [:]
    private var installed = false

    private init() {}

    func registerAll() {
        installHandlerIfNeeded()
        unregisterAll()

        bind(id: 1, action: .toggle)  { GridSettings.shared.toggleVisible(); GridWindowController.shared.apply() }
    }

    func reregister() {
        registerAll()
    }

    func unregisterAll() {
        for (_, ref) in refs {
            UnregisterEventHotKey(ref)
        }
        refs.removeAll()
        handlers.removeAll()
    }

    private func bind(id: UInt32, action: HotKeyAction, handler: @escaping () -> Void) {
        guard let binding = GridSettings.shared.hotKeys[action] else { return }

        var hkRef: EventHotKeyRef?
        var hotKeyID = EventHotKeyID(signature: OSType(0x47524944), id: id) // 'GRID'
        let status = RegisterEventHotKey(
            binding.keyCode,
            binding.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hkRef
        )
        if status == noErr, let ref = hkRef {
            refs[id] = ref
            handlers[id] = handler
        }
    }

    private func installHandlerIfNeeded() {
        guard !installed else { return }
        installed = true

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: OSType(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, eventRef, userData) -> OSStatus in
                guard let eventRef = eventRef, let userData = userData else { return noErr }
                var hkID = EventHotKeyID()
                let err = GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                if err == noErr {
                    let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                    DispatchQueue.main.async {
                        manager.handlers[hkID.id]?()
                    }
                }
                return noErr
            },
            1,
            &spec,
            selfPtr,
            nil
        )
    }
}
