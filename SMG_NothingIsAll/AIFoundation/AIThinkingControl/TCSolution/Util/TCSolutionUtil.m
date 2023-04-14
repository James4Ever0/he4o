//
//  TCSolutionUtil.m
//  SMG_NothingIsAll
//
//  Created by jia on 2022/6/5.
//  Copyright © 2022年 XiaoGang. All rights reserved.
//

#import "TCSolutionUtil.h"

@implementation TCSolutionUtil


//MARK:===============================================================
//MARK:                     < 快思考 >
//MARK:===============================================================

/**
 *  MARK:--------------------R快思考--------------------
 *  @desc 习惯 (参考26142);
 *  @version
 *      2022.11.30: 先关掉快思考功能,因为慢思考有了indexDic和相似度复用后并不慢,并且effectDic和SP等效 (参考27205);
 */
+(AISolutionModel*) rSolution_Fast:(ReasonDemandModel *)demand except_ps:(NSArray*)except_ps{
    if (!Switch4FastSolution) return nil;
    //1. 数据准备;
    except_ps = ARRTOOK(except_ps);
    
    //2. 收集所有解决方案候选集;
    NSArray *cansetModels = [SMGUtils convertArr:demand.validPFos convertItemArrBlock:^NSArray *(AIMatchFoModel *pFoM) {
        //a. 取出pFo的effectDic候选集;
        AIFoNodeBase *pFo = [SMGUtils searchNode:pFoM.matchFo];
        NSArray *cansetFos = [pFo getValidEffs:pFo.count];
        if (Log4Solution_Fast && ARRISOK(cansetFos)) NSLog(@"\tF%ld的第%ld帧取: %@",pFo.pointer.pointerId,pFo.count,CLEANSTR(cansetFos));
        
        //b. 分析analyst结果 & 排除掉不适用当前场景的(为nil) (参考26232-TODO8);
        return [SMGUtils convertArr:cansetFos convertBlock:^id(AIEffectStrong *eff) {
            //c. 分析比对结果;
            NSInteger rAleardayCount = [self getRAleardayCount:demand pFo:pFoM];
            AISolutionModel *sModel = [self getSolutionModel:eff.solutionFo sceneFo:pFoM.matchFo basePFoOrTargetFoModel:pFoM ptAleardayCount:rAleardayCount isH:true];
            return sModel;
        }];
    }];
    
    //3. 快思考算法;
    return [TCSolutionUtil generalSolution_Fast:demand cansets:cansetModels except_ps:except_ps];
}

/**
 *  MARK:--------------------H快思考--------------------
 *  @desc 习惯 (参考26142);
 *  @version
 *      2022.11.30: 先关掉快思考功能,因为慢思考有了indexDic和相似度复用后并不慢,并且effectDic和SP等效 (参考27205);
 */
+(AISolutionModel*) hSolution_Fast:(HDemandModel *)hDemand except_ps:(NSArray*)except_ps{
    if (!Switch4FastSolution) return nil;
    //1. 数据准备;
    TOFoModel *targetFoM = (TOFoModel*)hDemand.baseOrGroup.baseOrGroup;
    AIFoNodeBase *targetFo = [SMGUtils searchNode:targetFoM.content_p];
    
    //2. 从targetFo取解决方案候选集;
    NSArray *cansetFos = [targetFo.effectDic objectForKey:@(targetFoM.actionIndex)];
    
    //3. 分析analyst结果 & 排除掉不适用当前场景的(为nil) (参考26232-TODO8);
    NSArray *cansetModels = [SMGUtils convertArr:cansetFos convertBlock:^id(AIEffectStrong *eff) {
        //a. 分析比对结果;
        NSInteger hAleardayCount = [self getHAleardayCount:targetFoM];
        AISolutionModel *sModel = [self getSolutionModel:eff.solutionFo sceneFo:targetFoM.content_p basePFoOrTargetFoModel:targetFoM ptAleardayCount:hAleardayCount isH:true];
        return sModel;
    }];
    
    //3. 快思考算法;
    return [TCSolutionUtil generalSolution_Fast:hDemand cansets:cansetModels except_ps:except_ps];
}

/**
 *  MARK:--------------------快思考--------------------
 *  @desc 习惯 (参考26142);
 *  @version
 *      2022.06.03: 将cansets中hnStrong合并,一直这么设计的,今发现写没实现,补上;
 *      2022.06.03: 排除掉候选方案不适用当前场景的 (参考26192);
 *      2022.06.05: 支持三个阈值 (参考26199);
 *      2022.06.05: 将R快思考和H快思考整理成通用快思考算法;
 *      2022.06.09: 废弃阈值方案和H>5的要求 (参考26222-TODO3);
 *      2022.06.09: 弃用阈值方案,改为综合排名 (参考26222-TODO2);
 *      2022.06.12: 废弃同cansetFo的effStrong累计 (参考26232-TODO8);
 *      2022.06.12: 每个pFo独立做analyst比对,转为cansetModels (参考26232-TODO8);
 *      2022.10.15: 快思考支持反思,不然因为一点点小任务就死循环 (参考27143-问题2);
 */
