//
//  TVPanelView.m
//  SMG_NothingIsAll
//
//  Created by jia on 2022/3/18.
//  Copyright © 2022年 XiaoGang. All rights reserved.
//

#import "TVPanelView.h"
#import "MASConstraint.h"
#import "View+MASAdditions.h"
#import "TOMVisionItemModel.h"
#import "PINDiskCache.h"
#import "TVideoWindow.h"

@interface TVPanelView () <TVideoWindowDelegate>

@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UISlider *sliderView;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UISegmentedControl *speedSegment;
@property (weak, nonatomic) IBOutlet UILabel *changeLab;
@property (weak, nonatomic) IBOutlet UILabel *frameLab;
@property (weak, nonatomic) IBOutlet UILabel *timeLab;
@property (weak, nonatomic) IBOutlet UILabel *loopLab;
@property (weak, nonatomic) IBOutlet UIButton *plusBtn;
@property (weak, nonatomic) IBOutlet UIButton *subBtn;
@property (strong, nonatomic) TVideoWindow *tvideoWindow;
@property (assign, nonatomic) BOOL playing;             //播放中;
@property (assign, nonatomic) NSInteger curIndex;       //当前帧
@property (assign, nonatomic) CGFloat speed;            //播放速度 (其中0为直播);
@property (strong, nonatomic) NSTimer *timer;           //用于播放时计时触发器;

@end

@implementation TVPanelView

-(id) init {
    self = [super init];
    if(self != nil){
        [self initView];
        [self initData];
        [self initDisplay];
    }
    return self;
}

-(void) initView{
    //self
    [self setFrame:CGRectMake(0, ScreenHeight - 40, ScreenWidth, 40)];
    
    //containerView
    [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self.class) owner:self options:nil];
    [self addSubview:self.containerView];
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self);
        make.trailing.mas_equalTo(self);
        make.top.mas_equalTo(self);
        make.bottom.mas_equalTo(self);
    }];
    
    //tvideoWindow
    self.tvideoWindow = [[TVideoWindow alloc] init];
    self.tvideoWindow.delegate = self;
}

-(void) initData{
    self.models = [[NSMutableArray alloc] init];
    self.playing = true;
    self.speed = 0;
    self.curIndex = 0;
}

-(void) initDisplay{
}

-(void) updateFrame:(BOOL)newLoop{
    //1. 数据检查;
    //if (!self.isOpen && !self.forceMode) return;
    if (theTC.outModelManager.getAllDemand.count <= 0) {
        return;
    }
    
    //2. 记录快照;
    TOMVisionItemModel *newFrame = [[TOMVisionItemModel alloc] init];
    newFrame.roots = CopyByCoding(theTC.outModelManager.getAllDemand);
    [self.models addObject:newFrame];
    
    //3. 新轮循环Id;
    if (newLoop) {
        TOMVisionItemModel *lastFrame = ARR_INDEX_REVERSE(self.models, 0);
        NSInteger oldLoopId = lastFrame ? lastFrame.loopId : 0;
        newFrame.loopId = oldLoopId + 1;
    }
    
    //3. 当前直播播放中,则实时更新;
    if (self.playing && self.speed == 0) {
        self.curIndex = self.models.count - 1;
        [self refreshDisplay];
    }
}

-(void) refreshDisplay{
    [self refreshDisplay:true];
}
-(void) refreshDisplay:(BOOL)refreshSlider{
    //1. 取model
    TOMVisionItemModel *playModel = ARR_INDEX(self.models, self.curIndex);
    TOMVisionItemModel *lastModel = ARR_INDEX_REVERSE(self.models, 0);
    self.curIndex = MAX(MIN(self.curIndex, (long)self.models.count - 1), 0);
    
    //2. 播放
    [self.delegate panelPlay:playModel];
    
    //3. 更新帧进度和循环数进度;
    self.frameLab.text = STRFORMAT(@"帧数: %ld/%ld",self.curIndex + 1,self.models.count);
    self.loopLab.text = STRFORMAT(@"循环: %ld/%ld",playModel ? playModel.loopId : 0,lastModel ? lastModel.loopId : 0);
    
    //4. 更新进度条 (当前sliderValue与curIndex不匹配时,更新进度条);
    if (refreshSlider) {
        CGFloat sliderValue = self.curIndex / (float)((long)self.models.count - 1);
        [self.sliderView setValue:sliderValue];
    }
    
    //4. 更新时间进度;
    if (self.speed == 0) {
        self.timeLab.text = @"时长: --/--";
    }else{
        NSInteger allS = self.models.count / self.speed;
        NSInteger curS = self.sliderView.value * allS;
        NSString *timeStr = STRFORMAT(@"时长: %ld:%ld/%ld:%ld",curS / 60,curS % 60,allS / 60,allS % 60);
        self.timeLab.text = timeStr;
    }
}

