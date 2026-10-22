import AppKit
import WebKit
import Darwin

func logEvent(_ value: String) {
    print("[starwake] \(value)")
    fflush(stdout)
}

// One splash at a time, including when the manual launcher also triggers a launch event.
func acquireSplashLock() -> Int32? {
    let path = NSTemporaryDirectory() + "io.github.kizai.codex-starwake-splash-\(getuid()).lock"
    let descriptor = open(path, O_CREAT | O_RDWR | O_NOFOLLOW, S_IRUSR | S_IWUSR)
    guard descriptor >= 0 else { return nil }
    if flock(descriptor, LOCK_EX | LOCK_NB) != 0 { close(descriptor); return nil }
    return descriptor
}

final class StartupWatcher: NSObject, NSApplicationDelegate {
    var observer: NSObjectProtocol?
    var child: Process?
    var lastPID: pid_t?
    let arguments = CommandLine.arguments

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard arguments.count > 1 else { logEvent("missing web directory"); exit(64) }
        let center = NSWorkspace.shared.notificationCenter
        observer = center.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main) { [weak self] event in
            guard let process = event.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            self?.didLaunch(process)
        }
        logEvent("watcher-ready")
        // Verify the real event handler against a running Codex, without quitting it.
        if arguments.contains("--test-open") {
            guard let process = NSRunningApplication.runningApplications(withBundleIdentifier: "com.openai.codex").first else {
                logEvent("test-error: no running Codex"); exit(1)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                center.post(name: NSWorkspace.didLaunchApplicationNotification, object: nil,
                            userInfo: [NSWorkspace.applicationUserInfoKey: process])
            }
        }
    }

    func didLaunch(_ process: NSRunningApplication) {
        guard process.bundleIdentifier == "com.openai.codex", !process.isTerminated else { return }
        guard process.processIdentifier != lastPID, child?.isRunning != true else { return }
        lastPID = process.processIdentifier
        let splash = Process()
        splash.executableURL = URL(fileURLWithPath: arguments[0])
        splash.arguments = [arguments[1], "--overlay-pid", String(process.processIdentifier)]
        splash.terminationHandler = { [weak self] finished in
            logEvent("splash-exit=\(finished.terminationStatus)")
            if self?.arguments.contains("--test-open") == true {
                DispatchQueue.main.async { exit(finished.terminationStatus) }
            }
        }
        do {
            try splash.run()
            child = splash
            logEvent("launch-detected pid=\(process.processIdentifier)")
        } catch {
            lastPID = nil
            logEvent("splash-error: \(error.localizedDescription)")
            if arguments.contains("--test-open") { exit(1) }
        }
    }
}

final class SplashWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