+(AISolutionModel*) generalSolution_Fast:(DemandModel *)demand cansets:(NSArray*)cansets except_ps:(NSArray*)except_ps{
    //1. 数据准备;
    except_ps = ARRTOOK(except_ps);
    BOOL havBack = ISOK(demand, HDemandModel.class); //H有后段,别的没有;
    NSLog(@"1. 快思考protoCansets数:%ld",cansets.count);
    
    //2. solutionModels过滤器;
    cansets = [SMGUtils filterArr:cansets checkValid:^BOOL(AISolutionModel *item) {
        //a. 排除不应期;
        if([except_ps containsObject:item.cansetFo]) return false;
        
        //b. 时间不急评价: 不急 = 解决方案所需时间 <= 父任务能给的时间 (参考:24057-方案3,24171-7);
        if (![AIScore FRS_Time:demand solutionModel:item]) return false;

        ////2. 后段-目标匹配 (阈值>80%) (参考26199-TODO1);
        //if (item.backMatchValue < 0.8f) return false;
        //
        ////3. 中段-按有效率 (effectScore>0) (参考26199-TODO2);
        //if (item.effectScore <= 0) return false;
        //
        ////4. 前段-场景匹配 (阈值>80%) (参考26199-TODO3);
        //if (item.frontMatchValue < 0.8) return false;

        //5. 闯关成功;
        return true;
    }];
    NSLog(@"2. (不应期 & FRSTime & 后中后段阈值)过滤后:%ld",cansets.count);

    //6. 对候选集排序;
    NSArray *sortCansets = [AIRank solutionFoRankingV2:cansets needBack:havBack fromSlow:false];
    NSLog(@"3. 有效率排序后:%ld",cansets.count);
    if (Log4Solution_Fast) for (AISolutionModel *m in ARR_SUB(sortCansets, 0, 5)) {
        NSLog(@"\t(前%.2f 中%.2f 后%.2f) %@",m.frontMatchValue,m.midEffectScore,m.backMatchValue,Pit2FStr(m.cansetFo));
    }

    //6. 逐条S反思;
    AISolutionModel *result = nil;
    for (AISolutionModel *item in sortCansets) {
        BOOL score = [TCRefrection refrection:item demand:demand];
        if (score) {
            result = item;
            break;
        }
    }
    
    //7. 日志及更新强度值等;
    if (result) {
        if (Log4Solution && result) NSLog(@"4. 快思考最佳结果:F%ld (前%.2f 中%.2f 后%.2f",result.cansetFo.pointerId,result.frontMatchValue,result.midEffectScore,result.backMatchValue);
        
        //8. 更新其前段帧的con和abs抽具象强度 (参考28086-todo2);
        [AINetUtils updateConAndAbsStrongByIndexDic:result.matchFrontIndexDic matchFo:result.sceneFo cansetFo:result.cansetFo];
        
        //16. 更新后段的的具象强度 (参考28092-todo4);
        [AINetUtils updateConAndAbsStrongByIndexDic:result.backIndexDic matchFo:result.sceneFo cansetFo:result.cansetFo];
    }
    
    //8. 将首条最佳方案返回;
    return result;
}


//MARK:===============================================================
//MARK:                     < 慢思考 >
//MARK:===============================================================

/**
 *  MARK:--------------------H慢思考--------------------
 */
+(AISolutionModel*) hSolution_Slow:(HDemandModel *)hDemand except_ps:(NSArray*)except_ps{
    //1. 取targetFo;
    TOFoModel *targetFoModel = (TOFoModel*)hDemand.baseOrGroup.baseOrGroup;
    
    //2. 取出cansetFos候选集;
    //TODOTEST20221123: 测下此处取actionIndex是否正确...
    NSArray *cansetFos = [self getCansetFos_SlowV2:targetFoModel.content_p targetIndex:targetFoModel.actionIndex];
    NSLog(@"第1步 H候选集数:%ld fromTargetFo:%@ (帧%ld)",cansetFos.count,Pit2FStr(targetFoModel.content_p),targetFoModel.actionIndex);
    
    //3. 过滤器 & 转cansetModels候选集 (参考26128-第1步 & 26161-1&2&3);
    NSInteger hAleardayCount = [self getHAleardayCount:targetFoModel];
    NSArray *cansetModels = [SMGUtils convertArr:cansetFos convertBlock:^id(AIKVPointer *cansetFo_p) {
        return [self getSolutionModel:cansetFo_p sceneFo:targetFoModel.content_p basePFoOrTargetFoModel:targetFoModel ptAleardayCount:hAleardayCount isH:true];
    }];
    
    //4. 慢思考;
    return [self generalSolution_Slow:hDemand cansetModels:cansetModels except_ps:except_ps];
}

