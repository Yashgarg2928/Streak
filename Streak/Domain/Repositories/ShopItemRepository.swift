// Domain/Repositories/ShopItemRepository.swift

import Foundation

public protocol ShopItemRepository {
    func fetchAll() throws -> [ShopItem]
    func fetchActive(type: FixedShopItemType) throws -> [ShopItem]
    func save(_ item: ShopItem) throws
}
