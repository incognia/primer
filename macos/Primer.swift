import Cocoa
import WebKit

// Autoprueba, sin cuenta ni red y sin abrir Prime Video:
//   Primer.app/Contents/MacOS/Primer --selftest     (imprime una línea por comprobación; código 0 si todas pasan)
// Variable opcional: PRIMER_FIXTURES=<carpeta> para usar otras páginas de prueba que shared/fixtures/.

// Dirección de inicio de Prime Video. Es una sola constante a propósito: depende de la región
// y del canal de la cuenta (ver «Open Questions» en openspec/changes/add-macos-viewer/design.md).
let homeURL = URL(string: "https://www.primevideo.com/")!

// Franja invisible superior de 14 px: arrastrar desde aquí mueve la ventana; doble clic alterna maximizar
final class DragStrip: NSView {
    static let height: CGFloat = 14
    override func mouseDown(with e: NSEvent) { window?.performDrag(with: e) }
    override func mouseUp(with e: NSEvent) { if e.clickCount == 2 { window?.zoom(nil) } }
}

// Ventana sin barra de título visible; ⌥ Option + arrastrar desde cualquier punto la mueve
final class Win: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    override func sendEvent(_ e: NSEvent) {
        if e.type == .leftMouseDown, e.modifierFlags.contains(.option) { performDrag(with: e); return }
        super.sendEvent(e)
    }
}

// Ventana sin bordes. La proporción se fija sobre el MARCO y no sobre el contenido: el contenido ocupa todo el marco
// (la barra de título es transparente), así que el área del video queda exactamente 16:9 y no sobran bandas negras.
@MainActor
func makeChromeWindow(content: NSView) -> Win {
    let win = Win(contentRect: NSRect(x: 0, y: 0, width: 1280, height: 720),
                  styleMask: [.titled, .fullSizeContentView, .resizable, .miniaturizable, .closable],
                  backing: .buffered, defer: false)
    let container = NSView(frame: NSRect(x: 0, y: 0, width: 1280, height: 720))
    content.frame = container.bounds
    content.autoresizingMask = [.width, .height]
    container.addSubview(content)
    let strip = DragStrip(frame: NSRect(x: 0, y: container.bounds.height - DragStrip.height, width: container.bounds.width, height: DragStrip.height))
    strip.autoresizingMask = [.width, .minYMargin]
    container.addSubview(strip)
    win.contentView = container
    win.titlebarAppearsTransparent = true
    win.titleVisibility = .hidden
    [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton].forEach { win.standardWindowButton($0)?.isHidden = true }
    win.appearance = NSAppearance(named: .darkAqua)
    win.backgroundColor = .black
    win.hasShadow = true
    win.aspectRatio = NSSize(width: 16, height: 9)
    win.center()
    return win
}

// Rectángulo más grande que cabe en el área útil con la proporción dada, centrado en ella
func fillAndCenterRect(aspect: NSSize, in area: NSRect) -> NSRect {
    let w = min(area.width, area.height * aspect.width / aspect.height)
    let h = w * aspect.height / aspect.width
    return NSRect(x: area.midX - w / 2, y: area.midY - h / 2, width: w, height: h)
}

// Alterna que la ventana quede por encima de las demás
@MainActor
func toggleAlwaysOnTop(_ w: NSWindow) { w.level = w.level == .floating ? .normal : .floating }

// Guardián de audio de cada panel. Si el panel debe estar silenciado y el reproductor reactiva su sonido, lo vuelve a silenciar
// en el acto (evento volumechange) y, por si acaso, cada 500 ms. Solo desilencia los medios que ÉL silenció: un silencio puesto a
// mano desde el reproductor no se revierte. Solo actúa en el marco principal de la página.
let audioGuardScript = """
(() => {
  if (window.__primerAudio) return;
  const state = { muted: false, reapplied: 0 };
  const media = () => [...document.querySelectorAll('video,audio')];
  const enforce = (m) => { if (state.muted && !m.muted) { m.__primerForced = true; m.muted = true; state.reapplied++; } };
  window.__primerAudio = {
    setMuted(on) {
      state.muted = !!on;
      if (on) media().forEach(enforce);
      else media().forEach(m => { if (m.__primerForced) { m.__primerForced = false; m.muted = false; } });
    },
    reapplied: () => state.reapplied,
    isMuted: () => state.muted
  };
  const onEvent = (e) => { const t = e.target; if (t && (t.tagName === 'VIDEO' || t.tagName === 'AUDIO')) enforce(t); };
  ['volumechange', 'play', 'playing'].forEach(n => document.addEventListener(n, onEvent, true));
  setInterval(() => media().forEach(enforce), 500);
})();
"""

