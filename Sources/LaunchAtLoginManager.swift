import Foundation
import ServiceManagement

/// 管理 macOS 13+ 开机自动启动服务 (基于 SMAppService.mainApp)
public final class LaunchAtLoginManager {
    public static let shared = LaunchAtLoginManager()
    
    // MARK: - Properties
    
    /// 当前是否已配置开机自动启动
    public var isEnabled: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            }
            return false
        }
        set {
            if #available(macOS 13.0, *) {
                do {
                    if newValue {
                        if SMAppService.mainApp.status != .enabled {
                            try SMAppService.mainApp.register()
                        }
                    } else {
                        if SMAppService.mainApp.status == .enabled {
                            try SMAppService.mainApp.unregister()
                        }
                    }
                } catch {
                    NSLog("[LaunchAtLoginManager] 设置开机自启失败: \(error)")
                }
            }
        }
    }
    
    /// 获取当前自启状态描述
    public var statusDescription: String {
        if #available(macOS 13.0, *) {
            switch SMAppService.mainApp.status {
            case .enabled:
                return "已开启"
            case .requiresApproval:
                return "需系统设置批准"
            case .notFound:
                return "未找到应用服务"
            case .notRegistered:
                return "未开启"
            @unknown default:
                return "未知状态"
            }
        }
        return "不支持"
    }
}
