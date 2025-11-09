//
//  MicrophonePermissionRequestUseCase.swift
//  UseCaseArchitecture
//
//  Created by Timothy Rosenvall on 11/7/25.
//

import AVFoundation

struct MicrophonePermissionRequestUseCase: BasicUseCaseProtocol {
    typealias InputParams = Void
    typealias Input = Void
    typealias Output = Bool

    init(_ params: Void = ()) {}

    func validate(input: Void?) -> Bool { true }

    func execute(_ input: Void) async throws -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
    }
}
