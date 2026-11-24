import MetalKit
import SwiftUI

enum VoiceViewportTurn: String {
    case idle, listening, speaking

    init(connected: Bool, paused: Bool, state: String, replaying: Bool = false) {
        if !connected || paused { self = .idle }
        else if replaying || state == "speaking" { self = .speaking }
        else if state == "thinking" { self = .idle }
        else { self = .listening }
    }
}

struct VoiceViewportPresentation {
    let live: LiveTutorService
    let turn: VoiceViewportTurn
}

var supportsVoiceNavigationBackground: Bool {
    if #available(iOS 18.0, *) { return true }
    return false
}

extension View {
    @ViewBuilder func voiceNavigationBackground(_ presentation: VoiceViewportPresentation) -> some View {
        if #available(iOS 18.0, *) {
            containerBackground(.clear, for: .navigation)
        } else {
            background { VoicePracticeBackground(presentation: presentation) }
        }
    }
}

/// The fixed web backdrop, shared by both voice surfaces and their dock.
struct VoicePracticeBackground: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    let presentation: VoiceViewportPresentation
    private var light: Bool { scheme != .dark }
    private var speaking: Bool { presentation.turn == .speaking }

    var body: some View {
        ZStack {
            LinearGradient(colors: (light ? ["fffdf9", "f8f2e8", "f3ebdf"] : ["030712", "0f172a", "030712"]).map(PiyaliBrand.unitColor),
                           startPoint: .top, endPoint: .bottom)
            Canvas { context, size in
                if light {
                    wash(context, size, "60a5fa", 0.10, 0.18, 0.82, 0.65 * 0.44, 0.48 * 0.44)
                    wash(context, size, "f97316", 0.10, 0.85, 0.12, 0.62 * 0.52, 0.46 * 0.52)
                    wash(context, size, "fbbf24", 0.18, 0.50, -0.1, 0.85 * 0.54, 0.58 * 0.54)
                } else {
                    wash(context, size, "a78bfa", 0.08, 0.1, 0.8, 0.50 * 0.40, 0.30 * 0.40)
                    wash(context, size, "0ea5e9", 0.10, 0.8, 1, 0.60 * 0.40, 0.40 * 0.40)
                    wash(context, size, "14b8a6", 0.15, 0.50, -0.2, 0.80 * 0.50, 0.50 * 0.50)
                }
            }
            Canvas { context, size in
                var grid = Path()
                for x in stride(from: CGFloat(0.5), to: size.width, by: 60) {
                    grid.move(to: CGPoint(x: x, y: 0))
                    grid.addLine(to: CGPoint(x: x, y: size.height))
                }
                for y in stride(from: CGFloat(0.5), to: size.height, by: 60) {
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(grid, with: .color(PiyaliBrand.unitColor(light ? "786043" : "14b8a6").opacity(light ? 0.045 : 0.03)), lineWidth: 1)
            }.mask {
                GeometryReader { geometry in
                    RadialGradient(colors: [.black, .clear], center: .center, startRadius: 0, endRadius: geometry.size.height / 2)
                        .scaleEffect(x: 0.8 * geometry.size.width / max(1, geometry.size.height / 2), y: 1)
                }
            }
            VoiceSpeakingWash(live: presentation.live, visible: speaking)
                .opacity(speaking ? 1 : 0)
                .animation(reducedMotion || scenePhase != .active ? nil : .timingCurve(0.22, 1, 0.36, 1, duration: 1.1), value: speaking)
        }.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
    }

    private func wash(_ context: GraphicsContext, _ size: CGSize, _ hex: String, _ opacity: Double,
                      _ x: CGFloat, _ y: CGFloat, _ radiusX: CGFloat, _ radiusY: CGFloat) {
        guard size.width > 0, size.height > 0 else { return }
        var layer = context
        layer.translateBy(x: size.width * x, y: size.height * y)
        layer.scaleBy(x: size.width * radiusX, y: size.height * radiusY)
        layer.fill(Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2)),
                   with: .radialGradient(Gradient(colors: [PiyaliBrand.unitColor(hex).opacity(opacity), .clear]),
                                         center: .zero, startRadius: 0, endRadius: 1))
    }
}

