//
//  CombinedView.swift
//  Stats
//
//  Created by Serhiy Mytrovtsiy on 09/01/2023
//  Using Swift 5.0
//  Running on macOS 13.1
//
//  Copyright © 2023 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa
import Kit

internal class CombinedView: NSObject, NSGestureRecognizerDelegate {
    private var menuBarItem: NSStatusItem? = nil
    private var view: NSView = NSView(frame: NSRect(x: 0, y: 0, width: 0, height: Constants.Widget.height))
    private var popup: PopupWindow? = nil
    
    private var status: Bool {
        Store.shared.bool(key: "CombinedModules", defaultValue: false)
    }
    private var spacing: CGFloat {
        CGFloat(Int(Store.shared.string(key: "CombinedModules_spacing", defaultValue: "")) ?? 0)
    }
    private var separator: Bool {
        Store.shared.bool(key: "CombinedModules_separator", defaultValue: false)
    }
    
    private var activeModules: [Module] {
        modules.filter({ $0.enabled }).sorted(by: { $0.combinedPosition < $1.combinedPosition })
    }
    
    private var combinedModulesPopup: Bool {
        get { Store.shared.bool(key: "CombinedModules_popup", defaultValue: true) }
        set { Store.shared.set(key: "CombinedModules_popup", value: newValue) }
    }
    
    override init() {
        super.init()
        
        modules.forEach { (m: Module) in
            m.menuBar.callback = { [weak self] in
                if let s = self?.status, s {
                    DispatchQueue.main.async(execute: {
                        self?.recalculate()
                    })
                }
            }
        }
        
        self.popup = PopupWindow(title: "Combined modules", module: .combined, view: CombinedPopup(modules)) { _ in }
        
        if self.status {
            self.enable()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(listenForOneView), name: .toggleOneView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(listenForModuleRearrrange), name: .moduleRearrange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(closePopup), name: .combinedModulesPopup, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .toggleOneView, object: nil)
        NotificationCenter.default.removeObserver(self, name: .moduleRearrange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .combinedModulesPopup, object: nil)
    }
    
    public func enable() {
        self.menuBarItem = NSStatusBar.system.statusItem(withLength: 0)
        DispatchQueue.main.async(execute: {
            self.menuBarItem?.autosaveName = "CombinedModules"
        })
        self.menuBarItem?.button?.addSubview(self.view)
        self.menuBarItem?.button?.image = NSImage()
        self.menuBarItem?.button?.toolTip = localizedString("Combined modules")
        
        self.menuBarItem?.button?.target = self
        self.menuBarItem?.button?.action = #selector(self.handleClick)
        self.menuBarItem?.button?.sendAction(on: [.leftMouseDown, .rightMouseDown])
        
        DispatchQueue.main.async(execute: {
            self.recalculate()
        })
    }
    
    public func disable() {
        self.closePopup()
        if let item = self.menuBarItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        self.menuBarItem = nil
    }
    
    private func recalculate() {
        self.view.subviews.forEach({ $0.removeFromSuperview() })
        
        let visibleModules = self.activeModules.filter({ !$0.menuBar.activeWidgets.isEmpty })
        var w: CGFloat = 0
        visibleModules.enumerated().forEach { (i, m) in
            if i != 0 {
                w += self.spacing
                if self.separator {
                    self.view.addSubview(SeparatorLineView(frame: NSRect(x: w, y: 3, width: 1, height: Constants.Widget.height-6)))
                    w += 3 + self.spacing
                }
            }
            self.view.addSubview(m.menuBar.view)
            m.menuBar.view.setFrameOrigin(NSPoint(x: w, y: 0))
            w += m.menuBar.view.frame.width
        }
        self.view.setFrameSize(NSSize(width: w, height: self.view.frame.height))
        self.menuBarItem?.length = w
    }
    
    @objc private func closePopup() {
        self.popup?.setIsVisible(false)
    }
    
    @objc private func handleClick() {
        if self.combinedModulesPopup {
            self.togglePopup()
        } else {
            self.openModulePopup()
        }
    }
    
    private func openModulePopup() {
        guard let window = self.menuBarItem?.button?.window else { return }
        let location = self.view.convert(window.convertPoint(fromScreen: NSEvent.mouseLocation), from: nil)
        let visibleModules = self.activeModules.filter({ !$0.menuBar.activeWidgets.isEmpty })
        guard let module = visibleModules.last(where: { $0.menuBar.view.frame.minX <= location.x }) ?? visibleModules.first else { return }
        
        var userInfo: [String: Any] = [
            "module": module.name,
            "origin": window.frame.origin,
            "center": window.frame.width/2
        ]
        let widgetLocation = module.menuBar.view.convert(location, from: self.view)
        let widgets = module.menuBar.activeWidgets
        if let widget = widgets.last(where: { $0.item.frame.minX <= widgetLocation.x }) ?? widgets.first {
            userInfo["widget"] = widget.type
        }
        NotificationCenter.default.post(name: .togglePopup, object: nil, userInfo: userInfo)
    }
    
