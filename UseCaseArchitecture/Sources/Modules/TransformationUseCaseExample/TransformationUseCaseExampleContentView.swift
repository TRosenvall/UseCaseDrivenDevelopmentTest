//
//  ContentView.swift
//  UseCase+InputStreaming
//
//  Created by Timothy Rosenvall on 10/26/25.
//

import SwiftUI

extension TransformationUseCaseExample {
    struct ContentView: View {

        @Environment(\.scenePhase) private var scenePhase
        @State var viewModel = TransformationUseCaseExample.ViewModel()

        var body: some View {
            Slider(value: $viewModel.state.brightness, in: 0...100) { isEditing in
                if isEditing {
                    viewModel.handle(.onSliderStart)
                } else {
                    viewModel.handle(.onSliderEnd)
                }
            }
            .onAppear {
                viewModel.handle(.viewDidLoad)
            }
            .onChange(of: scenePhase, { oldValue, newValue in
                if oldValue == .background {
                    viewModel.handle(.didScenePhase)
                }
            })
            .alert(isPresented: $viewModel.state.showPermissionsDeniedAlert) {
                permissionDeniedAlert
            }
        }

        var permissionDeniedAlert: Alert {
            Alert(
                title: Text("Permission Denied"),
                message: Text("Please enable microphone access in Settings to use this feature"),
                primaryButton: .default(Text("Open Settings"), action: {
                    viewModel.handle(.routeToSettingsButtonTapped)
                }),
                secondaryButton: .cancel({
                    viewModel.handle(.cancelRouteToSettingsButtonTapped)
                })
            )
        }
    }
}

#Preview {
    TransformationUseCaseExample.ContentView()
}