//MARK:===============================================================
//MARK:                     < getset >
//MARK:===============================================================
-(void)setSpeed:(CGFloat)speed{
    //1. set
    _speed = speed;
    
    //2. 速度变化时,调整播放器播放间隔;
    if (self.timer) [self.timer invalidate];
    if (speed > 0) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f / speed target:self selector:@selector(timeBlock) userInfo:nil repeats:true];
    }
}

-(void) setPlaying:(BOOL)playing{
    _playing = playing;
    [self.playBtn setTitle:(self.playing ? @"||" : @"▶") forState:UIControlStateNormal];
}

//MARK:===============================================================
//MARK:                     < block >
//MARK:===============================================================
-(void) timeBlock {
    if (self.playing) {
        //1. 播放中时,播放下帧;
        long lastIndex = (long)self.models.count - 1;//models.count是UInt类型,为0条时再-1会越界;
        if (self.curIndex < lastIndex) {
            self.curIndex ++;
            [self refreshDisplay];
        }else{
            //2. 播放完成时,停止计时器,停止播放;
            self.playing = false;
            NSLog(@"播放完成");
        }
    }
}

//MARK:===============================================================
//MARK:                     < onclick >
//MARK:===============================================================
- (IBAction)sliderChanged:(UISlider*)sender {
    self.curIndex = ((long)self.models.count - 1) * sender.value;
    [self refreshDisplay:false];
}

- (IBAction)speedSegmentChanged:(UISegmentedControl*)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.speed = 0.25f;
    }else if (sender.selectedSegmentIndex == 1) {
        self.speed = 0.5f;
    }else if (sender.selectedSegmentIndex == 2) {
        self.speed = 1;
    }else if (sender.selectedSegmentIndex == 3) {
        self.speed = 2.0f;
    }else if (sender.selectedSegmentIndex == 4) {
        self.speed = 3.0f;
    }else if (sender.selectedSegmentIndex == 5) {
        self.speed = 4.0f;
    }else if (sender.selectedSegmentIndex == 6) {
        self.speed = 0;
    }
    [self refreshDisplay];
}

- (IBAction)scaleSegmentChanged:(UISegmentedControl*)sender {
    CGFloat scale = 1.0f;
    if (sender.selectedSegmentIndex == 0) {
        scale = 0.25f;
    }else if (sender.selectedSegmentIndex == 1) {
        scale = 0.5f;
    }else if (sender.selectedSegmentIndex == 2) {
        scale = 1;
    }else if (sender.selectedSegmentIndex == 3) {
        scale = 2.0f;
    }else if (sender.selectedSegmentIndex == 4) {
        scale = 3.0f;
    }else if (sender.selectedSegmentIndex == 5) {
        scale = 4.0f;
    }
    [self.delegate panelScaleChanged:scale];
}

- (IBAction)playBtnClicked:(id)sender {
    self.playing = !self.playing;
}

- (IBAction)plusBtnClicked:(id)sender {
    if (self.curIndex < (long)self.models.count - 1) {
        self.curIndex++;
        [self refreshDisplay];
    }
}

- (IBAction)subBtnClicked:(id)sender {
    if (self.curIndex > 0) {
        self.curIndex--;
        [self refreshDisplay];
    }
}

- (IBAction)closeBtnClicked:(id)sender {
    [self.delegate panelCloseBtnClicked];
}

- (IBAction)saveBtnOnClicked:(id)sender {
    [self.tvideoWindow open];
}

//MARK:===============================================================
//MARK:                     < TVideoWindowDelegate >
//MARK:===============================================================
-(void) tvideo_ClearModels{
    [self.models removeAllObjects];
    [self refreshDisplay];
}

-(void) tvideo_Save:(NSString*)fileName{
    //1. 数据准备;
    NSString *cachePath = kCachePath;
    NSURL *fileURL = [NSURL fileURLWithPath:STRFORMAT(@"%@/tvideo/%@.tv",cachePath,fileName)];
    NSData *data = OBJ2DATA(self.models);
    BOOL success = [data writeToURL:fileURL options:NSDataWritingAtomic error:nil];
    
    //2. 备份UserDefaults记忆;
    NSLog(@"======> 存储思维录像《%@.tv》%@",fileName,success ? @"成功" : @"失败");
}

-(void) tvideo_Read:(NSString*)fileName{
    //1. 数据准备
    NSString *cachePath = kCachePath;
    NSURL *fileURL = [NSURL fileURLWithPath:STRFORMAT(@"%@/tvideo/%@",cachePath,fileName)];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            //2. 异步取数据;
            NSArray *object = [NSKeyedUnarchiver unarchiveObjectWithFile:[fileURL path]];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                //3. 主线程同步更新UI;
                [self.models removeAllObjects];
                [self.models addObjectsFromArray:object];
                [self refreshDisplay];
            });
        }@catch (NSException *exception) {}
    });
}

@end
