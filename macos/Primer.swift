import Cocoa
import WebKit

// Autoprueba, sin cuenta ni red y sin abrir Prime Video:
//   Primer.app/Contents/MacOS/Primer --selftest     (imprime una línea por comprobación; código 0 si todas pasan)
// Variable opcional: PRIMER_FIXTURES=<carpeta> para usar otras páginas de prueba que shared/fixtures/.

// Dirección de inicio de Prime Video. Es una sola constante a propósito: depende de la región
// y del canal de la cuenta (ver «Open Questions» en openspec/changes/archive/2026-10-20-add-macos-viewer/design.md).
let homeURL = URL(string: "https://www.primevideo.com/")!

// Diagnóstico opcional: solo con --debug. Escribe debug.log junto a la aplicación y habilita el inspector web.
// Nunca se leen contraseñas, códigos ni el contenido de los campos de la página; de una dirección solo se registran servidor y ruta.
let debugMode = CommandLine.arguments.contains("--debug")

// Lo único que se registra de una dirección: servidor y ruta, sin consulta ni fragmento (pueden llevar fichas, correos o códigos).
// Las direcciones data: pueden llevar contenido y no se registran.
func debugSafeLocation(_ url: URL?) -> String {
    guard let url else { return "(sin dirección)" }
    if url.scheme == "data" { return "data:" }
    var s = (url.host ?? "") + url.path
    if s.isEmpty { s = url.scheme ?? "" }
    return s.count > 80 ? String(s.prefix(80)) + "…" : s
}

@MainActor
final class DebugLog {
    static let shared = DebugLog()
    let path = Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("debug.log").path
    private(set) var linesWritten = 0

    func write(_ message: String) {
        guard debugMode else { return }
        linesWritten += 1
        let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(message)\n"
        if let h = FileHandle(forWritingAtPath: path) { h.seekToEndOfFile(); h.write(line.data(using: .utf8)!); try? h.close() }
        else { try? line.write(toFile: path, atomically: true, encoding: .utf8) }
    }
}

