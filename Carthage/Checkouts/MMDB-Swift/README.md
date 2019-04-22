# MMDB-Swift

![Language](https://img.shields.io/badge/language-Swift%204.2-orange.svg)
[![Version](https://img.shields.io/cocoapods/v/MMDB-Swift.svg?style=flat)](http://cocoapods.org/pods/MMDB-Swift)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-✓-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SPM Compatible](https://img.shields.io/badge/SPM-✓-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![Platform](https://img.shields.io/badge/platform-iOS%7COSX%7CLinux-lightgrey.svg)


A tiny wrapper for [libmaxminddb](https://github.com/maxmind/libmaxminddb) which allows you to lookup Geo data by IP address.

This product includes [GeoLite2 data](http://dev.maxmind.com/geoip/geoip2/geolite2/) created by MaxMind, available from [http://www.maxmind.com](http://www.maxmind.com).

## CocoaPods

MMDB-Swift is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

``` ruby
platform :ios, '8.0'
use_frameworks!
pod "MMDB-Swift"
```

Then, run the following command:

``` bash
pod install
```

## Carthage

To integrate MMDB-Swift into your Xcode project using Carthage, add the following line to your `Cartfile`:

``` 
github "lexrus/MMDB-Swift"
```

Run `carthage update` to build the frameworks and drag the built `MMDB.framework` into your Xcode project.

## Swift Package Manager

Package.swift

``` swift
import PackageDescription

let package = Package(
          name: "YOUR_AWESOME_PROJECT",
       targets: [],
  dependencies: [
                  .Package(
                    url: "https://github.com/lexrus/MMDB-Swift",
               versions: "0.0.1" ..< Version.max
                  )
                ]
)
```


## Usage

``` swift
guard let db = MMDB() else {
  print("Failed to open DB.")
  return
}
if let country = db.lookup("8.8.4.4") {
  print(country)
}
```

This outputs:

``` json
{
  "continent": {
    "code": "NA",
    "names": {
      "ja": "北アメリカ",
      "en": "North America",
      "ru": "Северная Америка",
      "es": "Norteamérica",
      "de": "Nordamerika",
      "zh-CN": "北美洲",
      "fr": "Amérique du Nord",
      "pt-BR": "América do Norte"
    }
  },
  "isoCode": "US",
  "names": {
    "ja": "アメリカ合衆国",
    "en": "United States",
    "ru": "США",
    "es": "Estados Unidos",
    "de": "USA",
    "zh-CN": "美国",
    "fr": "États-Unis",
    "pt-BR": "Estados Unidos"
  }
}
```

Notice that country is a struct defined as:

``` swift
public struct MMDBContinent {
  var code: String?
  var names: [String: String]?
}

public struct MMDBCountry: CustomStringConvertible {
  var continent = MMDBContinent()
  var isoCode = ""
  var names = [String: String]()
  ...
}
```

## Author

[Lex Tang](https://github.com/lexrus) (Twitter: [@lexrus](https://twitter.com/lexrus))

## License

MMDB-Swift is available under the [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0). See the [LICENSE](https://github.com/lexrus/MMDB-Swift/blob/master/LICENSE) file for more info.

The GeoLite2 databases are distributed under the [Creative Commons Attribution-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-sa/3.0/).
