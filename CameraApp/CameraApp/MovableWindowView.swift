//
//  MovableWindowView.swift
//  CameraApp
//
//  Created by Saldivar on 14/09/23.
//

import AppKit
class MovableWindowView: NSView {
    var initialLocation: NSPoint?

    override func mouseDown(with event: NSEvent) {
        self.initialLocation = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window = self.window, let initialLocation = initialLocation else {
            return
        }

        let currentLocation = event.locationInWindow
        let newOriginX = window.frame.origin.x + (currentLocation.x - initialLocation.x)
        let newOriginY = window.frame.origin.y + (currentLocation.y - initialLocation.y)

        window.setFrameOrigin(CGPoint(x: newOriginX, y: newOriginY))
    }
}
