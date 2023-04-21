//
//  DirectoryViewController.swift
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

import UIKit
import YandexDiskKit

public protocol DirectoryViewControllerDelegate {
    func directoryViewController(dirController:DirectoryViewController!, didSelectFileWithURL fileURL: NSURL?, resource:YandexDiskResource) -> Void
}

public class DirectoryViewController: UITableViewController {

    public var delegate : DirectoryViewControllerDelegate?
    var disk: YandexDisk!
    var dirItem: YandexDiskResource?
    var entries: [YandexDiskResource?] = []

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(style: UITableView.Style) {
        super.init(style: style)

        refreshControl = UIRefreshControl()
        if let refreshControl = refreshControl {
            refreshControl.addTarget(self, action: "reloadDir", for: .valueChanged)
        }
    }

    public convenience init?(disk: YandexDisk) {
        self.init(style: .plain)
        self.disk = disk

        refreshTitle()
        reloadDir()
    }

    public convenience init?(disk: YandexDisk, path: YandexDiskResource) {
        self.init(style: .plain)
        self.disk = disk
        self.dirItem = path

        refreshTitle()
        reloadDir()
    }

    private var bundle : Bundle {
        return Bundle(for: DirectoryViewController.self)
    }

    func reloadDir() -> Void {
        var ownPath = YandexDisk.Path.Disk("")

        if let path = dirItem {
            ownPath = path.path
        }

        DispatchQueue.main.async {
            if let refreshControl = self.refreshControl {
                refreshControl.beginRefreshing()
            }
        }

        disk.listPath(path: ownPath, preview_size:.L, handler: listHandler)
    }

    func listHandler(listing:YandexDisk.ListingResult) -> Void {
        switch listing {
        case .Failed(let error):
            print("An error occured: \(error?.localizedDescription)")
        case .File(let file):
            print("Callback Handler was called for a file: \(file.name) at path: \(file.path)")
        case let .Listing(dir, limit, offset, total, path, sort, items):
            if offset == 0 {
                self.entries = Array<YandexDiskResource?>();
            }
            
            for item in items {
                self.entries.append(item)
            }

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
            
            let sliceSize = 100
            let currentSize = self.entries.count
            if total > currentSize {
                disk.listPath(path: path, sort: sort, limit: min(sliceSize,total - currentSize), offset: currentSize, preview_size:.L, handler: listHandler)
            }
        }

        DispatchQueue.main.async {
            if let refreshControl = self.refreshControl {
                refreshControl.endRefreshing()
            }
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = self
        self.tableView.delegate = self

        refreshTitle()
    }

    func refreshTitle() {
        if let pathListing = dirItem {
            title = (pathListing.path.description as NSString).lastPathComponent
        } else {
            title = "Tiny Disk"
        }
    }

    // MARK: UITableView methods

    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }

    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell  {

        let cellIdentifier = "TinyDiskDirCell"

        var cell : UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? UITableViewCell

        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }

        if let entry = entries[indexPath.row] {

            cell.textLabel?.text = entry.name
            cell.detailTextLabel?.text = entry.mime_type

            switch entry.type {
            case .Directory:
                cell.imageView?.image = UIImage(named: "Folder_icon", in:self.bundle, compatibleWith:nil)
                cell.accessoryType = .detailDisclosureButton
            case .File:
                cell.imageView?.image = UIImage(named: "File_icon", in:self.bundle, compatibleWith:nil)
                cell.accessoryType = .none
            }
        }

        return cell
    }

    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let entry = entries[indexPath.row] {
            switch entry.type {
            case .Directory:
                if let nextDirController = DirectoryViewController(disk: disk, path:entry) {
                    nextDirController.delegate = delegate
                    navigationController?.pushViewController(nextDirController, animated: true)
                }
            case .File:
                delegate?.directoryViewController(dirController: self, didSelectFileWithURL: nil, resource: entry)
            }
        }
    }

    public func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        if let entry = entries[indexPath.row] {
            delegate?.directoryViewController(dirController: self, didSelectFileWithURL: nil, resource: entry)
        }
    }

    public func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    public override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .none:
            break
        case .insert:
            break

        case .delete:
            if let entry = entries[indexPath.row] {
                disk.deletePath(path: entry.path, permanently:nil) {
                    (result) in
                    switch result {
                    case .Failed:
                        break
                    default:
                        self.reloadDir()
                    }
                }
            }
        }
    }

    public func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String!  {
        return "Delete"
    }

    public func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {

        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") {
            (action, indexPath) -> Void in
            self.tableView(self.tableView, commit: UITableViewCell.EditingStyle.delete, forRowAt: indexPath)
        }

        if let entry = entries[indexPath.row] {
            if entry.public_url != nil {
                let unpublishAction = UITableViewRowAction(style: .default, title: "Unpublish") { action, indexPath in
                    if let entry = self.entries[indexPath.row] {
                        self.disk.unpublishPath(path: entry.path) {_ in
                            self.reloadDir()
                        }
                    }
                }
                unpublishAction.backgroundColor = UIColor.orange
                return [deleteAction, unpublishAction]
            } else {
                let publishAction = UITableViewRowAction(style: .default, title: "Publish") { action, indexPath in
                    if let entry = self.entries[indexPath.row] {
                        self.disk.publishPath(path: entry.path) {_ in
                            self.reloadDir()
                        }
                    }
                }
                publishAction.backgroundColor = UIColor.green
                return [deleteAction, publishAction]
            }
        }

        return [deleteAction]
    }

}
