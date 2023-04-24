//
//  YDisk+Request.swift
//  YandexDiskKit
//
//  Created by Artem on 24.04.2023.
//  Copyright © 2023 aucl.net. All rights reserved.
//

import Foundation

@objc public class YandexDiskCancellableRequest: NSObject {
    
    private var result: AnyObject
    
    init(with result: AnyObject) {
        self.result = result
        super.init()
    }
    
    @objc func cancel() {
        if self.result.responds(to: "cancel") {
            self.result.cancel()
        }
    }
    
    @objc func getURLTask() -> URLSessionTask? {
        if self.result.responds(to: "task") {
            return self.result.task
        }
        return nil
    }

}

