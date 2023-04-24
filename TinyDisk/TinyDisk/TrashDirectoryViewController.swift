//
//  TrashDirectoryViewController.swift
//  TinyDisk
//
//  Created by DE4ME on 20.04.2023.
//  Copyright © 2023 DE4ME.COM. All rights reserved.
//

import UIKit;
import YandexDiskKit;


class TrashDirectoryViewController: RootDirectoryViewController {
    
    private var clearOperationTimer: Timer?;
    private var clearOperationHref: String? {
        didSet {
            self.clearOperationTimer?.invalidate();
            self.didSetClearOperationHref();
        }
    }
    
    deinit {
        self.clearOperationTimer?.invalidate();
    }

    override func viewDidLoad() {
        super.viewDidLoad();
    }
    
    private func didSetClearOperationHref() {
        guard let disk = self.disk,
              let href = self.clearOperationHref
        else {
            return;
        }
        self.clearOperationTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true, block: { [weak self] timer in
            let _ = disk.operationStatusWithHref(href) { result in
                guard let `self` = self else {
                    timer.invalidate();
                    return;
                }
                switch result {
                case .Status(let status):
                    switch status {
                    case "success", "failed":
                        timer.invalidate();
                        DispatchQueue.main.async {
                            self.refreshClick(nil);
                        }
                    default:
                        break;
                    }
                case .Failed(let error):
                    print(error);
                    timer.invalidate();
                    DispatchQueue.main.async {
                        self.refreshClick(nil);
                    }
                }
            }
        })
    }
    
    @IBAction func clearTrashClick(_ sender:Any) {
        guard let disk = self.disk else {
            return;
        }
        let _ = disk.emptyTrash() { result in
            DispatchQueue.main.async {
                switch result {
                case .Done:
                    self.refreshClick(nil);
                case .InProcess(let href, _, _):
                    self.clearOperationHref = href;
                case .Failed(let error):
                    print(error);
                }
            }
        }
    }

}