/**
 *  MARK:--------------------R慢思考--------------------
 */
+(AISolutionModel*) rSolution_Slow:(ReasonDemandModel *)demand except_ps:(NSArray*)except_ps {
    /////////// v3新版 ///////////
    //1. 收集cansetModels候选集;
    NSArray *sceneModels = [self getSceneFos_SlowV3:demand];
    NSLog(@"第1步 R候选集数:%ld",sceneModels.count);
    
    //2. 每个cansetModel转solutionModel;
    NSMutableArray *cansetModels = [[NSMutableArray alloc] init];
    for (AISceneModel *sceneModel in sceneModels) {
        
        //3. 取出overrideCansets;
        NSArray *cansets = ARRTOOK([sceneModel overrideCansets]);
        for (AIKVPointer *canset in cansets) {
            NSInteger aleardayCount = sceneModel.cutIndex + 1;
            AIMatchFoModel *pFo = [SMGUtils filterSingleFromArr:demand.validPFos checkValid:^BOOL(AIMatchFoModel *item) {
                return [item.matchFo isEqual:sceneModel.getRoot.scene];
            }];
            
            //4. 过滤器 & 转cansetModels候选集 (参考26128-第1步 & 26161-1&2&3);
            AISolutionModel *cansetModel = [self getSolutionModel:canset sceneFo:sceneModel.scene basePFoOrTargetFoModel:pFo ptAleardayCount:aleardayCount isH:false];
            if (cansetModel) [cansetModels addObject:cansetModel];
        }
    }

    //5. 慢思考;
    return [self generalSolution_Slow:demand cansetModels:cansetModels except_ps:except_ps];
}

/**
 *  MARK:--------------------慢思考--------------------
 *  @desc 思考求解: 前段匹配,中段加工,后段静默 (参考26127);
 *  @version
 *      2022.06.04: 修复结果与当前场景相差甚远BUG: 分三级排序窄出 (参考26194 & 26195);
 *      2022.06.09: 将R和H的慢思考封装成同一方法,方便调用和迭代;
 *      2022.06.09: 弃用阈值方案,改为综合排名 (参考26222-TODO2);
 *      2022.06.12: 每个pFo独立做analyst比对,转为cansetModels (参考26232-TODO8);
 *      2023.02.19: 最终激活后,将match和canset的前段抽具象强度+1 (参考28086-todo2);
 */
