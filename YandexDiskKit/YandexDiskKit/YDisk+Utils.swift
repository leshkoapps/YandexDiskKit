//
//  YDisk+Utils.swift
//  YandexDiskKit
//
//  Created by Artem on 24.04.2023.
//  Copyright © 2023 aucl.net. All rights reserved.
//

import Foundation

//https://stackoverflow.com/questions/24844681/list-of-classs-properties-in-swift
extension YandexDisk {

    public static func propertyNames(forObject object: Any, recursively: Bool) -> [AnyHashable] {
        let mirror = Mirror(reflecting: object)
        return propertyNames(forMirror: mirror, recursively: recursively)
    }

    public static func propertyNames(forMirror mirror: Mirror, recursively: Bool) -> [AnyHashable] {
        var result: [AnyHashable] = []
        let selfPropertyNames = mirror.children.compactMap{ $0.label }
        result.append(contentsOf: selfPropertyNames)
        if recursively {
            if let superclassMirror = mirror.superclassMirror {
                let superPropertyNames = propertyNames(forMirror: superclassMirror, recursively: recursively)
                result.append(contentsOf: superPropertyNames)
            }
        }
        return result
    }

    public static func propertyValues(forObject object: Any, recursively: Bool) -> [Any] {
        let mirror = Mirror(reflecting: object)
        return propertyValues(forMirror: mirror, recursively: recursively)
    }

    public static func isBasicDataObject(_ value: Any) -> Bool{
        if value is NSNumber || value is NSString || value is NSDate || value is NSData {
            return true
        }
        return false
    }

    public static func propertyValues(forMirror mirror: Mirror, recursively: Bool) -> [Any] {
        var result: [Any] = []
        let selfPropertyValues = mirror.children.map{object -> Any in

            let value = object.value

            if YandexDisk.isBasicDataObject(value) {
                return value
            }
            else if value is Array<Any> {
                let array = value as! Array<Any>
                var resultArray: [Any] = []
                for element in array {
                    if YandexDisk.isBasicDataObject(element) {
                        resultArray.append(element)
                    }
                    else {
                        let dictRepresentation = YandexDisk.propertyNamesAndValuesOrDescription(forObject: element)
                        resultArray.append(dictRepresentation)
                    }
                }
                return resultArray
            }
            else if value is Dictionary<AnyHashable,Any> {
                var resultDictionary: [AnyHashable:Any] = [:]
                let dict = value as! Dictionary<AnyHashable,Any>
                for (key, object) in dict {
                    let resultKey = key
                    var resultObject: Any
                    if YandexDisk.isBasicDataObject(object) {
                        resultObject = object
                    }
                    else {
                        let dictRepresentation = YandexDisk.propertyNamesAndValuesOrDescription(forObject: object)
                        resultObject = dictRepresentation
                    }
                    resultDictionary[resultKey] = resultObject
                }
                return resultDictionary
            }

            let dictRepresentation = YandexDisk.propertyNamesAndValuesOrDescription(forObject: value)
            return dictRepresentation
        }

        result.append(contentsOf: selfPropertyValues)
        if recursively {
            if let superclassMirror = mirror.superclassMirror {
                let superPropertyValues = propertyValues(forMirror: superclassMirror, recursively: recursively)
                result.append(contentsOf: superPropertyValues)
            }
        }
        return result
    }

    public static func propertyNamesAndValues(forObject object: Any, recursively: Bool = true) -> [AnyHashable:Any] {

         if object is Array<Any> {
             let values = propertyValues(forObject: object, recursively: recursively)
             var arrayDictionary: [String:Any] = [:]
             arrayDictionary["array"] = values
             return arrayDictionary
         }
        else if object is Dictionary<AnyHashable,Any> {
            return object as! Dictionary<AnyHashable,Any>
        }

        let names = propertyNames(forObject: object, recursively: recursively)
        let values = propertyValues(forObject: object, recursively: recursively)
        return Dictionary(keys: names, values: values)
    }

    public static func propertyNamesAndValuesOrDescription(forObject object: Any) -> Any {
        let dictionary = YandexDisk.propertyNamesAndValues(forObject: object)
        if dictionary.isEmpty {
            if let convertible = object as? CustomStringConvertible {
                return convertible.description
            }
            return ""
        }
        return dictionary
    }
}

extension Dictionary {
    public init(keys: [Key], values: [Value]) {
        precondition(keys.count == values.count)
        self.init()
        for (index, key) in keys.enumerated() {
            self[key] = values[index]
        }
    }
}