struct VoiceListeningRim: View {
    @ObservedObject var live: LiveTutorService
    let visible: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    @State private var began = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reducedMotion || !visible || scenePhase != .active)) { time in
            Canvas { context, size in
                let light = scheme != .dark
                let level = OrbVisuals.clamp(live.audioLevel)
                let seconds = reducedMotion ? 0 : time.date.timeIntervalSince(began)
                let edge = light ? 2.88 + level * 1.44 : 3.6 + level * 1.1
                let spread = light ? edge : 1.6 + level * 1.2
                let strength = light ? 1 : 0.56 + level * 0.44
                let deep = PiyaliBrand.unitColor(light ? "039b89" : "1656c1")
                let mid = PiyaliBrand.unitColor(light ? "74edc5" : "65c7ff")
                let pale = PiyaliBrand.unitColor(light ? "e6fff2" : "e0f8ff")
                for side in [Edge.top, .bottom, .leading, .trailing] {
                    draw(side, context, size, width: edge, spread: spread, drift: 0.008 * sin(seconds * .pi / 5.8),
                         deep: deep, mid: mid, pale: pale, strength: strength, light: light)
                }
            }
        }.ignoresSafeArea().opacity(visible ? 1 : 0)
            .animation(reducedMotion || scenePhase != .active ? nil : .easeInOut(duration: 0.75), value: visible)
            .allowsHitTesting(false).accessibilityHidden(true)
    }

    private func draw(_ side: Edge, _ context: GraphicsContext, _ size: CGSize, width: CGFloat, spread: CGFloat,
                      drift: CGFloat, deep: Color, mid: Color, pale: Color, strength: Double, light: Bool) {
        let horizontal = side == .top || side == .bottom
        let reverse = side == .bottom || side == .trailing
        let inwardLength = horizontal ? size.height : size.width
        let alongLength = horizontal ? size.width : size.height
        func point(_ along: CGFloat, _ inward: CGFloat) -> CGPoint {
            let position = reverse ? inwardLength - inward : inward
            return horizontal ? CGPoint(x: along, y: position) : CGPoint(x: position, y: along)
        }
        func strip(_ thickness: CGFloat) -> Path {
            Path(CGRect(origin: point(0, reverse ? thickness : 0),
                        size: horizontal ? CGSize(width: alongLength, height: thickness) : CGSize(width: thickness, height: alongLength)))
        }
        let halo = width + spread * 3.2
        context.fill(strip(halo), with: .linearGradient(Gradient(stops: [
            .init(color: deep.opacity(0.44 * strength), location: 0),
            .init(color: mid.opacity(0.23 * strength), location: 0.35),
            .init(color: .clear, location: 1)
        ]), startPoint: point(0, 0), endPoint: point(0, halo)))
        let mintHighlight = PiyaliBrand.unitColor("85ebc8")
        let colors: [Color]
        let positions: [CGFloat]
        if light {
            colors = [deep, mid, mintHighlight, mid, deep]
            positions = [0, 0.2, 0.5, 0.8, 1]
        } else if horizontal {
            colors = [deep, mid, pale, mid, deep]
            positions = [0, 0.16, 0.58, 0.78, 1]
        } else {
            colors = [pale, mid, deep, mid, deep]
            positions = [0, 0.26, 0.52, 0.76, 1]
        }
        let rim = Gradient(stops: zip(colors, positions).map { .init(color: $0.0.opacity(strength), location: $0.1) })
        let innerWidth = light ? width : width - 1.5
        context.fill(strip(innerWidth), with: .linearGradient(rim, startPoint: point(alongLength * drift, 0),
                                                             endPoint: point(alongLength * (1 + drift), 0)))
    }
}

private struct VoiceSpeakingWash: UIViewRepresentable {
    @ObservedObject var live: LiveTutorService
    let visible: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reducedMotion

    func makeUIView(context: Context) -> VoiceAtmosphereHost { VoiceAtmosphereHost() }
    func updateUIView(_ view: VoiceAtmosphereHost, context: Context) {
        view.update(light: scheme != .dark, level: live.audioLevel, visible: visible,
                    animated: !reducedMotion && scenePhase == .active)
    }
}

