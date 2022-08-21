//
//  TCDebug.m
//  SMG_NothingIsAll
//
//  Created by jia on 2022/8/20.
//  Copyright © 2022年 XiaoGang. All rights reserved.
//

#import "TCDebug.h"

//判断卡了功能->开关
#define TCDebugKaleSwitch false

//调试中的TC名称 (当前调试哪个,就改成哪个名称);
#define DebugingTC @"TCRecognition.m"

//对最后多少条时间汇总分析
#define DebugLastOperesNum 10

//判断为卡状态的阈值 (单位:ms)
#define DebugKaleTime 800

//TCOper操作剔除最小数的阈值 (单位:ms)
#define DebugOperMinTime 200

@interface TCDebug()

//最后几次调试中操作用时记录;
@property (strong, nonatomic) NSMutableArray *lastOperesTimeArr;
@property (assign, nonatomic) NSTimeInterval lastOperTime;
@property (assign, nonatomic) NSTimeInterval lastLoopTime;
@property (strong, nonatomic) NSString *lastOperater;

@end

@implementation TCDebug

/**
 *  MARK:--------------------调试TC的操作--------------------
 *  @desc 说明:
 *          1. 调试用时: 大于DebugOperMinTime(200ms)时,才算达到"分析表"入门资格;
 *          2. 调试卡顿:
 *              a. 记录当前正在调试的DebugingTC最后DebugLastOperesNum(10条);
 *              b. 平均用时超过DebugKaleTime(800ms)时,则判定为卡顿状态;
 *              c. 判断卡顿时,转为植物状态,并暂停强化训练;
 */
-(void) updateOperCount:(NSString*)operater {
    
    //功能1: ============ 调试用时 ============
    NSTimeInterval now = [NSDate new].timeIntervalSince1970 * 1000;
    NSTimeInterval useTime = now - self.lastOperTime;
    BOOL thanMin = useTime > DebugOperMinTime;
    if (self.lastOperTime > 0 && thanMin) {
        //1. 打印计数日志;
        NSString *useTimeStr = @"";
        for (int i = 0; i < (int)(useTime / 100); i++) {useTimeStr = STRFORMAT(@"%@*",useTimeStr);}
        NSLog(@"当前:%@ 操作计数更新:%lld 用时:%@ (%.0f) from:%@",operater,theTC.getOperCount,useTimeStr,useTime,self.lastOperater);
    }
    
    //功能2: ============ 判断卡顿 ============
    if (TCDebugKaleSwitch && thanMin && [self.lastOperater containsString:DebugingTC]) {
        
        //1. 存10条;
        [self.lastOperesTimeArr addObject:@(useTime)];
        if (self.lastOperesTimeArr.count > DebugLastOperesNum) {
            [self.lastOperesTimeArr removeObjectAtIndex:0];
        }
        
        //2. 算出10条总耗时;
        double sumUseTime = 0;
        for (NSNumber *item in self.lastOperesTimeArr) {
            sumUseTime += item.doubleValue;
        }
        
        //3. 平均耗时>800ms时,属于卡顿状态;
        BOOL lastKale = sumUseTime > DebugKaleTime * self.lastOperesTimeArr.count;
        
        //4. 达到10次,才判断是否卡;
        BOOL lastLimited = self.lastOperesTimeArr.count >= DebugLastOperesNum;
        
        //5. 思维控制器工作正常,且判断卡住时,转入植物状态;
        if (!theTC.stopThink && lastLimited && lastKale) {
            
            //a. 设为植物模式;
            NSLog(@"操作计数判断当前为: 卡顿状态,转为植物模式");
            theTC.stopThink = true;
            
            //b. 并暂停强化训练;
            [theRT setPlaying:false];
            
            //d. 调试具体慢原因性能;
            NSArray *debugModels = [theDebug getDebugModels:TCDebugPrefixV2(DebugingTC)];
            for (XGDebugModel *model in debugModels) {
                NSLog(@"%@ 计数:%ld 均耗:%.0f = 总耗:%.0f 读:%ld 写:%ld",model.key,model.sumCount,model.sumTime / model.sumCount,model.sumTime,model.sumReadCount,model.sumWriteCount);
            }
        }
    }
    
    //5. 记录lastOperater
    self.lastOperTime = now;
    self.lastOperater = operater;
}

/**
 *  MARK:--------------------调试TC的循环--------------------
 */
-(void) updateLoopId {
    //调试用时
    NSTimeInterval now = [NSDate new].timeIntervalSince1970 * 1000;
    NSTimeInterval useTime = now - self.lastLoopTime;
    if (self.lastLoopTime > 0 && useTime > 2000)
        NSLog(@"循环计数更新:%lld 用时:%.0f ========================================",theTC.getLoopId,useTime);
    self.lastLoopTime = now;
}

//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================
-(NSMutableArray*) lastOperesTimeArr {
    if (!_lastOperesTimeArr) {
        _lastOperesTimeArr = [[NSMutableArray alloc] init];
    }
    return _lastOperesTimeArr;
}

@end
