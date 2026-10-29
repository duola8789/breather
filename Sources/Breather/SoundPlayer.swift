import AppKit
import BreatherCore

final class SoundPlayer {
    private let preferences: Preferences
    private var current: NSSound?

    init(preferences: Preferences) {
        self.preferences = preferences
    }

    func playStart() {
        play(named: "Glass", volume: preferences.bellStartVolume)
    }

    func playEnd() {
        play(named: "Ping", volume: preferences.bellEndVolume)
    }

    func previewStart() { playStart() }
    func previewEnd() { playEnd() }

    private func play(named name: String, volume: Int) {
        current?.stop()
        guard let sound = NSSound(named: NSSound.Name(name)) else { return }
        sound.volume = Float(max(0, min(100, volume))) / 100
        sound.play()
        current = sound
    }
}
