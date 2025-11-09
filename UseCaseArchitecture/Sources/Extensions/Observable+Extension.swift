//
//  Observable+Extension.swift
//  UseCase+InputStreaming
//
//  Created by Timothy Rosenvall on 10/28/25.
//

import Foundation
import Observation

fileprivate final class ObservationResultPlaceholder {}
fileprivate class ObservationTokenHolder<Value> {
    var valueToken: AnyObject?
    var terminationToken: AnyObject?
    var lastValue: Value?
    var debounceTask: Task<Void, Never>?

    func updateValue(token: AnyObject?) {
        self.valueToken = token
    }

    func updateTermination(token: AnyObject?) {
        self.terminationToken = token
    }

    func updateLast(value: Value?) {
        self.lastValue = value
    }

    func updateDebounce(task: Task<Void, Never>?) {
        self.debounceTask = task
    }

    func cancelDebounceTask() {
        self.debounceTask?.cancel()
    }
}

extension Observation.Observable {
    func stream<Value: Equatable>(
        for valueKeyPath: KeyPath<Self, Value>,
        until terminationKeyPath: KeyPath<Self, TerminationReason>,
        debounce: Duration = .zero,
        onStreamComplete: ((TerminationReason) -> ())? = nil
    ) -> AsyncStream<Value> {
        AsyncStream { continuation in
            let holder = ObservationTokenHolder<Value>()

            @Sendable func startTerminationTracking() {
                holder.updateTermination(token: nil)

                let terminationObservation: AnyObject? = withObservationTracking {
                    _ = self[keyPath: terminationKeyPath]

                    return ObservationResultPlaceholder()
                } onChange: {
                    Task {
                        if self[keyPath: terminationKeyPath] != .active {
                            continuation.finish()
                            holder.updateValue(token: nil)
                            holder.updateTermination(token: nil)
                        } else {
                            startTerminationTracking()
                        }
                    }
                }
                holder.updateTermination(token: terminationObservation)
            }

            @Sendable func startValueTracking() {
                if holder.terminationToken == nil {
                    startTerminationTracking()
                }

                let valueObservation: AnyObject? = withObservationTracking {
                    let newValue = self[keyPath: valueKeyPath]

                    if holder.lastValue == nil || holder.lastValue != newValue {
                        continuation.yield(newValue)
                        holder.updateLast(value: newValue)
                    }

                    return ObservationResultPlaceholder()
                } onChange: {
                    holder.cancelDebounceTask()
                    let task = Task {
                        try? await Task.sleep(for: debounce)

                        guard !Task.isCancelled else { return }
                        if self[keyPath: terminationKeyPath] == .active {
                            startValueTracking()
                        }
                    }
                    holder.updateDebounce(task: task)
                }

                holder.updateValue(token: valueObservation)
            }

            continuation.yield(self[keyPath: valueKeyPath])
            holder.updateLast(value: self[keyPath: valueKeyPath])
            startTerminationTracking()
            startValueTracking()

            continuation.onTermination = { _ in
                holder.updateLast(value: nil)
                holder.updateValue(token: nil)
                holder.updateTermination(token: nil)
                holder.cancelDebounceTask()
                holder.updateDebounce(task: nil)

                onStreamComplete?(self[keyPath: terminationKeyPath])
            }
        }
    }
}
