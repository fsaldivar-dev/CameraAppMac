//
//  ViewController.swift
//  CameraApp
//
//  Created by Saldivar on 14/09/23.
//

import Cocoa

final class ViewController: NSViewController {
    private var cameraManager: CameraManagerProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            view.wantsLayer = true
            cameraManager = try CameraManager(containerView: view)
            cameraManager.delegate = self
        } catch {
            // Cath the error here
            print(error.localizedDescription)
        }
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        do {
            try cameraManager.startSession()
            configureWindow()
        } catch {
            // Cath the error here
            print(error.localizedDescription)
        }
    }
    
    func configureWindow() {
        // Hace que la ventana siempre esté en primer plano
        self.view.window?.level = .statusBar
        
        // Hace que la ventana aparezca en todos los espacios
        self.view.window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Establece un tamaño fijo y mantiene una relación de aspecto 1:1
        let windowSize = CGSize(width: 200, height: 200) // Por ejemplo, 200x200
        self.view.window?.setContentSize(windowSize)
        self.view.window?.minSize = windowSize
        //self.view.window?.maxSize = windowSize
        self.view.window?.aspectRatio = windowSize
        
        // Darle forma circular y añadir un borde blanco
        self.view.window?.isOpaque = false
        self.view.window?.backgroundColor = NSColor.clear
        self.view.window?.contentView?.wantsLayer = true
        self.view.window?.contentView?.layer?.cornerRadius = windowSize.width / 2
        self.view.window?.contentView?.layer?.masksToBounds = true
        self.view.window?.contentView?.layer?.borderWidth = 2 // Tamaño del borde
        self.view.window?.contentView?.layer?.borderColor = NSColor.white.cgColor
    }
    
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        do {
            try cameraManager.stopSession()
            self.view.window?.level = .normal
        } catch {
            // Cath the error here
            print(error.localizedDescription)
        }
    }
}

extension ViewController: CameraManagerDelegate {
    func cameraManager(_ output: CameraCaptureOutput,
                       didOutput sampleBuffer: CameraSampleBuffer,
                       from connection: CameraCaptureConnection) {
        
    }
}
