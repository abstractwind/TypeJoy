import Cocoa
import ApplicationServices

/// 负责全局击键事件监听与 macOS 辅助功能 (Accessibility) 权限管理
public final class KeystrokeMonitor {
    // MARK: - Properties
    
    private var globalMonitor: Any?
    private var permissionPollTimer: Timer?
    private var wasTrusted: Bool = false
    
    /// 当监听到合法击键时触发
    public var onKeystroke: (() -> Void)?
    
    /// 辅助功能权限状态发生变化时的回调
    public var onPermissionStatusChanged: ((Bool) -> Void)?
    
    // MARK: - Initializer & Deinitializer
    
    public init() {
        self.wasTrusted = Self.isAccessibilityTrusted()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Permission Checking & Requesting
    
    /// 检查当前进程是否已被授予辅助功能权限
    public static func isAccessibilityTrusted() -> Bool {
        return AXIsProcessTrusted()
    }
    
    /// 弹出系统辅助功能授权确认弹窗
    public static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    /// 打开系统偏好设置 / 系统设置中的「辅助功能」权限面板
    public static func openAccessibilityPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// 弹出系统弹窗并唤起系统设置页面
    public func promptAndOpenPermissionSettings() {
        Self.requestAccessibilityPermission()
        Self.openAccessibilityPreferences()
    }
    
    // MARK: - Monitoring Controls
    
    /// 启动按键监听
    public func startMonitoring() {
        let isTrusted = Self.isAccessibilityTrusted()
        wasTrusted = isTrusted
        
        if isTrusted {
            registerGlobalMonitor()
        } else {
            // 未授权时启动轮询定时器，在用户于系统设置授权后自动开始监听
            startPermissionPolling()
        }
    }
    
    /// 停止按键监听并清理定时器
    public func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        stopPermissionPolling()
    }
    
    // MARK: - Private Methods
    
    private func registerGlobalMonitor() {
        guard globalMonitor == nil else { return }
        
        // 注册全局击键监听器
        // 纯粹计数：绝不读取或记录 event.characters 或任何按键内容，完全零隐私侵犯
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            // 过滤长按连击产生的重复事件 (Key Repeat)
            guard !event.isARepeat else { return }
            self?.onKeystroke?()
        }
    }
    
    private func startPermissionPolling() {
        guard permissionPollTimer == nil else { return }
        
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let trusted = Self.isAccessibilityTrusted()
            if trusted != self.wasTrusted {
                self.wasTrusted = trusted
                self.onPermissionStatusChanged?(trusted)
                
                if trusted {
                    self.stopPermissionPolling()
                    self.registerGlobalMonitor()
                }
            }
        }
    }
    
    private func stopPermissionPolling() {
        permissionPollTimer?.invalidate()
        permissionPollTimer = nil
    }
}
