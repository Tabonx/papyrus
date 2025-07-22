//
//  MainActorIsolated.swift
//  papyrus
//
//  Created by Pavel Kroupa on 22.07.2025.
//

@MainActor
final class MainActorIsolated<Value>: Sendable {
    lazy var value: Value = initialValue()
    private let initialValue: @Sendable @MainActor () -> Value
    nonisolated init(initialValue: @escaping @Sendable @MainActor () -> Value) {
        self.initialValue = initialValue
    }
}