// Recibe los avisos del guardián de audio (solo con --debug). Se ignora cualquier mensaje que no sea el aviso conocido.
final class PaneLogHandler: NSObject, WKScriptMessageHandler {
    static let shared = PaneLogHandler()
    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        guard (m.body as? String) == "reapplied" else { return }
        let name = (m.webView as? Pane)?.logName ?? "?"
        Task { @MainActor in DebugLog.shared.write("audio: el reproductor del panel \(name) reactivó el sonido y se volvió a silenciar") }
    }
}

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
  const note = () => { if (window.__primerDebug) { try { window.webkit.messageHandlers.primerLog.postMessage('reapplied'); } catch (e) {} } };
  const enforce = (m) => { if (state.muted && !m.muted) { m.__primerForced = true; m.muted = true; state.reapplied++; note(); } };
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
    if debugMode {
        cfg.userContentController.addUserScript(WKUserScript(source: "window.__primerDebug = true;", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        cfg.userContentController.add(PaneLogHandler.shared, name: "primerLog")
    }
    cfg.userContentController.addUserScript(WKUserScript(source: audioGuardScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
    return cfg
}

// Un panel: un WKWebView que avisa cuando se hace clic en él y que mantiene su silencio al cargar páginas nuevas
final class Pane: WKWebView, WKNavigationDelegate {
    var onFocus: (() -> Void)?
    var onFinish: (() -> Void)?
    var logName = "?"
    var wantsMuted = false {
        didSet {
            pushMute()
            if oldValue != wantsMuted { DebugLog.shared.write("audio: panel \(logName) \(wantsMuted ? "silenciado" : "con sonido")") }
        }
    }

    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        navigationDelegate = self
        isInspectable = debugMode                       // el inspector web solo existe con --debug
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
    func webView(_ w: WKWebView, didCommit n: WKNavigation!) {
        pushMute()
        DebugLog.shared.write("panel \(logName): carga \(debugSafeLocation(url))")
    }
    func webView(_ w: WKWebView, didFinish n: WKNavigation!) {
        pushMute()
        DebugLog.shared.write("panel \(logName): terminó de cargar")
        onFinish?()
    }
    func webView(_ w: WKWebView, didFail n: WKNavigation!, withError e: Error) {
        DebugLog.shared.write("panel \(logName): falló la carga (\((e as NSError).code))")
    }
    func webView(_ w: WKWebView, didFailProvisionalNavigation n: WKNavigation!, withError e: Error) {
        DebugLog.shared.write("panel \(logName): falló la carga (\((e as NSError).code))")
    }
    override func setFrameSize(_ s: NSSize) {
        let changed = s != frame.size
        super.setFrameSize(s)
        if changed { DebugLog.shared.write("panel \(logName): tamaño \(Int(s.width))×\(Int(s.height))") }
    }
}

// Disposición de los paneles: uno junto al otro (horizontal) o uno sobre otro (vertical)
enum PaneLayout { case horizontal, vertical }

// Hasta tres paneles de 16:9. Con uno, el panel llena la ventana. Con dos o tres, quedan pegados, sin hueco, a lo largo del eje de la
// disposición: en horizontal cada uno mide 1/n del ancho y toda la altura, en vertical el ancho completo y 1/n de la altura.
// Los paneles adicionales existen solo mientras se piden.
let maxPanes = 3

final class PaneGrid: NSView {
    let factory: () -> NSView
    private(set) var panes: [NSView] = []
    // Cambiar la disposición no recoloca los paneles: lo hace layoutPanes() cuando la ventana ya tiene su marco nuevo
    var layout: PaneLayout = .horizontal

    init(factory: @escaping () -> NSView) {
        self.factory = factory
        super.init(frame: .zero)
        addPane()
    }
    required init?(coder: NSCoder) { fatalError("no se usa") }

    var count: Int { panes.count }

    private(set) var focused = 0

    func addPane() {
        guard panes.count < maxPanes else { return }
        let p = factory()
        panes.append(p)
        addSubview(p)
        if let pane = p as? Pane {
            pane.logName = "\(panes.count)"
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
        DebugLog.shared.write("panel \((p as? Pane)?.logName ?? "?"): se quitó de la ventana y se liberó")
        if focused >= panes.count { focused = 0 }
        applyAudio()
    }

    // Solo suena el panel con foco; con un solo panel no se silencia nada
    func setFocus(_ i: Int) {
        guard panes.indices.contains(i) else { return }
        focused = i
        window?.makeFirstResponder(panes[i])
        DebugLog.shared.write("audio: el foco pasó al panel \(i + 1)")
        applyAudio()
    }
    func nextPane() { setFocus((focused + 1) % panes.count) }
    func applyAudio() {
        for (i, p) in panes.enumerated() { (p as? Pane)?.wantsMuted = panes.count > 1 && i != focused }
    }

    // La dirección se abre solo en el panel con foco
    func openAddress(_ url: URL) { (panes[focused] as? Pane)?.load(URLRequest(url: url)) }

    // Recargar solo el panel con foco
    func reloadFocused() { (panes[focused] as? Pane)?.reload() }

    override func setFrameSize(_ s: NSSize) {
        super.setFrameSize(s)
        layoutPanes()
    }

    // En AppKit el origen está abajo: en vertical el primer panel se coloca en la franja de arriba
    func layoutPanes() {
        let n = CGFloat(panes.count)
        if panes.count == 1 { panes[0].frame = bounds; return }
        for (i, p) in panes.enumerated() {
            switch layout {
            case .horizontal:
                p.frame = NSRect(x: bounds.width / n * CGFloat(i), y: 0, width: bounds.width / n, height: bounds.height)
            case .vertical:
                p.frame = NSRect(x: 0, y: bounds.height - bounds.height / n * CGFloat(i + 1), width: bounds.width, height: bounds.height / n)
            }
        }
    }
}

// Proporción de la ventana: 16n:9 en horizontal y 16:9n en vertical (n paneles de 16:9 uno junto al otro o uno sobre otro)
func windowAspect(forPanes n: Int, layout: PaneLayout) -> NSSize {
    layout == .horizontal ? NSSize(width: 16 * CGFloat(n), height: 9) : NSSize(width: 16, height: 9 * CGFloat(n))
}

// Marco de la ventana al pasar a n paneles y a la disposición `layout`. Se deduce el tamaño de un panel del marco actual y el marco
// nuevo repite ese panel n veces a lo largo del nuevo eje, de modo que los paneles que ya estaban abiertos conservan su tamaño y no se
// refrescan (cambiar el tamaño de la ventana rehace el reproductor). Si no cabe en `area` se reduce con la misma proporción, y si se
// sale se desplaza lo mínimo. Conserva la esquina superior izquierda y nunca baja de 320 px de ancho.
func windowFrame(forPanes n: Int, layout: PaneLayout, from old: NSRect, fromPanes oldN: Int, fromLayout oldLayout: PaneLayout, in area: NSRect) -> NSRect {
    let oldCount = CGFloat(max(oldN, 1)), count = CGFloat(n)
    let pane = oldLayout == .horizontal ? NSSize(width: old.width / oldCount, height: old.height) : NSSize(width: old.width, height: old.height / oldCount)
    var size = layout == .horizontal ? NSSize(width: pane.width * count, height: pane.height) : NSSize(width: pane.width, height: pane.height * count)
    let fit = min(1, area.width / size.width, area.height / size.height)
    size = NSSize(width: size.width * fit, height: size.height * fit)
    if size.width < 320 { let up = 320 / size.width; size = NSSize(width: 320, height: size.height * up) }
    let x = min(max(old.minX, area.minX), max(area.maxX - size.width, area.minX))
    let top = max(min(old.maxY, area.maxY), area.minY + size.height)
    return NSRect(x: x, y: top - size.height, width: size.width, height: size.height)
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

    var usableArea: NSRect { (window.screen ?? NSScreen.main)?.visibleFrame ?? window.frame }

    // De uno a tres paneles: primero se crean o se quitan los paneles y luego cambia la ventana, una sola vez, para que los paneles
    // que ya estaban abiertos no cambien de tamaño
    func setPanes(_ n: Int) {
        guard (1...maxPanes).contains(n), n != grid.count else { return }
        let target = windowFrame(forPanes: n, layout: grid.layout, from: window.frame, fromPanes: grid.count, fromLayout: grid.layout, in: usableArea)
        while grid.count < n { grid.addPane() }
        while grid.count > n { grid.removeLastPane() }
        window.aspectRatio = windowAspect(forPanes: n, layout: grid.layout)
        window.setFrame(target, display: true, animate: false)
        grid.layoutPanes()
    }

    // Horizontal o vertical: los mismos paneles en el mismo orden. Con un solo panel solo se recuerda para el siguiente que se abra
    func setLayout(_ layout: PaneLayout) {
        guard layout != grid.layout else { return }
        let target = windowFrame(forPanes: grid.count, layout: layout, from: window.frame, fromPanes: grid.count, fromLayout: grid.layout, in: usableArea)
        grid.layout = layout
        guard grid.count > 1 else { return }
        window.aspectRatio = windowAspect(forPanes: grid.count, layout: layout)
        window.setFrame(target, display: true, animate: false)
        grid.layoutPanes()
    }
    @objc func onePane() { setPanes(1) }
    @objc func twoPanes() { setPanes(2) }
    @objc func threePanes() { setPanes(3) }
    @objc func horizontalLayout() { setLayout(.horizontal) }
    @objc func verticalLayout() { setLayout(.vertical) }
    @objc func nextPane() { grid.nextPane() }
    @objc func reload() { grid.reloadFocused() }
    @objc func goHome() { grid.openAddress(homeURL) }

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

    func installMenu() { NSApp.mainMenu = makeMainMenu(target: self) }
}

// Menú de la aplicación, con los atajos de ⌘: Salir (Q); Ventana: rellenar y centrar (F), siempre encima (T) y cerrar (W);
// Paneles: 1, 2 y 3 paneles, disposición horizontal (⌥⌘H) y vertical (⌥⌘V), siguiente panel (`), abrir dirección (L), recargar (R)
// e inicio de Prime Video (H);
// Edición: deshacer, cortar, copiar, pegar y seleccionar todo. Recargar, inicio y abrir dirección actúan sobre el panel con foco.
@MainActor
func makeMainMenu(target: App) -> NSMenu {
    let main = NSMenu()
    func add(_ menu: NSMenu, _ title: String, _ action: Selector, _ key: String, targeted: Bool = true, option: Bool = false) {
        let it = NSMenuItem(title: title, action: action, keyEquivalent: key)
        if option { it.keyEquivalentModifierMask = [.command, .option] }
        if targeted { it.target = target }
        menu.addItem(it)
    }
    func submenu(_ title: String) -> NSMenu {
        let top = NSMenuItem(); main.addItem(top)
        let m = NSMenu(title: title); top.submenu = m
        return m
    }

    let app = submenu("Primer")
    add(app, "Salir de Primer", #selector(NSApplication.terminate(_:)), "q", targeted: false)

    let win = submenu("Ventana")
    add(win, "Rellenar y centrar", #selector(App.fillCenter), "f")
    add(win, "Siempre encima", #selector(App.toggleFloat), "t")
    add(win, "Cerrar", #selector(NSWindow.performClose(_:)), "w", targeted: false)

    let panes = submenu("Paneles")
    add(panes, "1 panel", #selector(App.onePane), "1")
    add(panes, "2 paneles", #selector(App.twoPanes), "2")
    add(panes, "3 paneles", #selector(App.threePanes), "3")
    add(panes, "Disposición horizontal", #selector(App.horizontalLayout), "h", option: true)
    add(panes, "Disposición vertical", #selector(App.verticalLayout), "v", option: true)
    add(panes, "Siguiente panel", #selector(App.nextPane), "`")
    add(panes, "Abrir dirección…", #selector(App.openAddress), "l")
    add(panes, "Recargar", #selector(App.reload), "r")
    add(panes, "Inicio de Prime Video", #selector(App.goHome), "h")

    let edit = submenu("Edición")
    add(edit, "Deshacer", Selector(("undo:")), "z", targeted: false)
    add(edit, "Cortar", #selector(NSText.cut(_:)), "x", targeted: false)
    add(edit, "Copiar", #selector(NSText.copy(_:)), "c", targeted: false)
    add(edit, "Pegar", #selector(NSText.paste(_:)), "v", targeted: false)
    add(edit, "Seleccionar todo", #selector(NSText.selectAll(_:)), "a", targeted: false)
    return main
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

    // Atajos del menú (tarea 5.1): los de la especificación existen con la tecla ⌘ y cada acción tiene quien la atienda
    func checkShortcuts() {
        var items: [String: NSMenuItem] = [:]
        // ⌥⌘H y ⌥⌘V comparten letra con ⌘H y ⌘V: la clave lleva el ⌥ cuando el atajo lo usa
        func walk(_ m: NSMenu) {
            for it in m.items {
                if !it.keyEquivalent.isEmpty { items[(it.keyEquivalentModifierMask.contains(.option) ? "⌥" : "") + it.keyEquivalent] = it }
                if let s = it.submenu { walk(s) }
            }
        }
        // El destino de un elemento de menú es una referencia débil: la App debe seguir viva mientras se revisa
        let objetivo = App()
        walk(makeMainMenu(target: objetivo))
        defer { withExtendedLifetime(objetivo) {} }
        let esperados = [("1", "1 panel"), ("2", "2 paneles"), ("3", "3 paneles"),
                         ("⌥h", "Disposición horizontal"), ("⌥v", "Disposición vertical"), ("l", "Abrir dirección…"), ("r", "Recargar"), ("h", "Inicio de Prime Video"),
                         ("`", "Siguiente panel"), ("t", "Siempre encima"), ("f", "Rellenar y centrar"), ("w", "Cerrar"), ("q", "Salir de Primer"),
                         ("z", "Deshacer"), ("x", "Cortar"), ("c", "Copiar"), ("v", "Pegar"), ("a", "Seleccionar todo")]
        for (key, title) in esperados {
            let it = items[key]
            check("atajos: \(key.hasPrefix("⌥") ? "⌥⌘" + key.dropFirst() : "⌘" + key) es «\(title)»", it?.title == title && it?.keyEquivalentModifierMask.contains(.command) == true,
                  "encontrado: \(it?.title ?? "nada")")
        }
        let sinAtender = items.values.filter { it in
            guard let t = it.target, let a = it.action else { return false }
            return !t.responds(to: a)
        }.map { $0.title }
        let conDestino = items.values.filter { $0.target != nil && $0.action != nil }.count
        check("atajos: las 11 acciones propias del menú tienen destino (la comprobación no pasa en vacío)", conDestino == 11, "con destino: \(conDestino)")
        check("atajos: cada acción propia del menú tiene quien la atienda", sinAtender.isEmpty && conDestino == 11, "sin atender: \(sinAtender)")
    }

    // Sesión persistente compartida entre paneles e instancias (tarea 5.1). Que la sesión sobreviva de verdad al cerrar la valida una persona (5.2)
    func checkSession() {
        let a = makePaneConfiguration(persistent: true).websiteDataStore, b = makePaneConfiguration(persistent: true).websiteDataStore
        check("sesión: los paneles de la aplicación usan el almacén de datos persistente", a.isPersistent && b.isPersistent)
        check("sesión: dos paneles comparten el mismo almacén (y por tanto la sesión)", a === b && a === WKWebsiteDataStore.default())
        check("sesión: la autoprueba usa un almacén no persistente y no toca la sesión", !makePaneConfiguration(persistent: false).websiteDataStore.isPersistent)
    }

    // Recargar solo el panel con foco (tarea 5.1)
    func checkReload() async {
        let grid = PaneGrid(factory: { Pane(frame: .zero, configuration: makePaneConfiguration(persistent: false)) })
        grid.addPane()
        let host = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1284, height: 722), styleMask: [.borderless], backing: .buffered, defer: false)
        host.alphaValue = 0
        host.ignoresMouseEvents = true
        host.contentView = grid
        host.orderFrontRegardless()
        grid.setFrameSize(NSSize(width: 1284, height: 722))
        guard let a = grid.panes[0] as? Pane, let b = grid.panes[1] as? Pane else { check("recargar: los paneles son de la clase Pane", false); return }
        do { try await load(a, "media.html"); try await load(b, "media.html") } catch { check("recargar: cargan las páginas de prueba", false, "\(error)"); return }
        _ = await paneJS(a, "(window.__marca = 1, 1)")
        _ = await paneJS(b, "(window.__marca = 1, 1)")
        grid.setFocus(0)
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            a.onFinish = { a.onFinish = nil; c.resume() }
            grid.reloadFocused()
        }
        let ma = await paneJS(a, "window.__marca"), mb = await paneJS(b, "window.__marca")
        check("recargar: el panel con foco se recarga", ma == "undefined", "marca: \(ma)")
        check("recargar: los demás paneles no se recargan", mb == "1", "marca: \(mb)")
    }

    // Diagnóstico opcional y sin datos personales (tarea 5.1)
    func checkDebug() async {
        let seguro = debugSafeLocation(URL(string: "https://www.primevideo.com/detail/ABC123?token=SECRETO&email=ana%40example.com#sesion"))
        check("debug: de una dirección solo se registran servidor y ruta", seguro == "www.primevideo.com/detail/ABC123", "registrado: \(seguro)")
        check("debug: una dirección data: no se registra", debugSafeLocation(URL(string: "data:text/html,<p>clave</p>")) == "data:")
        check("debug: las rutas largas se recortan", debugSafeLocation(URL(string: "https://x.com/" + String(repeating: "a", count: 200))).count <= 81)
        let pane = Pane(frame: .zero, configuration: makePaneConfiguration(persistent: false))
        check("debug: el inspector web \(debugMode ? "está habilitado con --debug" : "queda deshabilitado sin --debug")", pane.isInspectable == debugMode)
        do { try await load(pane, "form.html") } catch { check("debug: carga la página con campos", false, "\(error)"); return }
        await settle()
        if !debugMode {
            check("debug: sin --debug no se escribe ningún registro", DebugLog.shared.linesWritten == 0, "líneas escritas: \(DebugLog.shared.linesWritten)")
            return
        }
        let log = (try? String(contentsOfFile: DebugLog.shared.path, encoding: .utf8)) ?? ""
        check("debug: con --debug se escribe debug.log con eventos de audio", log.contains("audio: el foco pasó") && log.contains("silenciado"))
        check("debug: el registro anota que el reproductor reactivó el sonido", log.contains("reactivó el sonido"))
        check("debug: el registro trae los eventos de cada panel (carga y tamaño)", log.contains("carga ") && log.contains("tamaño"))
        let prohibido = ["secreto-123", "ana@example.com", "token=", "SECRETO"]
        let hallado = prohibido.filter { log.contains($0) }
        check("debug: el registro no contiene el contenido de los campos ni datos personales", hallado.isEmpty, "contiene: \(hallado)")
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

    // Uno y dos paneles de 16:9 sin hueco, y segundo panel a demanda (tarea 4.1)
    func checkPanes() {
        func close(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 0.01 }

        // Un panel: llena la ventana 16:9
        let one = PaneGrid(factory: { NSView() })
        one.setFrameSize(NSSize(width: 1280, height: 720))
        check("paneles: un panel mide el ancho de la ventana por 9/16", one.count == 1 && one.panes[0].frame.size == NSSize(width: 1280, height: 720), "\(one.panes[0].frame)")

        // Dos paneles: medidas, sin hueco y a altura completa, para varios anchos de ventana
        for width in [2560.0, 5120.0] {
            let g = PaneGrid(factory: { NSView() })
            g.addPane()
            g.setFrameSize(NSSize(width: width, height: width * 9 / 32))
            let a = g.panes[0].frame, b = g.panes[1].frame, pw = width / 2, alto = width * 9 / 32
            check("paneles: con \(Int(width)) px cada panel mide la mitad del ancho", close(a.width, pw) && close(b.width, pw), "\(a.width) y \(b.width) frente a \(pw)")
            check("paneles: con \(Int(width)) px no hay hueco entre ellos", close(b.minX - a.maxX, 0), "separación \(b.minX - a.maxX)")
            check("paneles: con \(Int(width)) px cada panel mide la altura completa de la ventana", close(a.height, alto) && close(b.height, alto) && close(a.minY, 0) && close(b.minY, 0), "alturas \(a.height) y \(b.height) frente a \(alto)")
            check("paneles: con \(Int(width)) px cada panel mide 16:9", abs(a.width / a.height - 16.0 / 9.0) < 0.0001 && abs(b.width / b.height - 16.0 / 9.0) < 0.0001,
                  "proporciones \(a.width / a.height) y \(b.width / b.height)")
        }

        // La proporción de la ventana: 16n:9 en horizontal y 16:9n en vertical
        check("paneles: la ventana mide 16:9 con un panel y 32:9 con dos",
              windowAspect(forPanes: 1, layout: .horizontal) == NSSize(width: 16, height: 9) && windowAspect(forPanes: 2, layout: .horizontal) == NSSize(width: 32, height: 9))
        check("paneles: la ventana mide 48:9 con tres paneles en horizontal", windowAspect(forPanes: 3, layout: .horizontal) == NSSize(width: 48, height: 9))
        check("paneles: la ventana mide 16:18 con dos paneles y 16:27 con tres en vertical",
              windowAspect(forPanes: 2, layout: .vertical) == NSSize(width: 16, height: 18) && windowAspect(forPanes: 3, layout: .vertical) == NSSize(width: 16, height: 27))

        // Segundo panel a demanda, con la ventana real: el primer panel conserva su tamaño
        let g = PaneGrid(factory: { NSView() })
        let w = makeChromeWindow(content: g)
        w.setFrame(NSRect(x: 100, y: 900, width: 1280, height: 720), display: false)
        let antes = g.panes[0].frame.size
        let amplia = NSRect(x: 0, y: 0, width: 5120, height: 3000)
        let target = windowFrame(forPanes: 2, layout: .horizontal, from: w.frame, fromPanes: 1, fromLayout: .horizontal, in: amplia)
        g.addPane()
        w.aspectRatio = windowAspect(forPanes: 2, layout: .horizontal)
        w.setFrame(target, display: false)
        check("paneles: al abrir el segundo, el primero conserva su tamaño", g.panes[0].frame.size == antes && g.count == 2,
              "antes \(antes), después \(g.panes[0].frame.size)")
        check("paneles: al abrir el segundo, la ventana pasa a 32:9 y mide exactamente el doble",
              abs(target.width / target.height - 32.0 / 9.0) < 0.0001 && close(target.width, 2560) && close(target.height, 720), "\(target.size)")
        check("paneles: al abrir el segundo, la ventana conserva su esquina superior izquierda", close(target.minX, 100) && close(target.maxY, 1620))
        let angosto = windowFrame(forPanes: 2, layout: .horizontal, from: NSRect(x: 0, y: 0, width: 1600, height: 900), fromPanes: 1, fromLayout: .horizontal,
                                  in: NSRect(x: 0, y: 0, width: 2000, height: 1400))
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
        let vuelta = windowFrame(forPanes: 1, layout: .horizontal, from: NSRect(x: 0, y: 0, width: 2560, height: 720), fromPanes: 2, fromLayout: .horizontal, in: amplia)
        check("paneles: al volver a un panel la ventana mide lo que medía cada panel (1280×720)", close(vuelta.width, 1280) && close(vuelta.height, 720), "\(vuelta.size)")
    }

    // Tres paneles y las dos disposiciones (tareas 1.2, 2.2, 3.1 a 3.3): medidas, cambio de disposición, foco, clic y audio con paneles reales
    func checkThreePanes() async {
        func close(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 0.01 }
        let area = NSRect(x: 0, y: 0, width: 5120, height: 3000)

        // Medidas sin hueco en las dos disposiciones, con vistas simples
        for (layout, nombre) in [(PaneLayout.horizontal, "horizontal"), (.vertical, "vertical")] {
            for n in [2, 3] {
                let g = PaneGrid(factory: { NSView() })
                for _ in 1..<n { g.addPane() }
                g.layout = layout
                let aspect = windowAspect(forPanes: n, layout: layout)
                let ancho: CGFloat = layout == .horizontal ? 480 * CGFloat(n) : 480
                g.setFrameSize(NSSize(width: ancho, height: ancho * aspect.height / aspect.width))
                let f = g.panes.map { $0.frame }
                let todos16x9 = f.allSatisfy { abs($0.width / $0.height - 16.0 / 9.0) < 0.0001 }
                var sinHueco = true
                for i in 1..<n {
                    sinHueco = sinHueco && (layout == .horizontal ? close(f[i].minX - f[i - 1].maxX, 0) && close(f[i].minY, 0) : close(f[i - 1].minY - f[i].maxY, 0) && close(f[i].minX, 0))
                }
                let llena = layout == .horizontal ? f.allSatisfy { close($0.height, g.bounds.height) } : f.allSatisfy { close($0.width, g.bounds.width) }
                let arriba = layout == .vertical ? close(f[0].maxY, g.bounds.height) && close(f[n - 1].minY, 0) : close(f[0].minX, 0) && close(f[n - 1].maxX, g.bounds.width)
                check("paneles: \(n) paneles en \(nombre) miden 16:9, llenan la ventana y no dejan hueco", todos16x9 && sinHueco && llena && arriba, "marcos \(f)")
            }
        }
        // Nunca más de tres
        let tope = PaneGrid(factory: { NSView() })
        for _ in 0..<5 { tope.addPane() }
        check("paneles: no hay más de tres paneles", tope.count == 3 && maxPanes == 3, "paneles \(tope.count)")

        // Marcos de la ventana: abrir paneles y cambiar de disposición conservan el tamaño de cada panel
        let uno = NSRect(x: 100, y: 1500, width: 1280, height: 720)
        let tres = windowFrame(forPanes: 3, layout: .horizontal, from: uno, fromPanes: 1, fromLayout: .horizontal, in: area)
        check("ventana: de uno a tres paneles en horizontal mide el triple (48:9) y conserva la esquina superior izquierda",
              close(tres.width, 3840) && close(tres.height, 720) && close(tres.minX, 100) && close(tres.maxY, 2220), "\(tres)")
        let vertical = windowFrame(forPanes: 3, layout: .vertical, from: tres, fromPanes: 3, fromLayout: .horizontal, in: area)
        check("ventana: de horizontal a vertical con tres paneles cada panel conserva su tamaño (16:27)",
              close(vertical.width, 1280) && close(vertical.height, 2160) && close(vertical.maxY, tres.maxY), "\(vertical)")
        let dosV = windowFrame(forPanes: 2, layout: .vertical, from: vertical, fromPanes: 3, fromLayout: .vertical, in: area)
        check("ventana: de tres a dos paneles en vertical mide 16:18", close(dosV.width, 1280) && close(dosV.height, 1440), "\(dosV)")
        // La pantalla no da: se reduce con la misma proporción y queda dentro
        let normal = NSRect(x: 0, y: 25, width: 1920, height: 1055)
        let ajustada = windowFrame(forPanes: 3, layout: .horizontal, from: NSRect(x: 50, y: 900, width: 1280, height: 720), fromPanes: 1, fromLayout: .horizontal, in: normal)
        check("ventana: si tres paneles no caben se reduce conservando 48:9 y queda dentro de la pantalla",
              abs(ajustada.width / ajustada.height - 48.0 / 9.0) < 0.0001 && ajustada.width <= normal.width + 0.01 && ajustada.minX >= normal.minX && ajustada.maxX <= normal.maxX + 0.01
                && ajustada.minY >= normal.minY - 0.01 && ajustada.maxY <= normal.maxY + 0.01, "\(ajustada)")
        let alta = windowFrame(forPanes: 3, layout: .vertical, from: NSRect(x: 50, y: 1000, width: 1280, height: 720), fromPanes: 1, fromLayout: .horizontal, in: normal)
        check("ventana: si tres paneles en vertical no caben en alto se reduce conservando 16:27",
              abs(alta.width / alta.height - 16.0 / 27.0) < 0.0001 && alta.height <= normal.height + 0.01 && alta.minY >= normal.minY - 0.01, "\(alta)")
        // Rellenar y centrar usa la proporción vigente en las dos disposiciones
        let rh = fillAndCenterRect(aspect: windowAspect(forPanes: 3, layout: .horizontal), in: normal)
        let rv = fillAndCenterRect(aspect: windowAspect(forPanes: 3, layout: .vertical), in: normal)
        check("rellenar: con tres paneles conserva 48:9 en horizontal y 16:27 en vertical y cabe en el área",
              abs(rh.width / rh.height - 48.0 / 9.0) < 0.0001 && abs(rv.width / rv.height - 16.0 / 27.0) < 0.0001
                && rh.width <= normal.width + 0.01 && rv.height <= normal.height + 0.01, "\(rh) y \(rv)")

        // Con paneles reales: foco, siguiente panel, clic y audio con tres paneles, y cambio de disposición
        let g = PaneGrid(factory: { Pane(frame: .zero, configuration: makePaneConfiguration(persistent: false)) })
        g.addPane(); g.addPane()
        let host = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1920, height: 360), styleMask: [.borderless], backing: .buffered, defer: false)
        host.alphaValue = 0
        host.ignoresMouseEvents = true
        host.contentView = g
        host.orderFrontRegardless()
        g.setFrameSize(NSSize(width: 1920, height: 360))
        let panes = g.panes.compactMap { $0 as? Pane }
        guard panes.count == 3 else { check("tres paneles: son de la clase Pane", false); return }
        for p in panes {
            do { try await load(p, "media.html") } catch { check("tres paneles: cargan las páginas de medios", false, "\(error)"); return }
        }
        await settle()
        func suena(_ p: Pane) async -> Bool { await paneJS(p, "window.__fixture.noneMuted()") == "true" }
        func callado(_ p: Pane) async -> Bool { await paneJS(p, "window.__fixture.allMuted()") == "true" }
        func soloSuena(_ i: Int) async -> Bool {
            for (j, p) in panes.enumerated() { if j == i ? !(await suena(p)) : !(await callado(p)) { return false } }
            return true
        }
        for i in [0, 1, 2] {
            g.setFocus(i); await settle()
            let ok = await soloSuena(i)
            check("tres paneles: con el foco en el panel \(i + 1) solo suena ese", ok)
        }
        // Siguiente panel recorre los tres y vuelve al primero
        g.setFocus(0)
        var recorrido: [Int] = []
        for _ in 0..<3 { g.nextPane(); recorrido.append(g.focused) }
        check("tres paneles: el siguiente panel recorre el segundo, el tercero y vuelve al primero", recorrido == [1, 2, 0], "recorrido \(recorrido)")
        await settle()
        // Un panel sin foco que reactiva el audio queda silenciado y el silencio manual no se revierte
        g.setFocus(0)
        do { try await load(panes[2], "unmutes.html") } catch { check("tres paneles: carga la página que reactiva el audio", false, "\(error)"); return }
        await settle(1.6)
        let intentos = Int(await paneJS(panes[2], "window.__fixture.unmuteAttempts()")) ?? 0
        let tercerCallado = await callado(panes[2])
        check("tres paneles: el tercer panel sin foco intentó reactivar el audio y sigue silenciado", intentos >= 1 && tercerCallado, "intentos \(intentos)")
        g.setFocus(1)
        _ = await paneJS(panes[1], "(window.__fixture.muteAll(), 1)")
        g.setFocus(0); await settle(); g.setFocus(2); await settle(); g.setFocus(1); await settle()
        let segundoCallado = await callado(panes[1])
        check("tres paneles: un silencio puesto a mano no se revierte al pasar el foco por los tres", segundoCallado)
        do { try await load(panes[2], "media.html") } catch { check("tres paneles: recarga la página de medios", false, "\(error)"); return }
        await settle()
        // Clic: el del panel sin foco solo da el foco
        func eventos(_ p: Pane) async -> Int { Int(await paneJS(p, "window.__fixture.mouseDowns()")) ?? -1 }
        g.setFocus(0)
        click(panes[2], in: host); await settle()
        let sinLlegar = await eventos(panes[2])
        check("tres paneles: el clic en un panel sin foco le pasa el foco y no llega a la página", g.focused == 2 && sinLlegar == 0, "foco \(g.focused), eventos \(sinLlegar)")
        click(panes[2], in: host); await settle()
        let llegado = await eventos(panes[2])
        check("tres paneles: el siguiente clic en ese panel sí llega a la página", llegado == 1, "eventos \(llegado)")

        // Cambio a vertical con los mismos paneles: orden, foco, tamaño y audio
        let tamanos = panes.map { $0.frame.size }
        let enfocado = g.focused
        host.setContentSize(NSSize(width: 640, height: 1080))
        g.layout = .vertical
        g.setFrameSize(NSSize(width: 640, height: 1080))
        g.layoutPanes()
        let f = panes.map { $0.frame }
        check("tres paneles: al pasar a vertical quedan en el mismo orden, de arriba abajo, sin hueco",
              f[0].maxY > f[1].maxY && f[1].maxY > f[2].maxY && close(f[0].minY - f[1].maxY, 0) && close(f[1].minY - f[2].maxY, 0) && close(f[0].maxY, 1080), "\(f)")
        check("tres paneles: al pasar a vertical cada panel conserva su tamaño (640×360)", tamanos.allSatisfy { close($0.width, 640) && close($0.height, 360) } && f.allSatisfy { close($0.width, 640) && close($0.height, 360) }, "\(tamanos) y \(f)")
        await settle()
        let mismoSuena = await soloSuena(enfocado)
        check("tres paneles: al pasar a vertical el foco sigue en el mismo panel y solo suena ese", g.focused == enfocado && mismoSuena)
        if debugMode {
            let log = (try? String(contentsOfFile: DebugLog.shared.path, encoding: .utf8)) ?? ""
            check("debug: el registro trae los eventos del tercer panel", log.contains("panel 3:"))
        }
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
        await checkThreePanes()
        checkShortcuts()
        checkSession()
        await checkReload()
        await checkDebug()
        print("")
        print("Comprobaciones: \(passed) pasaron, \(failed) fallaron.")
        print("Lo valida una persona: la sesión al reabrir, la segunda instancia y pegar una contraseña (5.2),")
        print("y el uso completo con dos partidos de Prime Video (6.3).")
        print("Aviso: la autoprueba no probó Prime Video; la reproducción y la apariencia requieren validación humana.")
        fflush(stdout)
        exit(failed == 0 && passed > 0 ? 0 : 1)
    }
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.run()
