# Uptake Keychain
![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat) ![API docs](http://mobile-toolkit-docs.services.common.int.uptake.com/docs/uptake-keychain-ios/badge.svg)

Simple secure storage.

## Description
`KeychainHelper` is a bag of functions useful for reading, writing, and removing data from the OS's secure keychain store. It provides an abstraction around the rather obscure C interface of Foundation's "SecItem" API. Data written using `KeychainHelper` is treated as the "generic password" of a given "service". As such, it's viewed as as sensitive by the OS and encrypted.

The keychain, used in this manner, is generally considered secure enough to store items like access tokens and passwords.

## Usage
```swift
let service = KeychainService("MyServiceName")
do {
  try KeychainHelper.writeString("my sensitive data", to: service)

  if KeychainHelper.hasStringItem(service) {
    let sensitive = try KeychainHelper.readString(from: service) 
  }
  
  try KeychainHelper.deleteItem(service)

} catch {
  // Something went wrong...
}
```

## Debugging
Uptake Keychain will print debugging messages to console whenever the environment variable `UPTAKE_KEYCHAIN_DEBUGGING` is set to a non-null value. Uptake Toolbox's messages will be prefixed with "🔑".
