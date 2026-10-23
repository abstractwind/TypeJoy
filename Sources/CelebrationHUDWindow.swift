import Cocoa

/// 专用于击键里程碑达成的轻量级非激活半透明毛玻璃 HUD 庆祝浮窗
public final class CelebrationHUDWindow: NSPanel {
    public static let shared = CelebrationHUDWindow()
    
    // MARK: - UI Elements
    
    private let visualEffectView = NSVisualEffectView()
    private let iconLabel = NSTextField(labelWithString: "🪙")
    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    
    private var dismissTimer: Timer?
    
    // MARK: - Initializer
    
    public init() {
        let contentRect = NSRect(x: 0, y: 0, width: 280, height: 74)
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        setupWindowAttributes()
        setupViews()
    }
    
    // MARK: - Setup
    
    private func setupWindowAttributes() {
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        ignoresMouseEvents = true // 点击穿透，绝不干扰用户当前正在打字的窗口与光标
    }
    
    private func setupViews() {
        visualEffectView.frame = contentView?.bounds ?? .zero
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 18
        visualEffectView.layer?.masksToBounds = true
        visualEffectView.layer?.borderWidth = 1.0
        visualEffectView.layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor
        
        // 布局元素
        iconLabel.font = NSFont.systemFont(ofSize: 32)
        iconLabel.alignment = .center
        iconLabel.frame = NSRect(x: 16, y: 16, width: 40, height: 42)
        
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        titleLabel.textColor = .labelColor
        titleLabel.frame = NSRect(x: 64, y: 38, width: 200, height: 20)
        
        subtitleLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.frame = NSRect(x: 64, y: 16, width: 200, height: 18)
        
        visualEffectView.addSubview(iconLabel)
        visualEffectView.addSubview(titleLabel)
        visualEffectView.addSubview(subtitleLabel)
        
        contentView?.addSubview(visualEffectView)
    }
    
    // MARK: - Presentation
    
    /// 弹出里程碑庆祝气泡
    /// - Parameters:
    ///   - count: 达成的击键次数 (如 500)
    ///   - estimatedCharsText: 预估字数文案 (如 "约 150 ~ 165 字")
    public func showCelebration(count: Int, estimatedCharsText: String) {
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let countStr = formatter.string(from: NSNumber(value: count)) ?? "\(count)"
        
        titleLabel.stringValue = "🎉 达成 \(countStr) 次击键！"
        subtitleLabel.stringValue = "✍️ 预估汉字：\(estimatedCharsText)"
        
        // 定位到主屏幕右上角
        if let screen = NSScreen.main {
            let visibleFrame = screen.visibleFrame
            let x = visibleFrame.maxX - frame.width - 24
            let y = visibleFrame.maxY - frame.height - 16
            setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        alphaValue = 0.0
        orderFront(nil)
        
        // 淡入动画
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1.0
        }
        
        // 停留 2.0 秒后自动淡出并隐藏
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.4
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                self.animator().alphaValue = 0.0
            }, completionHandler: {
                if self.alphaValue == 0.0 {
                    self.orderOut(nil)
                }
            })
        }
    }
}
