//
//  Kit.swift
//  Tests
//
//  Created by Serhiy Mytrovtsiy on 04/07/2026.
//  Using Swift 6.0.
//  Running on macOS 26.5.
//
//  Copyright © 2026 Serhiy Mytrovtsiy. All rights reserved.
//

import XCTest
import Cocoa
@testable import Kit
@testable import Stats

class KitTests: XCTestCase {
    func testIsNewestVersion_release() throws {
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.11.0", latestVersion: "v2.11.0"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v2.11.0", latestVersion: "v2.11.1"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.11.1", latestVersion: "v2.11.0"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v2.11.0", latestVersion: "v2.12.0"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.12.0", latestVersion: "v2.11.5"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v2.11.0", latestVersion: "v3.0.0"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v3.0.0", latestVersion: "v2.99.99"))
    }
    
    func testIsNewestVersion_beta() throws {
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.11.0-beta1", latestVersion: "v2.11.0-beta1"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.11.0-beta2", latestVersion: "v2.11.0-beta1"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v2.11.0-beta1", latestVersion: "v2.11.0-beta2"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v2.11.0-beta1", latestVersion: "v2.11.0"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.11.0-beta1", latestVersion: "v2.10.9"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.11.0", latestVersion: "v2.11.1-beta1"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v2.11.0-beta1", latestVersion: "v2.11.1-beta1"))
    }
    
    func testIsNewestVersion_malformed() throws {
        XCTAssertFalse(isNewestVersion(currentVersion: "v3", latestVersion: "v3.0.0"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v3", latestVersion: "v3.0.1"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v3.0", latestVersion: "v3.0.0"))
        XCTAssertFalse(isNewestVersion(currentVersion: "", latestVersion: ""))
    }
    
    func testUnitsGetReadableSpeed_byte() throws {
        XCTAssertEqual(Units(bytes: 0).getReadableSpeed(base: .byte), "0 KB/s")
        XCTAssertEqual(Units(bytes: 999).getReadableSpeed(base: .byte), "0 KB/s")
        XCTAssertEqual(Units(bytes: 1_000).getReadableSpeed(base: .byte), "1 KB/s")
        XCTAssertEqual(Units(bytes: 500_000).getReadableSpeed(base: .byte), "500 KB/s")
        XCTAssertEqual(Units(bytes: 2_500_000).getReadableSpeed(base: .byte), "2.5 MB/s")
        XCTAssertEqual(Units(bytes: 150_000_000).getReadableSpeed(base: .byte), "150 MB/s")
        XCTAssertEqual(Units(bytes: 2_000_000_000).getReadableSpeed(base: .byte), "2.0 GB/s")
        XCTAssertEqual(Units(bytes: 2_000_000_000_000).getReadableSpeed(base: .byte), "2.0 TB/s")
        XCTAssertEqual(Units(bytes: -5).getReadableSpeed(base: .byte), "0 KB/s")
    }
    
    func testUnitsGetReadableSpeed_bit() throws {
        XCTAssertEqual(Units(bytes: 100).getReadableSpeed(base: .bit), "0 Kb/s")
        XCTAssertEqual(Units(bytes: 50_000).getReadableSpeed(base: .bit), "400 Kb/s")
        XCTAssertEqual(Units(bytes: 500_000).getReadableSpeed(base: .bit), "4.0 Mb/s")
        XCTAssertEqual(Units(bytes: 200_000_000).getReadableSpeed(base: .bit), "1.6 Gb/s")
        XCTAssertEqual(Units(bytes: 200_000_000_000).getReadableSpeed(base: .bit), "1.6 Tb/s")
    }
    
