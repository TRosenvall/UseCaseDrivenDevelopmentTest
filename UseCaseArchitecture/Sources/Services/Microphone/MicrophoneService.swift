//
//  MicrophoneService.swift
//  UseCaseArchitecture
//
//  Created by Timothy Rosenvall on 11/7/25.
//

import AVFoundation

final class MicrophoneService {
    private let engine = AVAudioEngine()
    private var inputNode: AVAudioInputNode { engine.inputNode }

    private let bus = 0
    private let bufferSize: AVAudioFrameCount = 1024

    private let levelContinuation: AsyncStream<Double>.Continuation
    let loudnessStream: AsyncStream<Double>

    init() {
        var continuation: AsyncStream<Double>.Continuation!
        loudnessStream = AsyncStream<Double> { cont in
            continuation = cont
        }
        self.levelContinuation = continuation
    }

    func start() throws {
        let format = inputNode.inputFormat(forBus: bus)

        inputNode.installTap(onBus: bus,
                             bufferSize: bufferSize,
                             format: format) { [weak self] buffer, _ in
            guard let self = self else { return }

            let channelData = buffer.floatChannelData?[0]
            let frameLength = Int(buffer.frameLength)

            if let channelData = channelData {
                // Calculate RMS (Root Mean Square) for loudness
                let rms = sqrt((0..<frameLength).reduce(0) { sum, i in
                    let sample = channelData[i]
                    return sum + sample * sample
                } / Float(frameLength))

                // Convert to dB scale (optional)
                let db = 20 * log10(rms)
                let normalized = max(0.0, min(1.0, (db + 50) / 50)) // normalize between 0–1 roughly

                self.levelContinuation.yield(Double(normalized))
            }
        }

        try engine.start()
    }

    func stop() {
        inputNode.removeTap(onBus: bus)
        engine.stop()
        levelContinuation.finish()
    }
}
