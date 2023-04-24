//
//  AppDelegate.swift
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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?;
    private(set) var disk: YandexDisk?;
    private(set) var token: String? {
        didSet {
            if let token = self.token {
                self.disk = YandexDisk(token: token);
            } else {
                self.disk = nil;
            }
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if let launchURL = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL {
            handleURL(launchURL)
        }
        if let token = self.token ?? self.loadToken() {
            self.token = token;
        } else {
            let storyboard = UIStoryboard(name: "Login", bundle: nil);
            self.window?.rootViewController = storyboard.instantiateInitialViewController();
        }
        return true;
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if handleURL(url) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil);
            self.window?.rootViewController = storyboard.instantiateInitialViewController();
            return true;
        }
        return false;
    }

    @discardableResult
    func handleURL(_ url: URL) -> Bool {
        let components = url.fragment?.components(separatedBy: "&").reduce(into: [String:String](), { partialResult, string in
            let scanner = Scanner(string: string);
            var key: NSString?;
            var value: NSString?;
            guard scanner.scanUpTo("=", into: &key),
                  scanner.scanString("=", into: nil),
                  scanner.scanUpTo("&", into: &value),
                  let key = key,
                  let value = value
            else {
                return;
            }
            partialResult[key as String] = value as String;
        })
        guard let token = components?["access_token"] else {
            return false;
        }
        self.token = token;
        self.saveToken(token);
        return true;
    }

    @IBAction func logoutClick(_ sender: Any) {
        self.token = nil;
        self.deleteToken();
        let storyboard = UIStoryboard(name: "Login", bundle: nil);
        self.window?.rootViewController = storyboard.instantiateInitialViewController();
    }

}

//MARK: - KeyChain

extension AppDelegate {
    
    @discardableResult
    private func saveToken(_ token: String) -> Bool {
        guard let data = token.data(using: .utf8, allowLossyConversion: false) else {
            return false;
        }
        let keyChainQuery: [CFString:AnyObject] = [ kSecClass : kSecClassGenericPassword,
                                              kSecAttrService : CONF_CLIENTID as NSString,
                                                kSecValueData : data as NSData ];
        return SecItemAdd(keyChainQuery as CFDictionary, nil) == errSecSuccess;
    }

    private func loadToken() -> String? {
        let keyChainQuery: [CFString:AnyObject] = [ kSecClass : kSecClassGenericPassword,
                                              kSecAttrService : CONF_CLIENTID as NSString,
                                               kSecReturnData : kCFBooleanTrue,
                                               kSecMatchLimit : kSecMatchLimitOne,
                                       kSecUseOperationPrompt : "Authenticate to log in!" as NSString ];
        var extractedData: AnyObject?
        guard SecItemCopyMatching(keyChainQuery as CFDictionary, &extractedData) == errSecSuccess else {
            return nil;
        }
        switch extractedData {
        case let data as Data:
            return String(data: data, encoding: .utf8);
        default:
            return nil;
        }
    }

    @discardableResult
    private func deleteToken() -> Bool {
        let keyChainQuery: [CFString:AnyObject] = [ kSecClass : kSecClassGenericPassword,
                                              kSecAttrService : CONF_CLIENTID as NSString ];
        return SecItemDelete(keyChainQuery as CFDictionary) == errSecSuccess;
    }
}

