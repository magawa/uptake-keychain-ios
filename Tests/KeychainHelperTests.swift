import Foundation
import XCTest
import UptakeKeychain


/*
 Note that, as of Xcode9, these unit tests can't be run anonymously by XCTest and still have access to the keychain. So we've had to add an application (TestHost) to run them in. See also Quinn's comments [here](https://forums.developer.apple.com/thread/86961) and [here](https://forums.developer.apple.com/message/193810#193810)
 */


class KeychainHelperTests: XCTestCase {
  func testWriteStringDeleteAndHasStringItem() {
    let service = KeychainService("service")
    cleaningUp(service) { _ in
      try! KeychainHelper.writeString("foo", to: service)
      XCTAssert(KeychainHelper.hasStringItem(service))
    }
    XCTAssertFalse(KeychainHelper.hasStringItem(service))
  }
  
  
  func testWriteDeleteAndHasItem() {
    let service = KeychainService("service")
    cleaningUp(service) { _ in
      let data = Data(bytes: [7,7,7])
      try! KeychainHelper.write(data, to: service)
      XCTAssert(KeychainHelper.hasItem(service))
    }
    XCTAssertFalse(KeychainHelper.hasItem(service))
  }
  
  
  func testWriteZeroData() {
    let service = KeychainService("service")
    cleaningUp(service) { _ in
      let data = Data()
      try! KeychainHelper.write(data, to: service)
      XCTAssert(KeychainHelper.hasItem(service))
      XCTAssertEqual(Data(), try! KeychainHelper.read(from: service)!)
      //Make sure we update the data at service, not try to create it anew.
      try! KeychainHelper.write(Data([1,2,3]), to: service)
      XCTAssertEqual(Data([1,2,3]), try! KeychainHelper.read(from: service)!)
    }
  }

  
  func testReadString() {
    cleaningUp(KeychainService("service")) {
      try! KeychainHelper.writeString("foo", to: $0)
      XCTAssertEqual(try! KeychainHelper.readString(from: $0), "foo")
    }
  }
  
  
  func testOverwriteString() {
    cleaningUp(KeychainService("service")) {
      try! KeychainHelper.writeString("foo", to: $0)
      try! KeychainHelper.writeString("bar", to: $0)
      XCTAssertEqual(try! KeychainHelper.readString(from: $0), "bar")
    }
  }
  

  func testReadFromNonexistantService() {
    let subject = try! KeychainHelper.read(from: KeychainService("foo"))
    XCTAssertNil(subject)
  }

  
  func testReadStringFromNonexistantService() {
    let subject = try! KeychainHelper.readString(from: KeychainService("foo"))
    XCTAssertNil(subject)
  }
}


private func cleaningUp(_ service: KeychainService, f: (KeychainService)->Void) {
  defer {
    try! KeychainHelper.deleteItem(service)
  }
  f(service)
}