    private func togglePopup() {
        guard let popup = self.popup, let item = self.menuBarItem, let window = item.button?.window else { return }
        let openedWindows = NSApplication.shared.windows.filter{ $0 is NSPanel }
        openedWindows.forEach{ $0.setIsVisible(false) }
        
        if popup.occlusionState.rawValue == 8192 {
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            popup.contentView?.invalidateIntrinsicContentSize()
            
            let windowCenter = popup.contentView!.intrinsicContentSize.width / 2
            var x = window.frame.origin.x - windowCenter + window.frame.width/2
            let y = window.frame.origin.y - popup.contentView!.intrinsicContentSize.height - 3
            
            let buttonPoint = NSPoint(x: window.frame.midX, y: window.frame.midY)
            if let screen = NSScreen.screens.first(where: { $0.frame.contains(buttonPoint) }) ?? NSScreen.main {
                if x + popup.contentView!.intrinsicContentSize.width > screen.frame.maxX {
                    x = screen.frame.maxX - popup.contentView!.intrinsicContentSize.width - 3
                }
                if x < screen.frame.minX {
                    x = screen.frame.minX + 3
                }
            }
            
            popup.setFrameOrigin(NSPoint(x: x, y: y))
            popup.setIsVisible(true)
        } else {
            popup.setIsVisible(false)
        }
    }
    
    @objc private func listenForOneView(_ notification: Notification) {
        guard notification.userInfo?["module"] == nil else { return }
        
        if self.status {
            self.enable()
        } else {
            self.disable()
        }
    }
    
    @objc private func listenForModuleRearrrange() {
        self.recalculate()
    }
}

private class SeparatorLineView: NSView {
    override var wantsUpdateLayer: Bool { true }
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        self.wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateLayer() {
        self.layer?.backgroundColor = (self.isDarkMode ? NSColor.white : NSColor.black).cgColor
    }
    
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        self.needsDisplay = true
    }
}

internal class CombinedPopup: NSStackView, Popup_p {
    var keyboardShortcut: [UInt16] = []
    var sizeCallback: ((NSSize) -> Void)? = nil
    private let modules: [Module]
    private var mouseLocation: NSPoint = .zero
    private var displayedModules: [Module] = []
    private var activeModule: Module?
    private var detailPopup: PopupWindow?
    private var pendingModule: Module?
    private var showWorkItem: DispatchWorkItem?
    private var hideWorkItem: DispatchWorkItem?
    private var localMonitor: Any?
    private var globalMonitor: Any?
    
