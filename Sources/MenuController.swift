import Cocoa

/// 负责 macOS 菜单栏状态图标 (NSStatusItem) 及下拉菜单 (NSMenu) 的展示与交互
public final class MenuController: NSObject, NSMenuDelegate {
    // MARK: - UI Components
    
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    
    // 双指标展示项
    private let todayCountMenuItem = NSMenuItem()
    private let estimatedCharsMenuItem = NSMenuItem()
    
    // 历史归档子菜单
    private let historyMenuItem = NSMenuItem()
    private let historySubmenu = NSMenu()
    
    // 设置项
    private let launchAtLoginMenuItem = NSMenuItem()
    private let soundToggleMenuItem = NSMenuItem()
    private let milestoneStepMenuItem = NSMenuItem()
    private let milestoneSubmenu = NSMenu()
    private let step500MenuItem = NSMenuItem()
    private let step1000MenuItem = NSMenuItem()
    
    // 权限与常规菜单
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
    public var onMilestoneIntervalChanged: ((Int) -> Void)?
    
    // MARK: - State Cache
    
    private var currentInterval: Int = 500
    
    // MARK: - Initializer
    
    public override init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        
        setupMenu()
        updateCount(0)
        updatePermissionStatus(isTrusted: KeystrokeMonitor.isAccessibilityTrusted())
        updateHistory([])
    }
    
    // MARK: - Setup
    
    private func setupMenu() {
        menu.delegate = self
        
        // 1. 双指标展示项：今日击键 + 预估汉字
        todayCountMenuItem.isEnabled = false
        menu.addItem(todayCountMenuItem)
        
        estimatedCharsMenuItem.isEnabled = false
        menu.addItem(estimatedCharsMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 2. 最近 7 天打卡记录
        historyMenuItem.title = "📅 最近 7 天打卡记录"
        historyMenuItem.submenu = historySubmenu
        menu.addItem(historyMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 3. 偏好设置
        // 3.1 开机自启
        launchAtLoginMenuItem.title = "开机自动启动"
        launchAtLoginMenuItem.target = self
        launchAtLoginMenuItem.action = #selector(handleLaunchAtLoginClick)
        menu.addItem(launchAtLoginMenuItem)
        
        // 3.2 金币音效提醒
        soundToggleMenuItem.title = "金币音效庆祝"
        soundToggleMenuItem.target = self
        soundToggleMenuItem.action = #selector(handleSoundToggleClick)
        menu.addItem(soundToggleMenuItem)
        
        // 3.3 里程碑阶梯设置
        milestoneStepMenuItem.title = "里程碑庆祝间隔"
        step500MenuItem.title = "每 500 键庆祝一次"
        step500MenuItem.tag = 500
        step500MenuItem.target = self
        step500MenuItem.action = #selector(handleMilestoneStepClick(_:))
        
        step1000MenuItem.title = "每 1,000 键庆祝一次"
        step1000MenuItem.tag = 1000
        step1000MenuItem.target = self
        step1000MenuItem.action = #selector(handleMilestoneStepClick(_:))
        
        milestoneSubmenu.addItem(step500MenuItem)
        milestoneSubmenu.addItem(step1000MenuItem)
        milestoneStepMenuItem.submenu = milestoneSubmenu
        menu.addItem(milestoneStepMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 4. 权限状态展示项
        permissionMenuItem.target = self
        permissionMenuItem.action = #selector(handlePermissionClick)
        menu.addItem(permissionMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 5. 重置今日计数
        resetMenuItem.title = "重置今日计数"
        resetMenuItem.target = self
        resetMenuItem.action = #selector(handleResetCountClick)
        menu.addItem(resetMenuItem)
        
        // 6. 关于 TypeJoy
        aboutMenuItem.title = "关于 TypeJoy"
        aboutMenuItem.target = self
        aboutMenuItem.action = #selector(handleAboutClick)
        menu.addItem(aboutMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 7. 退出
        quitMenuItem.title = "退出 TypeJoy"
        quitMenuItem.target = self
        quitMenuItem.action = #selector(handleQuitClick)
        quitMenuItem.keyEquivalent = "q"
        menu.addItem(quitMenuItem)
        
        statusItem.menu = menu
    }
    
    // MARK: - Public Updaters
    
    /// 更新击键统计数值及折算汉字
    public func updateCount(_ count: Int) {
        let formatted = formatNumber(count)
        let estimateText = ChineseEstimator.formattedEstimate(keystrokes: count)
        
        // 更新菜单栏标题
        if let button = statusItem.button {
            button.title = "⌨️ \(formatted)"
            button.toolTip = "TypeJoy - 今日击键 \(formatted) 次 (\(estimateText))"
        }
        
        // 更新下拉菜单项
        todayCountMenuItem.title = "今日击键：\(formatted) 次"
        estimatedCharsMenuItem.title = "✍️ 预估汉字：\(estimateText)"
    }
    
    /// 更新最近 7 天历史归档子菜单
    public func updateHistory(_ records: [DailyRecord]) {
        historySubmenu.removeAllItems()
        
        if records.isEmpty {
            let emptyItem = NSMenuItem(title: "(暂无历史记录)", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            historySubmenu.addItem(emptyItem)
        } else {
            for record in records {
                let formattedCount = formatNumber(record.count)
                let estimateText = ChineseEstimator.formattedEstimate(keystrokes: record.count)
                let title = "\(record.date): \(formattedCount) 次 (\(estimateText))"
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.isEnabled = false
                historySubmenu.addItem(item)
            }
        }
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
    
    /// 更新当前配置的里程碑步长
    public func updateMilestoneInterval(_ interval: Int) {
        currentInterval = interval
        step500MenuItem.state = (interval == 500) ? .on : .off
        step1000MenuItem.state = (interval == 1000) ? .on : .off
    }
    
    // MARK: - NSMenuDelegate
    
    public func menuWillOpen(_ menu: NSMenu) {
        // 每次菜单展开时同步状态
        let isTrusted = KeystrokeMonitor.isAccessibilityTrusted()
        updatePermissionStatus(isTrusted: isTrusted)
        
        // 同步开机自启复选标记
        launchAtLoginMenuItem.state = LaunchAtLoginManager.shared.isEnabled ? .on : .off
        
        // 同步音效复选标记
        soundToggleMenuItem.state = (!SoundManager.shared.isMuted) ? .on : .off
        
        // 同步里程碑单选标记
        step500MenuItem.state = (currentInterval == 500) ? .on : .off
        step1000MenuItem.state = (currentInterval == 1000) ? .on : .off
    }
    
    // MARK: - Actions
    
    @objc private func handleLaunchAtLoginClick() {
        let willEnable = !LaunchAtLoginManager.shared.isEnabled
        LaunchAtLoginManager.shared.isEnabled = willEnable
        launchAtLoginMenuItem.state = willEnable ? .on : .off
    }
    
    @objc private func handleSoundToggleClick() {
        let currentlyMuted = SoundManager.shared.isMuted
        SoundManager.shared.isMuted = !currentlyMuted
        soundToggleMenuItem.state = currentlyMuted ? .on : .off
        
        // 如果开启声音，播放一次金币声反馈
        if currentlyMuted {
            SoundManager.shared.playCoinSound()
        }
    }
    
    @objc private func handleMilestoneStepClick(_ sender: NSMenuItem) {
        let step = sender.tag
        currentInterval = step
        updateMilestoneInterval(step)
        onMilestoneIntervalChanged?(step)
    }
    
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
        版本：1.0.0
        专为创作者打造的 macOS 极简常驻菜单栏击键统计与写作激励工具。
        
        • 0 按键内容采集，严格保护隐私
        • 双指标模式：击键 + 智能汉字折算
        • 马里奥金币音效与毛玻璃 HUD 庆祝
        • 每日 00:00 自动记录与 7 天打卡回顾
        • 支持开机自动启动，常驻菜单栏
        
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