+(AISolutionModel*) generalSolution_Slow:(DemandModel *)demand cansetModels:(NSArray*)cansetModels except_ps:(NSArray*)except_ps {
    //1. 数据准备;
    [AITest test13:cansetModels];
    except_ps = ARRTOOK(except_ps);
    AISolutionModel *result = nil;
    BOOL isH = ISOK(demand, HDemandModel.class); //H有后段,别的没有;
    NSLog(@"第5步 Anaylst匹配成功:%ld",cansetModels.count);//测时94条
    
    //8. 排除不应期;
    cansetModels = [SMGUtils filterArr:cansetModels checkValid:^BOOL(AISolutionModel *item) {
        return ![except_ps containsObject:item.cansetFo];
    }];
    NSLog(@"第6步 排除不应期:%ld",cansetModels.count);//测时xx条
    
    //9. 对下一帧做时间不急评价: 不急 = 解决方案所需时间 <= 父任务能给的时间 (参考:24057-方案3,24171-7);
    cansetModels = [SMGUtils filterArr:cansetModels checkValid:^BOOL(AISolutionModel *item) {
        return [AIScore FRS_Time:demand solutionModel:item];
    }];
    NSLog(@"第7步 排除FRSTime来不及的:%ld",cansetModels.count);//测时xx条
    
    //10. 计算衰后stableScore并筛掉为0的 (参考26128-2-1 & 26161-5);
    //NSArray *outOfFos = [SMGUtils convertArr:cansetModels convertBlock:^id(AISolutionModel *obj) {
    //    return obj.cansetFo;
    //}];
    //for (AISolutionModel *model in cansetModels) {
    //    AIFoNodeBase *cansetFo = [SMGUtils searchNode:model.cansetFo];
    //    model.stableScore = [TOUtils getColStableScore:cansetFo outOfFos:outOfFos startSPIndex:model.cutIndex + 1 endSPIndex:model.targetIndex];
    //}
    //cansetModels = [SMGUtils filterArr:cansetModels checkValid:^BOOL(AISolutionModel *item) {
    //    return item.stableScore > 0;
    //}];
    //NSLog(@"第8步 排序中段稳定性<=0的:%ld",cansetModels.count);//测时xx条
    
    //11. 根据候选集综合分排序 (参考26128-2-2 & 26161-4);
    NSArray *sortModels = [AIRank solutionFoRankingV2:cansetModels needBack:isH fromSlow:true];
    
    //12. debugLog
    for (AISolutionModel *model in sortModels) {
        AIFoNodeBase *sceneFo = [SMGUtils searchNode:model.sceneFo];
        AIEffectStrong *effStrong = [TOUtils getEffectStrong:sceneFo effectIndex:sceneFo.count solutionFo:model.cansetFo];
        NSString *effDesc = effStrong ? effStrong.description : @"";
        AIFoNodeBase *cansetFo = [SMGUtils searchNode:model.cansetFo];
        if (Log4Solution_Slow) NSLog(@"%ld: %@ (前%.2f 中%.2f 后%.2f) fromSceneFo:F%ld eff:%@ sp:%@",[sortModels indexOfObject:model],Pit2FStr(model.cansetFo),model.frontMatchValue,model.midStableScore,model.backMatchValue,sceneFo.pointer.pointerId,effDesc,CLEANSTR(cansetFo.spDic));
    }
    
    //13. 取通过S反思的最佳S;
    for (AISolutionModel *item in sortModels) {
        BOOL score = [TCRefrection refrection:item demand:demand];
        if (!score) continue;
        
        //14. 闯关成功,取出最佳,跳出循环;
        result = item;
        break;
    }
    
    //14. 返回最佳解决方案;
    if (result) {
        AIFoNodeBase *resultFo = [SMGUtils searchNode:result.cansetFo];
        NSLog(@"慢思考最佳结果:F%ld (前%.2f 中%.2f 后%.2f) %@",result.cansetFo.pointerId,result.frontMatchValue,result.midStableScore,result.backMatchValue,CLEANSTR(resultFo.spDic));
        
        //15. 更新其前段帧的con和abs抽具象强度 (参考28086-todo2);
        [AINetUtils updateConAndAbsStrongByIndexDic:result.matchFrontIndexDic matchFo:result.sceneFo cansetFo:result.cansetFo];
        
        //16. 更新后段的的具象强度 (参考28092-todo4);
        [AINetUtils updateConAndAbsStrongByIndexDic:result.backIndexDic matchFo:result.sceneFo cansetFo:result.cansetFo];
        
        //17. 更新其前段alg引用value的强度;
        [AINetUtils updateAlgRefStrongByIndexDic:result.protoFrontIndexDic matchFo:result.cansetFo];
    }
    return result;
}


//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================

/**
 *  MARK:--------------------取候选集fos--------------------
 *  @param pFoOrTargetFoOfMatch_p : R时传pFo, H时传targetFo;
 *  @version
 *      2022.07.14: 将取抽象,同级,自身全废弃掉,改为仅取具象 (参考27049);
 *      2022.07.15: 每个pFo下支持limit (参考27048-TODO6);
 *      2022.11.19: v2更新,支持从conCansets中取数据 (参考20202-1)
 *      2022.11.19: v2的limit由5改为500 (因为conCansets的复用数据更多,性能ok) (参考27202-2);
 *      2023.02.20: 取消limit,因为后面的过滤器和竞争机制完善了,完全不需要强行切掉一些 (参考n28p08 & n28p09);
 */
+(NSArray*) getCansetFos_SlowV2:(AIKVPointer*)pFoOrTargetFoOfMatch_p targetIndex:(NSInteger)targetIndex{
    AIFoNodeBase *matchFo = [SMGUtils searchNode:pFoOrTargetFoOfMatch_p];
    return [matchFo getConCansets:targetIndex];
}

/**
 *  MARK:--------------------cansets--------------------
 *  @desc 收集三处候选集 (参考29069-todo3);
 *  @status 目前仅支持R任务,等到做去皮训练时有需要再支持H任务 (29069-todo2);
 *  @version
 *      2023.04.13: 过滤出有同区mv指向的,才收集到各级候选集中 (参考29069-todo4);
 *      2023.04.14: 为sceneModel记录cutIndex (参考29069-todo5.6);
 *  @result 将三级全收集返回 (返回的数据为: I,Father,Brother三者场景生成的CansetModel);
 */
