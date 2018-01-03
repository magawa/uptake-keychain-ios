import Foundation



/// A bag of functions for reading, writing, and removing sensitive information from the keychain.
public enum KeychainHelper {
}



public extension KeychainHelper {
  /**
   Reads information previously written to the given service as a `String`.
   
   - Parameter service: The `KeychainService` to read from.
   
   - Returns: The decrypted string, or `nil` if no data for the given `service` exists.
   
   - Throws: `KeychainError.unexpectedItemFormat` if the data read from `service` cannot be decoded into a UTF-8 string.
   
   - Throws: `KeychainError.unknown` for error codes returned by the underlying `SecItem` API. These should be *very* rare.
   
   - Seealso: `read(from:)` if you don't care about the format of the data in service.
   */
  static func readString(from service: KeychainService) throws -> String? {
    debug? {["READ STRING FROM KEYCHAIN------------------"]}
    
    guard let data = try read(from: service) else {
      return nil
    }
    
    guard let string = String(data: data, encoding: .utf8) else {
      debug? {["String item unreadable!"]}
      throw KeychainError.unexpectedItemFormat
    }

    return string
  }
  
  
  /**
   Returns data previously written to the given service, or `nil` if none is found.
   
   - Parameter service: The `KeychainService` to read from.
   
   - Returns: The decrypted data, or `nil` if no data for the given `service` exists.
   
   - Throws: `KeychainError.unknown` for error codes returned by the underlying `SecItem` API. These should be *very* rare.
   
   - Seealso: `readString(from:)` to save yourself from decoding the data into a string.
   */
  static func read(from service: KeychainService) throws -> Data? {
    debug? {["READ DATA FROM KEYCHAIN------------------"]}
    
    var readQuery = Helper.makeQuery(service: service)
    readQuery[kSecMatchLimit as String] = kSecMatchLimitOne
    readQuery[kSecReturnAttributes as String] = kCFBooleanTrue
    readQuery[kSecReturnData as String] = kCFBooleanTrue
    
    var queryResult: AnyObject?
    let status = withUnsafeMutablePointer(to: &queryResult) {
      SecItemCopyMatching(readQuery as CFDictionary, UnsafeMutablePointer($0))
    }
    
    switch status {
    case noErr:
      debug? {["Item found…"]}
      guard
        let _result = queryResult as? [String : AnyObject],
        let data = _result[kSecValueData as String] as? Data else {
          debug? {["Item found, but contained no data. This shouldn't happen."]}
          return nil
      }
      return data
    case errSecItemNotFound:
      debug? {["Not found."]}
      return nil
    default:
      try fail(status)
    }
  }
  
  
  /**
   Securely writes to the given service in the keychain. If data already exists for the given service, it is overwritten. `readString(from:)` or `hasStringItem(_:)` can be used to determine if data already exists before writing.
   
   - Parameter item: The string to write to the given service.

   - Parameter service: The `KeychainService` to write to.
   
   - Throws: `KeychainError.unknown` for error codes returned by the underlying `SecItem` API. These should be *very* rare.
   */
  static func writeString(_ item: String, to service: KeychainService) throws {
    debug? {["WRITE STRING TO KEYCHAIN------------------"]}

    //with allows lossy, this can never be nil.
    let data = item.data(using: .utf8, allowLossyConversion: true)!
    try write(data, to: service)
  }
    
    
  /**
   Securely writes data to the given service in the keychain. If data already exists for the given service, it is overwritten. `read(from:)` or `hasItem(_:)` can be used to determine if data already exists before writing.
   
   - Parameter data: The data to write to the given service.
   
   - Parameter service: The `KeychainService` to write to.
   
   - Throws: `KeychainError.unknown` for error codes returned by the underlying `SecItem` API. These should be *very* rare.
   */
  static func write(_ data: Data, to service: KeychainService) throws {
    debug? {["WRITE DATA TO KEYCHAIN------------------"]}
    
    let status: OSStatus
    
    //Note that we're using `hasItem`, not `hasStringItem`. If the service exists but contains random data, we still want to update rather than create.
    switch hasItem(service) {
    case true:
      debug? {["Updating existing item…"]}
      let attributesToUpdate: [String : AnyObject] = [
        kSecValueData as String: data as AnyObject
      ]
      
      status = SecItemUpdate(Helper.makeQuery(service: service) as CFDictionary, attributesToUpdate as CFDictionary)
      
    case false:
      debug? {["Writing new item…"]}
      var newItem = Helper.makeQuery(service: service)
      newItem[kSecValueData as String] = data as AnyObject?
      
      status = SecItemAdd(newItem as CFDictionary, nil)
    }
    
    guard status == noErr else {
      try fail(status)
    }
    debug? {["Success!"]}
  }
  
  

  /**
   Removes the given service (and any information written to it) from the keychain, if it exists. If the given service doesn't exist, nothing happens.
   
   - Parameter service: The `KeychainService` to remove.
   
   - Throws: `KeychainError.unknown` for error codes returned by the underlying `SecItem` API. These should be *very* rare.
   */
  static func deleteItem(_ service: KeychainService) throws {
    debug? {["DELETE ITEM FROM KEYCHAIN-----------------"]}
    let status = SecItemDelete(Helper.makeQuery(service: service) as CFDictionary)
    guard status == noErr || status == errSecItemNotFound else {
      try fail(status)
    }
    debug? {["Success!"]}
  }
  
  
  /**
   Returns `true` if the given service exists in the keychain and has previously had a string written to it. Otherwise, `false`.

   - Note: Specifically, this reads the "general password" data of the service, and tries to decode it into a UTF-8 string. If there's no "general password" data, of if it can't be decoded, `false` will be returned. Use `hasItem(_:)` if you don't care about the format of the data.
   
   - Parameter service: The `KeychainService` to test.

   - Seealso: hasItem(_:)
   */
  static func hasStringItem(_ service: KeychainService) -> Bool {
    do {
      return try readString(from: service) != nil
    } catch {
      return false
    }
  }
  
  
  /**
   Returns `true` if the given service exists in the keychain and has previously had a string written to it. Otherwise, `false`.
   
   - Note: Specifically, this reads the "general password" data of the service, and tries to decode it into a UTF-8 string. If there's no "general password" data, of if it can't be decoded, `false` will be returned.
   
   - Parameter service: The `KeychainService` to test.
   */
  static func hasItem(_ service: KeychainService) -> Bool {
    do {
      return try read(from: service) != nil
    } catch {
      return false
    }
  }
}



private extension KeychainHelper {
  static func fail(_ status: OSStatus) throws -> Never {
    debug? {["Failed with status \(status)!"]}
    throw KeychainError.unknown(status: status)
  }
}



private enum Helper {
  static func makeQuery(service: KeychainService) -> [String : AnyObject] {
    return [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service.name as AnyObject
    ]
  }
}
