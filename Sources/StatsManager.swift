import Foundation

/// 管理击键统计数据的持久化与状态
public final class StatsManager {
    // MARK: - Constants
    
    private let defaults: UserDefaults
    private let dateKey = "TypeJoy_CurrentDate"
    private let countKey = "TypeJoy_TodayKeystrokeCount"
    
    // MARK: - Properties
    
    private let lock = NSLock()
    private var _todayCount: Int = 0
    
    /// 今日击键总数
    public var todayCount: Int {
        lock.lock()
        defer { lock.unlock() }
        ensureCurrentDay()
        return _todayCount
    }
    
    /// 击键计数更新回调 (主线程执行)
    public var onCountChanged: ((Int) -> Void)?
    
    // MARK: - Initializer
    
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadPersistedData()
    }
    
    // MARK: - Public Methods
    
    /// 增加击键计数
    public func incrementCount(by amount: Int = 1) {
        lock.lock()
        ensureCurrentDay()
        _todayCount += amount
        let current = _todayCount
        defaults.set(current, forKey: countKey)
        lock.unlock()
        
        DispatchQueue.main.async { [weak self] in
            self?.onCountChanged?(current)
        }
    }
    
    /// 重置今日数据 (用于测试或手动清零)
    public func resetToday() {
        lock.lock()
        _todayCount = 0
        defaults.set(0, forKey: countKey)
        defaults.set(todayDateString(), forKey: dateKey)
        lock.unlock()
        
        DispatchQueue.main.async { [weak self] in
            self?.onCountChanged?(0)
        }
    }
    
    // MARK: - Private Methods
    
    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }
    
    private func loadPersistedData() {
        lock.lock()
        defer { lock.unlock() }
        
        let today = todayDateString()
        let savedDate = defaults.string(forKey: dateKey)
        
        if savedDate == today {
            _todayCount = defaults.integer(forKey: countKey)
        } else {
            // 跨天或首次运行，初始化为 0
            _todayCount = 0
            defaults.set(0, forKey: countKey)
            defaults.set(today, forKey: dateKey)
        }
    }
    
    /// 检查是否发生跨天，若跨天则自动清零
    private func ensureCurrentDay() {
        let today = todayDateString()
        let savedDate = defaults.string(forKey: dateKey)
        if savedDate != today {
            _todayCount = 0
            defaults.set(0, forKey: countKey)
            defaults.set(today, forKey: dateKey)
        }
    }
}