+(NSArray*) getSceneFos_SlowV3:(ReasonDemandModel*)demand {
    //1. 数据准备;
    NSArray *iModels = nil;
    NSArray *fatherModels = nil;
    NSArray *brotherModels = nil;
    
    //2. 取自己级;
    iModels = [SMGUtils convertArr:demand.validPFos convertBlock:^id(AIMatchFoModel *pFo) {
        NSInteger aleardayCount = [self getRAleardayCount:demand pFo:pFo];
        return [AISceneModel newWithBase:nil type:CansetTypeI scene:pFo.matchFo cutIndex:aleardayCount - 1];
    }];
    
    //3. 取父类级;
    for (AISceneModel *iModel in iModels) {
        AIFoNodeBase *iFo = [SMGUtils searchNode:iModel.scene];
        NSArray *fatherScenePorts = [AINetUtils absPorts_All:iFo];
        
        //a. 过滤器 & 转为CansetModel;
        fatherModels = [SMGUtils convertArr:fatherScenePorts convertBlock:^id(AIPort *item) {
            //a1. 过滤father不含截点的 (参考29069-todo5.6);
            NSDictionary *indexDic = [iFo getAbsIndexDic:item.target_p];
            NSNumber *fatherCutIndex = ARR_INDEX([indexDic allKeysForObject:@(iModel.cutIndex)], 0);
            if (!fatherCutIndex) return nil;
            
            //a2. 过滤无同区mv指向的 (参考29069-todo4);
            AIFoNodeBase *fo = [SMGUtils searchNode:item.target_p];
            if (![iFo.cmvNode_p.identifier isEqualToString:fo.cmvNode_p.identifier]) return nil;
            
            //a3. 将father生成模型;
            return [AISceneModel newWithBase:iModel type:CansetTypeFather scene:item.target_p cutIndex:fatherCutIndex.integerValue];
        }];
    }
    
    //4. 取兄弟级;
    for (AISceneModel *fatherModel in fatherModels) {
        AIFoNodeBase *fatherFo = [SMGUtils searchNode:fatherModel.scene];
        NSArray *brotherScenePorts = [AINetUtils conPorts_All:fatherFo];
        
        //a. 过滤器 & 转为CansetModel;
        brotherModels = [SMGUtils convertArr:brotherScenePorts convertBlock:^id(AIPort *item) {
            //a1. 过滤brother不含截点的 (参考29069-todo5.6);
            NSDictionary *indexDic = [fatherFo getConIndexDic:item.target_p];
            NSNumber *brotherCutIndex = [indexDic objectForKey:@(fatherModel.cutIndex)];
            if (!brotherCutIndex) return nil;
            
            //a2. 过滤无同区mv指向的 (参考29069-todo4);
            AIFoNodeBase *fo = [SMGUtils searchNode:item.target_p];
            if (![fatherFo.cmvNode_p.identifier isEqualToString:fo.cmvNode_p.identifier]) return nil;
            
            //a3. 将brother生成模型;
            return [AISceneModel newWithBase:fatherModel type:CansetTypeBrother scene:item.target_p cutIndex:brotherCutIndex.integerValue];
        }];
    }
    
    //5. 将三级全收集返回;
    NSMutableArray *result = [[NSMutableArray alloc] init];
    [result addObjectsFromArray:iModels];
    [result addObjectsFromArray:fatherModels];
    [result addObjectsFromArray:brotherModels];
    return result;
}

+(NSInteger) getRAleardayCount:(ReasonDemandModel*)rDemand pFo:(AIMatchFoModel*)pFo{
    //1. 数据准备;
    BOOL isRoot = !rDemand.baseOrGroup;
    TOFoModel *demandBaseFo = (TOFoModel*)rDemand.baseOrGroup;
    
    //3. 取pFo已发生个数 (参考26232-TODO3);
    NSInteger pFoAleardayCount = 0;
    if (isRoot) {
        //a. 根R任务时 (参考26232-TODO5);
        pFoAleardayCount = pFo.cutIndex + 1;
    }else{
        //b. 子R任务时 (参考26232-TODO6);
        pFoAleardayCount = [SMGUtils filterArr:pFo.indexDic2.allValues checkValid:^BOOL(NSNumber *item) {
            int maskIndex = item.intValue;
            return maskIndex <= demandBaseFo.actionIndex;
        }].count;
    }
    return pFoAleardayCount;
}

+(NSInteger) getHAleardayCount:(TOFoModel*)targetFoM {
    //1. 已发生个数 (targetFo已行为化部分即已发生) (参考26161-模型);
    NSInteger targetFoAleardayCount = targetFoM.actionIndex;
    return targetFoAleardayCount;
}

/**
 *  MARK:--------------------递归找出pFo (参考28025-todo8)--------------------
 *  @desc 适用范围: 即可用于R任务,也可用于H任务;
 *  @desc 执行说明: H任务会自动递归,直到找到R为止   /   R任务不会递归,直接返回R的pFo;
 */
