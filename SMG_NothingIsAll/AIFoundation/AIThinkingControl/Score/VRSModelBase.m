//
//  VRSModelBase.m
//  SMG_NothingIsAll
//
//  Created by jia on 2021/11/2.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import "VRSModelBase.h"

@implementation VRSModelBase

/**
 *  MARK:--------------------获取评分--------------------
 */
-(double) getScore{
    //1. SP都为0时,稳定性为0;
    if (self.pScore == 0 && self.sScore == 0) {
        return 0;
    }
    
    //2. 否则根据SP得分,算出稳定性;
    double totalScore = self.pScore + self.sScore;
    double pPercent = self.pScore / totalScore;
    return (pPercent * 2) - 1;
}

/**
 *  MARK:--------------------获取稳定性--------------------
 *  @desc 用于判断哪个最稳定 (可以是S也可以是P) (参考24103-BUG1-一级排序因子);
 *  @result 越靠近1,则越稳定;
 */
-(double) getStablity{
    return fabs(self.score);
}

@end
