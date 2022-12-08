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

+(AIMatchFoModel*) newWithMatchFo:(AIKVPointer*)matchFo protoOrRegroupFo:(AIKVPointer*)protoOrRegroupFo sumNear:(CGFloat)sumNear nearCount:(NSInteger)nearCount indexDic:(NSDictionary*)indexDic cutIndex:(NSInteger)cutIndex{
    AIFoNodeBase *protoOrRegroupFoNode = [SMGUtils searchNode:protoOrRegroupFo];
    AIMatchFoModel *model = [[AIMatchFoModel alloc] init];
    model.matchFo = matchFo;
    [model.realMaskFo addObjectsFromArray:protoOrRegroupFoNode.content_ps];
    [model.realDeltaTimes addObjectsFromArray:protoOrRegroupFoNode.deltaTimes];
    model.lastFrameTime = [[NSDate date] timeIntervalSince1970];
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

-(NSMutableArray *)realDeltaTimes {
    if (!_realDeltaTimes) _realDeltaTimes = [[NSMutableArray alloc] init];
    return _realDeltaTimes;
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

//在发生完全后,构建完全protoFo时使用获取orders;
-(NSArray*) convertRealMaskFoAndRealDeltaTimes2Orders4CreateProtoFo {
    [AITest test15:self];
    NSMutableArray *order = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < self.realMaskFo.count; i++) {
        AIKVPointer *itemA_p = ARR_INDEX(self.realMaskFo, i);
        NSTimeInterval itemDeltaTime = NUMTOOK(ARR_INDEX(self.realDeltaTimes, i)).doubleValue;
        [order addObject:[AIShortMatchModel_Simple newWithAlg_p:itemA_p inputTime:itemDeltaTime]];
    }
    return order;
}

//MARK:===============================================================
//MARK:                     < publicMethod >
//MARK:===============================================================

/**
 *  MARK:--------------------当前帧有反馈--------------------
 *  @param fbProtoAlg : 瞬时记忆新帧,反馈feedback来的protoAlg;
 *  @version
 *      2022.09.15: 更新indexDic & realMaskFo (参考27097);
 *      2022.09.18: 将反馈处理和推进下一帧,集成到同一个方法执行 (参考27095-9 & 27098-todo3)
 *      2022.11.03: alg复用相似度 (参考27175-1);
 */
-(void) feedbackPushFrame:(AIKVPointer*)fbProtoAlg {
    //----------------当前帧处理----------------
    //1. 数据准备;
    AIFoNodeBase *matchFo = [SMGUtils searchNode:self.matchFo];
    AIKVPointer *waitAlg_p = ARR_INDEX(matchFo.content_ps, self.cutIndex + 1);
    AIAlgNodeBase *waitAlg = [SMGUtils searchNode:waitAlg_p];
    
    //2. 更新status & near & realMaskFo;
    [self setStatus:TIModelStatus_OutBackReason forCutIndex:self.cutIndex];
    self.feedbackNear = [waitAlg getConMatchValue:fbProtoAlg];
    [self.realMaskFo addObject:fbProtoAlg];
    
    //2. 更新realDeltaTimes和lastFrameTime;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    [self.realDeltaTimes addObject:@(now - self.lastFrameTime)];
    self.lastFrameTime = now;
    
    //3. 取到反馈fbProtoAlg的index(应该就是realMaskFo.count)
    NSInteger maskIndex = self.realMaskFo.count - 1;
    
    //4. 取当前waitAlg的index (应该就是cutIndex + 1)
    NSInteger matchIndex = self.cutIndex + 1;
    
    //5. 更新indexDic (V: 末位maskIndex, K: matchIndex);
    [self.indexDic2 setObject:@(maskIndex) forKey:@(matchIndex)];
    
    //----------------推进至下帧----------------
    //1. 推进到下一帧_更新: cutIndex & sumNear(匹配度分子) & nearCount(匹配度分母);
    self.cutIndex ++;
    self.sumNear += self.feedbackNear;
    self.nearCount ++;
    
    //2. 推进到下一步_重置: status & 失效状态 & 反馈相近度 & scoreCache(触发重新计算mv评分);
    [self setStatus:TIModelStatus_LastWait forCutIndex:self.cutIndex];
    self.isExpired = false;
    self.feedbackNear = 0;
    self.scoreCache = defaultScore;
    
    //3. 触发器 (非末帧继续R反省,末帧则P反省);
    [TCForecast forecast_Single:self];
}

//匹配度计算
-(CGFloat) matchFoValue {
    return self.nearCount > 0 ? self.sumNear / self.nearCount : 1;
}

/**
 *  MARK:--------------------推进帧结束(完全帧)时总结 (参考27201-5)--------------------
 *  @desc 触发及功能说明: 当解决方案有效解决了需求时,此处构建具象canset或进行canset再类比抽象;
 *  @desc 另 (方案无效时): 当阻止失败时,不应触发canset再类比 (本方法不做解决失败的处理,仅记录下逻辑说明在此);
 *              a. 在feedbackTIP中反馈负mv后: pFo.status=TIModelStatus_OutBackSameDelta;
 *              b. 在feedbackTOP中反馈负mv后: cansetS.status=TOModelStatus_OuterBack;
 *  @version
 *      2022.11.28: 自然未发生则生成protoCanset,行为有作用则触发再类比生成absCanset (参考27206c-R任务);
 *      2022.12.09: BUG_当解决方案实际执行0条时,不触发canset再类比 (如果触发,会导致抽象为nil,闪退);
 *      2022.12.09: 无论是否进行抽象,都生成具象canset (参考27228);
 */
-(void) pushFrameFinish {

    //TODOTOMORROW20221208:
    //1. 实际训练特性: 此处具象canset容易,但抽象太不易了
    //  思路: 再多训练训练,有了第一个,后面会越来越容易 (但目前还没一个成功抽象的,,,继续训练测试......);
    
    //2. 抽象很难原因: 第2步训练,从扔到飞,都是间隔太久,导致很难有习得通过飞行躲避成功的案例;
    //  方案: 可以尝试下,在扔出木棒后,快速通过躲避成功的案例经历 (较易复现方式,危险地带直投,然后立马下飞躲开...);
    
    //先继续跑跑,看能不能跑到a4;
    
    
    //1. =================有actYes的时,归功于解决方案,执行canset再类比 (参考27206c-R任务)=================
    NSLog(@"当前pFo:%ld 兄弟pFos:%@",self.matchFo.pointerId,[SMGUtils convertArr:self.baseRDemand.pFos convertBlock:^id(AIMatchFoModel *obj) {
        return Pit2FStr(obj.matchFo);
    }]);
    for (TOFoModel *solutionModel in self.baseRDemand.actionFoModels) {
        NSLog(@"item解决方案%@的状态是 %ld 基于pFo: %ld",Pit2FStr(solutionModel.content_p),solutionModel.status,solutionModel.basePFoOrTargetFo_p.pointerId);
        [AITest test17:solutionModel];
        
        //1. 判断处在actYes状态的解决方案 && 解决方案是属性当前pFo决策取得的 (参考27206c-综上&多S问题);
        //a. 非actYes状态的不做canset再类比;
        if (solutionModel.status != TOModelStatus_ActYes) continue;
        
        //b. 非当前pFo下的解决方案,不做canset再类比;
        if (![solutionModel.basePFoOrTargetFo_p isEqual:self.matchFo]) continue;
        
        //c. 数据准备;
        AIFoNodeBase *solutionFo = [SMGUtils searchNode:solutionModel.content_p];
        AIFoNodeBase *pFo = [SMGUtils searchNode:solutionModel.basePFoOrTargetFo_p];
        
        //d. 收集真实发生feedbackAlg (order为0条时,跳过);
        NSArray *order = [solutionModel convertFeedbackAlgAndRealDeltaTimes2Orders4CreateProtoFo:true];
        if (!ARRISOK(order)) continue;
        
        //e. 生成新protoFo时序 (参考27204-6);
        AIFoNodeBase *protoFo = [theNet createConFo:order];
        
        //f. 外类比 & 并将结果持久化 (挂到当前目标帧下标targetFoModel.actionIndex下) (参考27204-4&8);
        AIFoNodeBase *absCansetFo = [AIAnalogy analogyOutside:protoFo assFo:solutionFo type:ATDefault];
        NSLog(@"a4");
        [pFo updateConCanset:absCansetFo.pointer targetIndex:pFo.count];
        [AITest test101:absCansetFo];
        
        //g. 计算出absCansetFo的indexDic & 并将结果持久化 (参考27207-7至11);
        NSDictionary *newIndexDic = [solutionModel convertOldIndexDic2NewIndexDic:pFo.pointer];
        [absCansetFo updateIndexDic:pFo indexDic:newIndexDic];
        [AITest test18:newIndexDic newCanset:absCansetFo absFo:pFo];
        
        //h. 算出spDic (参考27213-5);
        [absCansetFo updateSPDic:[solutionModel convertOldSPDic2NewSPDic]];
        [AITest test20:absCansetFo newSPDic:absCansetFo.spDic];
    }
    
    //2. =================无actYes的S时,归功于自然未发生,则新增protoCanset (参考27206c-R任务)=================
    //a. 数据准备;
    AIFoNodeBase *matchFo = [SMGUtils searchNode:self.matchFo];
    NSArray *orders = [self convertRealMaskFoAndRealDeltaTimes2Orders4CreateProtoFo];
    
    //b. 用realMaskFo & realDeltaTimes生成protoFo (参考27201-1 & 5);
    AIFoNodeBase *protoFo = [theNet createConFo:orders];
    
    //c. 将protoFo挂载到matchFo下的conCansets下 (参考27201-2);
    [matchFo updateConCanset:protoFo.pointer targetIndex:matchFo.count];
    
    //d. 将item.indexDic挂载到matchFo的conIndexDDic下 (参考27201-3);
    [protoFo updateIndexDic:matchFo indexDic:self.indexDic2];
}

/**
 *  MARK:--------------------NSCoding--------------------
 */
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.matchFo = [aDecoder decodeObjectForKey:@"matchFo"];
        self.realMaskFo = [aDecoder decodeObjectForKey:@"realMaskFo"];
        self.realDeltaTimes = [aDecoder decodeObjectForKey:@"realDeltaTimes"];
        self.lastFrameTime = [aDecoder decodeDoubleForKey:@"lastFrameTime"];
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
    [aCoder encodeObject:self.realDeltaTimes forKey:@"realDeltaTimes"];
    [aCoder encodeDouble:self.lastFrameTime forKey:@"lastFrameTime"];
    [aCoder encodeFloat:self.sumNear forKey:@"sumNear"];
    [aCoder encodeInteger:self.nearCount forKey:@"nearCount"];
    [aCoder encodeObject:self.status forKey:@"status"];
    [aCoder encodeObject:self.indexDic2 forKey:@"indexDic2"];
    [aCoder encodeInteger:self.cutIndex forKey:@"cutIndex"];
    [aCoder encodeInteger:self.matchFoStrong forKey:@"matchFoStrong"];
    [aCoder encodeFloat:self.scoreCache forKey:@"scoreCache"];
}

@end
