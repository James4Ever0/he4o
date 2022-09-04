//
//  AIMatchFoModel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2021/1/23.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import "AIMatchFoModel.h"

@implementation AIMatchFoModel

+(AIMatchFoModel*) newWithMatchFo:(AIKVPointer*)matchFo maskFo:(AIKVPointer*)maskFo matchFoValue:(CGFloat)matchFoValue indexDic:(NSDictionary*)indexDic cutIndex:(NSInteger)cutIndex{
    AIMatchFoModel *model = [[AIMatchFoModel alloc] init];
    model.matchFo = matchFo;
    model.maskFo = maskFo;
    model.matchFoValue = matchFoValue;
    model.indexDic = indexDic;
    model.cutIndex = cutIndex;
    model.scoreCache = defaultScore; //评分缓存默认值;
    return model;
}

-(void) forwardFrame {
    //1. 推进到下一帧;
    self.cutIndex ++;
    
    //2. 状态重置 & 失效重置为false;
    self.status = TIModelStatus_LastWait;
    self.isExpired = false;
    
    //3. 重置scoreCache (重新计算mv评分);
    self.scoreCache = defaultScore;
    
    //4. 更新匹配度matchFoValue (可改成单存分子分母两个值,更新时分母+1,分子计算当前的相近度即可);
//    CGFloat near = [AIAnalyst compareCansetAlg:checkAssAlg_p protoAlg:compareProtoAlg];
//    sumNear += near;
//    nearCount ++;
    
    //5. 更新indexDic;
    //[indexDic setObject:@(curIndex) forKey:@(maskFoIndex)];
    
    //5. 触发器 (非末帧继续R反省,末帧则P反省);
    //[AITime setTimeTrigger:deltaTime trigger:^{
}

/**
 *  MARK:--------------------NSCoding--------------------
 */
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.matchFo = [aDecoder decodeObjectForKey:@"matchFo"];
        self.maskFo = [aDecoder decodeObjectForKey:@"maskFo"];
        self.matchFoValue = [aDecoder decodeFloatForKey:@"matchFoValue"];
        self.status = [aDecoder decodeIntegerForKey:@"status"];
        self.indexDic = [aDecoder decodeObjectForKey:@"indexDic"];
        self.cutIndex = [aDecoder decodeIntegerForKey:@"cutIndex"];
        self.matchFoStrong = [aDecoder decodeIntegerForKey:@"matchFoStrong"];
        self.scoreCache = [aDecoder decodeFloatForKey:@"scoreCache"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.matchFo forKey:@"matchFo"];
    [aCoder encodeObject:self.maskFo forKey:@"maskFo"];
    [aCoder encodeFloat:self.matchFoValue forKey:@"matchFoValue"];
    [aCoder encodeInteger:self.status forKey:@"status"];
    [aCoder encodeObject:self.indexDic forKey:@"indexDic"];
    [aCoder encodeInteger:self.cutIndex forKey:@"cutIndex"];
    [aCoder encodeInteger:self.matchFoStrong forKey:@"matchFoStrong"];
    [aCoder encodeFloat:self.scoreCache forKey:@"scoreCache"];
}

@end
