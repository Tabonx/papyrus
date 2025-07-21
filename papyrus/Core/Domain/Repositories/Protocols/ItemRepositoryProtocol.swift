//
//  ItemRepositoryProtocol.swift
//  papyrus
//
//  Created by Pavel Kroupa on 21.07.2025.
//

import Foundation

protocol ItemRepositoryProtocol {
    func fetchAllItems() async throws -> [ItemDTO]

    func fetchItems(searchText: String?) async throws -> [ItemDTO]

    func fetchItem(withId itemId: UUID) async throws -> ItemDTO?

    func fetchRecentlyModifiedItems(limit: Int) async throws -> [ItemDTO]

    func createItem(name: String, price: Decimal, taxRate: Double) async throws -> ItemDTO

    func updateItem(_ itemID: UUID, name: String?, price: Decimal?, taxRate: Double?) async throws

    func deleteItem(_ itemID: UUID) async throws

    func deleteItems(withIds itemIds: [UUID]) async throws
}
