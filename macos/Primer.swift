import Cocoa
import WebKit

// Dirección de inicio de Prime Video. Es una sola constante a propósito: depende de la región
// y del canal de la cuenta (ver «Open Questions» en openspec/changes/add-macos-viewer/design.md).
let homeURL = URL(string: "https://www.primevideo.com/")!

final class App: NSObject, NSApplicationDelegate, WKUIDelegate {
    var window: NSWindow!
    var web: WKWebView!

    func applicationDidFinishLaunching(_ n: Notification) {
        NSApp.setActivationPolicy(.regular)

        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = .default()                       // sesión persistente
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.preferences.isElementFullscreenEnabled = true       // sin esto el botón de pantalla completa no aparece
        // Con la identificación predeterminada de WKWebView Prime Video respondió «Video no disponible»
        // (tarea 1.2, 2026-10-20) y Safari sí reproduce. Se añade el sufijo de Safari a la identificación
        // real del motor, que sigue siendo el WebKit del sistema. Versión: la de Safari de esta Mac.
        cfg.applicationNameForUserAgent = "Version/27.0 Safari/605.1.15"
        web = WKWebView(frame: .zero, configuration: cfg)
        web.uiDelegate = self
        web.allowsBackForwardNavigationGestures = true

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1280, height: 720),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Primer"
        window.contentView = web
        window.center()
        window.makeKeyAndOrderFront(nil)

        installMenu()
        NSApp.activate(ignoringOtherApps: true)
        web.load(URLRequest(url: homeURL))
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }

    // target=_blank y similares se abren en la misma vista
    func webView(_ w: WKWebView, createWebViewWith c: WKWebViewConfiguration, for a: WKNavigationAction, windowFeatures f: WKWindowFeatures) -> WKWebView? {
        if a.targetFrame == nil { w.load(a.request) }
        return nil
    }

    // Salir (⌘Q) y Edición (deshacer, cortar, copiar, pegar y seleccionar todo)
    func installMenu() {
        let main = NSMenu()

        let appTop = NSMenuItem(); main.addItem(appTop)
        let appMenu = NSMenu(title: "Primer"); appTop.submenu = appMenu
        appMenu.addItem(NSMenuItem(title: "Salir de Primer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        let editTop = NSMenuItem(); main.addItem(editTop)
        let edit = NSMenu(title: "Edición"); editTop.submenu = edit
        for (t, sel, key) in [("Deshacer", Selector(("undo:")), "z"), ("Cortar", #selector(NSText.cut(_:)), "x"),
                              ("Copiar", #selector(NSText.copy(_:)), "c"), ("Pegar", #selector(NSText.paste(_:)), "v"),
                              ("Seleccionar todo", #selector(NSText.selectAll(_:)), "a")] {
            edit.addItem(NSMenuItem(title: t, action: sel, keyEquivalent: key))
        }

        NSApp.mainMenu = main
    }
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.run()
