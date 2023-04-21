//
//  YDisk+JSONParsingHelpers.swift
//
//  Copyright (c) 2014-2015, Clemens Auer
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import Foundation

extension YandexDisk {

    class func hrefMethodTemplatedWithDictionary(dict:NSDictionary?) -> (href:String, method:String, templated:Bool) {

        if let json = dict,
           let href = json["href"] as? String,
           let method = json["method"] as? String,
           let nr = json["templated"] as? NSNumber
        {
            assert(nr.boolValue == false, "Templated hrefs aren't handled.")
            return (href:href, method:method, templated:nr.boolValue)
        }

        return (href:"", method:"", templated:false)
    }

    class func JSONDictionaryWithData(data:NSData?, errorHandler:(NSError?)->Void) -> NSDictionary? {
        if let jsonData = data {
            if jsonData.length == 0 {
                return [:]
            }
            
            do {
                if let jsonRoot = try JSONSerialization.jsonObject(with: jsonData as Data, options: []) as? [String: Any] {
                    return jsonRoot as NSDictionary?
                }
                else {
                    errorHandler(NSError(domain: "Couldn't create JSON dictionary.", code: 0, userInfo: ["data":jsonData]))
                }
            } catch let anyError as NSError {
                print("Failed to parse: \(anyError.localizedDescription)")
                errorHandler(anyError)
            }
        }
        return nil
    }
}