// A separate splash window: the official application bundle is never modified.
final class Launcher: NSObject, NSApplicationDelegate, WKScriptMessageHandler, WKNavigationDelegate, NSWindowDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    var target: URL?
    var targetProcess: NSRunningApplication?
    var preparing = false
    var completed = false
    var launchError: Error?
    var lockDescriptor: Int32?
    var terminationObserver: NSObjectProtocol?
    let arguments = CommandLine.arguments
    var preview: Bool { arguments.contains("--preview") }
    var overlay: Bool { arguments.contains("--overlay-pid") }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard arguments.count > 1 else { showError("缺少动画目录。"); return }
        guard let descriptor = acquireSplashLock() else {
            logEvent("splash-already-playing"); NSApp.terminate(nil); return
        }
        lockDescriptor = descriptor
        let directory = URL(fileURLWithPath: arguments[1], isDirectory: true)
        if overlay {
            guard let index = arguments.firstIndex(of: "--overlay-pid"), index + 1 < arguments.count,
                  let pid = Int32(arguments[index + 1]), let process = NSRunningApplication(processIdentifier: pid),
                  process.bundleIdentifier == "com.openai.codex", !process.isTerminated else {
                logEvent("overlay-target-gone"); NSApp.terminate(nil); return
            }
            targetProcess = process
            preparing = true
            terminationObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main) { event in
                if let app = event.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                   app.processIdentifier == pid { NSApp.terminate(nil) }
            }
        } else if !preview {
            target = findCodex()
            guard target != nil else { showError("找不到 Codex（com.openai.codex）。请先安装应用，或使用预览入口查看动画。"); return }
        }
        let content = WKUserContentController()
        content.add(self, name: "launcher")
        let config = WKWebViewConfiguration()
        config.userContentController = content
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let width = min(1120, screen.width * 0.9, screen.height * 0.88 * 16 / 9)
        let size = NSSize(width: width, height: width * 9 / 16)
        window = SplashWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.backgroundColor = NSColor(calibratedRed: 2/255, green: 8/255, blue: 18/255, alpha: 1)
        window.isOpaque = true
        window.hasShadow = true
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = webView
        window.center()
        // Keep hidden until the artwork is decoded to avoid a white loading flash.
        webView.loadFileURL(directory.appendingPathComponent("index.html"), allowingReadAccessTo: directory)
        DispatchQueue.main.asyncAfter(deadline: .now() + 14) { [weak self] in
            guard let self = self, !self.completed else { return }
            logEvent("splash-timeout")
            if self.overlay || self.preview { exit(1) }
            self.finish()
        }
    }

    func findCodex() -> URL? {
        if let index = arguments.firstIndex(of: "--codex-app"), index + 1 < arguments.count {
            let url = URL(fileURLWithPath: arguments[index + 1])
            return Bundle(url: url)?.bundleIdentifier == "com.openai.codex" ? url : nil
        }
        let candidates = ["/Applications/ChatGPT.app", "/Applications/Codex.app",
                          NSHomeDirectory() + "/Applications/Codex.app", NSHomeDirectory() + "/Applications/ChatGPT.app"]
        for path in candidates {
            let url = URL(fileURLWithPath: path)
            if Bundle(url: url)?.bundleIdentifier == "com.openai.codex" { return url }
        }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.openai.codex")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let event = message.body as? String else { return }
        switch event {
        case "ready":
            logEvent("animation-ready")
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.9) { [weak self] in self?.prepareCodex() }
        case "finish": logEvent("animation-finished"); finish()
        case "error": showError("动画素材载入失败。请保留 index.html、style.css、animation.js 和 assets 文件夹在同一目录。");
        default: break
        }
    }

    func prepareCodex() {
        guard !preview, !preparing, let target = target else { return }
        preparing = true
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        configuration.createsNewApplicationInstance = false
        NSWorkspace.shared.openApplication(at: target, configuration: configuration) { [weak self] process, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.targetProcess = process
                self.launchError = error
                if self.completed { self.handoff() }
            }
        }
    }

    func finish() {
        guard !completed else { return }
        completed = true
        if preview { NSApp.terminate(nil); return }
        prepareCodex()
        // If Codex is still starting, retain the final dark frame until it responds.
        if targetProcess != nil || launchError != nil { handoff() }
    }

    func handoff() {
        if let error = launchError { showError("启动 Codex 失败：\(error.localizedDescription)"); return }
        targetProcess?.activate(options: [.activateAllWindows])
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            window.animator().alphaValue = 0
        }, completionHandler: { NSApp.terminate(nil) })
    }

    func showError(_ message: String) {
        completed = true
        if overlay { logEvent("animation-error: \(message)"); exit(1) }
        window?.orderOut(nil)
        let alert = NSAlert()
        alert.messageText = "Codex Starwake"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "好")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
        NSApp.terminate(nil)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError("无法打开动画：\(error.localizedDescription)")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

guard CommandLine.arguments.count > 1 else {
    print("Usage: Starwake <web-directory> [--preview | --watch | --overlay-pid PID | --codex-app PATH]")
    exit(64)
}
let application = NSApplication.shared
if CommandLine.arguments.contains("--watch") {
    let watcher = StartupWatcher()
    application.delegate = watcher
    application.setActivationPolicy(.prohibited)
    withExtendedLifetime(watcher) { application.run() }
} else {
    let launcher = Launcher()
    application.delegate = launcher
    application.setActivationPolicy(.accessory)
    withExtendedLifetime(launcher) { application.run() }
}
