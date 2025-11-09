//
//  GetMicrophonePermissionsStatusUseCase.swift
//  UseCaseArchitecture
//
//  Created by Timothy Rosenvall on 11/8/25.
//

import AVFoundation

struct GetMicrophonePermissionsStatusUseCase: BasicUseCaseProtocol {
    typealias InputParams = Void
    typealias Input = Void
    typealias Output = AVAuthorizationStatus

    init(_ params: Void = ()) {}

    func validate(input: Void?) -> Bool {true}

    func execute(_ input: Void) async throws -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .audio)
    }
}
