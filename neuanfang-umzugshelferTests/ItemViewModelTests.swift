
import XCTest
import CoreData
@testable import neuanfang_umzugshelfer

final class ItemViewModelTests: XCTestCase {

    var viewModel: ItemViewModel!
    var mockPersistenceController: MockPersistenceController!
    var mockItem: Item!

    override func setUpWithError() throws {
        mockPersistenceController = MockPersistenceController()
        
        // Create a mock item for testing
        mockItem = Item(context: mockPersistenceController.container.viewContext)
        mockItem.name = "Test Item"
        mockItem.value = 100.0
        mockItem.isFragile = true
        
        viewModel = ItemViewModel(item: mockItem)
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockItem = nil
        mockPersistenceController = nil
    }

    func testInitialItemDataLoad() throws {
        XCTAssertEqual(viewModel.item.name, "Test Item")
        XCTAssertEqual(viewModel.item.value, 100.0)
        XCTAssertTrue(viewModel.item.isFragile)
    }

    func testSaveItem() throws {
        viewModel.item.name = "Updated Item"
        viewModel.save()
        
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", "Updated Item")
        let fetchedItems = try mockPersistenceController.container.viewContext.fetch(fetchRequest)
        XCTAssertEqual(fetchedItems.first?.name, "Updated Item")
    }
}
