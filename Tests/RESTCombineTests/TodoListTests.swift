//
//  File.swift
//  
//
//  Created by 游宗諭 on 2020/4/8.
//

import XCTest
import RESTCombine

enum TodoList: APINameSpace {
	static var baseURL: String = "http://localhost:8080/api/"
	
	static var baseHeader: [String : String] = [:]
	static let user = APIEndPoint<UserBody, UserResponse, TodoError>(endpoint: "user", httpMethod: .GET, contentType: nil, apiList: Self.self)
}

struct UserBody:Body {
	var encoded: Data?
	var queryDic: [String : String] {[:]}
}

struct UserResponse: Decodable {
  var id: UUID
  var name: String
  var username: String
}

struct TodoError:Decodable,Error {
	
	let error:Bool
	let reason:String
	
}
class TodoListTests: XCTestCase {
	
	
	func testUser() {
		let await = XCTestExpectation()
		let s = URLSession.shared.dataTaskPublisher(for: TodoList.user)
			.map(\.data)
			.twoDecode(successType: [UserResponse].self, failureType: TodoError.self, decoder: JSONDecoder())
			.sink(receiveCompletion: {print($0)}) { (r) in
				print(r)
				await.fulfill()
		}
		wait(for: [await], timeout: 15)
	}
}
