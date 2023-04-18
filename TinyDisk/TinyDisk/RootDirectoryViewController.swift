//
//  RootDirectoryViewController.swift
//  TinyDisk
//
//  Created by DE4ME on 18.04.2023.
//  Copyright © 2023 DE4ME.COM. All rights reserved.
//

import UIKit;


class RootDirectoryViewController: DirectoryViewController {

    override func viewDidLoad() {
        self.disk = (UIApplication.shared.delegate as? AppDelegate)?.disk;
        super.viewDidLoad();
    }
    
    @IBAction func logoutClick(_ sender: Any) {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return;
        }
        delegate.logout();
    }

}
