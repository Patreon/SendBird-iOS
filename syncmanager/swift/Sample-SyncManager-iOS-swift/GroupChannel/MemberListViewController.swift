//
//  MemberListViewController.swift
//  SendBird-iOS-LocalCache-Sample-swift
//
//  Created by Jed Kyung on 10/13/16.
//  Copyright © 2016 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK


class MemberListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SBDChannelDelegate, SBDConnectionDelegate {
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    
    var channel: SBDGroupChannel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.register(MemberListTableViewCell.nib(), forCellReuseIdentifier: MemberListTableViewCell.cellReuseIdentifier())
        
        let negativeLeftSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.fixedSpace, target: nil, action: nil)
        negativeLeftSpacer.width = -2
        let leftCloseItem = UIBarButtonItem(image: UIImage(named: "btn_close"), style: UIBarButtonItem.Style.done, target: self, action: #selector(close))
        self.navItem.leftBarButtonItems = [negativeLeftSpacer, leftCloseItem]
        
        SBDMain.add(self as SBDChannelDelegate, identifier: self.description)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.channel.refresh { (error) in
            if error != nil {
                let vc = UIAlertController(title: "Error", message: error?.domain, preferredStyle: UIAlertController.Style.alert)
                let closeAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.cancel, handler: nil)
                vc.addAction(closeAction)
                DispatchQueue.main.async {
                    self.present(vc, animated: true, completion: nil)
                }
                
                return
            }
        }
        
        DispatchQueue.main.async {
            self.navItem.title = "Members \(self.channel.memberCount)"
            self.tableView.reloadData()
        }
    }
    
    @objc private func close() {
        self.dismiss(animated: false, completion: nil)
    }
    
    // MARK: GroupChannelChattingViewController
    func didStartReconnection() {
        
    }
    
    func didSucceedReconnection() {
        self.channel .refresh { (error) in
            if error == nil {
                DispatchQueue.main.async {
                    self.navItem.title = "Members \(self.channel.memberCount)"
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func didFailReconnection() {
        
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.channel.members?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: MemberListTableViewCell?

        cell = tableView.dequeueReusableCell(withIdentifier: MemberListTableViewCell.cellReuseIdentifier()) as! MemberListTableViewCell?
        cell?.setModel(aUser: self.channel.members![indexPath.row] as! SBDUser)
        
        return cell!
    }

}
