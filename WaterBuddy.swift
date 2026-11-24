import Cocoa
import SceneKit

class WalkWindow: NSWindow {
    private var sceneView: SCNView!
    private var bubbleLabel: NSTextField!
    private var dropTimer: Timer?
    private var walkTimer: Timer?
    private var posX: CGFloat = -220
    private var posY: CGFloat = 0
    private let speed: CGFloat = 3
    private let screenW = NSScreen.main!.frame.width
    private let screenH = NSScreen.main!.frame.height
    var onDone: (() -> Void)?

    init() {
        super.init(
            contentRect: NSRect(x: -220, y: 0, width: 220, height: 300),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        isOpaque = false
        backgroundColor = NSColor.clear
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        hasShadow = false

        setupScene()
        setupBubble()
    }

    private func setupScene() {
        sceneView = SCNView(frame: NSRect(x: 0, y: 30, width: 220, height: 260))
        sceneView.backgroundColor = NSColor.clear
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.antialiasingMode = .multisampling4X
        sceneView.rendersContinuously = true
        sceneView.wantsLayer = true
        sceneView.layer?.backgroundColor = CGColor.clear

        let scene = SCNScene()
        sceneView.scene = scene

        // Lights
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 600
        ambient.light?.color = NSColor.white
        scene.rootNode.addChildNode(ambient)

        let omni = SCNNode()
        omni.light = SCNLight()
        omni.light?.type = .omni
        omni.light?.intensity = 2000
        omni.light?.color = NSColor.white
        omni.position = SCNVector3(0, 20, 20)
        scene.rootNode.addChildNode(omni)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .directional
        fill.light?.intensity = 800
        fill.eulerAngles = SCNVector3(0, Float.pi, 0)
        scene.rootNode.addChildNode(fill)

        // Load character
        let usdzPath = "/Users/srinivas/opt/waterbuddy_mac/character.usdz"
        guard let charScene = try? SCNScene(url: URL(fileURLWithPath: usdzPath), options: nil) else { return }

        let node = charScene.rootNode.clone()
        scene.rootNode.addChildNode(node)

        // Bounding box auto camera
        let (mn, mx) = node.boundingBox
        let cx = (mn.x + mx.x) / 2
        let cy = (mn.y + mx.y) / 2
        let sy = mx.y - mn.y

        let cam = SCNNode()
        cam.camera = SCNCamera()
        cam.position = SCNVector3(cx, cy, sy * 2.2)
        scene.rootNode.addChildNode(cam)

        // Play skeleton walk animation
        node.enumerateChildNodes { child, _ in
            for key in child.animationKeys {
                if let p = child.animationPlayer(forKey: key) {
                    p.animation.repeatCount = .infinity
                    p.speed = 1.0
                    p.play()
                }
            }
        }

        contentView?.addSubview(sceneView)
    }

    private func setupBubble() {
        bubbleLabel = NSTextField(labelWithString: "💧 Have you had water?")
        bubbleLabel.frame = NSRect(x: 5, y: 5, width: 210, height: 24)
        bubbleLabel.alignment = .center
        bubbleLabel.font = NSFont.boldSystemFont(ofSize: 11)
        bubbleLabel.textColor = NSColor.white
        bubbleLabel.backgroundColor = NSColor(red: 0.1, green: 0.45, blue: 1.0, alpha: 1)
        bubbleLabel.isBezeled = false
        bubbleLabel.isEditable = false
        bubbleLabel.wantsLayer = true
        bubbleLabel.layer?.cornerRadius = 8
        bubbleLabel.layer?.masksToBounds = true
        contentView?.addSubview(bubbleLabel)
    }

    func startAnimation() {
        posX = -220
        posY = screenH + 10
        setFrameOrigin(NSPoint(x: posX, y: posY))
        orderFrontRegardless()

        // Drop from top of screen
        dropTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] t in
            guard let self = self else { return }
            self.posY -= 14
            if self.posY <= 40 {
                self.posY = 40
                t.invalidate()
                self.walk()
            }
            self.setFrameOrigin(NSPoint(x: self.posX, y: self.posY))
        }
    }

    private func walk() {
        // Move window smoothly left to right — robot's own skeleton animates the legs
        walkTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] t in
            guard let self = self else { return }
            self.posX += self.speed
            self.setFrameOrigin(NSPoint(x: self.posX, y: self.posY))
            if self.posX > self.screenW + 10 {
                t.invalidate()
                self.orderOut(nil)
                self.onDone?()
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var snoozeTimer: Timer?
    var walkWindow: WalkWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        setupSleepWakeListener()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.triggerReminder()
        }
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.triggerReminder()
        }
    }

    func setupSleepWakeListener() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(screenWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(screenSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
    }

    @objc func screenSleep() {
        timer?.invalidate()
        walkWindow?.orderOut(nil)
    }

    @objc func screenWake() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.triggerReminder()
        }
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.title = "💧"
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Reminder", action: #selector(triggerReminder), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit WaterBuddy", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc func triggerReminder() {
        snoozeTimer?.invalidate()
        walkWindow = WalkWindow()
        walkWindow?.onDone = { [weak self] in
            DispatchQueue.main.async { self?.showAlert() }
        }
        walkWindow?.startAnimation()
    }

    func showAlert() {
        let alert = NSAlert()
        alert.messageText = "💧 Have you had water?"
        alert.informativeText = "Stay hydrated! Your body needs water."
        alert.addButton(withTitle: "Yes, I drank water ✅")
        alert.addButton(withTitle: "Remind me in 10 min ⏰")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertSecondButtonReturn {
            snoozeTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: false) { [weak self] _ in
                self?.triggerReminder()
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