+(AIMatchFoModel*) getPFo:(AIKVPointer*)cansetFo_p basePFoOrTargetFoModel:(id)basePFoOrTargetFoModel {
    //1. 本次非R时: 继续递归;
    if (ISOK(basePFoOrTargetFoModel, TOFoModel.class)) {
        TOFoModel *baseTargetFo = (TOFoModel*)basePFoOrTargetFoModel;
        return [self getPFo:baseTargetFo.content_p basePFoOrTargetFoModel:baseTargetFo.basePFoOrTargetFoModel];
    }
    //2. 本次是R时: 返回最终找到的pFo;
    else {
        return basePFoOrTargetFoModel;
    }
}

/**
 *  MARK:--------------------条件满足时: 获取前段indexDic--------------------
 *  @desc 即从proto中找abs: 判断当前proto场景对abs是条件满足的 (参考28052-2);
 *  @param absCutIndex : 其中absFo执行到的最大值 (含absCutIndex) (是ptAleardayCount-1对应的canset下标);
 *  @version
 *      2023.02.04: 初版,为解决条件满足不完全的问题,此方法将尝试从proto找出canset前段的每帧 (参考28052);
 *  @result 在proto中全找到canset的前段则返回indexDic映射,未全找到时(条件不满足)返回nil;
 */
+(NSDictionary*) getFrontIndexDic:(AIFoNodeBase*)protoFo absFo:(AIFoNodeBase*)absFo absCutIndex:(NSInteger)absCutIndex {
    //1. 数据准备;
    NSMutableDictionary *indexDic = [[NSMutableDictionary alloc] init];
    if (!protoFo || !absFo) return nil;
        
    //2. 每帧match都到proto里去找,找到则记录proto的进度,找不到则全部失败;
    NSInteger protoMin = 0;
    
    //2. 说明: 所有已发生帧,都要判断一下条件满足 (absCutIndex之前全是前段) (参考28022-todo4);
    for (NSInteger absI = 0; absI < absCutIndex + 1; absI ++) {
        AIKVPointer *absAlg = ARR_INDEX(absFo.content_ps, absI);
        BOOL findItem = false;
        for (NSInteger protoI = protoMin; protoI < protoFo.count; protoI++) {
            AIKVPointer *protoAlg = ARR_INDEX(protoFo.content_ps, protoI);
            //3. B源于absFo,此处只判断B是1层抽象 (参考27161-调试1&调试2);
            //3. 单条判断方式: 此处proto抽象仅指向刚识别的matchAlgs,所以与contains等效 (参考28052-3);
            BOOL mIsC = [TOUtils mIsC_1:protoAlg c:absAlg];
            if (mIsC) {
                //4. 找到了 & 记录protoI的进度;
                findItem = true;
                protoMin = protoI + 1;
                [indexDic setObject:@(protoI) forKey:@(absI)];
                if (Log4SceneIsOk) NSLog(@"\t第%ld帧,条件满足通过 canset:%@ (fromProto:F%ldA%ld)",absI,Pit2FStr(absAlg),protoFo.pointer.pointerId,protoAlg.pointerId);
                break;
            }
        }
        
        //5. 有一条失败,则全失败;
        if (!findItem) {
            if (Log4SceneIsOk) NSLog(@"\t第%ld帧,条件满足未通过 canset:%@ (fromProtoFo:F%ld)",absI,Pit2FStr(absAlg),protoFo.pointer.pointerId);
            return nil;
        }
    }
    
    //6. 全找到,则成功;
    if (Log4SceneIsOk) NSLog(@"条件满足通过:%@ (absCutIndex:%ld fromProtoFo:%ld)",Fo2FStr(absFo),absCutIndex,protoFo.pointer.pointerId);
    return indexDic;
}

//MARK:===============================================================
//MARK:                     < Fo相似度 (由TO调用) >
//MARK:===============================================================

