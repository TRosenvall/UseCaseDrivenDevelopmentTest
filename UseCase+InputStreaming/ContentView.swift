//
//  ContentView.swift
//  UseCase+InputStreaming
//
//  Created by Timothy Rosenvall on 10/26/25.
//

import SwiftUI

extension InputStreaming {
    struct ContentView: View {

        @State var viewModel = InputStreaming.BrightnessViewModel()

        var body: some View {
            Slider(value: $viewModel.state.brightness, in: 0...100) { isEditing in
                if isEditing {
                    viewModel.handle(.onSliderStart)
                } else {
                    viewModel.handle(.onSliderEnd)
                }
            }
        }
    }
}

#Preview {
    InputStreaming.ContentView()
}
