//
//  CreateGroupChannelUserListViewController.swift
//  SendBird-iOS-LocalCache-Sample-swift
//
//  Created by Jed Kyung on 10/10/16.
//  Copyright © 2016 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK

protocol CreateGroupChannelUserListViewControllerDelegate: class {
    func presentGroupChannel(channel: SBDGroupChannel, parentViewController: UIViewController)
}

class CreateGroupChannelUserListViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDelegate, UITableViewDataSource, CreateGroupChannelSelectOptionViewControllerDelegate {
    weak var delegate: CreateGroupChannelUserListViewControllerDelegate?
    var userSelectionMode: Int = 0
    var groupChannel: SBDGroupChannel?
    
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var selectedUserListCollectionView: UICollectionView!
    @IBOutlet weak var userListTableView: UITableView!
    @IBOutlet weak var selectedUserListHeight: NSLayoutConstraint!
    
    private var refreshControl: UIRefreshControl!
    private var users: [SBDUser] = []
    private var userListQuery: SBDApplicationUserListQuery?
    private var selectedUsers: [SBDUser] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let negativeLeftSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.fixedSpace, target: nil, action: nil)
        negativeLeftSpacer.width = -2
        let negativeRightSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.fixedSpace, target: nil, action: nil)
        negativeRightSpacer.width = -2
        
        let leftCloseItem = UIBarButtonItem(image: UIImage(named: "btn_close"), style: UIBarButtonItem.Style.done, target: self, action: #selector(close))
        var rightNextItem: UIBarButtonItem?
        if self.userSelectionMode == 0 {
            rightNextItem = UIBarButtonItem(title: Bundle.sbLocalizedStringForKey(key: "NextButton"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(nextStage))
            rightNextItem?.setTitleTextAttributes([NSAttributedString.Key.font : Constants.navigationBarButtonItemFont()], for: UIControl.State.normal)
        }
        else {
            rightNextItem = UIBarButtonItem(title: Bundle.sbLocalizedStringForKey(key: "InviteButton"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(invite))
            rightNextItem?.setTitleTextAttributes([NSAttributedString.Key.font : Constants.navigationBarButtonItemFont()], for: UIControl.State.normal)
        }
        
        self.navItem.leftBarButtonItems = [negativeLeftSpacer, leftCloseItem]
        self.navItem.rightBarButtonItems = [negativeRightSpacer, rightNextItem!]
        
        self.selectedUserListCollectionView.contentInset = UIEdgeInsets.init(top: 0, left: 14, bottom: 0, right: 14)
        self.selectedUserListCollectionView.delegate = self
        self.selectedUserListCollectionView.dataSource = self
        self.selectedUserListCollectionView.register(SelectedUserListCollectionViewCell.nib(), forCellWithReuseIdentifier: SelectedUserListCollectionViewCell.cellReuseIdentifier())
        self.selectedUserListHeight.constant = 0
        self.selectedUserListCollectionView.isHidden = true
        
        self.userListTableView.delegate = self
        self.userListTableView.dataSource = self
        self.userListTableView.register(CreateGroupChannelUserListTableViewCell.nib(), forCellReuseIdentifier: CreateGroupChannelUserListTableViewCell.cellReuseIdentifier())
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: #selector(refreshUserList), for: UIControl.Event.valueChanged)
        self.userListTableView.addSubview(self.refreshControl)
        
        self.view.layoutIfNeeded()
        
        self.loadUserList(initial: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc private func close() {
        self.dismiss(animated: false, completion: nil)
    }
    
    @objc private func nextStage() {
        if self.selectedUsers.count == 0 {
            return
        }
        
        let vc = CreateGroupChannelSelectOptionViewController(nibName: "CreateGroupChannelSelectOptionViewController", bundle: Bundle.main)
        vc.selectedUser = NSArray(array: self.selectedUsers) as! [SBDUser]
        vc.delegate = self
        self.present(vc, animated: false, completion: nil)
    }
    
    @objc private func invite() {
        if self.selectedUsers.count == 0 {
            return
        }
        
        self.groupChannel?.invite(self.selectedUsers, completionHandler: { (error) in
            DispatchQueue.main.async {
                self.dismiss(animated: false, completion: nil)
            }
        })
    }
    
    @objc private func refreshUserList() {
        self.loadUserList(initial: true)
    }
    
    @objc private func loadUserList(initial: Bool) {
        if initial == true {
            self.users.removeAll()
            self.selectedUsers.removeAll()
            
            DispatchQueue.main.async {
                self.selectedUserListHeight.constant = 0
                self.selectedUserListCollectionView.isHidden = true
                
                self.userListTableView.reloadData()
                self.selectedUserListCollectionView.reloadData()
            }
            
            self.userListQuery = nil
        }
        
        if self.userListQuery == nil {
            self.userListQuery = SBDMain.createApplicationUserListQuery()
            self.userListQuery?.limit = 25
        }
        
        if self.userListQuery?.hasNext == false {
            self.refreshControl.endRefreshing()
            return
        }
        
        self.userListQuery?.loadNextPage(completionHandler: { (users, error) in
            if error != nil {
                let vc = UIAlertController(title: Bundle.sbLocalizedStringForKey(key: "ErrorTitle"), message: error?.domain, preferredStyle: UIAlertController.Style.alert)
                let closeAction = UIAlertAction(title: Bundle.sbLocalizedStringForKey(key: "CloseButton"), style: UIAlertAction.Style.cancel, handler:nil)
                vc.addAction(closeAction)
                DispatchQueue.main.async {
                    self.present(vc, animated: true, completion: nil)
                }
                
                self.refreshControl.endRefreshing()
                
                return
            }
            
            for user in users! as [SBDUser] {
                if user.userId == SBDMain.getCurrentUser()?.userId {
                    continue
                }
                
                if self.userSelectionMode == 1 {
                    var isMember: Bool = false
                    for item in (self.groupChannel?.members)! {
                        let member: SBDUser = item as! SBDUser
                        if member.userId == user.userId {
                            isMember = true
                            break
                        }
                    }
                    
                    if isMember == false {
                        self.users.append(user)
                    }
                }
                else {
                    self.users.append(user)
                }
            }
            
            DispatchQueue.main.async {
                self.userListTableView.reloadData()
            }
            
            self.refreshControl.endRefreshing()
        })
    }
    
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: SelectedUserListCollectionViewCell.cellReuseIdentifier(), for: indexPath)) as! SelectedUserListCollectionViewCell
        cell.setModel(aUser: self.selectedUsers[indexPath.row])
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedUsers.remove(at: indexPath.row)
        
        DispatchQueue.main.async {
            if self.selectedUsers.count == 0 {
                self.selectedUserListHeight.constant = 0
                self.selectedUserListCollectionView.isHidden = true
            }
            collectionView.reloadData()
            self.userListTableView.reloadData()
        }
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let selectedUser = self.users[indexPath.row] as SBDUser
        
        if self.selectedUsers.firstIndex(of: selectedUser) == nil {
            self.selectedUsers.append(selectedUser)
        }
        else {
            if self.selectedUsers.firstIndex(of: selectedUser) != nil {
                self.selectedUsers.remove(at: self.selectedUsers.firstIndex(of: selectedUser)!)
            }
        }
        
        DispatchQueue.main.async {
            if self.selectedUsers.count > 0 {
                self.selectedUserListHeight.constant = 70
                self.selectedUserListCollectionView.isHidden = false
            }
            else {
                self.selectedUserListHeight.constant = 0
                self.selectedUserListCollectionView.isHidden = true
            }
            
            self.userListTableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.none)
            self.selectedUserListCollectionView.reloadData()
        }
    }
    
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CreateGroupChannelUserListTableViewCell.cellReuseIdentifier()) as! CreateGroupChannelUserListTableViewCell
        cell.setModel(aUser: self.users[indexPath.row])
        
        if self.selectedUsers.firstIndex(of: self.users[indexPath.row]) == nil {
            DispatchQueue.main.async {
                cell.setSelectedUser(selected: false)
            }
        }
        else {
            DispatchQueue.main.async {
                cell.setSelectedUser(selected: true)
            }
        }
        
        if self.users.count > 0 && indexPath.row + 1 == self.users.count {
            self.loadUserList(initial: false)
        }
        
        return cell
    }
    
    // MARK: CreateGroupChannelSelectOptionViewControllerDelegate
    func didFinishCreating(channel: SBDGroupChannel, vc: UIViewController) {
        self.dismiss(animated: false) { 
            if self.delegate != nil {
                self.delegate?.presentGroupChannel(channel: channel, parentViewController: self)
            }
        }
    }
}