/**
 *  MARK:--------------------时序比对--------------------
 *  @desc 初步比对候选集是否适用于protoFo (参考26128-第1步);
 *  @param ptAleardayCount      : ptFo已发生个数: 即取得"canset的basePFoOrTargetFo推进到哪了"的截点 (aleardayCount = cutIndex+1 或 actionIndex);
 *                                  1. 根R=cutIndex+1
 *                                  2. 子R=父actionIndex对应indexDic条数;
 *                                  3. H.actionIndex前已发生;
 *  @param sceneFo_p            : 当前cansetFo_p挂在哪个场景fo下就传哪个;
 *  @param basePFoOrTargetFoModel : 一用来取protoFo用,二用来传参给结果AISolutionModel用;
 *  @version
 *      2022.05.30: 匹配度公式改成: 匹配度总和/proto长度 (参考26128-1-4);
 *      2022.05.30: R和H模式复用封装 (参考26161);
 *      2022.06.11: 修复反思子任务没有protoFo用于analyst的BUG (参考26224-方案图);
 *      2022.06.11: 改用pFo参与analyst算法比对 & 并改取pFo已发生个数计算方式 (参考26232-TODO3&5&6);
 *      2022.06.12: 每帧analyst都映射转换成maskFo的帧元素比对 (参考26232-TODO4);
 *      2022.07.14: filter过滤器S的价值pk迭代: 将过滤负价值的,改成过滤无价值指向的 (参考27048-TODO4&TODO9);
 *      2022.07.20: filter过滤器不要求mv指向 (参考27055-步骤1);
 *      2022.09.15: 导致任务的maskFo不从demand取,而是从pFo取 (因为它在推进时会变化) (参考27097-todo3);
 *      2022.11.03: compareHCansetFo比对中复用alg相似度 (参考27175-3);
 *      2022.11.03: 复用alg相似度 (参考27175-2&3);
 *      2022.11.20: 改为match与canset比对,复用indexDic和alg相似度 (参考27202-3&4&5);
 *      2022.11.20: 持久化复用: 支持indexDic复用和概念matchValue复用 (参考20202-3&4);
 *      2022.12.03: 修复复用matchValue有时为0的问题 (参考27223);
 *      2022.12.03: 当canset前段有遗漏时,该方案无效 (参考27224);
 *      2023.01.08: filter过滤器加上条件满足过滤器-R任务部分 (参考28022);
 *      2023.01.08: filter过滤器V1末版说明: 根据28025,递归找match,proto,canset三者的映射,来判断条件满足,已废弃 (参考28023&28051);
 *      2023.01.08: 将R和H的时序比对,整理删除仅留下这个通用时序比对方法;
 *      2023.02.04: filter过滤器V2版本,解决原方式条件满足不完全问题 (参考28052);
 *      2023.02.04: 修复条件满足不完全问题 (参考28052);
 *      2023.02.17: 从Analyze整理到TCSolutionUtil中,因为它现在其实就是获取SolutionModel用的 (参考28084-1);
 *      2023.02.17: 废弃filter过滤器,并合并到此处来 (参考28084-2);
 *      2023.02.18: 计算前段竞争值 (参考28084-4);
 *      2023.03.16: 先用任意帧sp值>5脱离惰性期 (参考28182-todo9);
 *      2023.03.18: 惰性期阈值改为eff>2时脱离惰性期 (参考28185-todo6);
 *  @result 返回cansetFo前段匹配度 & 以及已匹配的cutIndex截点;
 */
