//
//  ContentView.swift
//  UseCaseArchitecture
//
//  Created by Timothy Rosenvall on 11/8/25.
//

import SwiftUI

extension Home {
    struct ContentView: View {
        var body: some View {
            VStack(spacing: 8) {
                makeHStack(withCases: ["Basic", "Aggregation"])
                makeHStack(withCases: ["Observation", "Transformation"])
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(8)
        }

        func makeHStack(withCases cases: [String]) -> some View {
            HStack(spacing: 8) {
                ForEach(cases, id: \.self) { `case` in
                    makeButton(withTitleText: "\(`case`) Use Case Example")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        func makeButton(withTitleText text: String) -> some View {
            Button(action: {
                print(text)
            }) {
                Text(text)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .border(Color.black, width: 4)
            .tint(.gray)
            .background(Color.gray)
            .clipShape(Rectangle())
        }
    }
}