    func testUnitsGetReadableSpeed_fixedUnit() throws {
        XCTAssertEqual(Units(bytes: 500_000).getReadableSpeed(base: .byte, unit: "KB"), "500.00 KB/s")
        XCTAssertEqual(Units(bytes: 500_000).getReadableSpeed(base: .byte, unit: "MB"), "0.50 MB/s")
        XCTAssertEqual(Units(bytes: 500_000).getReadableSpeed(base: .bit, unit: "MB"), "4.00 Mb/s")
        XCTAssertEqual(Units(bytes: 1_250_000_000).getReadableSpeed(base: .byte, unit: "GB"), "1.25 GB/s")
        XCTAssertEqual(Units(bytes: 1_250_000_000_000).getReadableSpeed(base: .byte, unit: "TB"), "1.25 TB/s")
    }
    
    func testUnitsGetReadableSpeed_fixedUnitZero() throws {
        for unit in ["KB", "MB", "GB", "TB"] {
            for base in [DataSizeBase.byte, .bit] {
                XCTAssertEqual(Units(bytes: 0).getReadableSpeed(base: base, unit: unit, omitUnits: true), "0.00")
                XCTAssertEqual(Units(bytes: 1).getReadableSpeed(base: base, unit: unit, omitUnits: true), base == .bit && unit == "KB" ? "0.01" : "0.00")
            }
        }
    }
    
    func testUnitsGetReadableSpeed_fixedUnitPrecision() throws {
        XCTAssertEqual(Units(bytes: 4_900).getReadableSpeed(unit: "MB"), "0.00 MB/s")
        XCTAssertEqual(Units(bytes: 5_100).getReadableSpeed(unit: "MB"), "0.01 MB/s")
        XCTAssertEqual(Units(bytes: 10_000).getReadableSpeed(unit: "MB"), "0.01 MB/s")
        XCTAssertEqual(Units(bytes: 350_000).getReadableSpeed(unit: "MB"), "0.35 MB/s")
        XCTAssertEqual(Units(bytes: 1_260_000).getReadableSpeed(unit: "MB"), "1.26 MB/s")
        XCTAssertEqual(Units(bytes: 9_999_000).getReadableSpeed(unit: "MB"), "10.00 MB/s")
        XCTAssertEqual(Units(bytes: 12_340_000).getReadableSpeed(unit: "MB"), "12.34 MB/s")
        XCTAssertEqual(Units(bytes: 99_999_000).getReadableSpeed(unit: "MB"), "100.00 MB/s")
        XCTAssertEqual(Units(bytes: 123_450_000).getReadableSpeed(unit: "MB"), "123.45 MB/s")
        XCTAssertEqual(Units(bytes: 1_000_000_000).getReadableSpeed(unit: "KB"), "1000000.00 KB/s")
    }
}

class PopupWindowTests: XCTestCase {
    func testDetailsPreferLeftAndAlignWithSection() {
        let frame = PopupWindow.frame(
            beside: NSRect(x: 1000, y: 500, width: 280, height: 120),
            parent: NSRect(x: 990, y: 200, width: 300, height: 650),
            size: NSSize(width: 300, height: 400),
            screen: NSRect(x: 0, y: 0, width: 1440, height: 900)
        )
        XCTAssertEqual(frame.maxX, 984)
        XCTAssertEqual(frame.maxY, 620)
    }

    func testDetailsUseRightWhenLeftDoesNotFit() {
        let frame = PopupWindow.frame(
            beside: NSRect(x: 30, y: 500, width: 280, height: 120),
            parent: NSRect(x: 20, y: 200, width: 300, height: 650),
            size: NSSize(width: 300, height: 400),
            screen: NSRect(x: 0, y: 0, width: 1440, height: 900)
        )
        XCTAssertEqual(frame.minX, 326)
        XCTAssertEqual(frame.maxY, 620)
    }

    func testDetailsStayInsideSecondaryScreenNearBottom() {
        let screen = NSRect(x: -1440, y: -200, width: 1440, height: 900)
        let frame = PopupWindow.frame(
            beside: NSRect(x: -400, y: -180, width: 280, height: 120),
            parent: NSRect(x: -410, y: -190, width: 300, height: 650),
            size: NSSize(width: 300, height: 500),
            screen: screen
        )
        XCTAssertTrue(screen.contains(frame))
        XCTAssertEqual(frame.minY, screen.minY)
        XCTAssertEqual(frame.maxX, -416)
    }