+(AISolutionModel*) getSolutionModel:(AIKVPointer*)cansetFo_p sceneFo:(AIKVPointer*)sceneFo_p basePFoOrTargetFoModel:(id)basePFoOrTargetFoModel ptAleardayCount:(NSInteger)ptAleardayCount isH:(BOOL)isH {
    //1. 数据准备 & 复用indexDic & 取出pFoOrTargetFo;
    AIFoNodeBase *matchFo = [SMGUtils searchNode:sceneFo_p];
    AIFoNodeBase *cansetFo = [SMGUtils searchNode:cansetFo_p];
    NSInteger matchTargetIndex = isH ? ptAleardayCount : matchFo.count;
    
    //2. 判断是否H任务 (H有后段,别的没有);
    int minCount = isH ? 2 : 1;
    if (Log4SolutionFilter) NSLog(@"S过滤器 checkItem: %@",Pit2FStr(cansetFo_p));
    if (cansetFo.count < minCount) return nil; //过滤1: 过滤掉长度不够的 (因为前段全含至少要1位,中段修正也至少要0位,后段H目标要1位R要0位);
    
    //3. 惰性期 (阈值为2: EFF默认值为1,达到阈值时触发) (参考28182-todo9 & 28185-todo6);
    AIEffectStrong *effStrong = [TOUtils getEffectStrong:matchFo effectIndex:matchFo.count solutionFo:cansetFo_p];
    if (effStrong.hStrong <= 2) return nil;
    //NSLog(@"惰性期通过:%@",CLEANSTR(cansetFo.spDic));
    
    //5. 根据matchFo取得与canset的indexDic映射;
    NSDictionary *indexDic = [cansetFo getAbsIndexDic:sceneFo_p];
    [AITest test102:cansetFo];
    
    //2. 计算出canset的cutIndex (canset的cutIndex,也已在proto中发生) (参考26128-1-1);
    //7. 根据ptAleardayCount取出对应的cansetIndex,做为中段截点 (aleardayCount - 1 = cutIndex);
    NSInteger matchCutIndex = ptAleardayCount - 1;
    NSInteger cansetCutIndex = NUMTOOK([indexDic objectForKey:@(matchCutIndex)]).integerValue;
    
    //8. canset目标下标 (R时canset没有mv,所以要用count-1);
    NSInteger cansetTargetIndex = isH ? NUMTOOK([indexDic objectForKey:@(ptAleardayCount)]).integerValue : cansetFo.count - 1;
    if (cansetCutIndex < matchCutIndex) return nil; //过滤2: 判断canset前段是否有遗漏 (参考27224);
    if (cansetFo.count <= cansetCutIndex + 1) return nil; //过滤3: 过滤掉canset没后段的 (没可行为化的东西) (参考28052-4);
    
    //9. 递归找到protoFo;
    AIMatchFoModel *pFo = [self getPFo:cansetFo_p basePFoOrTargetFoModel:basePFoOrTargetFoModel];
    AIKVPointer *protoFo_p = pFo.baseRDemand.protoOrRegroupFo;
    AIFoNodeBase *protoFo = [SMGUtils searchNode:protoFo_p];
    
    //10. 判断protoFo对cansetFo条件满足 (返回条件满足的每帧间映射);
    NSDictionary *protoFrontIndexDic = [self getFrontIndexDic:protoFo absFo:cansetFo absCutIndex:cansetCutIndex];
    if (!DICISOK(protoFrontIndexDic)) return nil; //过滤4: 条件不满足时,直接返回nil (参考28052-2 & 28084-3);
    
    //4. 计算前段竞争值之匹配值 (参考28084-4);
    CGFloat frontMatchValue = [AINetUtils getMatchByIndexDic:protoFrontIndexDic absFo:cansetFo_p conFo:protoFo_p callerIsAbs:true];
    if (frontMatchValue == 0) return nil; //过滤5: 前段不匹配时,直接返回nil (参考26128-1-3);
    
    //5. 计算前段竞争值之强度竞争值 (参考28086-todo1);
    NSDictionary *matchFrontIndexDic = [SMGUtils filterDic:indexDic checkValid:^BOOL(NSNumber *key, id value) {
        return key.integerValue <= matchCutIndex;
    }];
    NSInteger sumStrong = [AINetUtils getSumConStrongByIndexDic:matchFrontIndexDic matchFo:sceneFo_p cansetFo:cansetFo_p];
    CGFloat frontStrongValue = (float)sumStrong / matchFrontIndexDic.count;
    
    //6. 计算中断竞争值;
    CGFloat midEffectScore = [TOUtils getEffectScore:matchFo effectIndex:matchTargetIndex solutionFo:cansetFo_p];
    CGFloat midStableScore = [TOUtils getStableScore:cansetFo startSPIndex:cansetCutIndex + 1 endSPIndex:cansetTargetIndex];
    
    //6. 后段: 找canset后段目标 和 后段匹配度 (H需要后段匹配, R不需要);
    if (isH) {
        //7. 后段匹配度 (后段不匹配时,直接返nil);
        NSDictionary *backIndexDic = [SMGUtils filterDic:indexDic checkValid:^BOOL(NSNumber *key, id value) {
            return key.integerValue == ptAleardayCount;
        }];
        CGFloat backMatchValue = [AINetUtils getMatchByIndexDic:backIndexDic absFo:sceneFo_p conFo:cansetFo_p callerIsAbs:true];
        if (backMatchValue == 0) return nil; //过滤6: 后段不匹配时,直接返回nil;
        
        //7. 后段强度竞争值;
        NSInteger backStrongValue = [AINetUtils getSumConStrongByIndexDic:backIndexDic matchFo:sceneFo_p cansetFo:cansetFo_p];
        
        //9. 后段成功;
        return [AISolutionModel newWithCansetFo:cansetFo_p sceneFo:sceneFo_p protoFrontIndexDic:protoFrontIndexDic matchFrontIndexDic:matchFrontIndexDic frontMatchValue:frontMatchValue frontStrongValue:frontStrongValue
                                 midEffectScore:midEffectScore midStableScore:midStableScore
                                   backIndexDic:backIndexDic backMatchValue:backMatchValue backStrongValue:backStrongValue
                                       cutIndex:cansetCutIndex targetIndex:cansetTargetIndex basePFoOrTargetFoModel:basePFoOrTargetFoModel];
    }else{
        //11. 后段: R不判断后段;
        return [AISolutionModel newWithCansetFo:cansetFo_p sceneFo:sceneFo_p protoFrontIndexDic:protoFrontIndexDic matchFrontIndexDic:matchFrontIndexDic frontMatchValue:frontMatchValue frontStrongValue:frontStrongValue
                                 midEffectScore:midEffectScore midStableScore:midStableScore
                                   backIndexDic:nil backMatchValue:1 backStrongValue:0
                                       cutIndex:cansetCutIndex targetIndex:cansetFo.count basePFoOrTargetFoModel:basePFoOrTargetFoModel];
    }
}

@end
