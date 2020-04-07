import XCTest
@testable import RESTCombine

final class RESTCombineTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(RESTCombine().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
