//
//  ViewController.m
//  AudioDemo
//
//  Created by Simon on 24/2/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    AVAudioRecorder *recorder;  //sets up audio recorder
    AVAudioPlayer *players;  //sets up audio player
    NSTimer *recorderTimer;  //creates the timer that's used to monitor audio recorder
    double lowPassResults;  //creates the double the audio data will be outputted to
}

@property (nonatomic, strong) NSMutableArray *soundDataArray;

@end

@implementation ViewController

@synthesize stopButton, playButton, recordPauseButton;

//method to create table
-(void) createTable: (NSString *)tableName
         withField1: (NSString *) field1

{
    char *err;
    NSString *sql = [NSString stringWithFormat:
                     @"CREATE TABLE IF NOT EXISTS '%@' ('%@', DOUBLE);", tableName, field1];
    if(sqlite3_exec(dbb, [sql UTF8String], NULL,NULL, &err)
       != SQLITE_OK) {
        sqlite3_close(dbb);
        NSAssert(0,@"Could not create table");
    }else{
        NSLog(@"table created");
    }
}


//file path to PEFHistory
-(NSString *) filePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:@"data.sql"];
}

//Open the DataBase
-(void)openDB {
    if (sqlite3_open([[self filePath] UTF8String], &dbb) != SQLITE_OK) {
        sqlite3_close(dbb);
        NSAssert(0,@"Database failed to open");
    }
    else{
        NSLog(@"database opened");
    }
    
}


- (void)viewDidLoad
{
    
    [self openDB];
    [self createTable:@"PEFData" withField1:@"Data"];
    [super viewDidLoad];

    // initialize the array
    _soundDataArray = [[NSMutableArray alloc] init];
    
    // Disable Stop/Play button when application launches
    [stopButton setEnabled:NO];
    [playButton setEnabled:NO];
    
    // Set the audio file
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"MyAudioMemo.m4a",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    
    // Initiate and prepare the recorder
    recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:NULL];
    recorder.delegate = self;
    [recorder prepareToRecord];
    recorder.meteringEnabled = YES;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)recordPauseTapped:(id)sender {
    // Stop the audio player before recording
    if (players.playing) {
        [players stop];
        //if the player is playing when the record button is pressed, then it stops playing
    }
    
    if (!recorder.recording) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        
        //sets up the timer that will be used
         if (!recorderTimer)
         {
         recorderTimer = [NSTimer scheduledTimerWithTimeInterval:0.001  //time interval
                                                            target:self selector:@selector(monitorAudioRecorder)  //sets the target of the timer.  the monitorAudioRecorder method is below
                                                            userInfo:nil
                                                            repeats:YES];  //if set to "no" the timer runs once and stops
         }

        
        // Start recording
        [recorder record];
        [recordPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
        
    } else {
        
        // Pause recording
        [recorder pause];
        [recordPauseButton setTitle:@"Record" forState:UIControlStateNormal];
    }
    
    [stopButton setEnabled:YES];
    [playButton setEnabled:NO];
}

- (IBAction)stopTapped:(id)sender {
    [recorder stop];
    //the mic stops recording
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
}

- (IBAction)playTapped:(id)sender {
    if (!recorder.recording){
        players = [[AVAudioPlayer alloc] initWithContentsOfURL:recorder.url error:nil];
        [players setDelegate:self];
        players.meteringEnabled = YES;
        players.delegate = self;
        [players play];
    }
}


-(void) monitorAudioRecorder {

    [recorder updateMeters]; //have to update the meters everytime you use the averagePowerOfChannel
   // NSMutableArray *array = [[NSMutableArray alloc] init];  //sets up the array the audio information will be outputted to
    
    const double ALPHA = 0.05;  //lowpass filter
    double peakPowerForChannel = pow(10, (0.05 * [recorder averagePowerForChannel:0]));
    lowPassResults = ALPHA * peakPowerForChannel + (1.0 - ALPHA) * lowPassResults;
    //NSString *lowPassString = [NSString stringWithFormat:@"%f", lowPassResults];  //have to make the data into a string (some type of object] to put it into an array
    //[array addObject:lowPassString];  //the array the data is outputted to
    NSLog(@"PEFData: %f", lowPassResults);
    //NSLog(@"Peak Flow Data: %@", array);
    
    //NSString *sql = [NSString stringWithFormat:@"INSERT INTO PEFData ('Data') VALUES ('%f')", lowPassResults];
    
    // Should add data to array here as needed
    [_soundDataArray addObject:[NSNumber numberWithDouble:lowPassResults]];
    
    /*
     * Moved SQL saving to the end of the file
     *
    char *err;
    if (sqlite3_exec(dbb, [sql UTF8String], NULL, NULL, &err) !=SQLITE_OK) {
        sqlite3_close(dbb);
        NSAssert(0, @"Could not update table)");
    }else{
        NSLog(@"table updated");
    }
    */
}

- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag{
    [recordPauseButton setTitle:@"Record" forState:UIControlStateNormal];
    
    [stopButton setEnabled:NO];
    [playButton setEnabled:YES];
    
    [recorderTimer invalidate];  //stops the timer when the recorder is done recording
    recorderTimer = nil; 
    
    // Save the data in _soundDataArray
    // TODO: save it to sql database
    // Then clear array by doing [_soundDataArray removeAllObjects];
    
    }

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Done"
                                                    message: @"Finish playing the recording!"
                                                   delegate: nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

-(IBAction) returned:(UIStoryboardSegue *) seque{
    
}


@end
