import Cocoa

/// 应用程序生命周期代理，协调各个模块组件的生命周期与通信
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statsManager = StatsManager()
    private let monitor = KeystrokeMonitor()
    private var menuController: MenuController?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置应用为 Accessory 模式（常驻菜单栏，不在 Dock 栏显示）
        NSApp.setActivationPolicy(.accessory)
        
        // 初始化菜单栏控制器
        let menuCtrl = MenuController()
        self.menuController = menuCtrl
        
        // 绑定回调：菜单中点击授权辅助功能
        menuCtrl.onRequestPermission = { [weak self] in
            self?.monitor.promptAndOpenPermissionSettings()
        }
        
        // 绑定回调：菜单中重置今日计数
        menuCtrl.onResetCount = { [weak self] in
            self?.statsManager.resetToday()
        }
        
        // 绑定回调：修改里程碑步长
        menuCtrl.onMilestoneIntervalChanged = { [weak self] interval in
            self?.statsManager.setMilestoneInterval(interval)
        }
        
        // 绑定回调：击键次数变更 -> 刷新菜单栏展示
        statsManager.onCountChanged = { [weak menuCtrl] count in
            menuCtrl?.updateCount(count)
        }
        
        // 绑定回调：达成里程碑 -> 播放金币音效 + 弹出毛玻璃 HUD 庆祝浮窗
        statsManager.onMilestoneReached = { count, estimatedCharsText in
            SoundManager.shared.playCoinSound()
            CelebrationHUDWindow.shared.showCelebration(count: count, estimatedCharsText: estimatedCharsText)
        }
        
        // 绑定回调：历史数据归档更新 -> 刷新下拉历史菜单
        statsManager.onHistoryChanged = { [weak menuCtrl] history in
            menuCtrl?.updateHistory(history)
        }
        
        // 绑定回调：监听到有效击键 -> 统计计数递增
        monitor.onKeystroke = { [weak self] in
            self?.statsManager.incrementCount()
        }
        
        // 绑定回调：权限状态变更 -> 刷新菜单中权限项
        monitor.onPermissionStatusChanged = { [weak menuCtrl] isTrusted in
            menuCtrl?.updatePermissionStatus(isTrusted: isTrusted)
        }
        
        // 加载初始状态
        let initialCount = statsManager.todayCount
        menuCtrl.updateCount(initialCount)
        menuCtrl.updateHistory(statsManager.historyRecords)
        menuCtrl.updateMilestoneInterval(statsManager.milestoneInterval)
        menuCtrl.updatePermissionStatus(isTrusted: KeystrokeMonitor.isAccessibilityTrusted())
        
        // 启动全局击键监听
        monitor.startMonitoring()
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        monitor.stopMonitoring()
    }
}
