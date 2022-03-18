//
//  TOMVision2.m
//  SMG_NothingIsAll
//
//  Created by jia on 2022/3/13.
//  Copyright © 2022年 XiaoGang. All rights reserved.
//

#import "TOMVision2.h"
#import "MASConstraint.h"
#import "View+MASAdditions.h"
#import "AIKVPointer.h"
#import "TOMVisionItemModel.h"
#import "UIView+Extension.h"
#import "TOMVisionFoView.h"
#import "TOMVisionDemandView.h"
#import "TOMVisionFoView.h"
#import "TOMVisionAlgView.h"
#import "TOModelVisionUtil.h"
#import "UnorderItemModel.h"
#import "TVPanelView.h"

@interface TOMVision2 () <TVPanelViewDelegate>

@property (strong,nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIButton *openCloseBtn;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) TVPanelView *panelView;
@property (assign, nonatomic) NSInteger loopId;         //当前循环Id
@property (strong, nonatomic) NSMutableArray *models;   //所有帧数据 List<TOMVisionItemModel>
@property (assign, nonatomic) NSInteger curIndex;       //当前显示的data下标

@end

@implementation TOMVision2

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
    [self setFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    
    //containerView
    [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self.class) owner:self options:nil];
    [self addSubview:self.containerView];
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self);
        make.trailing.mas_equalTo(self);
        make.top.mas_equalTo(self);
        make.bottom.mas_equalTo(self);
    }];
    
    //scrollView
    self.scrollView = [[UIScrollView alloc] init];
    [self.containerView insertSubview:self.scrollView belowSubview:self.openCloseBtn];
    [self.scrollView setFrame:CGRectMake(0, 20, ScreenWidth, ScreenHeight - 20)];
    [self.scrollView setShowsVerticalScrollIndicator:NO];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setContentSize:CGSizeMake(ScreenWidth, ScreenHeight)];
    
    //contentView
    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];
    [self.contentView setBackgroundColor:[UIColor clearColor]];
    [self.contentView setFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    
    //panelView
    self.panelView = [[TVPanelView alloc] init];
    self.panelView.delegate = self;
    [self.containerView addSubview:self.panelView];
}

-(void) initData{
    self.models = [[NSMutableArray alloc] init];
}

-(void) initDisplay{
    [self close];
}

//MARK:===============================================================
//MARK:                     < method >
//MARK:===============================================================
-(void) updateLoopId{
    self.loopId++;
}

-(void) updateFrame{
    //1. 数据检查;
    //if (!self.isOpen && !self.forceMode) return;
    if (theTC.outModelManager.getAllDemand.count <= 0) {
        return;
    }
    
    //2. 记录快照;
    TOMVisionItemModel *newFrame = [[TOMVisionItemModel alloc] init];
    newFrame.loopId = self.loopId;
    newFrame.roots = theTC.outModelManager.getAllDemand;
    [self.models addObject:newFrame];
    
    //3. 当前为末帧;
    self.curIndex = self.models.count - 1;
    
    //3. 更新UI
    [self refreshDisplay];
}

-(void) refreshDisplay{
    //1. 数据检查;
    TOMVisionItemModel *model = ARR_INDEX(self.models, self.curIndex);
    if (!model) return;
    
    //2. 取出旧有节点缓存 & 并清空画板;
    NSArray *subViews = [self.contentView subViews_AllDeepWithClass:TOMVisionNodeBase.class];
    [self.contentView removeAllSubviews];
    
    //2. 刷新显示_计算根节点宽度 (参考25182-4);
    CGFloat rootWidth = ScreenWidth / model.roots.count * 0.6f;
    CGFloat curX = rootWidth * 0.2f;
    for (DemandModel *demand in model.roots) {
        
        //6. 从根节点递归生长出它的分枝,
        NSMutableArray *unorderModels = [TOModelVisionUtil convertCur2Sub2UnorderModels:demand];
        
        //3. 转为nodeView
        for (UnorderItemModel *unorder in unorderModels) {
            
            //4. 新建根节点;
            TOMVisionNodeBase *nodeView = [self getOrCreateNode:unorder.data oldSubViews:subViews];
            [self.contentView addSubview:nodeView];
            [nodeView setFrame:CGRectMake(curX, unorder.tabNum * 60, rootWidth, nodeView.height)];
            
            //TODOTOMORROW20220317:
            //5. 根据当前tabNum,对curX值进行更新;
            
            //6. 对nodeView进行缩放;
            if (nodeView.data.baseOrGroup) {
                
                //8. 有base时: 子元素宽度 = base宽度 / 子元素数;
                TOMVisionNodeBase *baseView = [self getOrCreateNode:nodeView.data oldSubViews:subViews];
                NSMutableArray *subModels = [TOUtils getSubOutModels:nodeView.data];
                if (baseView && ARRISOK(subModels)) {
                    CGFloat subWidth = baseView.width / subModels.count;
                    
                    //9. 然后: 缩放比例 = 子元素宽度 / rootWidth;
                    CGFloat scale = subWidth / rootWidth;
                    
                    //10. 缩放;
                    NSLog(@"缩放比例:%f",scale);
                    [nodeView setTransform:CGAffineTransformScale(nodeView.transform, scale, scale)];
                }
            }
            
        }
        
        //5. 更新curX值;
        curX += rootWidth;
    }
}

-(void) clear{
    
}

-(void) invokeForceMode:(void(^)())block{
    if (block) {
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL bakForceMode = self.forceMode;
            [self setForceMode:true];
            block();
            [self setForceMode:bakForceMode];
        });
    }
}

-(void) open{
    [self setHidden:false];
}

-(void) close{
    [self setHidden:true];
}

//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================
-(BOOL) isOpen{
    return !self.isHidden;
}

/**
 *  MARK:--------------------创建新节点--------------------
 *  @result notnull
 */
-(TOMVisionNodeBase*) getOrCreateNode:(id)data oldSubViews:(NSArray*)subViews{
    //1. 数据准备;
    TOMVisionNodeBase *result = nil;
    
    //2. 优先找复用;
    result = ARR_INDEX([SMGUtils filterArr:subViews checkValid:^BOOL(TOMVisionNodeBase *subView) {
        return [subView isEqualByData:data];
    } limit:1], 0);
    
    //3. 没复用则新建;
    if (!result) {
        
        //4. demand节点;
        if (ISOK(data, DemandModel.class)) {
            result = [[TOMVisionDemandView alloc] init];
            [result setData:data];
        }else if(ISOK(data, TOFoModel.class)){
            result = [[TOMVisionFoView alloc] init];
            [result setData:data];
        }else if(ISOK(data, TOAlgModel.class)){
            result = [[TOMVisionAlgView alloc] init];
            [result setData:data];
        }else{
            //TODOTOMORROW20220317: 别的类型还没支持,就先返回baseView;
            result = [[TOMVisionNodeBase alloc] init];
            [result setData:data];
            [result setBackgroundColor:UIColor.redColor];
        }
    }
    
    return result;
}

//MARK:===============================================================
//MARK:                     < onclick >
//MARK:===============================================================
- (IBAction)openCloseBtnOnClick:(id)sender {
    [self close];
}

//MARK:===============================================================
//MARK:                     < TVPanelViewDelegate >
//MARK:===============================================================
-(void) panelSubBtnClicked{
    if (self.curIndex > 0) {
        self.curIndex--;
        [self refreshDisplay];
    }
}

-(void) panelPlusBtnClicked{
    if (self.curIndex < self.models.count - 1) {
        self.curIndex++;
        [self refreshDisplay];
    }
}

@end
