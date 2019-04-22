# CommonCrypto

[![Version](https://img.shields.io/github/release/soffes/CommonCrypto.svg)](https://github.com/soffes/CommonCrypto/releases) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Simple CommonCrypto wrapper for Swift for OS X, iOS, watchOS, and tvOS with [Carthage](https://github.com/carthage/carthage) support. **For additional crypto helpers, see [Crypto](https://github.com/soffes/Crypto).**

Released under the [MIT license](LICENSE). Enjoy.


## Installation

[Carthage](https://github.com/carthage/carthage) is the recommended way to install Crypto. Add the following to your Cartfile:

``` ruby
github "soffes/CommonCrypto"
```


## Usage

You can't directly use `CommonCrypto` in Swift since Apple doesn't define a module for it. This library includes frameworks for each platform that wraps the C library. This makes importing it into Swift as simple as

``` swift
import CommonCrypto
```

Enjoy.
