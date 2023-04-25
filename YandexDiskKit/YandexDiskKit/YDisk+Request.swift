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
    private var observation: NSKeyValueObservation? = nil
    @objc public var onTaskProgressUpdate: ((URLSessionTask?,Double) -> Void)? = nil
    
    init(with result: URLSessionTaskWrapper) {
        self.result = result
        super.init()
        self.updateTaskObservation(task: self.getURLTask())
        result.onTaskUpdate = {[weak self] urlSessionTask in
            self?.updateTaskObservation(task: urlSessionTask)
        }
    }
    
    public func updateTaskObservation(task:URLSessionTask?) {
        self.observation?.invalidate()
        self.observation = task?.progress.observe(\.fractionCompleted) {[weak self] progress, _ in
            self?.onTaskProgressUpdate?(self?.getURLTask(),progress.fractionCompleted)
        }
    }
    
    deinit{
        self.observation?.invalidate()
    }
    
    @objc public func cancel() {
        self.result.task?.cancel()
    }
    
    @objc public func getURLTask() -> URLSessionTask? {
        return self.result.task
    }

}

