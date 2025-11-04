//
//  ChangeBrightnessUseCase.swift
//  UseCase+InputStreaming
//
//  Created by Timothy Rosenvall on 10/26/25.
//

import Foundation

struct BrightnessStreamUseCase: TransformationUseCaseProtocol {

    typealias Input = AsyncStream<InputValueType>
    typealias Output = AsyncThrowingStream<OutputValueType, Error>
    typealias InputValueType = Double
    typealias OutputValueType = Double

    func validate(inputStream input: Input) -> Bool {
        //no-op
        return true
    }

    func validate(inputValue: Double) -> Bool {
        (0.0...1.0).contains(inputValue)
    }

    func execute(
        _ input: Input,
        shouldCloseStreamForReason: @escaping (TerminationReason) async -> (Bool)
    ) async throws -> AsyncThrowingStream<Double, Error> {
        AsyncThrowingStream { continuation in
            Task {
                for await value in input {
                    let newValue = value * 100 / .pi
                    continuation.yield(newValue)
                }
                if await shouldCloseStreamForReason(.finished) {
                    continuation.finish()
                }
            }
        }
    }
}
