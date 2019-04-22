//
//  MMDB.swift
//  MMDB
//
//  Created by Lex on 12/16/15.
//  Copyright © 2017 lexrus.com. All rights reserved.
//

import Foundation

public struct MMDBContinent {
    public var code: String?
    public var names: [String: String]?
}

public struct MMDBCountry: CustomStringConvertible {
    public var continent = MMDBContinent()
    public var isoCode = ""
    public var names = [String: String]()

    init(dictionary: NSDictionary) {
        if let dict = dictionary["continent"] as? NSDictionary,
            let code = dict["code"] as? String,
            let continentNames = dict["names"] as? [String: String]
        {
            continent.code = code
            continent.names = continentNames
        }
        if let dict = dictionary["country"] as? NSDictionary,
            let iso = dict["iso_code"] as? String,
            let countryNames = dict["names"] as? [String: String]
        {
            self.isoCode = iso
            self.names = countryNames
        }
    }
    
    public var description: String {
        var s = "{\n"
        s += "  \"continent\": {\n"
        s += "    \"code\": \"" + (self.continent.code ?? "") + "\",\n"
        s += "    \"names\": {\n"
        var i = continent.names?.count ?? 0
        continent.names?.forEach {
            s += "      \""
            s += $0.0 + "\": \""
            s += $0.1 + "\""
            s += (i > 1 ? "," : "")
            s += "\n"
            i -= 1
        }
        s += "    }\n"
        s += "  },\n"
        s += "  \"isoCode\": \"" + self.isoCode + "\",\n"
        s += "  \"names\": {\n"
        i = names.count
        names.forEach {
            s += "    \""
            s += $0.0 + "\": \""
            s += $0.1 + "\""
            s += (i > 1 ? "," : "")
            s += "\n"
            i -= 1
        }
        s += "  }\n}"
        return s
    }
}

final public class MMDB {

    fileprivate var db = MMDB_s()

    fileprivate typealias ListPtr = UnsafeMutablePointer<MMDB_entry_data_list_s>
    fileprivate typealias StringPtr = UnsafeMutablePointer<String>

    public init?(_ filename: String? = nil) {
        if let filename = filename, openDB(atPath: filename) { return }

        let path = Bundle(for: MMDB.self).path(forResource: "GeoLite2-Country", ofType: "mmdb")
        if let path = path, openDB(atPath: path) { return }

        return nil
    }
    private func openDB(atPath: String) -> Bool {
        let cfilename = (atPath as NSString).utf8String
        let cfilenamePtr = UnsafePointer<Int8>(cfilename)
        let status = MMDB_open(cfilenamePtr, UInt32(MMDB_MODE_MASK), &db)
        if status != MMDB_SUCCESS {
            print(String(cString: MMDB_strerror(errno)))
            return false
        } else {
            return true
        }
    }

    fileprivate func lookupString(_ s: String) -> MMDB_lookup_result_s? {
        let string = (s as NSString).utf8String
        let stringPtr = UnsafePointer<Int8>(string)

        var gaiError: Int32 = 0
        var error: Int32 = 0

        let result = MMDB_lookup_string(&db, stringPtr, &gaiError, &error)
        if gaiError == noErr && error == noErr {
            return result
        }
        return nil
    }

    fileprivate func getString(_ list: ListPtr) -> String {
        var data = list.pointee.entry_data
        let type = (Int32)(data.type)

        // Ignore other useless keys
        guard data.has_data && type == MMDB_DATA_TYPE_UTF8_STRING else {
            return ""
        }

        let str = MMDB_get_entry_data_char(&data)
        let size = size_t(data.data_size)
        let cKey = mmdb_strndup(str, size)
        let key = String(cString: cKey!)
        free(cKey)

        return key
    }

    fileprivate func getType(_ list: ListPtr) -> Int32 {
        let data = list.pointee.entry_data
        return (Int32)(data.type)
    }

    fileprivate func getSize(_ list: ListPtr) -> UInt32 {
        return list.pointee.entry_data.data_size
    }


    public func lookup(_ IPString: String) -> MMDBCountry? {
        guard let dict = lookup(ip: IPString) else {
            return nil
        }

        let country = MMDBCountry(dictionary: dict)

        return country
    }
    
    private func dump(list: ListPtr?) -> (ptr: ListPtr?, out: Any?) {
        var list = list
        switch getType(list!) {
            
        case MMDB_DATA_TYPE_MAP:
            let dict = NSMutableDictionary()
            var size = getSize(list!)
            
            list = list?.pointee.next
            while size > 0 && list != nil {
                let key = getString(list!)
                list = list?.pointee.next
                let sub = dump(list: list)
                list = sub.ptr
                if let out = sub.out, key.count > 0 {
                    dict[key] = out
                } else {
                    break
                }
                size -= 1
            }
            return (ptr: list, out: dict)
            
        case MMDB_DATA_TYPE_UTF8_STRING:
            let str = getString(list!)
            list = list?.pointee.next
            return (ptr: list, out: str)
            
        case MMDB_DATA_TYPE_UINT32:
            var res: NSNumber = 0
            if let entryData = list?.pointee.entry_data {
                var mutableEntryData = entryData
                if let uint = MMDB_get_entry_data_uint32(&mutableEntryData) {
                    let v: UInt32 = uint.pointee
                    res = NSNumber(value: v)
                }
            }
            list = list?.pointee.next
            return (ptr: list, out: res)
            
        default: ()
            
        }
        return (ptr: list, out: nil)
    }
    
    public func lookup(ip: String) -> NSDictionary? {
        guard let result = lookupString(ip) else {
            return nil
        }
        
        var entry = result.entry
        var list: ListPtr?
        let status = MMDB_get_entry_data_list(&entry, &list)
        if status != MMDB_SUCCESS {
            return nil
        }
        let res = self.dump(list: list)
        if let dict = res.out, let d = dict as? NSDictionary {
            return d
        }
        return nil
    }

    deinit {
        MMDB_close(&db)
    }

}
