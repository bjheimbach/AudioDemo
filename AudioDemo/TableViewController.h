//
//  TableViewController.h
//  AudioDemo
//
//  Created by bheimbach on 3/24/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "sqlite3.h"
//#import "ViewController.h"

@interface TableViewController : UITableViewController

{
    sqlite3 *dbb;
}

@property (nonatomic, retain) NSMutableArray *entries;

-(NSString *) filepath;
-(void)openDB;

-(IBAction)returned:(UIStoryboardSegue *)segue;

@end
