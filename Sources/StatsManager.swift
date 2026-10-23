import Foundation

/// 单日击键历史记录数据结构
public struct DailyRecord: Codable, Equatable {
    public let date: String // "yyyy-MM-dd"
    public let count: Int
    
    public init(date: String, count: Int) {
        self.date = date
        self.count = count
    }
}

/// 管理击键统计数据的持久化、里程碑触发以及最近 7 天历史归档
public final class StatsManager {
    // MARK: - Constants
    
    private let defaults: UserDefaults
    private let dateKey = "TypeJoy_CurrentDate"
    private let countKey = "TypeJoy_TodayKeystrokeCount"
    private let historyKey = "TypeJoy_HistoryRecords"
    private let milestoneIntervalKey = "TypeJoy_MilestoneInterval"
    private let lastMilestoneKey = "TypeJoy_LastCelebratedMilestone"
    
    // MARK: - Properties
    
    private let lock = NSLock()
    private var _todayCount: Int = 0
    private var _lastCelebratedMilestone: Int = 0
    private var _historyRecords: [DailyRecord] = []
    
    /// 今日击键总数
    public var todayCount: Int {
        lock.lock()
        defer { lock.unlock() }
        ensureCurrentDay()
        return _todayCount
    }
    
    /// 里程碑触发步长 (默认 500)
    public var milestoneInterval: Int {
        get {
            let val = defaults.integer(forKey: milestoneIntervalKey)
            return val > 0 ? val : 500
        }
        set {
            defaults.set(newValue, forKey: milestoneIntervalKey)
        }
    }
    
    /// 最近 7 天打卡记录列表 (按日期降序排列)
    public var historyRecords: [DailyRecord] {
        lock.lock()
        defer { lock.unlock() }
        ensureCurrentDay()
        return _historyRecords
    }
    
    // MARK: - Callbacks
    
    /// 击键计数更新回调 (主线程执行)
    public var onCountChanged: ((Int) -> Void)?
    
    /// 达成击键里程碑回调 (主线程执行，提供达成次数及预估字数文案)
    public var onMilestoneReached: ((_ count: Int, _ estimatedCharsText: String) -> Void)?
    
    /// 历史归档数据更新回调 (主线程执行)
    public var onHistoryChanged: (([DailyRecord]) -> Void)?
    
    // MARK: - Initializer & Deinitializer
    
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadPersistedData()
        
        // 注册系统级跨天通知监听 (每天 00:00 自动触发)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCalendarDayChanged),
            name: .NSCalendarDayChanged,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// 增加击键计数
    public func incrementCount(by amount: Int = 1) {
        lock.lock()
        ensureCurrentDay()
        _todayCount += amount
        let current = _todayCount
        defaults.set(current, forKey: countKey)
        
        // 检测是否触发里程碑
        let interval = milestoneInterval
        let milestoneReached = (current / interval) * interval
        var shouldTriggerCelebration = false
        var reachedCount = 0
        var estimateText = ""
        
        if milestoneReached > _lastCelebratedMilestone && milestoneReached > 0 {
            _lastCelebratedMilestone = milestoneReached
            defaults.set(_lastCelebratedMilestone, forKey: lastMilestoneKey)
            shouldTriggerCelebration = true
            reachedCount = milestoneReached
            estimateText = ChineseEstimator.formattedEstimate(keystrokes: milestoneReached)
        }
        
        lock.unlock()
        
        DispatchQueue.main.async { [weak self] in
            self?.onCountChanged?(current)
            if shouldTriggerCelebration {
                self?.onMilestoneReached?(reachedCount, estimateText)
            }
        }
    }
    
    /// 重置今日数据 (用于测试或手动清零)
    public func resetToday() {
        lock.lock()
        _todayCount = 0
        _lastCelebratedMilestone = 0
        defaults.set(0, forKey: countKey)
        defaults.set(0, forKey: lastMilestoneKey)
        defaults.set(todayDateString(), forKey: dateKey)
        lock.unlock()
        
        DispatchQueue.main.async { [weak self] in
            self?.onCountChanged?(0)
        }
    }
    
    /// 设置新的里程碑步长
    public func setMilestoneInterval(_ interval: Int) {
        lock.lock()
        milestoneInterval = interval
        // 同步重设最后达成的里程碑为当前对应的区间，防止步长缩小时异常暴击
        _lastCelebratedMilestone = (_todayCount / interval) * interval
        defaults.set(_lastCelebratedMilestone, forKey: lastMilestoneKey)
        lock.unlock()
    }
    
    // MARK: - Notifications
    
    @objc private func handleCalendarDayChanged() {
        lock.lock()
        ensureCurrentDay()
        let count = _todayCount
        let history = _historyRecords
        lock.unlock()
        
        DispatchQueue.main.async { [weak self] in
            self?.onCountChanged?(count)
            self?.onHistoryChanged?(history)
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
        
        // 加载历史记录
        if let data = defaults.data(forKey: historyKey),
           let list = try? JSONDecoder().decode([DailyRecord].self, from: data) {
            _historyRecords = list
        } else {
            _historyRecords = []
        }
        
        let today = todayDateString()
        let savedDate = defaults.string(forKey: dateKey)
        
        if savedDate == today {
            _todayCount = defaults.integer(forKey: countKey)
            _lastCelebratedMilestone = defaults.integer(forKey: lastMilestoneKey)
        } else {
            // 归档旧的一天并重置
            archiveOldDateIfNeeded(savedDate: savedDate)
            _todayCount = 0
            _lastCelebratedMilestone = 0
            defaults.set(0, forKey: countKey)
            defaults.set(0, forKey: lastMilestoneKey)
            defaults.set(today, forKey: dateKey)
        }
    }
    
    /// 检查是否发生跨天，若跨天则自动归档并清零
    private func ensureCurrentDay() {
        let today = todayDateString()
        let savedDate = defaults.string(forKey: dateKey)
        if savedDate != today {
            archiveOldDateIfNeeded(savedDate: savedDate)
            _todayCount = 0
            _lastCelebratedMilestone = 0
            defaults.set(0, forKey: countKey)
            defaults.set(0, forKey: lastMilestoneKey)
            defaults.set(today, forKey: dateKey)
        }
    }
    
    private func archiveOldDateIfNeeded(savedDate: String?) {
        guard let savedDate = savedDate, !savedDate.isEmpty else { return }
        let savedCount = defaults.integer(forKey: countKey)
        
        if savedCount > 0 {
            // 移除同日已有记录，放入最新记录
            _historyRecords.removeAll { $0.date == savedDate }
            _historyRecords.insert(DailyRecord(date: savedDate, count: savedCount), at: 0)
            
            // 仅保留最近 7 天
            if _historyRecords.count > 7 {
                _historyRecords = Array(_historyRecords.prefix(7))
            }
            
            if let data = try? JSONEncoder().encode(_historyRecords) {
                defaults.set(data, forKey: historyKey)
            }
        }
    }
}
