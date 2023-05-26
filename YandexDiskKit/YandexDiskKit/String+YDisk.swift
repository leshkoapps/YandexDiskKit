//
//  String+YDisk.swift
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

extension String {

    func urlEncoded() -> String {
        let charactersToEscape = "!*'();:@&=+$,/?%#[]\" "
        let allowedCharacters = CharacterSet(charactersIn: charactersToEscape).inverted
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? self
    }
    
    func urlEncodedRFC3986() -> String {
        let urlQueryParameterAllowedCharacterSetRFC3986 : CharacterSet = CharacterSet.init(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~/?")
        let escapedString = self.addingPercentEncoding(withAllowedCharacters:urlQueryParameterAllowedCharacterSetRFC3986)
        return escapedString ?? self
    }

    mutating func appendOptionalURLParameter<T>(_ name: String, value: T?) {
        if let value = value {
            let seperator = self.range(of:"?") == nil ? "?" : "&"

            self.insert(contentsOf: "\(seperator)\(name)=\(value)", at: self.endIndex);
        }
    }
}
