//
//  InputStreamingNamespace.swift
//  UseCase+InputStreaming
//
//  Created by Timothy Rosenvall on 10/28/25.
//

import Observation

enum TransformationUseCaseExample {}

extension TransformationUseCaseExample {
    enum Event {
        case viewDidLoad
        case microphonePermissionDenied
        case routeToSettingsButtonTapped
        case cancelRouteToSettingsButtonTapped
        case didScenePhase
        case onSliderStart
        case onSliderEnd
    }

    @Observable
    class ModuleState {
        var brightness: Double = 50.0
        var brightnessStreamStatus: TerminationReason = .active
        var showPermissionsDeniedAlert: Bool = false
    }
}
