import XCTest
@testable import CoreLogic

final class CoreLogicTests: XCTestCase {
    func testPackageWired() {
        XCTAssertFalse(CoreLogic.version.isEmpty)
    }
}