// Configuración de un panel. Con persistent = false no toca la sesión (autoprueba).
@MainActor
func makePaneConfiguration(persistent: Bool) -> WKWebViewConfiguration {
    let cfg = WKWebViewConfiguration()
    cfg.websiteDataStore = persistent ? .default() : .nonPersistent()   // sesión persistente, compartida entre paneles e instancias
    cfg.mediaTypesRequiringUserActionForPlayback = []
    cfg.preferences.isElementFullscreenEnabled = true       // sin esto el botón de pantalla completa no aparece
    // Con la identificación predeterminada de WKWebView Prime Video respondió «Video no disponible»
    // (tarea 1.2, 2026-10-20) y Safari sí reproduce. Se añade el sufijo de Safari a la identificación
    // real del motor, que sigue siendo el WebKit del sistema. Versión: la de Safari de esta Mac.
    cfg.applicationNameForUserAgent = "Version/27.0 Safari/605.1.15"
    cfg.userContentController.addUserScript(WKUserScript(source: audioGuardScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
    return cfg
}

// Un panel: un WKWebView que avisa cuando se hace clic en él y que mantiene su silencio al cargar páginas nuevas
final class Pane: WKWebView, WKNavigationDelegate {
    var onFocus: (() -> Void)?
    var onFinish: (() -> Void)?
    var wantsMuted = false { didSet { pushMute() } }

    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        navigationDelegate = self
    }
    required init?(coder: NSCoder) { fatalError("no se usa") }

    func pushMute() { evaluateJavaScript("window.__primerAudio && window.__primerAudio.setMuted(\(wantsMuted))", completionHandler: nil) }

    // El clic que da el foco no llega a la página: el reproductor de Prime pausa con un clic en cualquier parte del video.
    // Se descartan también el soltado y los arrastres de ese mismo clic, para que la página no reciba medio clic.
    var isFocused: () -> Bool = { true }
    private var swallowingClick = false

    override func mouseDown(with e: NSEvent) {
        if !isFocused() { swallowingClick = true; onFocus?(); return }
        swallowingClick = false
        super.mouseDown(with: e)
    }
    override func mouseUp(with e: NSEvent) {
        if swallowingClick { swallowingClick = false; return }
        super.mouseUp(with: e)
    }
    override func mouseDragged(with e: NSEvent) {
        if swallowingClick { return }
        super.mouseDragged(with: e)
    }

    // El estado del guardián vive en cada documento: al cargar una página nueva hay que volver a indicárselo
    func webView(_ w: WKWebView, didCommit n: WKNavigation!) { pushMute() }
    func webView(_ w: WKWebView, didFinish n: WKNavigation!) { pushMute(); onFinish?() }
}

// Uno o dos paneles de 16:9. Con uno, el panel llena la ventana. Con dos, quedan lado a lado con 8 px de hueco DENTRO del ancho
// de la ventana, y cada uno mide (ancho − 8) / 2 por esa cantidad × 9 / 16. El segundo panel existe solo mientras se pide.
final class PaneGrid: NSView {
    static let gap: CGFloat = 8
    let factory: () -> NSView
    private(set) var panes: [NSView] = []

    init(factory: @escaping () -> NSView) {
        self.factory = factory
        super.init(frame: .zero)
        addPane()
    }
    required init?(coder: NSCoder) { fatalError("no se usa") }

    var count: Int { panes.count }

    private(set) var focused = 0

    func addPane() {
        let p = factory()
        panes.append(p)
        addSubview(p)
        if let pane = p as? Pane {
            pane.onFocus = { [weak self, weak pane] in
                guard let self, let pane, let i = self.panes.firstIndex(of: pane) else { return }
                self.setFocus(i)
            }
            // Con un solo panel todos los clics llegan; con dos, solo los del panel con foco
            pane.isFocused = { [weak self, weak pane] in
                guard let self, let pane else { return true }
                return self.panes.count < 2 || self.panes[self.focused] === pane
            }
        }
        applyAudio()
    }

    // El segundo panel se detiene, sale de la ventana y se libera por completo
    func removeLastPane() {
        guard panes.count > 1 else { return }
        let p = panes.removeLast()
        (p as? WKWebView)?.stopLoading()
        p.removeFromSuperview()
        if focused >= panes.count { focused = 0 }
        applyAudio()
    }

    // Solo suena el panel con foco; con un solo panel no se silencia nada
    func setFocus(_ i: Int) {
        guard panes.indices.contains(i) else { return }
        focused = i
        window?.makeFirstResponder(panes[i])
        applyAudio()
    }
    func nextPane() { setFocus((focused + 1) % panes.count) }
    func applyAudio() {
        for (i, p) in panes.enumerated() { (p as? Pane)?.wantsMuted = panes.count > 1 && i != focused }
    }

    // La dirección se abre solo en el panel con foco
    func openAddress(_ url: URL) { (panes[focused] as? Pane)?.load(URLRequest(url: url)) }

    override func setFrameSize(_ s: NSSize) {
        super.setFrameSize(s)
        layoutPanes()
    }

    func layoutPanes() {
        if panes.count == 1 { panes[0].frame = bounds; return }
        let pw = (bounds.width - PaneGrid.gap) / 2, ph = pw * 9 / 16
        let y = (bounds.height - ph) / 2
        panes[0].frame = NSRect(x: 0, y: y, width: pw, height: ph)
        panes[1].frame = NSRect(x: pw + PaneGrid.gap, y: y, width: pw, height: ph)
    }
}

// Proporción de la ventana: 16:9 con un panel y 32:9 con dos (dos paneles de 16:9 lado a lado)
func windowAspect(forPanes n: Int) -> NSSize { NSSize(width: 16 * CGFloat(n), height: 9) }

// Marco de la ventana al pasar a n paneles. Con dos, mide el doble más el hueco, de modo que el panel que ya estaba abierto
// conserva su tamaño y no se refresca (cambiar el tamaño de la ventana rehace el reproductor); se limita al ancho de la pantalla.
// Al volver a uno mide lo que medía cada panel. Conserva la esquina superior izquierda.
func windowFrame(forPanes n: Int, from old: NSRect, maxWidth: CGFloat) -> NSRect {
    let w: CGFloat = n == 2 ? min(old.width * 2 + PaneGrid.gap, maxWidth) : max((old.width - PaneGrid.gap) / 2, 320)
    let h = w * 9 / (16 * CGFloat(n))
    return NSRect(x: old.minX, y: old.maxY - h, width: w, height: h)
}

final class App: NSObject, NSApplicationDelegate, WKUIDelegate {
    var window: NSWindow!
    var grid: PaneGrid!
    var selfTest: SelfTest?

    // Cada panel es un contexto web independiente; todos comparten la sesión (almacén de datos predeterminado)
    func makePane() -> Pane {
        let p = Pane(frame: .zero, configuration: makePaneConfiguration(persistent: true))
        p.uiDelegate = self
        p.allowsBackForwardNavigationGestures = true
        p.load(URLRequest(url: homeURL))
        return p
    }

    // Uno o dos paneles: primero se crea o se quita el panel y luego cambia la ventana, para que el primer panel no cambie de tamaño
    func setPanes(_ n: Int) {
        guard n == 1 || n == 2, n != grid.count else { return }
        let maxW = (window.screen ?? NSScreen.main)?.visibleFrame.width ?? window.frame.width
        let target = windowFrame(forPanes: n, from: window.frame, maxWidth: maxW)
        if n == 2 { grid.addPane() } else { grid.removeLastPane() }
        window.aspectRatio = windowAspect(forPanes: n)
        window.setFrame(target, display: true, animate: false)
    }
    @objc func onePane() { setPanes(1) }
    @objc func twoPanes() { setPanes(2) }
    @objc func nextPane() { grid.nextPane() }

    // Abrir una dirección en el panel con foco (⌘L)
    @objc func openAddress() {
        let alert = NSAlert()
        alert.messageText = "Abrir dirección en el panel con foco"
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 420, height: 24))
        alert.accessoryView = field
        alert.addButton(withTitle: "Abrir")
        alert.addButton(withTitle: "Cancelar")
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        var text = field.stringValue.trimmingCharacters(in: .whitespaces)
        if !text.contains("://") { text = "https://" + text }
        if let url = URL(string: text), url.host != nil { grid.openAddress(url) }
    }

    func applicationDidFinishLaunching(_ n: Notification) {
        if CommandLine.arguments.contains("--selftest") { startSelfTest(); return }
        NSApp.setActivationPolicy(.regular)

        grid = PaneGrid(factory: { [unowned self] in self.makePane() })
        window = makeChromeWindow(content: grid)
        window.makeKeyAndOrderFront(nil)

        installMenu()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }

    func startSelfTest() {
        NSApp.setActivationPolicy(.accessory)   // sin ícono en el Dock
        // Si algo se cuelga, la autoprueba falla en lugar de quedarse abierta
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            print("[FAIL] tiempo agotado (60 s)"); fflush(stdout); exit(1)
        }
        let test = SelfTest(fixtures: SelfTest.fixturesDirectory())
        selfTest = test
        Task { @MainActor in await test.run() }
    }

    // target=_blank y similares se abren en la misma vista
    func webView(_ w: WKWebView, createWebViewWith c: WKWebViewConfiguration, for a: WKNavigationAction, windowFeatures f: WKWindowFeatures) -> WKWebView? {
        if a.targetFrame == nil { w.load(a.request) }
        return nil
    }

    // Rellenar y centrar: la ventana más grande que cabe en el área útil de su pantalla, con su proporción actual
    @objc func fillCenter() {
        let area = (window.screen ?? NSScreen.main)?.visibleFrame ?? window.frame
        window.setFrame(fillAndCenterRect(aspect: window.aspectRatio, in: area), display: true, animate: true)
    }

    @objc func toggleFloat() { toggleAlwaysOnTop(window) }

    // Salir (⌘Q), Ventana (⌘F y ⌘T) y Edición (deshacer, cortar, copiar, pegar y seleccionar todo)
    func installMenu() {
        let main = NSMenu()

        let appTop = NSMenuItem(); main.addItem(appTop)
        let appMenu = NSMenu(title: "Primer"); appTop.submenu = appMenu
        appMenu.addItem(NSMenuItem(title: "Salir de Primer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        let winTop = NSMenuItem(); main.addItem(winTop)
        let winMenu = NSMenu(title: "Ventana"); winTop.submenu = winMenu
        for (t, sel, key) in [("Rellenar y centrar", #selector(fillCenter), "f"), ("Siempre encima", #selector(toggleFloat), "t")] {
            let it = NSMenuItem(title: t, action: sel, keyEquivalent: key)
            it.target = self
            winMenu.addItem(it)
        }

        let panesTop = NSMenuItem(); main.addItem(panesTop)
        let panesMenu = NSMenu(title: "Paneles"); panesTop.submenu = panesMenu
        for (t, sel, key) in [("1 panel", #selector(onePane), "1"), ("2 paneles", #selector(twoPanes), "2"),
                              ("Siguiente panel", #selector(nextPane), "`"), ("Abrir dirección…", #selector(openAddress), "l")] {
            let it = NSMenuItem(title: t, action: sel, keyEquivalent: key)
            it.target = self
            panesMenu.addItem(it)
        }

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

enum SelfTestError: Error { case missing(String) }

// Carga páginas locales en un WKWebView no persistente (no toca la sesión) y comprueba lo que hoy existe.
// Las comprobaciones de ventana, paneles y audio por foco llegan con las tareas 3.1, 3.3, 4.1 y 4.3.
@MainActor
final class SelfTest: NSObject, WKNavigationDelegate {
    let fixtures: URL
    var web: WKWebView!
    var window: NSWindow!
    var pageLoaded: CheckedContinuation<Void, Error>?
    var passed = 0, failed = 0

    init(fixtures: URL) {
        self.fixtures = fixtures
        super.init()
        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = .nonPersistent()
        cfg.mediaTypesRequiringUserActionForPlayback = []
        web = WKWebView(frame: NSRect(x: 0, y: 0, width: 480, height: 360), configuration: cfg)
        web.navigationDelegate = self
        // Ventana invisible pero «visible» para el sistema: así la página no se considera oculta y sus temporizadores corren
        window = NSWindow(contentRect: web.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.alphaValue = 0
        window.ignoresMouseEvents = true
        window.contentView = web
        window.orderFrontRegardless()
    }

    // macos/Primer.app → macos → raíz del repositorio → shared/fixtures
    static func fixturesDirectory() -> URL {
        if let env = ProcessInfo.processInfo.environment["PRIMER_FIXTURES"] { return URL(fileURLWithPath: env, isDirectory: true) }
        return Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("shared/fixtures", isDirectory: true)
    }

    func check(_ name: String, _ ok: Bool, _ detail: String = "") {
        if ok { passed += 1; print("[PASS] \(name)") }
        else { failed += 1; print("[FAIL] \(name)\(detail.isEmpty ? "" : ": \(detail)")") }
        fflush(stdout)
    }

    func load(_ file: String) async throws {
        let url = fixtures.appendingPathComponent(file)
        guard FileManager.default.fileExists(atPath: url.path) else { throw SelfTestError.missing(url.path) }
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            pageLoaded = c
            web.loadFileURL(url, allowingReadAccessTo: fixtures)
        }
    }

    func webView(_ w: WKWebView, didFinish n: WKNavigation!) { pageLoaded?.resume(); pageLoaded = nil }
    func webView(_ w: WKWebView, didFail n: WKNavigation!, withError e: Error) { pageLoaded?.resume(throwing: e); pageLoaded = nil }
    func webView(_ w: WKWebView, didFailProvisionalNavigation n: WKNavigation!, withError e: Error) { pageLoaded?.resume(throwing: e); pageLoaded = nil }

    // Se evalúa siempre una expresión convertida a texto, para no depender del tipo de resultado de JavaScript
    func js(_ expr: String) async -> String {
        let code = "(() => { try { return String(\(expr)); } catch (e) { return 'error: ' + e; } })()"
        do { return (try await web.evaluateJavaScript(code) as? String) ?? "" } catch { return "error: \(error)" }
    }

    // Ventana sin bordes y proporción fija (tarea 3.1). Se usa la misma función que crea la ventana real.
    func checkWindow() {
        let content = NSView()
        let w = makeChromeWindow(content: content)
        let buttons: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
        check("ventana: sin título ni botones visibles",
              w.titleVisibility == .hidden && w.titlebarAppearsTransparent && buttons.allSatisfy { w.standardWindowButton($0)?.isHidden == true })
        let cv = w.contentView!
        let strip = cv.subviews.compactMap { $0 as? DragStrip }.first
        check("ventana: franja de arrastre de 14 px en el borde superior",
              strip != nil && strip!.frame.height == 14 && abs(strip!.frame.maxY - cv.bounds.maxY) < 0.5 && strip!.frame.width == cv.bounds.width)
        check("ventana: se puede redimensionar desde los bordes", w.styleMask.contains(.resizable))
        check("ventana: proporción fija 16:9", abs(w.aspectRatio.width / w.aspectRatio.height - 16.0 / 9.0) < 0.0001,
              "aspectRatio = \(w.aspectRatio.width):\(w.aspectRatio.height)")
        // El área del video es todo el contenido: si no mide 16:9, el reproductor deja bandas negras
        for width in [640.0, 1280.0, 1920.0] {
            w.setFrame(NSRect(x: 0, y: 0, width: width, height: width * 9 / 16), display: false)
            let ratio = cv.bounds.width / cv.bounds.height
            check("ventana: con \(Int(width)) px de ancho el contenido mide 16:9", abs(ratio - 16.0 / 9.0) < 0.005,
                  "contenido \(Int(cv.bounds.width))×\(Int(cv.bounds.height)), proporción \(String(format: "%.4f", ratio))")
        }
        check("ventana: el contenido llena la ventana", content.frame == cv.bounds, "\(content.frame) frente a \(cv.bounds)")
    }

    // Rellenar y centrar y siempre encima (tarea 3.3)
    func checkFillCenterAndLevel() {
        let aspect = NSSize(width: 16, height: 9)
        // Pantalla más ancha que la proporción: todo el alto útil, centrada horizontalmente
        let wide = NSRect(x: 100, y: 25, width: 3440, height: 1415)
        let a = fillAndCenterRect(aspect: aspect, in: wide)
        check("rellenar: pantalla más ancha ocupa todo el alto útil", abs(a.height - wide.height) < 0.01, "alto \(a.height) frente a \(wide.height)")
        check("rellenar: pantalla más ancha conserva 16:9", abs(a.width / a.height - 16.0 / 9.0) < 0.0001)
        check("rellenar: pantalla más ancha queda centrada horizontalmente", abs(a.midX - wide.midX) < 0.01 && abs(a.midY - wide.midY) < 0.01)
        // Pantalla más alta que la proporción: todo el ancho útil, centrada verticalmente
        let tall = NSRect(x: 0, y: 0, width: 1080, height: 1920)
        let b = fillAndCenterRect(aspect: aspect, in: tall)
        check("rellenar: pantalla más alta ocupa todo el ancho útil", abs(b.width - tall.width) < 0.01, "ancho \(b.width) frente a \(tall.width)")
        check("rellenar: pantalla más alta conserva 16:9", abs(b.width / b.height - 16.0 / 9.0) < 0.0001)
        check("rellenar: pantalla más alta queda centrada verticalmente", abs(b.midX - tall.midX) < 0.01 && abs(b.midY - tall.midY) < 0.01)
        // Con 32:9 (dos paneles) el mismo cálculo llena una pantalla ultraancha
        let ultra = fillAndCenterRect(aspect: NSSize(width: 32, height: 9), in: wide)
        check("rellenar: con 32:9 conserva la proporción dentro del área", abs(ultra.width / ultra.height - 32.0 / 9.0) < 0.0001 && ultra.width <= wide.width + 0.01 && ultra.height <= wide.height + 0.01)
        // Siempre encima: dos veces seguidas vuelve al nivel normal
        let w = makeChromeWindow(content: NSView())
        let inicial = w.level
        toggleAlwaysOnTop(w); let encima = w.level
        toggleAlwaysOnTop(w); let final = w.level
        check("siempre encima: activar lo deja por encima y desactivar lo regresa a su nivel", encima == .floating && final == inicial && inicial == .normal,
              "niveles: \(inicial.rawValue) → \(encima.rawValue) → \(final.rawValue)")
    }

    // Carga una página de prueba en un panel y espera a que termine
    func load(_ pane: Pane, _ file: String) async throws {
        let url = fixtures.appendingPathComponent(file)
        guard FileManager.default.fileExists(atPath: url.path) else { throw SelfTestError.missing(url.path) }
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            pane.onFinish = { pane.onFinish = nil; c.resume() }
            pane.loadFileURL(url, allowingReadAccessTo: fixtures)
        }
    }

    func paneJS(_ pane: Pane, _ expr: String) async -> String {
        let code = "(() => { try { return String(\(expr)); } catch (e) { return 'error: ' + e; } })()"
        do { return (try await pane.evaluateJavaScript(code) as? String) ?? "" } catch { return "error: \(error)" }
    }

    func settle(_ seconds: Double = 0.4) async { try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000)) }

    // Audio por foco, cambio de panel y abrir una dirección (tarea 4.3), con paneles reales de la misma clase que usa la app
    func checkAudio() async {
        let grid = PaneGrid(factory: { Pane(frame: .zero, configuration: makePaneConfiguration(persistent: false)) })
        grid.addPane()
        let host = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1284, height: 722), styleMask: [.borderless], backing: .buffered, defer: false)
        host.alphaValue = 0
        host.ignoresMouseEvents = true
        host.contentView = grid
        host.orderFrontRegardless()
        grid.setFrameSize(NSSize(width: 1284, height: 722))
        guard let a = grid.panes[0] as? Pane, let b = grid.panes[1] as? Pane else { check("audio: los paneles son de la clase Pane", false); return }
        do { try await load(a, "media.html"); try await load(b, "media.html") } catch { check("audio: cargan las páginas de medios en los dos paneles", false, "\(error)"); return }
        await settle()

        func estado(_ p: Pane) async -> (silenciado: Bool, sonando: Bool) {
            let m = await paneJS(p, "window.__fixture.allMuted()") == "true"
            let s = await paneJS(p, "window.__fixture.noneMuted()") == "true"
            return (m, s)
        }

        var ea = await estado(a), eb = await estado(b)
        check("audio: con el foco en el primer panel, el primero suena", ea.sonando, "estado \(ea)")
        check("audio: con el foco en el primer panel, el segundo queda silenciado", eb.silenciado, "estado \(eb)")

        grid.setFocus(1); await settle()
        ea = await estado(a); eb = await estado(b)
        check("audio: al pasar el foco al segundo, el primero queda silenciado", ea.silenciado, "estado \(ea)")
        check("audio: al pasar el foco al segundo, el segundo suena", eb.sonando, "estado \(eb)")

        // Silencio manual: el usuario silencia el panel con foco; al perder y recuperar el foco sigue silenciado
        _ = await paneJS(b, "(window.__fixture.muteAll(), 1)")
        grid.setFocus(0); await settle()
        grid.setFocus(1); await settle()
        eb = await estado(b)
        check("audio: un silencio puesto a mano no se revierte al recuperar el foco", eb.silenciado, "estado \(eb)")

        // Cambio de panel con foco (atajo)
        grid.setFocus(0)
        grid.nextPane()
        let primero = grid.focused
        grid.nextPane()
        check("audio: el atajo de siguiente panel pasa el foco al otro y da la vuelta", primero == 1 && grid.focused == 0, "foco \(primero) y luego \(grid.focused)")
        await settle()

        // El reproductor intenta reactivar el audio del panel sin foco
        do { try await load(b, "unmutes.html") } catch { check("audio: carga la página que reactiva el audio", false, "\(error)"); return }
        await settle(1.6)
        eb = await estado(b)
        let intentos = Int(await paneJS(b, "window.__fixture.unmuteAttempts()")) ?? 0
        let vueltas = Int(await paneJS(b, "window.__primerAudio.reapplied()")) ?? 0
        check("audio: la página sin foco intentó reactivar el audio", intentos >= 1, "intentos \(intentos)")
        check("audio: aun así el panel sin foco sigue silenciado", eb.silenciado, "estado \(eb), intentos \(intentos)")
        check("audio: el guardián volvió a silenciarlo", vueltas >= 1, "veces \(vueltas)")

        // Abrir una dirección: solo cambia el panel con foco
        grid.setFocus(0)
        let urlB = b.url?.absoluteString
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            a.onFinish = { a.onFinish = nil; c.resume() }
            grid.openAddress(URL(string: "data:text/html,<p>destino</p>")!)
        }
        check("audio: abrir una dirección la carga en el panel con foco", a.url?.scheme == "data", "dirección \(a.url?.absoluteString ?? "ninguna")")
        check("audio: abrir una dirección no cambia el otro panel", b.url?.absoluteString == urlB, "antes \(urlB ?? "nil"), después \(b.url?.absoluteString ?? "nil")")
    }

    // Un clic sintético en el centro de un panel, entregado directamente a su vista
    func click(_ pane: Pane, in window: NSWindow) {
        let p = pane.convert(NSPoint(x: pane.bounds.midX, y: pane.bounds.midY), to: nil)
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            guard let e = NSEvent.mouseEvent(with: type, location: p, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                                             windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1,
                                             pressure: type == .leftMouseDown ? 1 : 0) else { continue }
            if type == .leftMouseDown { pane.mouseDown(with: e) } else { pane.mouseUp(with: e) }
        }
    }

    // El clic que da el foco no llega a la página (tarea 4.3)
    func checkFocusClick() async {
        func montar(_ n: Int) async -> (grid: PaneGrid, host: NSWindow, panes: [Pane])? {
            let g = PaneGrid(factory: { Pane(frame: .zero, configuration: makePaneConfiguration(persistent: false)) })
            if n == 2 { g.addPane() }
            let host = NSWindow(contentRect: NSRect(x: 0, y: 0, width: n == 2 ? 1284 : 640, height: n == 2 ? 722 : 360), styleMask: [.borderless], backing: .buffered, defer: false)
            host.alphaValue = 0
            host.ignoresMouseEvents = true
            host.contentView = g
            host.orderFrontRegardless()
            g.setFrameSize(host.contentRect(forFrameRect: host.frame).size)
            let panes = g.panes.compactMap { $0 as? Pane }
            for p in panes {
                do { try await load(p, "media.html") } catch { check("clic: cargan las páginas de medios", false, "\(error)"); return nil }
            }
            await settle()
            return (g, host, panes)
        }
        func eventos(_ p: Pane) async -> Int { Int(await paneJS(p, "window.__fixture.mouseDowns()")) ?? -1 }

        guard let dos = await montar(2) else { return }
        let a = dos.panes[0], b = dos.panes[1]
        // Control positivo: si un clic permitido no llegara, esta prueba no demostraría nada
        click(a, in: dos.host); await settle()
        let enA = await eventos(a)
        check("clic: un clic en el panel con foco llega a la página", enA == 1, "eventos recibidos: \(enA)")
        // Clic en el panel sin foco: recibe el foco y la página no se entera
        click(b, in: dos.host); await settle()
        let enB = await eventos(b)
        check("clic: el clic en el panel sin foco le pasa el foco", dos.grid.focused == 1, "foco en \(dos.grid.focused)")
        check("clic: ese clic no llega a la página", enB == 0, "eventos recibidos: \(enB)")
        // El siguiente clic, ya con foco, sí llega
        click(b, in: dos.host); await settle()
        let enB2 = await eventos(b)
        check("clic: el siguiente clic en ese panel sí llega a la página", enB2 == 1, "eventos recibidos: \(enB2)")
        // Con un solo panel todos los clics llegan
        guard let uno = await montar(1) else { return }
        click(uno.panes[0], in: uno.host); await settle()
        let enU = await eventos(uno.panes[0])
        check("clic: con un solo panel el clic llega a la página", enU == 1, "eventos recibidos: \(enU)")
    }

    // Uno y dos paneles de 16:9 con hueco de 8 px, y segundo panel a demanda (tarea 4.1)
    func checkPanes() {
        let gap = PaneGrid.gap
        func close(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 0.01 }

        // Un panel: llena la ventana 16:9
        let one = PaneGrid(factory: { NSView() })
        one.setFrameSize(NSSize(width: 1280, height: 720))
        check("paneles: un panel mide el ancho de la ventana por 9/16", one.count == 1 && one.panes[0].frame.size == NSSize(width: 1280, height: 720), "\(one.panes[0].frame)")

        // Dos paneles: medidas y hueco para varios anchos de ventana
        for width in [2568.0, 5120.0] {
            let g = PaneGrid(factory: { NSView() })
            g.addPane()
            g.setFrameSize(NSSize(width: width, height: width * 9 / 32))
            let a = g.panes[0].frame, b = g.panes[1].frame, pw = (width - gap) / 2
            check("paneles: con \(Int(width)) px cada panel mide (ancho − 8) / 2", close(a.width, pw) && close(b.width, pw), "\(a.width) y \(b.width) frente a \(pw)")
            check("paneles: con \(Int(width)) px el hueco entre ellos es de 8 px", close(b.minX - a.maxX, gap), "hueco \(b.minX - a.maxX)")
            check("paneles: con \(Int(width)) px cada panel mide 16:9", abs(a.width / a.height - 16.0 / 9.0) < 0.0001 && abs(b.width / b.height - 16.0 / 9.0) < 0.0001,
                  "proporciones \(a.width / a.height) y \(b.width / b.height)")
        }

        // La proporción de la ventana: 16:9 con uno y 32:9 con dos
        check("paneles: la ventana mide 16:9 con un panel y 32:9 con dos",
              windowAspect(forPanes: 1) == NSSize(width: 16, height: 9) && windowAspect(forPanes: 2) == NSSize(width: 32, height: 9))

        // Segundo panel a demanda, con la ventana real: el primer panel conserva su tamaño
        let g = PaneGrid(factory: { NSView() })
        let w = makeChromeWindow(content: g)
        w.setFrame(NSRect(x: 100, y: 900, width: 1280, height: 720), display: false)
        let antes = g.panes[0].frame.size
        let target = windowFrame(forPanes: 2, from: w.frame, maxWidth: 5120)
        g.addPane()
        w.aspectRatio = windowAspect(forPanes: 2)
        w.setFrame(target, display: false)
        check("paneles: al abrir el segundo, el primero conserva su tamaño", g.panes[0].frame.size == antes && g.count == 2,
              "antes \(antes), después \(g.panes[0].frame.size)")
        check("paneles: al abrir el segundo, la ventana pasa a 32:9 y conserva su esquina superior izquierda",
              abs(target.width / target.height - 32.0 / 9.0) < 0.0001 && close(target.minX, 100) && close(target.maxY, 1620))
        let angosto = windowFrame(forPanes: 2, from: NSRect(x: 0, y: 0, width: 1600, height: 900), maxWidth: 2000)
        check("paneles: si no cabe el doble, la ventana se limita al ancho de la pantalla y sigue siendo 32:9",
              angosto.width <= 2000 + 0.01 && abs(angosto.width / angosto.height - 32.0 / 9.0) < 0.0001, "ancho \(angosto.width)")

        // Volver a un panel: el segundo se quita de la ventana y se libera
        weak var segundo: NSView?
        var quitado = false
        autoreleasepool {
            let h = PaneGrid(factory: { NSView() })
            h.addPane()
            segundo = h.panes[1]
            h.removeLastPane()
            quitado = h.count == 1 && segundo?.superview == nil
        }
        check("paneles: al volver a un panel el segundo sale de la ventana", quitado)
        check("paneles: al volver a un panel el segundo se libera por completo", segundo == nil)
        let vuelta = windowFrame(forPanes: 1, from: NSRect(x: 0, y: 0, width: 2568, height: 722.25), maxWidth: 5120)
        check("paneles: al volver a un panel la ventana mide lo que medía cada panel (1280×720)", close(vuelta.width, 1280) && close(vuelta.height, 720), "\(vuelta.size)")
    }

    func run() async {
        print("Autoprueba de Primer (páginas de \(fixtures.path))")
        for file in ["media.html", "unmutes.html"] {
            let name = String(file.dropLast(".html".count))
            do { try await load(file) } catch { check("\(file): carga", false, "\(error)"); continue }
            check("\(file): carga", true)
            check("\(file): expone window.__fixture", await js("window.__fixture.name") == name)
            check("\(file): tiene dos elementos de medios", await js("window.__fixture.media().length") == "2")
            check("\(file): el silencio se puede cambiar y leer", await js("(window.__fixture.muteAll(), window.__fixture.allMuted())") == "true")
            check("\(file): no suena (volumen 0)", await js("window.__fixture.media().every(m => m.volume === 0)") == "true")
            if name == "media" {
                check("\(file): el audio se puede reactivar a mano", await js("(window.__fixture.unmuteAll(), window.__fixture.noneMuted())") == "true")
            } else {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                let attempts = Int(await js("window.__fixture.unmuteAttempts()")) ?? 0
                let sounding = await js("window.__fixture.noneMuted()") == "true"
                check("\(file): reactiva el audio por su cuenta", attempts >= 1 && sounding, "intentos: \(attempts), sin silenciar: \(sounding)")
                check("\(file): sigue sin sonar tras reactivar el audio (volumen 0)", await js("window.__fixture.media().every(m => m.volume === 0)") == "true")
            }
        }
        checkWindow()
        checkFillCenterAndLevel()
        checkPanes()
        await checkAudio()
        await checkFocusClick()
        print("")
        print("Comprobaciones: \(passed) pasaron, \(failed) fallaron.")
        print("Lo valida una persona: los paneles con un partido reproduciéndose, que el primero no se refresque y que el hueco se vea bien (4.2),")
        print("y que con dos partidos de Prime Video el panel sin foco no se escuche en ningún momento (4.4).")
        print("Aviso: la autoprueba no probó Prime Video; la reproducción y la apariencia requieren validación humana.")
        fflush(stdout)
        exit(failed == 0 && passed > 0 ? 0 : 1)
    }
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.run()
