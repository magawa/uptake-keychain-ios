import Foundation



/// Errors thrown by `KeychainHelper`.
public enum KeychainError: Error {
  /// The `SecItem` API doesn't use `NSErrors`. It uses `OSStatus` codes. This wraps those codes and is thrown when a code other than `noErr` is encountered.
  case unknown(status: OSStatus)
  
  /// Information is stored in the keychain as raw data. So it's always possible for there to be encoding errors when attempting to read data back out of a service. If read data cannot be decoded to the expected type, this error is thrown.
  case unexpectedItemFormat
}
