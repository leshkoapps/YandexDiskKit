//
//  YDisk+Request.swift
//  YandexDiskKit
//
//  Created by Artem on 24.04.2023.
//  Copyright © 2023 aucl.net. All rights reserved.
//

import Foundation

@objc public class YandexDiskCancellableRequest: NSObject {
    
    private var result: URLSessionTaskWrapper
    
    init(with result: URLSessionTaskWrapper) {
        self.result = result
        super.init()
    }
    
    @objc func cancel() {
        self.result.task?.cancel()
    }
    
    @objc func getURLTask() -> URLSessionTask? {
        return self.result.task
    }
    
}

