//
//  DemandModel.m
//  SMG_NothingIsAll
//
//  Created by iMac on 2018/8/2.
//  Copyright © 2018年 XiaoGang. All rights reserved.
//

#import "DemandModel.h"
#import "TOFoModel.h"

@interface DemandModel()

@property (strong, nonatomic) NSMutableArray *actionFoModels;

@end

@implementation DemandModel

-(id) init{
    self = [super init];
    if (self) {
        self.initTime = [[NSDate new] timeIntervalSince1970];
    }
    return self;
}

-(NSMutableArray *)actionFoModels{
    if (_actionFoModels == nil) {
        _actionFoModels = [[NSMutableArray alloc] init];
    }
    return _actionFoModels;
}

-(CGFloat) demandUrgentTo{
    return self.urgentTo;
}

//-(id) getCurSubModel{
//    TOFoModel *maxModel = nil;
//    for (TOModelBase *model in self.subModels) {
//        //1. 取不在except中的;
//        if (![SMGUtils containsSub_p:model.content_p parent_ps:self.except_ps]) {
//
//            //2. 最高得分的返回;
//            if (maxModel == nil || maxModel.score < model.score) {
//                maxModel = model;
//            }
//        }
//    }
//    return maxModel;
//}

//MARK:===============================================================
//MARK:                     < private_Method >
//MARK:===============================================================

/**
 *  MARK:--------------------重排序cmvCache--------------------
 *  1. 懒排序,什么时候assLoop,什么时候排序;
 */
//-(void) refreshExpCacheSort{
//    [self.subModels sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
//        TOModelBase *itemA = (TOModelBase*)obj1;
//        TOModelBase *itemB = (TOModelBase*)obj2;
//        return [SMGUtils compareFloatA:itemB.score floatB:itemA.score];
//    }];
//}

@end
