//
//  YDisk.swift
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

/// A Class that provides access to the Yandex Disk REST API
///
/// Background session support:
/// 
/// To use a dedicated background session for up- and downloads, assign meaningful values to:
/// - transferSessionIdentifier
/// - transferSessionDelegate
///
/// optionally it is possible to specify the queue in which background transfers are processed.
/// - transferSessionQueue
///
public class YandexDisk {

    public let token : [String:Any]
    public let baseURL = "https://cloud-api.yandex.net:443"

    /// MARK: - URL Session related

    var additionalHTTPHeaders : [String:String] {
        
        var authorizationHeaderValue = ""
        if let tokenType = self.token["token_type"] as! String? {
            authorizationHeaderValue += tokenType
        }
        else {
            authorizationHeaderValue += "OAuth"
        }
        
        if let accessToken = self.token["access_token"] as! String? {
            authorizationHeaderValue += " "
            authorizationHeaderValue += accessToken
        }
        
        return [
            "Accept"        :   "application/json",
            "Authorization" :   authorizationHeaderValue,
            "User-Agent"    :   "Yandex Disk swift SDK"]
    }

    public lazy var session : URLSession = {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = self.additionalHTTPHeaders
        sessionConfig.httpShouldUsePipelining = true

        let _session = URLSession(configuration: sessionConfig)
        return _session
    }()

    private var _transferSession : URLSession?
    public var transferSession : URLSession {
        if _transferSession != nil {
            return _transferSession!
        } else if transferSessionIdentifier != nil && transferSessionDelegate != nil {
            let transferSessionConfig = URLSessionConfiguration.background(withIdentifier: transferSessionIdentifier!)
            
            transferSessionConfig.httpAdditionalHeaders = self.additionalHTTPHeaders
            transferSessionConfig.httpShouldUsePipelining = true

            let queue = transferSessionQueue ?? OperationQueue.main
            _transferSession = URLSession(configuration: transferSessionConfig, delegate: transferSessionDelegate, delegateQueue: queue)
            
            return _transferSession!
        } else {
            return session
        }
    }

    public var transferSessionIdentifier: String?
    public var transferSessionDelegate: URLSessionDownloadDelegate?
    public var transferSessionQueue : OperationQueue?

    public init(token:[String:Any]) {
        self.token = token
    }
    
    public static func token(from url: NSURL) -> [String:Any]? {
        guard let urlString = url.absoluteString else { return nil }
        
        if let urlComponent = URLComponents(string: urlString) {
            
            let fragment = urlComponent.fragment
            var fragmentComponents = URLComponents()
            fragmentComponents.query = fragment
            
            let queryItems: [URLQueryItem]? = fragmentComponents.queryItems
            let access_token = queryItems?.first(where: { $0.name == "access_token" })?.value
            if access_token == nil {
                return nil
            }
            else if let queryItemsUnwrapped = queryItems {
                let tokenDict = queryItemsUnwrapped.toDictionary()
                return tokenDict
            }
        }
        
        return nil
    }

}