    init(_ modules: [Module]) {
        self.modules = modules
        self.keyboardShortcut = Store.shared.array(key: "CombinedModules_popup_keyboardShortcut", defaultValue: []) as? [UInt16] ?? []
        
        super.init(frame: NSRect(x: 0, y: 0, width: Constants.Popup.width, height: 0))
        
        self.orientation = .vertical
        self.distribution = .fill
        self.alignment = .width
        self.spacing = Constants.Popup.spacing*3
        
        self.reinit()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reinit), name: .toggleModule, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reinit), name: .moduleRearrange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(close), name: NSApplication.didResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(close), name: .togglePopup, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.stopMonitoring()
        NotificationCenter.default.removeObserver(self)
    }
    
    func settings() -> NSView? { return nil }
    func appear() {
        self.stopMonitoring()
        self.localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .scrollWheel, .leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            guard let self = self else { return event }
            let point = event.window?.convertPoint(toScreen: event.locationInWindow) ?? NSEvent.mouseLocation
            if event.type == .keyDown {
                if event.keyCode == 53 {
                    self.close()
                    return nil
                }
            } else if event.type == .leftMouseDown || event.type == .rightMouseDown {
                if !self.containsMouse(at: point) { self.close() }
            } else {
                DispatchQueue.main.async { [weak self] in self?.updateHover(at: point) }
            }
            return event
        }
        self.globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown, .rightMouseDown]) { [weak self] event in
            if event.type == .mouseMoved {
                self?.updateHover(at: NSEvent.mouseLocation)
            } else {
                self?.close()
            }
        }
        DispatchQueue.main.async { [weak self] in self?.updateHover(at: NSEvent.mouseLocation) }
    }

    func disappear() {
        self.stopMonitoring()
        self.hideDetails()
    }

    private func stopMonitoring() {
        if let monitor = self.localMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = self.globalMonitor { NSEvent.removeMonitor(monitor) }
        self.localMonitor = nil
        self.globalMonitor = nil
        self.cancelPendingShow()
        self.hideWorkItem?.cancel()
        self.hideWorkItem = nil
    }

    private func containsMouse(at point: NSPoint) -> Bool {
        return self.window?.frame.contains(point) == true || self.detailPopup?.frame.contains(point) == true
    }

    private func moduleUnderMouse() -> Module? {
        guard let window = self.window, window.isVisible, window.frame.contains(self.mouseLocation) else { return nil }
        self.layoutSubtreeIfNeeded()
        return self.displayedModules.first { module in
            guard let portal = module.portal else { return false }
            let rect = portal.bounds.intersection(portal.visibleRect)
            return !rect.isEmpty && window.convertToScreen(portal.convert(rect, to: nil)).contains(self.mouseLocation)
        }
    }

    private func updateHover(at point: NSPoint) {
        self.mouseLocation = point
        guard self.window?.isVisible == true else { return }
        if let popup = self.detailPopup, popup.isVisible, popup.frame.contains(point) {
            self.cancelPendingShow()
            self.hideWorkItem?.cancel()
            self.hideWorkItem = nil
            return
        }
        if let module = self.moduleUnderMouse() {
            self.hideWorkItem?.cancel()
            self.hideWorkItem = nil
            if module === self.activeModule, self.detailPopup?.isVisible == true {
                self.cancelPendingShow()
                self.detailPopup?.positionBesideAnchor()
                return
            }
            guard module !== self.pendingModule else { return }
            self.cancelPendingShow()
            self.pendingModule = module
            let work = DispatchWorkItem { [weak self] in
                guard let self = self, self.moduleUnderMouse() === module, let portal = module.portal else { return }
                self.hideDetails()
                self.detailPopup = module.showPopup(beside: portal)
                if self.detailPopup != nil {
                    self.activeModule = module
                    portal.wantsLayer = true
                    portal.layer?.cornerRadius = 6
                    portal.layer?.borderColor = NSColor.controlAccentColor.cgColor
                    portal.layer?.borderWidth = 1
                }
            }
            self.showWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
        } else {
            self.cancelPendingShow()
            if let popup = self.detailPopup, popup.isVisible, popup.frame.insetBy(dx: -8, dy: -8).contains(point) {
                self.hideWorkItem?.cancel()
                self.hideWorkItem = nil
                return
            }
            guard self.detailPopup != nil, self.hideWorkItem == nil else { return }
            let work = DispatchWorkItem { [weak self] in self?.hideDetails() }
            self.hideWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
        }
    }

    private func cancelPendingShow() {
        self.showWorkItem?.cancel()
        self.showWorkItem = nil
        self.pendingModule = nil
    }

    private func hideDetails() {
        self.cancelPendingShow()
        self.hideWorkItem?.cancel()
        self.hideWorkItem = nil
        self.activeModule?.portal?.layer?.borderWidth = 0
        self.activeModule = nil
        let wasKey = self.detailPopup?.isKeyWindow == true
        self.detailPopup?.setIsVisible(false)
        self.detailPopup = nil
        if wasKey, self.window?.isVisible == true { self.window?.makeKey() }
    }

    @objc private func close() {
        self.window?.setIsVisible(false)
    }
    func setKeyboardShortcut(_ binding: [UInt16]) {
        self.keyboardShortcut = binding
        Store.shared.set(key: "CombinedModules_popup_keyboardShortcut", value: binding)
    }
    
    @objc private func reinit() {
        self.hideDetails()
        self.subviews.forEach({ $0.removeFromSuperview() })
        
        let availableModules = self.modules.filter({ $0.enabled && $0.portal != nil }).sorted { $0.combinedPosition < $1.combinedPosition }
        self.displayedModules = availableModules
        var modulesHeight: CGFloat = 0
        availableModules.forEach { (m: Module) in
            if let p = m.portal {
                modulesHeight += p.height
                self.addArrangedSubview(p)
            }
        }
        
        let h = modulesHeight + (CGFloat(availableModules.count-1)*self.spacing)
        if h > 0 {
            self.setFrameSize(NSSize(width: self.frame.width, height: h))
            self.sizeCallback?(self.frame.size)
        }
    }
}
