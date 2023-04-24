//
//  RootDirectoryViewController.swift
//  TinyDisk
//
//  Created by DE4ME on 18.04.2023.
//  Copyright © 2023 DE4ME.COM. All rights reserved.
//

import UIKit;
import YandexDiskKit;


private enum DiskPath: String {
    case files;
    case trash;
    case app;
}

private extension DiskPath {
    
    var path: YandexDisk.Path {
        switch self {
        case .files:
            return .Disk("");
        case .app:
            return .App("");
        case .trash:
            return .Trash("");
        }
    }
    
}

class RootDirectoryViewController: DirectoryViewController {
    
    @IBInspectable var diskContainer: String = "files";

    override func viewDidLoad() {
        self.disk = (UIApplication.shared.delegate as? AppDelegate)?.disk;
        self.path = DiskPath(rawValue: self.diskContainer)?.path;
        super.viewDidLoad();
    }

}
