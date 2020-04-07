import XCTest
@testable import RESTCombine

final class RESTCombineTests: XCTestCase {
	private struct SomeFailure:Error, Decodable {}
	enum SampleGroup: APINameSpace {
		static var baseURL: String = "https://someserver.com:8888/"
		
		static var baseHeader: [String : String] = ["Referer":"https://someReferer.com"]
		
	}
	
	func testGetAPIEndpoint() {
		struct SomeBody:Body {
			var queryDic: [String : String] = ["foo":"bar"]
			var encoded: Data?
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
	func testPostAPIEndpoint() {
		struct SomeBody:Body, Codable {
			var text = "SomeText"
			var queryDic: [String : String] = ["foo":"bar"]
		}
		var someAPI = APIEndPoint<SomeBody,String,SomeFailure>(
			endpoint: "some/path",
			httpMethod: .POST,
			contentType: .json,
			apiList: SampleGroup.self)
		someAPI.body = SomeBody()
		let request = someAPI.request
		XCTAssertEqual(request.url?.host, "someserver.com")
		XCTAssertEqual(request.url?.port, 8888)
		XCTAssertEqual(request.url?.path, "/some/path")
		XCTAssertEqual(request.url?.query, "foo=bar")
		XCTAssertEqual(request.allHTTPHeaderFields, ["Referer":"https://someReferer.com","Content-Type": "application/json; charset=UTF-8"])
		XCTAssertEqual(request.httpMethod, "POST")
		XCTAssertNotNil(request.httpBody)
		XCTAssertNoThrow(try JSONDecoder().decode(SomeBody.self, from: request.httpBody!), "request's body is not body")
	}
	
	
	static var allTests = [
		("testExample", testGetAPIEndpoint),
		("testPostAPIEndpoint",testPostAPIEndpoint),
	]
}
