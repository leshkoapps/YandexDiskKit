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


public class DirectoryViewController: UITableViewController {

    var disk: YandexDisk?
    var dirItem: YandexDiskResource?
    var entries: [YandexDiskResource?] = []

    @IBAction func refreshClick(_ sender: UIRefreshControl?) -> Void {
        guard let disk = self.disk else {
            return;
        }
        let ownPath = self.dirItem?.path ?? YandexDisk.Path.Disk("");
        let _ = disk.listPath(ownPath, preview_size:.L, handler: self.listHandler);
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
                        let _ = self.disk?.listPath(path, sort: sort, limit: sliceSize, offset: sliceOffset, handler: listHandler);
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
            self.refreshControl?.endRefreshing();
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad();
        self.refreshTitle();
        self.refreshClick(nil);
    }

    func refreshTitle() {
        guard let pathListing = self.dirItem else {
            self.title = "Tiny Disk";
            return;
        }
        let string = pathListing.path.description;
        if let index = string.lastIndex(of: "/") {
            self.title = String( string[string.index(after: index)..<string.endIndex] );
        } else {
            self.title = string;
        }
    }

    func unpublishAction(action: UITableViewRowAction, indexPath: IndexPath) {
        guard let entry = self.entries[indexPath.row],
              let disk = self.disk
        else {
            return;
        }
        let _ = disk.unpublishPath(entry.path) {  _ in
            self.refreshClick(nil);
        }
    }
    
    func publishAction(action: UITableViewRowAction, indexPath: IndexPath) {
        guard let entry = self.entries[indexPath.row],
              let disk = self.disk
        else {
            return;
        }
        let _ = disk.publishPath(entry.path) { _ in
            self.refreshClick(nil);
        }
    }
    
}

// MARK: - UITableView

extension DirectoryViewController {
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TinyDiskDirCell", for: indexPath);
        guard let entry = self.entries[indexPath.row] else {
            return cell;
        }
        cell.textLabel?.text = entry.name
        cell.detailTextLabel?.text = entry.mime_type
        switch entry.type {
        case .Directory:
            cell.imageView?.image = UIImage(named: "Folder_icon")
            cell.accessoryType = .detailDisclosureButton
        case .File:
            cell.imageView?.image = UIImage(named: "File_icon")
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let entry = self.entries[indexPath.row],
              let disk = self.disk
        else {
            return;
        }
        switch entry.type {
        case .Directory:
            guard let controller = self.storyboard?.instantiateViewController(withIdentifier: "directory") as? DirectoryViewController else {
                return;
            }
            controller.disk = disk;
            controller.dirItem = entry;
            self.navigationController?.pushViewController(controller, animated: true);
        case .File:
            guard let controller = self.storyboard?.instantiateViewController(withIdentifier: "file") as? ItemViewController else {
                return;
            }
            controller.disk = disk;
            controller.item = entry;
            self.navigationController?.pushViewController(controller, animated: true);
        }
    }

    public override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard let entry = self.entries[indexPath.row],
              let disk = self.disk,
              let controller = self.storyboard?.instantiateViewController(withIdentifier: "file") as? ItemViewController
        else {
            return;
        }
        controller.disk = disk;
        controller.item = entry;
        self.navigationController?.pushViewController(controller, animated: true);
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
            guard let entry = entries[indexPath.row],
                  let disk = self.disk
            else {
                return;
            }
            let _ = disk.deletePath(entry.path, permanently:nil) { result in
                switch result {
                case .Done:
                    self.refreshClick(nil);
                default:
                    break;
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

    public override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") {
            (action, indexPath) -> Void in
            self.tableView(tableView, commit: .delete, forRowAt: indexPath)
        }
        guard let entry = entries[indexPath.row] else {
            return [deleteAction];
        }
        if entry.public_url != nil {
            let unpublishAction = UITableViewRowAction(style: .default, title: "Unpublish", handler: self.unpublishAction);
            unpublishAction.backgroundColor = UIColor.orange
            return [deleteAction, unpublishAction]
        } else {
            let publishAction = UITableViewRowAction(style: .default, title: "Publish", handler: self.publishAction);
            publishAction.backgroundColor = UIColor.green
            return [deleteAction, publishAction]
        }
    }

}
