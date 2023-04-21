//
//  YDisk+Downloading.swift
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

    public enum DownloadResult {
        case Done
        case Failed(NSError!)
    }

    /// Downloads a resource from Yandex Disk.
    ///
    /// :param: path        Path to the resource which should be downloaded from Yandex Disk.
    /// :param: toURL       Local file path under which the file should be stored.
    /// :param: handler     Optional.
    /// :returns: `DownloadResult` future.
    ///
    /// API reference:
    ///   `english http://api.yandex.com/disk/api/reference/content.xml`_,
    ///   `russian https://tech.yandex.ru/disk/api/reference/content-docpage/`_.
    public func downloadPath(path:Path, toURL:NSURL, handler:((_ result:DownloadResult) -> Void)? = nil) -> Result<DownloadResult> {
        let url = "\(baseURL)/v1/disk/resources/download?path=\(path.toUrlEncodedString)"
        return _downloadURL(url: url, toURL: toURL, handler: handler)
    }

    func _downloadURL(url:String, toURL:NSURL, handler:((_ result:DownloadResult) -> Void)? = nil) -> Result<DownloadResult> {
        let result = Result<DownloadResult>(handler: handler)

        let error = { result.set(result: .Failed($0)) }

        session.jsonTaskWithURL(url: url, errorHandler: error) {
            (jsonRoot, response)->Void in

            let (href, method, _) = YandexDisk.hrefMethodTemplatedWithDictionary(dict: jsonRoot)

            guard let requestUrl = URL(string: href) else {
                error(NSError(domain: "YDisk", code: 1, userInfo: ["message":"Invalid URL."]))
                return
            }
            var request = URLRequest(url: requestUrl)
            request.httpMethod = method

            self.transferSession.downloadTask(with: request) {
                (url, response, trasferError)->Void in

                if trasferError != nil {
                    return error(trasferError as NSError?)
                }

                if let url = url {
                    do {
                        try FileManager.default.moveItem(at: url, to: toURL as URL)
                    }
                    catch let fmerror{
                        return error(fmerror as NSError)
                    }
                }
                return result.set(result: .Done)
            }.resume()
        }?.resume()

        return result
    }
}
