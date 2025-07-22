
import XCTest
import CoreData
@testable import neuanfang_umzugshelfer

final class BoxDetailViewModelTests: XCTestCase {

    var viewModel: BoxDetailViewModel!
    var mockPersistenceController: MockPersistenceController!
    var mockQRCodeService: MockQRCodeService!
    var mockNFCService: MockNFCService!
    var mockBox: Box!

    override func setUpWithError() throws {
        mockPersistenceController = MockPersistenceController()
        mockQRCodeService = MockQRCodeService()
        mockNFCService = MockNFCService()
        
        // Create a mock box for testing
        mockBox = Box(context: mockPersistenceController.container.viewContext)
        mockBox.name = "Test Box"
        mockBox.createdDate = Date()
        
        viewModel = BoxDetailViewModel(box: mockBox,
                                       viewContext: mockPersistenceController.container.viewContext,
                                       qrCodeService: mockQRCodeService,
                                       nfcService: mockNFCService)
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockBox = nil
        mockPersistenceController = nil
        mockQRCodeService = nil
        mockNFCService = nil
    }

    func testInitialBoxDataLoad() throws {
        XCTAssertEqual(viewModel.boxName, "Test Box")
        XCTAssertEqual(viewModel.items.count, 0)
    }

    func testAddItem() throws {
        let initialItemCount = viewModel.items.count
        viewModel.addItem(name: "Test Item")
        XCTAssertEqual(viewModel.items.count, initialItemCount + 1)
        XCTAssertTrue(viewModel.items.contains(where: { $0.name == "Test Item" }))
    }

    func testDeleteItem() throws {
        viewModel.addItem(name: "Item to Delete")
        let itemToDelete = viewModel.items.first(where: { $0.name == "Item to Delete" })!
        viewModel.deleteItem(itemToDelete)
        XCTAssertFalse(viewModel.items.contains(where: { $0.name == "Item to Delete" }))
    }

    func testGenerateQRCode() throws {
        let qrCodeImage = viewModel.generateQRCode()
        XCTAssertNotNil(qrCodeImage)
    }

    func testGetQRCodeData() throws {
        let qrCodeData = viewModel.getQRCodeData()
        XCTAssertNotNil(qrCodeData)
        XCTAssertEqual(qrCodeData?.name, "Test Box")
    }
}

// MARK: - Mock QRCodeService for Testing

class MockQRCodeService: QRCodeService {
    override func generateQRCode(from string: String) -> UIImage? {
        // Return a dummy image for testing
        return UIImage(systemName: "qrcode")
    }
}

// MARK: - Mock NFCService for Testing

class MockNFCService: NFCService {
    override func writeNFCTag(with data: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Simulate successful write
        completion(.success(()))
    }
}
