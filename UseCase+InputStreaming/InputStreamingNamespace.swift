//
//  InputStreamingNamespace.swift
//  UseCase+InputStreaming
//
//  Created by Timothy Rosenvall on 10/28/25.
//

import Observation

enum InputStreaming {}

extension InputStreaming {
    @Observable
    class ModelState {
        var brightness: Double = 50.0
        var brightnessStreamStatus: TerminationReason = .active
    }
}
