//
//  Executor.swift
//  UseCase+InputStreaming
//
//  Created by Timothy Rosenvall on 10/26/25.
//

import Foundation

actor UseCaseExecutor {
    private var queue: [() async -> Void] = []
    private var runningTasks: [UUID: Task<Void, Never>] = [:]

    // For single value use case outputs.
    @discardableResult
    func enqueue<T: BasicUseCaseProtocol>(
        _ useCase: T,
        input: T.Input,
        onValue: @escaping (T.Output) -> Void,
        onComplete: @escaping (TerminationReason) -> Void
    ) -> UUID {
        let id = UUID()

        queue.append {
            let task = Task {
                await self.run(
                    useCase,
                    input: input,
                    onValue: onValue,
                    onComplete: onComplete
                )
            }

            self.register(task: task, id: id)
            await task.value
            self.unregister(id: id)
        }

        Task { await self.processQueue() }
        return id
    }

    // For aggregating input values into a single output.
    @discardableResult
    func enqueue<T: AggregationUseCaseProtocol>(
        _ useCase: T,
        input: T.Input,
        onValue: @escaping (T.Output) -> Void,
        onComplete: @escaping (TerminationReason) -> Void
    ) -> UUID {
        let id = UUID()

        queue.append {
            let task = Task {
                await self.run(
                    useCase,
                    input: input,
                    onValue: onValue,
                    onComplete: onComplete
                )
            }

            self.register(task: task, id: id)
            await task.value
            self.unregister(id: id)
        }
        
        Task { await self.processQueue() }
        return id
    }

    // For observing multiple output values streaming from a single input value.
    @discardableResult
    func enqueue<T: ObserverUseCaseProtocol>(
        _ useCase: T,
        input: T.Input,
        onValue: @escaping (T.Output.Element) -> Void,
        onComplete: @escaping (TerminationReason) -> Void
    ) -> UUID {
        let id = UUID()

        queue.append {
            let task = Task {
                await self.run(
                    useCase,
                    input: input,
                    onValue: onValue,
                    onComplete: onComplete
                )
            }

            self.register(task: task, id: id)
            await task.value
            self.unregister(id: id)
        }

        Task { await self.processQueue() }
        return id
    }

    // For observing multiple output values streaming from a single input value.
    @discardableResult
    func enqueue<T: TransformationUseCaseProtocol>(
        _ useCase: T,
        input: T.Input,
        onValue: @escaping (T.Output.Element) -> Void,
        onComplete: @escaping (TerminationReason) -> Void
    ) -> UUID {
        let id = UUID()

        queue.append {
            let task = Task {
                await self.run(
                    useCase,
                    input: input,
                    onValue: onValue,
                    onComplete: onComplete
                )
            }

            self.register(task: task, id: id)
            await task.value
            self.unregister(id: id)
        }

        Task { await self.processQueue() }
        return id
    }

    func cancel(id: UUID) {
        if let task = runningTasks[id] {
            task.cancel()
            runningTasks.removeValue(forKey: id)
        }
    }

    func cancelAll() {
        for task in runningTasks.values {
            task.cancel()
        }
        runningTasks.removeAll()
    }

    private func register(task: Task<Void, Never>, id: UUID) {
        runningTasks[id] = task
    }

    private func unregister(id: UUID) {
        runningTasks.removeValue(forKey: id)
    }

    private func processQueue() async {
        while !queue.isEmpty {
            let task = queue.removeFirst()
            await task()
        }
    }

    private func run<T: BasicUseCaseProtocol>(
        _ useCase: T,
        input: T.Input,
        onValue: @escaping (T.Output) -> Void,
        onComplete: @escaping (TerminationReason) -> Void
    ) async where T.Output: Sendable {
        guard useCase.validate(input: input) else {
            onComplete(.inputInvalidated(reason: "Invalid Input: \(input)"))
            return
        }

        do {
            let result = try await useCase.execute(input)

            if Task.isCancelled {
                onComplete(.cancelled)
            }

            onValue(result)
            onComplete(.finished)
        } catch {
            onComplete(.errorOutput(reason: error))
        }
    }

    private func run<T: AggregationUseCaseProtocol>(
        _ useCase: T,
        input: T.Input,
        onValue: @escaping (T.Output) -> Void,
        onComplete: @escaping (TerminationReason) -> Void
    ) async where T.Output: Sendable {
        guard useCase.validate(inputStream: input) else {
            onComplete(.inputInvalidated(reason: "Stream Not Found: \(input)")) // Check if stream exists
            return
        }

        do {
            let result = try await useCase.execute(input)

            if Task.isCancelled {
                onComplete(.cancelled)
            }

            onValue(result)
            onComplete(.finished)
        } catch {
            onComplete(.errorOutput(reason: error))
        }
    }

    private func run<T: ObserverUseCaseProtocol>(
        _ useCase: T,
        input: T.Input,
        onValue: @escaping (T.OutputValueType) -> Void,
        onComplete: @escaping (TerminationReason) -> Void
    ) async {
        let termination = TerminationState()

        guard useCase.validate(input: input) else {
            onComplete(.inputInvalidated(reason: "Invalid Input: \(input)"))
            return
        }

        do {
            let stream = try await useCase.execute(
                input,
                shouldCloseStreamForReason: { reason in
                    await termination.terminate(with: reason)
                    return await termination.isTerminationRequested
                }
            )

            for try await value in stream {
                onValue(value)
            }

            onComplete(await termination.reason)
        } catch {
            onComplete(.errorOutput(reason: error))
        }
    }

    private func run<T: TransformationUseCaseProtocol>(
        _ useCase: T,
        input: T.Input,
        onValue: @escaping (T.OutputValueType) -> Void,
        onComplete: @escaping (TerminationReason) -> Void
    ) async {
        let termination = TerminationState()

        guard useCase.validate(inputStream: input) else {
            onComplete(.inputInvalidated(reason: "Stream Not Found: \(input)"))
            return
        }

        do {
            let stream = try await useCase.execute(
                input,
                shouldCloseStreamForReason: { reason in
                    await termination.terminate(with: reason)
                    return await termination.isTerminationRequested
                }
            )

            for try await value in stream {
                onValue(value)
            }

            onComplete(await termination.reason)
        } catch {
            onComplete(.errorOutput(reason: error))
        }
    }
}
