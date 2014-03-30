//
//  ViewController.h
//  AudioDemo
//
//  Created by Simon on 24/2/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "sqlite3.h"


@interface ViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate>
{
    sqlite3 *dbb;
}



@property (weak, nonatomic) IBOutlet UIButton *recordPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *viewHistoryButton;

- (IBAction)recordPauseTapped:(id)sender;
- (IBAction)stopTapped:(id)sender;
- (IBAction)playTapped:(id)sender;


-(NSString *) filePath;
-(void)openDB;

//field names: date, longitude, latitude, PEF%
-(void) createTable: (NSString *) tableName
         withField1: (NSString *) field1;


@end
