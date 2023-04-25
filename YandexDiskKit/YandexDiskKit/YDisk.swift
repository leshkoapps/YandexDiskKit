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
@objc public class YandexDisk : NSObject {

    @objc public let token : String
    @objc public let baseURL = "https://cloud-api.yandex.net:443"

    /// MARK: - URL Session related
    @objc public var userAgent: String?
    @objc public var additionalHTTPHeaders : [String:String] {
        return [
            "Accept"        :   "application/json",
            "Authorization" :   "OAuth \(token)",
            "User-Agent"    :   userAgent ?? "Yandex Disk swift SDK"]
    }

    @objc public var sessionDelegate: URLSessionDelegate?
    @objc public var sessionQueue : OperationQueue?
    @objc public lazy var session : URLSession = {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = self.additionalHTTPHeaders
        sessionConfig.httpShouldUsePipelining = true

        let _session = URLSession(configuration: sessionConfig, delegate: self.sessionDelegate, delegateQueue: self.sessionQueue)
        return _session
    }()

    private var _transferSession : URLSession?
    @objc public var transferSessionIdentifier: String?
    @objc public var transferSessionDelegate: URLSessionDownloadDelegate?
    @objc public var transferSessionQueue : OperationQueue?
    @objc public var transferSession : URLSession {
        if _transferSession != nil {
            return _transferSession!
        } else if self.transferSessionIdentifier != nil && self.transferSessionDelegate != nil {
            let transferSessionConfig = URLSessionConfiguration.background(withIdentifier: self.transferSessionIdentifier!)
            transferSessionConfig.httpAdditionalHeaders = self.additionalHTTPHeaders
            transferSessionConfig.httpShouldUsePipelining = true

            let queue = self.transferSessionQueue ?? OperationQueue.main
            _transferSession = URLSession(configuration: transferSessionConfig, delegate: self.transferSessionDelegate, delegateQueue: queue)
            return _transferSession!
        } else {
            return self.session
        }
    }

    public typealias YandexDiskProgressHandler = ((_ current: Int64, _ total: Int64) -> Void)?
    public typealias YandexDiskURLHandler = ((_ url: NSURL?) -> Void)?
    public typealias YandexDiskURLRequestHandler = ((_ urlRequest: NSURLRequest?) -> Void)?
    public typealias YandexDiskDictionaryHandler = ((_ dictionary: NSDictionary?) -> Void)?
    public typealias YandexDiskArrayHandler = ((_ array: NSArray?) -> Void)?
    public typealias YandexDiskErrorHandler = ((_ error: NSError?) -> Void)?
    public typealias YandexDiskVoidHandler = (() -> Void)?
    public typealias YandexDiskInProgressHandler = ((_ href:NSString, _ method:NSString, _ templated:Bool) -> Void)?
    public typealias YandexDiskMetaInfoHandler = ((_ total_space:Int, _ used_space:Int, _ trash_size:Int, _ system_folders:NSDictionary) -> Void)?
    public typealias YandexDiskListingHandler = ((_ dir:NSDictionary?, _ limit:Int, _ offset:Int, _ total:Int, _ path:NSString?, _ sort:NSString?, _ items:NSArray? ) -> Void)?
    public typealias YandexDiskPublicResourcesListingHandler = ((_ items:NSArray?, _ type:NSString?, _ limit:Int, _ offset:Int) -> Void)?
    public typealias YandexDiskStringHandler = ((_ href:NSString) -> Void)?

    @objc public init(token:String) {
        self.token = token
    }

}
