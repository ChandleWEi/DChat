//
//  ConversationTableViewController.m
//  DChat
//
//  Created by Donal on 14-4-14.
//  Copyright (c) 2014年 DChat. All rights reserved.
//

#import "ConversationTableViewController.h"
#import "LoginStep1ViewController.h"
#import "CRNavigationController.h"
#import "PomeloManager.h"
#import "ChattingViewController.h"
#import "MessageManager.h"
#import "TDBadgedCell.h"

@interface ConversationTableViewController () <LoginStep1ViewControllerDelegate, ChattingViewControllerDelegate>
{
    NSMutableArray *conversations;
}
@end

@implementation ConversationTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newMsgCome:) name:ChatNewMsgNotifaction object:nil];
    conversations = [NSMutableArray array];
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView setTableFooterView:v];
    if (!isLogin) {
        [self showLogin];
    }
    else {
        [self registerPomelo];
    }
    [conversations removeAllObjects];
    [conversations addObjectsFromArray:[MessageManager getConversations]];
    NSArray *unReadedConversations = [MessageManager getUnReadedConversations];
    [self setBadge:unReadedConversations];
    [self.tableView reloadData];
}

-(void)setBadge:(NSArray *)unReadedConversations
{
    NSInteger badge = 0;
    for (IMMessage *conversation in unReadedConversations) {
        for (IMMessage *con in conversations) {
            if ([con.roomId isEqualToString:conversation.roomId]) {
                con.noticeSum = conversation.noticeSum;
            }
        }
        badge += [conversation.noticeSum integerValue];
    }
    if (badge != 0) {
        [[[self.tabBarController.viewControllers objectAtIndex:0] tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%i", badge]];
    }
    else {
        [[[self.tabBarController.viewControllers objectAtIndex:0] tabBarItem] setBadgeValue:nil];
    }
}

#pragma mark pomelomanager
-(void)registerPomelo
{
    if (![[PomeloManager sharedInstance] getIsPomeloConnected]) {
        [[PomeloManager sharedInstance] setupClient];
    }
}

#pragma mark chat somebody
-(void)chatSomebody:(NSString *)user
{
    ChattingViewController *vc = [[ChattingViewController alloc] init];
    vc.roomId = user;
    vc.hidesBottomBarWhenPushed = YES;
    vc.chatDelegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark chat delegate
-(void)updateConversationBadge
{
    [conversations removeAllObjects];
    [conversations addObjectsFromArray:[MessageManager getConversations]];
    NSArray *unReadedConversations = [MessageManager getUnReadedConversations];
    [self setBadge:unReadedConversations];
    [self.tableView reloadData];
}

#pragma mark login
-(void)showLogin
{
    setLogout;
    LoginStep1ViewController *vc = [[LoginStep1ViewController alloc] initWithNibName:@"LoginStep1ViewController" bundle:nil];
    vc.delegate                  = self;
    CRNavigationController *nav  = [[CRNavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:NO completion:nil];
}

#pragma mark login delegate
-(void)vertifySuccess
{
    [self dismissViewControllerAnimated:NO completion:nil];
    if (![[PomeloManager sharedInstance] getIsPomeloConnected]) {
        [[PomeloManager sharedInstance] setupClient];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return conversations.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier;
    CellIdentifier = @"conversationcell";
    TDBadgedCell *cell = [[TDBadgedCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] ;
    IMMessage *conversation = [conversations objectAtIndex:indexPath.row];
    cell.textLabel.text = conversation.roomId;
    cell.detailTextLabel.text = conversation.content;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.badgeString = conversation.noticeSum;
    cell.badgeColor = UIColorFromRGB(0xff3b30, 1.0);
    cell.badge.fontSize = 16;
    return cell;
    if (conversations.count-1 == indexPath.row) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    else {
        [cell setSeparatorInset:UIEdgeInsetsMake(0, 15, 0, 0)];
    }
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    IMMessage *user = [conversations objectAtIndex:indexPath.row];
    [self chatSomebody:user.roomId];
}

#pragma mark  接受更新UI消息广播
-(void)newMsgCome:(NSNotification *)notifacation
{
    [conversations removeAllObjects];
    [conversations addObjectsFromArray:[MessageManager getConversations]];
    NSArray *unReadedConversations = [MessageManager getUnReadedConversations];
    [self setBadge:unReadedConversations];
    [self.tableView reloadData];
}
@end
