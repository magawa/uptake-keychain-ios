import Foundation



/**
 An opaque type representing a service stored in the keychain.
 
 * Note: In the `SecItem` API, this service is represented as a simple `String`. But the secret information to be stored in the keychain is also often a `String`. The dangers of conflating the two values are extreme enough to warrant wrapping the session in its own type-safe struct.
 */
public struct KeychainService {
  internal let name: String
  
  /**
   Initializes a `KeychainService` value. The service uniquely identifies items stored in the keychain.
   
   - Parameter serviceName: Unique name for a service to be read from or written to the keychain.
   */
  public init(_ serviceName: String) {
    name = serviceName
  }
}



