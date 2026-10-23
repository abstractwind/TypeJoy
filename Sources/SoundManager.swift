import AppKit
import AVFoundation

/// 管理应用内音效播放与静音设置
public final class SoundManager {
    public static let shared = SoundManager()
    
    // MARK: - Constants
    
    private let mutedKey = "TypeJoy_IsMuted"
    private let defaults: UserDefaults
    
    // MARK: - Properties
    
    private var audioPlayer: AVAudioPlayer?
    private let lock = NSLock()
    
    /// 是否开启静音模式
    public var isMuted: Bool {
        get {
            defaults.bool(forKey: mutedKey)
        }
        set {
            defaults.set(newValue, forKey: mutedKey)
        }
    }
    
    // MARK: - Initializer
    
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        preloadSound()
    }
    
    // MARK: - Preload & Playback
    
    /// 预加载金币音效到音频缓存中，保证击键触发时零延迟播放
    private func preloadSound() {
        // 优先从 App Bundle 中加载 Resources/coin.wav
        var soundURL = Bundle.main.url(forResource: "coin", withExtension: "wav")
        
        // 开发/脚本测试模式下的路径回退
        if soundURL == nil {
            let possiblePaths = [
                "Resources/coin.wav",
                "../Resources/coin.wav",
                "./Resources/coin.wav"
            ]
            for path in possiblePaths {
                let url = URL(fileURLWithPath: path)
                if FileManager.default.fileExists(atPath: url.path) {
                    soundURL = url
                    break
                }
            }
        }
        
        guard let url = soundURL else {
            NSLog("[SoundManager] 警告：未能找到 coin.wav 资源文件")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = 0.8
            self.audioPlayer = player
        } catch {
            NSLog("[SoundManager] 无法初始化音频播放器: \(error)")
        }
    }
    
    /// 播放马里奥经典金币音效
    public func playCoinSound() {
        guard !isMuted else { return }
        
        lock.lock()
        defer { lock.unlock() }
        
        if audioPlayer == nil {
            preloadSound()
        }
        
        guard let player = audioPlayer else { return }
        
        // 若当前正在播放，重置到起点重新播放
        if player.isPlaying {
            player.currentTime = 0
        }
        player.play()
    }
}
