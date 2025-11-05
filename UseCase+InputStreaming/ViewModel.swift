//
//  ViewModel.swift
//  UseCase+InputStreaming
//
//  Created by Timothy Rosenvall on 10/26/25.
//

import Foundation

extension InputStreaming {
    struct BrightnessViewModel {

        enum Event {
            case onSliderStart
            case onSliderEnd
        }

        var state = InputStreaming.ModelState()
        private var executor = UseCaseExecutor()

        func handle(_ event: Event) {
            switch event {
            case .onSliderStart:
                startStreamingUseCase()
            case .onSliderEnd:
                endStreamingUseCase()
            }
        }

        private func startStreamingUseCase() {
            Task {
                state.brightnessStreamStatus = .active

                let stream = state.stream(
                    for: \.brightness,
                    until: \.brightnessStreamStatus,
                    debounce: .milliseconds(1000)
                )

                await executor.enqueue(
                    BrightnessStreamUseCase(),
                    input: stream
                ) { output in
                    print("Brightness applied to \(output)")
                } onComplete: { reason in
                    print("Brightness stream finished: \(String(describing: reason))")
                }
            }
        }

        private func endStreamingUseCase() {
            state.brightnessStreamStatus = .finished
        }
    }
}
