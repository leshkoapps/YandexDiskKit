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
    func directoryViewController(_ dirController:DirectoryViewController!, didSelectFileWithURL fileURL: URL?, resource:YandexDiskResource) -> Void
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
            refreshControl.addTarget(self, action: #selector(self.reloadDir(_:)), for: .valueChanged)
        }
    }

    public convenience init?(disk: YandexDisk) {
        self.init(style: .plain)
        self.disk = disk

        refreshTitle()
        reloadDir(nil)
    }

    public convenience init?(disk: YandexDisk, path: YandexDiskResource) {
        self.init(style: .plain)
        self.disk = disk
        self.dirItem = path

        refreshTitle()
        reloadDir(nil)
    }

    private var bundle : Bundle {
        return Bundle(for: DirectoryViewController.self)
    }

    @IBAction func reloadDir(_ sender: Any?) -> Void {
        var ownPath = YandexDisk.Path.Disk("")

        if let path = dirItem {
            ownPath = path.path
        }
        
        DispatchQueue.main.async {
            if let refreshControl = self.refreshControl {
                refreshControl.beginRefreshing()
            }
        }

        disk.listPath(ownPath, preview_size:.L, handler: listHandler)
    }

    func listHandler(listing:YandexDisk.ListingResult) -> Void {
        switch listing {
        case .Failed(let error):
            print("An error occured: \(error.localizedDescription)")
        case .File(let file):
            print("Callback Handler was called for a file: \(file.name) at path: \(file.path)")
        case let .Listing(dir, limit, offset, total, path, sort, items):
            if offset == 0 {
                self.entries = Array<YandexDiskResource?>.init(repeating: nil, count: total)

                if total > items.count {
                    let sliceSize = 100

                    for sliceOffset in stride(from: limit, to: total, by: sliceSize) {
                        disk.listPath(path, sort: sort, limit: sliceSize, offset: sliceOffset, handler: listHandler)
                    }
                }
            }
            for (index, item) in items.enumerated() {
                self.entries[offset + index] = item
            }

            DispatchQueue.main.async {
                self.tableView.reloadData()
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
            let string = pathListing.path.description;
            if let index = string.lastIndex(of: "/") {
                title = String( string[string.index(after: index)..<string.endIndex] );
            } else {
                title = string;
            }
        } else {
            title = "Tiny Disk"
        }
    }

    // MARK: UITableView methods
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cellIdentifier = "TinyDiskDirCell"

        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier);

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

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let entry = entries[indexPath.row] {
            switch entry.type {
            case .Directory:
                if let nextDirController = DirectoryViewController(disk: disk, path:entry) {
                    nextDirController.delegate = delegate
                    navigationController?.pushViewController(nextDirController, animated: true)
                }
            case .File:
                delegate?.directoryViewController(self, didSelectFileWithURL: nil, resource: entry)
            }
        }
    }

    public override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        if let entry = entries[indexPath.row] {
            delegate?.directoryViewController(self, didSelectFileWithURL: nil, resource: entry)
        }
    }

    public override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
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
                disk.deletePath(entry.path, permanently:nil) {
                    (result) in
                    switch result {
                    case .Failed:
                        break
                    default:
                        self.reloadDir(nil)
                    }
                }
            }
        default:
            break;
        }
        return
    }

    public override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Delete"
    }

    func performAction(action: UITableViewRowAction, indexPath: IndexPath) {

        if let entry = self.entries[indexPath.row] {
            switch action.title {
            case "Unpublish":
                disk.unpublishPath(entry.path) {  _ in
                    self.reloadDir(nil)
                }

            case "Publish":
                disk.publishPath(entry.path) { _ in
                    self.reloadDir(nil)
                }

            default:
                break
            }
        }
    }

    public override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") {
            (action, indexPath) -> Void in
            self.tableView(tableView, commit: .delete, forRowAt: indexPath)
        }

        if let entry = entries[indexPath.row] {
            if entry.public_url != nil {
                let unpublishAction = UITableViewRowAction(style: .default, title: "Unpublish", handler: performAction)
                unpublishAction.backgroundColor = UIColor.orange
                return [deleteAction, unpublishAction]
            } else {
                let publishAction = UITableViewRowAction(style: .default, title: "Publish", handler: performAction)
                publishAction.backgroundColor = UIColor.green
                return [deleteAction, publishAction]
            }
        }

        return [deleteAction]
    }

}
