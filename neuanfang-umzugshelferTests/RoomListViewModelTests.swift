
import XCTest
import CoreData
@testable import neuanfang_umzugshelfer

final class RoomListViewModelTests: XCTestCase {

    var viewModel: RoomListViewModel!
    var mockPersistenceController: MockPersistenceController!
    var mockCloudKitService: MockCloudKitService!

    override func setUpWithError() throws {
        mockPersistenceController = MockPersistenceController()
        mockCloudKitService = MockCloudKitService()
        viewModel = RoomListViewModel(viewContext: mockPersistenceController.container.viewContext, cloudKitService: mockCloudKitService)
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockPersistenceController = nil
        mockCloudKitService = nil
    }

    func testAddRoom() throws {
        let initialRoomCount = viewModel.rooms.count
        viewModel.addRoom(name: "Test Room", type: .bedroom)
        XCTAssertEqual(viewModel.rooms.count, initialRoomCount + 1)
        XCTAssertTrue(viewModel.rooms.contains(where: { $0.name == "Test Room" }))
    }

    func testDeleteRoom() throws {
        viewModel.addRoom(name: "Room to Delete", type: .livingRoom)
        let roomToDelete = viewModel.rooms.first(where: { $0.name == "Room to Delete" })!
        viewModel.deleteRoom(roomToDelete)
        XCTAssertFalse(viewModel.rooms.contains(where: { $0.name == "Room to Delete" }))
    }

    func testFilterRooms() throws {
        viewModel.addRoom(name: "Kitchen", type: .kitchen)
        viewModel.addRoom(name: "Bathroom", type: .bathroom)
        viewModel.addRoom(name: "Living Room", type: .livingRoom)

        viewModel.searchText = "Kitchen"
        XCTAssertEqual(viewModel.filteredRooms.count, 1)
        XCTAssertEqual(viewModel.filteredRooms.first?.name, "Kitchen")

        viewModel.searchText = ""
        viewModel.filterCriteria = .completed
        // Assuming no rooms are completed by default
        XCTAssertEqual(viewModel.filteredRooms.count, 0)
    }

    func testSortRoomsByName() throws {
        viewModel.addRoom(name: "C Room", type: .other)
        viewModel.addRoom(name: "A Room", type: .other)
        viewModel.addRoom(name: "B Room", type: .other)

        viewModel.sortOrder = .name
        XCTAssertEqual(viewModel.filteredRooms.first?.name, "A Room")
        XCTAssertEqual(viewModel.filteredRooms[1].name, "B Room")
        XCTAssertEqual(viewModel.filteredRooms.last?.name, "C Room")
    }
}

// MARK: - Mock PersistenceController for Testing

class MockPersistenceController: ObservableObject {
    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "DataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType // Use in-memory store for testing
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}

// MARK: - Mock CloudKitService for Testing

class MockCloudKitService: ObservableObject, CloudKitServiceProtocol {
    @Published var syncStatus: CloudKitSyncStatus = .idle
    
    func syncData() async {
        syncStatus = .success
    }
    
    func shareRecord(_ record: CKRecord) async throws -> CKShare {
        throw NSError(domain: "MockCloudKitService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Sharing not implemented in mock"])
    }
    
    func fetchSharedRecords() async throws -> [CKRecord] {
        return []
    }
    
    func acceptShare(_ url: URL) async throws -> CKShare {
        throw NSError(domain: "MockCloudKitService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Accepting share not implemented in mock"])
    }
}

// Define CloudKitServiceProtocol to allow mocking
protocol CloudKitServiceProtocol: ObservableObject {
    var syncStatus: CloudKitSyncStatus { get }
    func syncData() async
    func shareRecord(_ record: CKRecord) async throws -> CKShare
    func fetchSharedRecords() async throws -> [CKRecord]
    func acceptShare(_ url: URL) async throws -> CKShare
}

// Extend CloudKitService to conform to the protocol
extension CloudKitService: CloudKitServiceProtocol {}
