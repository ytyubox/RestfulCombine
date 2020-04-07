import XCTest
@testable import RESTCombine

final class RESTCombineTests: XCTestCase {
	private struct SomeBody:Body {
		var queryDic: [String : String] = ["foo":"bar"]
		var encoded: Data?
	}
	private struct SomeFailure:Error, Decodable {}
	
	func testAPIEndpoint() {
		enum SampleGroup: APINameSpace {
			static var baseURL: String = "https://someserver.com:8888/"
			
			static var baseHeader: [String : String] = ["Referer":"https://someReferer.com"]
			
		}
		var someAPI = APIEndPoint<SomeBody,String,SomeFailure>(
			endpoint: "some/path",
			httpMethod: .GET,
			contentType: nil,
			apiList: SampleGroup.self)
		someAPI.body = SomeBody()
		let request = someAPI.request
		XCTAssertEqual(request.url?.host, "someserver.com")
		XCTAssertEqual(request.url?.port, 8888)
		XCTAssertEqual(request.url?.path, "/some/path")
		XCTAssertEqual(request.url?.query, "foo=bar")
		XCTAssertEqual(request.allHTTPHeaderFields, ["Referer":"https://someReferer.com"])
		XCTAssertEqual(request.httpMethod, "GET")
	}
	
	static var allTests = [
		("testExample", testAPIEndpoint),
	]
}
