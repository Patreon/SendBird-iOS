//
//  OpenChatListViewController.h
//  JSQMessagesViewController_SendBird
//
//  Created by Jed Kyung on 4/25/16.
//  Copyright © 2016 SENDBIRD. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OpenChatListViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

- (void)setUserID:(NSString *)aUserID userName:(NSString *)aUserName;

@end