//
//  AIMatchFoModel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2021/1/23.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import "AIMatchFoModel.h"

@interface AIMatchFoModel ()

/**
 *  MARK:--------------------当前反馈帧的相近度--------------------
 *  @desc 比对feedback输入的protoAlg和当前等待反馈的itemAlg之间相近度,并存到此值下;
 *  @callers
 *      1. 有反馈时,计算并赋值;
 *      2. 跳转下帧时,恢复默认值0;
 */
@property (assign, nonatomic) CGFloat feedbackNear;

@end

@implementation AIMatchFoModel

+(AIMatchFoModel*) newWithMatchFo:(AIKVPointer*)matchFo maskFo:(AIKVPointer*)maskFo sumNear:(CGFloat)sumNear nearCount:(NSInteger)nearCount indexDic:(NSDictionary*)indexDic cutIndex:(NSInteger)cutIndex{
    AIFoNodeBase *maskFoNode = [SMGUtils searchNode:maskFo];
    AIMatchFoModel *model = [[AIMatchFoModel alloc] init];
    model.matchFo = matchFo;
    [model.realMaskFo addObjectsFromArray:maskFoNode.content_ps];
    model.sumNear = sumNear;
    model.nearCount = nearCount;
    model.indexDic2 = [[NSMutableDictionary alloc] initWithDictionary:indexDic];
    model.cutIndex = cutIndex;
    model.scoreCache = defaultScore; //评分缓存默认值;
    return model;
}

//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================
-(NSMutableArray *)realMaskFo {
    if (!_realMaskFo) _realMaskFo = [[NSMutableArray alloc] init];
    return _realMaskFo;
}

-(NSMutableDictionary *)status {
    if (!_status) _status = [[NSMutableDictionary alloc] init];
    return _status;
}

-(TIModelStatus) getStatusForCutIndex:(NSInteger)cutIndex {
    return NUMTOOK([self.status objectForKey:@(cutIndex)]).integerValue;
}

-(void) setStatus:(TIModelStatus)status forCutIndex:(NSInteger)cutIndex {
    [self.status setObject:@(status) forKey:@(cutIndex)];
}

//MARK:===============================================================
//MARK:                     < publicMethod >
//MARK:===============================================================

/**
 *  MARK:--------------------当前帧有反馈--------------------
 *  @version
 *      2022.09.15: 更新indexDic & realMaskFo (参考27097);
 */
-(void) feedbackFrame:(AIKVPointer*)fbProtoAlg {
    //----------------当前帧处理----------------
    //1. 数据准备;
    AIFoNodeBase *matchFo = [SMGUtils searchNode:self.matchFo];
    AIKVPointer *waitAlg_p = ARR_INDEX(matchFo.content_ps, self.cutIndex + 1);
    
    //2. 更新status & near & realMaskFo;
    [self setStatus:TIModelStatus_OutBackReason forCutIndex:self.cutIndex];
    self.feedbackNear = [AIAnalyst compareCansetAlg:waitAlg_p protoAlg:fbProtoAlg];
    [self.realMaskFo addObject:fbProtoAlg];
    
    //3. 取到反馈fbProtoAlg的index(应该就是realMaskFo.count)
    NSInteger maskIndex = self.realMaskFo.count - 1;
    
    //4. 取当前waitAlg的index (应该就是cutIndex + 1)
    NSInteger matchIndex = self.cutIndex + 1;
    
    //5. 更新indexDic (V: 末位maskIndex, K: matchIndex);
    //TODOTEST20220915: 测下此处的新KV是否正确,比如断点查下原KV末位到了哪,或者查下当前时序的推进情况是否与新帧KV符合;
    [self.indexDic2 setObject:@(maskIndex) forKey:@(matchIndex)];
}

//推进至下一帧;
-(void) forwardFrame {
    //1. 推进到下一帧;
    self.cutIndex ++;
    
    //2. 更新匹配度分子分母值;
    self.sumNear += self.feedbackNear;
    self.nearCount ++;
    
    //3. 状态重置 & 失效重置为false & 反馈相近度重置 & 重置scoreCache(触发重新计算mv评分);
    [self setStatus:TIModelStatus_LastWait forCutIndex:self.cutIndex];
    self.isExpired = false;
    self.feedbackNear = 0;
    self.scoreCache = defaultScore;
    
    //4. 触发器 (非末帧继续R反省,末帧则P反省);
    [TCForecast forecast_Single:self];
}

//匹配度计算
-(CGFloat) matchFoValue {
    return self.nearCount > 0 ? self.sumNear / self.nearCount : 1;
}

/**
 *  MARK:--------------------NSCoding--------------------
 */
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.matchFo = [aDecoder decodeObjectForKey:@"matchFo"];
        self.realMaskFo = [aDecoder decodeObjectForKey:@"realMaskFo"];
        self.sumNear = [aDecoder decodeFloatForKey:@"sumNear"];
        self.nearCount = [aDecoder decodeIntegerForKey:@"nearCount"];
        self.status = [aDecoder decodeObjectForKey:@"status"];
        self.indexDic2 = [aDecoder decodeObjectForKey:@"indexDic2"];
        self.cutIndex = [aDecoder decodeIntegerForKey:@"cutIndex"];
        self.matchFoStrong = [aDecoder decodeIntegerForKey:@"matchFoStrong"];
        self.scoreCache = [aDecoder decodeFloatForKey:@"scoreCache"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.matchFo forKey:@"matchFo"];
    [aCoder encodeObject:self.realMaskFo forKey:@"realMaskFo"];
    [aCoder encodeFloat:self.sumNear forKey:@"sumNear"];
    [aCoder encodeInteger:self.nearCount forKey:@"nearCount"];
    [aCoder encodeObject:self.status forKey:@"status"];
    [aCoder encodeObject:self.indexDic2 forKey:@"indexDic2"];
    [aCoder encodeInteger:self.cutIndex forKey:@"cutIndex"];
    [aCoder encodeInteger:self.matchFoStrong forKey:@"matchFoStrong"];
    [aCoder encodeFloat:self.scoreCache forKey:@"scoreCache"];
}

@end