/// The palette field is compiled on the device, using the same resource path
/// as the native orb shaders. Both layers stay mounted across turn changes.
private enum VoiceAtmosphereMetal {
    static let gpu = MTLCreateSystemDefaultDevice()
    static let pipeline = Task.detached(priority: .utility) { () -> MTLRenderPipelineState? in
        guard let gpu, let url = Bundle.main.url(forResource: "voice-atmosphere", withExtension: "shader"),
              let source = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        do {
            let library = try gpu.makeLibrary(source: source, options: nil)
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: "voiceAtmosphereVertex")
            descriptor.fragmentFunction = library.makeFunction(name: "voiceAtmosphereFragment")
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            return try gpu.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            NSLog("Voice atmosphere shader: %@", error.localizedDescription)
            return nil
        }
    }
}

private final class VoiceAtmosphereHost: MTKView, MTKViewDelegate {
    private var queue: MTLCommandQueue?
    private var pipeline: MTLRenderPipelineState?
    private var pipelineTask: Task<Void, Never>?
    private var field = VoiceAtmosphereMotion()
    private var lastFrame: CFTimeInterval?
    private var level = 0.0
    private var light = true
    private var animated = false
    private var shown = false

    init() {
        super.init(frame: .zero, device: VoiceAtmosphereMetal.gpu)
        isOpaque = false
        layer.isOpaque = false
        backgroundColor = .clear
        clearColor = MTLClearColorMake(0, 0, 0, 0)
        colorPixelFormat = .bgra8Unorm
        isUserInteractionEnabled = false
        preferredFramesPerSecond = 30
        autoResizeDrawable = false
        enableSetNeedsDisplay = true
        isPaused = true
        queue = device?.makeCommandQueue()
        delegate = self
    }

    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        let height = bounds.height
        guard width > 0, height > 0 else { return }
        let scale = min(window?.screen.scale ?? 1, 900 / max(width, height))
        let size = CGSize(width: (width * scale).rounded(), height: (height * scale).rounded())
        if drawableSize != size { drawableSize = size; setNeedsDisplay() }
    }

    func update(light: Bool, level: Double, visible: Bool, animated: Bool) {
        let refresh = shown != visible || self.light != light || self.animated != animated
        if shown != visible || self.animated != animated { lastFrame = nil }
        self.light = light
        self.level = level
        self.animated = animated
        shown = visible

        if shown, pipeline == nil, pipelineTask == nil {
            pipelineTask = Task { [weak self] in
                let pipeline = await VoiceAtmosphereMetal.pipeline.value
                guard let self else { return }
                self.pipeline = pipeline
                syncDrawing()
                setNeedsDisplay()
            }
        }
        syncDrawing()
        if refresh { setNeedsDisplay() }
    }

    private func syncDrawing() {
        let moving = shown && animated && pipeline != nil
        if isPaused == moving {
            isPaused = !moving
            enableSetNeedsDisplay = !moving
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let pipeline, let drawable = currentDrawable, let pass = currentRenderPassDescriptor,
              let commands = queue?.makeCommandBuffer(),
              let encoder = commands.makeRenderCommandEncoder(descriptor: pass) else { return }
        if shown && animated {
            let now = CACurrentMediaTime()
            field.advance(level: level, elapsed: lastFrame.map { now - $0 } ?? 0)
            lastFrame = now
        }
        var values = [Float(field.time), light ? 1 : 0, Float(drawableSize.width / max(1, drawableSize.height)),
                      Float(field.activity), Float(field.speechOffset), Float(field.travel)]
        encoder.setRenderPipelineState(pipeline)
        values.withUnsafeMutableBytes { buffer in
            if let address = buffer.baseAddress { encoder.setFragmentBytes(address, length: buffer.count, index: 0) }
        }
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        commands.present(drawable)
        commands.commit()
    }
}

private struct VoiceAtmosphereMotion {
    private(set) var time = 0.0
    private(set) var activity = 0.0
    private(set) var speechOffset = 0.0
    private(set) var travel = 0.0
    private var reach = 0.0

    mutating func advance(level: Double, elapsed: TimeInterval) {
        let dt = min(0.1, max(0, elapsed))
        let target = OrbVisuals.clamp(level)
        activity += (target - activity) * (1 - exp(-dt / (target > activity ? 0.055 : 0.10)))
        reach += (target - reach) * (1 - exp(-dt / (target > reach ? 0.55 : 1.2)))
        speechOffset = tanh((activity - reach) * 4) * 0.10
        time += dt * 2
        travel += dt * (0.28 + activity * 0.90)
    }
}
