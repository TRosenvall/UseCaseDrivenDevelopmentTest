//
//  ViewModel.swift
//  UseCase+InputStreaming
//
//  Created by Timothy Rosenvall on 10/26/25.
//

import Foundation
import UIKit

extension TransformationUseCaseExample {
    struct ViewModel {
        var state = TransformationUseCaseExample.ModuleState()
        private var executor = UseCaseExecutor()

        func handle(_ event: TransformationUseCaseExample.Event) {
            switch event {
            case .viewDidLoad:
                viewDidLoad()
            case .onSliderStart:
                startStreamingUseCase()
            case .onSliderEnd:
                endStreamingUseCase()
            case .microphonePermissionDenied:
                displayRouteToSettingsAlert()
            case .routeToSettingsButtonTapped:
                routeToSettingsButtonTapped()
            case .cancelRouteToSettingsButtonTapped:
                dismissRouteToSettingsAlert()
            case .didScenePhase:
                dismissRouteToSettingsAlert()
            }
        }

        private func viewDidLoad() {
            Task {
                await executor.enqueue(
                    GetMicrophonePermissionsStatusUseCase(),
                    input: ()
                ) { output in
                    print("Current Status: \(output)")
                    switch output {
                    case .authorized:
                        state.showPermissionsDeniedAlert = false
                    case .notDetermined:
                        state.showPermissionsDeniedAlert = false
                        requestMicrophonePermission()
                    default:
                        state.showPermissionsDeniedAlert = true
                    }
                } onComplete: { reason in
                    print("Microphone Status Aquired")
                }
            }
        }

        private func requestMicrophonePermission() {
            Task {
                await executor.enqueue(
                    MicrophonePermissionRequestUseCase(),
                    input: ()
                ) { didGrantPermission in
                    print("Use Granted Microphone Permission: \(didGrantPermission)")
                    if !didGrantPermission {
                        handle(.microphonePermissionDenied)
                    }
                } onComplete: { reason in
                    print("MicrophonePermissionRequestUseCase Status: \(reason)")
                }
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

        private func displayRouteToSettingsAlert() {
            state.showPermissionsDeniedAlert = true
        }

        private func routeToSettingsButtonTapped() {
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettings)
            }
            state.showPermissionsDeniedAlert = false
        }

        private func dismissRouteToSettingsAlert() {
            state.showPermissionsDeniedAlert = false

            Task {
                await executor.enqueue(
                    GetMicrophonePermissionsStatusUseCase(),
                    input: ()
                ) { output in
                    print("Current Status: \(output)")
                    switch output {
                    case .denied, .restricted:
                        print("Route Back")
                        break
                    default:
                        break
                    }
                } onComplete: { reason in
                    print("Rechecked microphone permissions status.")
                }
            }
        }
    }
}
