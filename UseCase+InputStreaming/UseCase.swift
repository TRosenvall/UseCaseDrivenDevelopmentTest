//
//  UseCase.swift
//  UseCase+InputStreaming
//
//  Created by Timothy Rosenvall on 10/26/25.
//

import Foundation

protocol UseCaseProtocol {
    associatedtype Input: Sendable
    associatedtype Output: Sendable

    init()
}

protocol BasicUseCaseProtocol: UseCaseProtocol {
    func validate(input: Input?) -> Bool
    func execute(
        _ input: Input
    ) async throws -> Output
}

protocol AggregationUseCaseProtocol: UseCaseProtocol
where Input: AsyncSequence,
      Input.Element == InputValueType {
    associatedtype InputValueType: Sendable

    func validate(inputStream: Input) -> Bool
    func validate(inputValue: InputValueType) -> Bool
    func execute(
        _ input: Input
    ) async throws -> Output
}

protocol ObserverUseCaseProtocol: UseCaseProtocol
where Output: AsyncSequence,
      Output.Element == OutputValueType {
    associatedtype OutputValueType: Sendable

    func validate(input: Input) -> Bool
    func execute(
        _ input: Input,
        shouldCloseStreamForReason: @escaping (TerminationReason) async -> (Bool)
    ) async throws -> Output
}

protocol TransformationUseCaseProtocol: UseCaseProtocol
where Input: AsyncSequence,
      Input.Element == InputValueType,
      Output: AsyncSequence,
      Output.Element == OutputValueType {
    associatedtype InputValueType: Sendable
    associatedtype OutputValueType: Sendable

    func validate(inputStream: Input) -> Bool
    func validate(inputValue: InputValueType) -> Bool
    func execute(
        _ input: Input,
        shouldCloseStreamForReason: @escaping (TerminationReason) async -> (Bool)
    ) async throws -> Output
}

enum TerminationReason: Equatable, Sendable {
    case active // The task is running and has no reason to stop
    case finished // The task has finished and is safely closing out
    case cancelled // The consuming Task was cancelled
    case inputInvalidated(reason: String) // An upstream input stream became invalid
    case errorOutput(reason: Error) // An error occured during the usecase causing termination.
    case customStop(reason: String) // A specific internal logic determined a stop

    static func == (lhs: TerminationReason, rhs: TerminationReason) -> Bool {
        switch (lhs, rhs) {
        case (.active, .active),
             (.finished, .finished),
             (.cancelled, .cancelled):
            return true
        case let (.inputInvalidated(l), .inputInvalidated(r)):
            return l == r
        case let (.customStop(l), .customStop(r)):
            return l == r
        case let (.errorOutput(l), .errorOutput(r)):
            return String(describing: l) == String(describing: r)
        default:
            return false
        }
    }
}

actor TerminationState {
    var reason: TerminationReason = .active

    func terminate(with reason: TerminationReason) {
        guard case .active = self.reason else { return }
        self.reason = reason
    }

    var isTerminationRequested: Bool {
        if case .active = reason {
            return false
        }
        return true
    }
}
