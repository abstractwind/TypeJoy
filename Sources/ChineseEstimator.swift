import Foundation

/// 汉字打字量智能折算器 (基于中文全拼/双拼常见键字比约 3.0 ~ 3.3 键/字)
public struct ChineseEstimator {
    /// 计算击键次数对应的预估汉字范围 (min, max)
    public static func estimateRange(keystrokes: Int) -> (min: Int, max: Int) {
        guard keystrokes > 0 else { return (0, 0) }
        let minChars = Int(Double(keystrokes) / 3.3)
        let maxChars = Int(Double(keystrokes) / 3.0)
        return (minChars, max(minChars, maxChars))
    }
    
    /// 格式化汉字预估文案，如 "约 150 ~ 165 字"
    public static func formattedEstimate(keystrokes: Int) -> String {
        let (minChars, maxChars) = estimateRange(keystrokes: keystrokes)
        if minChars == 0 && maxChars == 0 {
            return "0 字"
        }
        if minChars == maxChars {
            return "约 \(minChars) 字"
        }
        return "约 \(minChars) ~ \(maxChars) 字"
    }
}
