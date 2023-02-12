//
//  RLTrainer.m
//  SMG_NothingIsAll
//
//  Created by jia on 2022/3/31.
//  Copyright © 2022年 XiaoGang. All rights reserved.
//

#import "RLTrainer.h"
#import "RTModel.h"
#import "RLTPanel.h"

@interface RLTrainer () <RTModelDelegate,RLTPanelDelegate>

@property (strong, nonatomic) RTModel *model;
@property (strong, nonatomic) RLTPanel *panel;

@end

@implementation RLTrainer

static RLTrainer *_instance;
+(RLTrainer*) sharedInstance{
    if (_instance == nil) {
        _instance = [[RLTrainer alloc] init];
    }
    return _instance;
}

-(id) init {
    self = [super init];
    if(self != nil){
        [self initData];
    }
    return self;
}

-(void) initData{
    self.model = [[RTModel alloc] init];
    self.model.delegate = self;
    self.panel = [[RLTPanel alloc] init];
    self.panel.delegate = self;
    [theApp.window addSubview:self.panel];
}

//MARK:===============================================================
//MARK:                     < publicMethod >
//MARK:===============================================================
-(void) regist:(NSString*)name target:(NSObject*)target selector:(SEL)selector{
    [self.model regist:name target:target selector:selector];
}
-(void) queue1:(RTQueueModel*)queue{
    [self queueN:@[queue] count:1];
}
-(void) queue1:(RTQueueModel*)queue count:(NSInteger)count{
    [self queueN:@[queue] count:count];
}
-(void) queueN:(NSArray*)queues count:(NSInteger)count{
    [self.panel open];
    [self.model queue:queues count:count];
    [self.panel reloadData];
}
-(void) invoked:(NSString*)name{
    [self.model invoked:name];
}
-(void) open{
    [self.panel open];
}

/**
 *  MARK:--------------------暂停或继续训练--------------------
 */
-(void)setPlaying:(BOOL)playing{
    [self.panel setPlaying:playing];
}

//MARK:===============================================================
//MARK:                     < RTModelDelegate >
//MARK:===============================================================
-(BOOL) rtModel_Playing{
    return self.panel.playing;
}

-(void) rtModel_Invoked{
    [self.panel reloadData];
}

-(void) rtModel_Finished{
    [theApp setNoLogMode:false];
}

//MARK:===============================================================
//MARK:                     < RLTPanelDelegate >
//MARK:===============================================================
-(void) rltPanel_Stop{
    [self.model clear];
    [self.panel reloadData];
}

-(NSArray*) rltPanel_getQueues{
    return self.model.queues;
}

-(NSInteger) rltPanel_getQueueIndex{
    return self.model.queueIndex;
}

-(double) rltPanel_getUseTimed{
    return self.model.getTotalUseTimed;
}

@end