    func testDetailsStayInsideScreenWhenNeitherSideFits() {
        let screen = NSRect(x: 0, y: 0, width: 600, height: 700)
        let frame = PopupWindow.frame(
            beside: NSRect(x: 200, y: 600, width: 280, height: 120),
            parent: NSRect(x: 190, y: 20, width: 300, height: 650),
            size: NSSize(width: 300, height: 500),
            screen: screen
        )
        XCTAssertTrue(screen.contains(frame))
    }

    @MainActor func testAttachedDetailsKeepParentOpenAndCloseWithIt() {
        let summary = PopupWrapper(.combined, frame: NSRect(x: 0, y: 0, width: 280, height: 300))
        let parent = PopupWindow(title: "Combined test", module: .combined, view: summary) { _ in }
        let detail = PopupWrapper(.CPU, frame: NSRect(x: 0, y: 0, width: 280, height: 200))
        var detailVisibility: [Bool] = []
        let child = PopupWindow(title: "CPU test", module: .CPU, view: detail) { detailVisibility.append($0) }
        defer {
            child.setIsVisible(false)
            parent.setIsVisible(false)
        }
        parent.setFrameOrigin(NSPoint(x: 600, y: 200))
        NSApp.activate(ignoringOtherApps: true)
        parent.makeKeyAndOrderFront(nil)
        child.show(beside: summary)
        child.makeKey()

        let focusSettled = expectation(description: "Window focus settles")
        DispatchQueue.main.async { focusSettled.fulfill() }
        wait(for: [focusSettled], timeout: 1)

        XCTAssertTrue(parent.isVisible)
        XCTAssertTrue(child.isVisible)
        XCTAssertTrue(child.parent === parent)

        parent.setIsVisible(false)
        XCTAssertFalse(child.isVisible)
        XCTAssertNil(child.parent)
        XCTAssertEqual(detailVisibility, [true, false])

        parent.setIsVisible(true)
        child.show(beside: summary)
        XCTAssertTrue(child.isVisible)
        XCTAssertTrue(child.parent === parent)
        XCTAssertEqual(detailVisibility, [true, false, true])
    }
}

@MainActor class CombinedPopupTests: XCTestCase {
    private func settleHover(for interval: TimeInterval = 0.3) {
        let settled = expectation(description: "Hover delay elapses")
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { settled.fulfill() }
        wait(for: [settled], timeout: 2)
    }

    private func moveMouse(to point: NSPoint, in window: NSWindow) throws {
        let event = try XCTUnwrap(NSEvent.mouseEvent(
            with: .mouseMoved,
            location: window.convertPoint(fromScreen: point),
            modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 0,
            pressure: 0
        ))
        NSApp.postEvent(event, atStart: false)
    }

    private func hover(_ module: Module, in window: NSWindow) throws {
        let portal = try XCTUnwrap(module.portal)
        let rect = window.convertToScreen(portal.convert(portal.bounds.intersection(portal.visibleRect), to: nil))
        XCTAssertFalse(rect.isEmpty)
        try self.moveMouse(to: NSPoint(x: rect.midX, y: rect.midY), in: window)
    }

