import Cocoa

/// 负责 macOS 菜单栏状态图标 (NSStatusItem) 及下拉菜单 (NSMenu) 的展示与交互
public final class MenuController: NSObject, NSMenuDelegate {
    // MARK: - UI Components
    
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    
    private let todayCountMenuItem = NSMenuItem()
    private let permissionMenuItem = NSMenuItem()
    private let resetMenuItem = NSMenuItem()
    private let aboutMenuItem = NSMenuItem()
    private let quitMenuItem = NSMenuItem()
    
    // MARK: - Formatters
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter
    }()
    
    // MARK: - Callbacks
    
    public var onRequestPermission: (() -> Void)?
    public var onResetCount: (() -> Void)?
    
    // MARK: - Initializer
    
    public override init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        
        setupMenu()
        updateCount(0)
        updatePermissionStatus(isTrusted: KeystrokeMonitor.isAccessibilityTrusted())
    }
    
    // MARK: - Setup
    
    private func setupMenu() {
        menu.delegate = self
        
        // 1. 今日击键详情展示项
        todayCountMenuItem.isEnabled = false
        menu.addItem(todayCountMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 2. 权限状态展示项
        permissionMenuItem.target = self
        permissionMenuItem.action = #selector(handlePermissionClick)
        menu.addItem(permissionMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 3. 重置今日计数
        resetMenuItem.title = "重置今日计数"
        resetMenuItem.target = self
        resetMenuItem.action = #selector(handleResetCountClick)
        menu.addItem(resetMenuItem)
        
        // 4. 关于 TypeJoy
        aboutMenuItem.title = "关于 TypeJoy"
        aboutMenuItem.target = self
        aboutMenuItem.action = #selector(handleAboutClick)
        menu.addItem(aboutMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 5. 退出
        quitMenuItem.title = "退出 TypeJoy"
        quitMenuItem.target = self
        quitMenuItem.action = #selector(handleQuitClick)
        quitMenuItem.keyEquivalent = "q"
        menu.addItem(quitMenuItem)
        
        statusItem.menu = menu
    }
    
    // MARK: - Public Updaters
    
    /// 更新击键统计数值
    public func updateCount(_ count: Int) {
        let formatted = formatNumber(count)
        
        // 更新菜单栏标题
        if let button = statusItem.button {
            button.title = "⌨️ \(formatted)"
            button.toolTip = "TypeJoy - 今日击键 \(formatted) 次"
        }
        
        // 更新下拉菜单项
        todayCountMenuItem.title = "今日击键：\(formatted) 次"
    }
    
    /// 更新辅助功能权限显示
    public func updatePermissionStatus(isTrusted: Bool) {
        if isTrusted {
            permissionMenuItem.title = "✓ 辅助功能权限：已授权"
            permissionMenuItem.isEnabled = false
        } else {
            permissionMenuItem.title = "⚠️ 辅助功能权限：未授权 (点击授权)"
            permissionMenuItem.isEnabled = true
        }
    }
    
    // MARK: - NSMenuDelegate
    
    public func menuWillOpen(_ menu: NSMenu) {
        // 每次菜单打开时，实时同步一次权限状态
        let isTrusted = KeystrokeMonitor.isAccessibilityTrusted()
        updatePermissionStatus(isTrusted: isTrusted)
    }
    
    // MARK: - Actions
    
    @objc private func handlePermissionClick() {
        onRequestPermission?()
    }
    
    @objc private func handleResetCountClick() {
        let alert = NSAlert()
        alert.messageText = "重置今日击键计数"
        alert.informativeText = "确定要将今天的击键次数重置为 0 吗？此操作不可撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定重置")
        alert.addButton(withTitle: "取消")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            onResetCount?()
        }
    }
    
    @objc private func handleAboutClick() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "TypeJoy (字得其乐)"
        alert.informativeText = """
        版本：1.0.0 (Milestone 2)
        专为创作者打造的 macOS 极简常驻菜单栏击键统计与写作激励工具。
        
        • 0 按键内容采集，严格保护隐私
        • 轻量常驻菜单栏，零干扰
        
        GitHub: github.com/abstractwind/TypeJoy
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好")
        alert.runModal()
    }
    
    @objc private func handleQuitClick() {
        NSApp.terminate(nil)
    }
    
    // MARK: - Helpers
    
    private func formatNumber(_ number: Int) -> String {
        return numberFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