    func testHoverSwitchesDetailsAndAllowsMovingBetweenWindows() throws {
        let cpu = try XCTUnwrap(modules.first { $0.name == "CPU" && $0.available })
        let ram = try XCTUnwrap(modules.first { $0.name == "RAM" && $0.available })
        let enabledStates = [cpu.enabled, ram.enabled]
        cpu.enabled = true
        ram.enabled = true
        NotificationCenter.default.post(name: .toggleModule, object: nil)
        defer {
            cpu.enabled = enabledStates[0]
            ram.enabled = enabledStates[1]
            NotificationCenter.default.post(name: .toggleModule, object: nil)
        }
        let parent = try XCTUnwrap(cpu.portal?.window as? PopupWindow)
        defer { parent.setIsVisible(false) }
        parent.setFrameOrigin(NSPoint(x: 700, y: 0))
        NSApp.activate(ignoringOtherApps: true)
        parent.makeKeyAndOrderFront(nil)
        parent.contentView?.layoutSubtreeIfNeeded()
        self.settleHover(for: 0.02)
        let cpuPortal = try XCTUnwrap(cpu.portal)
        let ramPortal = try XCTUnwrap(ram.portal)

        try self.hover(cpu, in: parent)
        XCTAssertTrue(parent.childWindows?.isEmpty ?? true)
        self.settleHover()
        let cpuPopup = try XCTUnwrap(parent.childWindows?.first as? PopupWindow)
        XCTAssertEqual(cpuPopup.title, "CPU")
        XCTAssertTrue(parent.isVisible)

        try self.moveMouse(to: NSPoint(x: cpuPopup.frame.midX, y: cpuPopup.frame.midY), in: cpuPopup)
        self.settleHover()
        XCTAssertTrue(cpuPopup.isVisible)
        XCTAssertTrue(parent.isVisible)

        try self.hover(ram, in: parent)
        self.settleHover()
        XCTAssertFalse(cpuPopup.isVisible)
        let ramPopup = try XCTUnwrap(parent.childWindows?.first as? PopupWindow)
        XCTAssertEqual(ramPopup.title, "RAM")
        XCTAssertEqual(parent.childWindows?.count, 1)
        XCTAssertEqual(cpuPortal.layer?.borderWidth ?? 0, 0)
        XCTAssertEqual(ramPortal.layer?.borderWidth, 1)

        try self.moveMouse(to: NSPoint(x: -10000, y: -10000), in: parent)
        XCTAssertTrue(ramPopup.isVisible)
        self.settleHover()
        XCTAssertFalse(ramPopup.isVisible)
        XCTAssertTrue(parent.isVisible)
        XCTAssertEqual(ramPortal.layer?.borderWidth ?? 0, 0)

        try self.hover(cpu, in: parent)
        try self.moveMouse(to: NSPoint(x: -10000, y: -10000), in: parent)
        self.settleHover()
        XCTAssertTrue(parent.childWindows?.isEmpty ?? true)

        try self.hover(cpu, in: parent)
        self.settleHover(for: 0.02)
        parent.setIsVisible(false)
        self.settleHover()
        XCTAssertTrue(parent.childWindows?.isEmpty ?? true)
        XCTAssertFalse(cpuPopup.isVisible)

        parent.makeKeyAndOrderFront(nil)
        self.settleHover(for: 0.02)
        try self.hover(cpu, in: parent)
        self.settleHover()
        let escape = try XCTUnwrap(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: parent.windowNumber,
            context: nil, characters: "\u{1b}", charactersIgnoringModifiers: "\u{1b}", isARepeat: false, keyCode: 53
        ))
        NSApp.postEvent(escape, atStart: false)
        self.settleHover(for: 0.02)
        XCTAssertFalse(parent.isVisible)
        XCTAssertFalse(cpuPopup.isVisible)

        parent.makeKeyAndOrderFront(nil)
        self.settleHover(for: 0.02)
        try self.hover(ram, in: parent)
        self.settleHover()
        let outsideClick = try XCTUnwrap(NSEvent.mouseEvent(
            with: .leftMouseDown, location: NSPoint(x: -100, y: -100), modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: parent.windowNumber,
            context: nil, eventNumber: 0, clickCount: 1, pressure: 1
        ))
        NSApp.postEvent(outsideClick, atStart: false)
        self.settleHover(for: 0.02)
        XCTAssertFalse(parent.isVisible)
        XCTAssertFalse(ramPopup.isVisible)
    }
}
