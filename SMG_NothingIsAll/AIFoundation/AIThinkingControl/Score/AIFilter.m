//
//  AIFilter.m
//  SMG_NothingIsAll
//
//  Created by jia on 2023/2/25.
//  Copyright © 2023年 XiaoGang. All rights reserved.
//

#import "AIFilter.h"

@implementation AIFilter

/**
 *  MARK:--------------------概念识别过滤器--------------------
 *  @version
 *      2023.03.06: 概念识别过滤器匹配度为主,强度为辅 (参考28152-方案4-todo4);
 */
+(NSArray*) recognitonAlgFilter:(NSArray*)matchAlgModels {
    return [self filterTwice:matchAlgModels mainBlock:^double(AIMatchAlgModel *item) {
        return item.matchValue;
    } subBlock:^double(AIMatchAlgModel *item) {
        return item.strongValue;
    } radio:0.16f resultNum:4];
}

/**
 *  MARK:--------------------时序识别过滤器--------------------
 *  @version
 *      2023.03.06: 时序识别过滤器强度为主,匹配度为辅 (参考28152-方案4-todo5);
 */
+(NSArray*) recognitonFoFilter:(NSArray*)matchModels {
    //此过滤度参数调整中...
    //20230318. 由0.16调整为0.6 (概念已经很准了,时序只要把不准部分切了就行,不需要过滤太多);
    CGFloat radio = 0.6f;
    return [self filterTwice:matchModels mainBlock:^double(AIMatchFoModel *item) {
        return item.strongValue;
    } subBlock:^double(AIMatchFoModel *item) {
        return item.matchFoValue;
    } radio:radio resultNum:4];
}

/**
 *  MARK:--------------------Canset识别过滤器 (参考29042)--------------------
 *  @desc 初版Canset识别因为结果太多再类比时性能差,加过滤器体现竞争 (参考29042);
 *  @version
 *      2023.04.04: 将过滤器由SP主EFF辅,改为映射数为主SP为辅 (参考29055-方案);
 */
+(NSArray*) recognitonCansetFilter:(NSArray*)matchModels sceneFo:(AIFoNodeBase*)sceneFo {
    CGFloat radio = 0.2f;
    NSArray *result = ARR_SUB([SMGUtils sortBig2Small:matchModels compareBlock:^double(AIMatchCansetModel *obj) {
        return obj.indexDic.count;
    }], 0, matchModels.count * radio);
    NSLog(@"Canset识别过滤器: 总%ld * 需%.0f%% => 剩:%ld",matchModels.count,radio * 100,result.count);
    return result;
}

/**
 *  MARK:--------------------Canset求解过滤器 (参考29081-todo41)--------------------
 */
+(NSArray*) solutionCansetFilter:(AIFoNodeBase*)sceneFo targetIndex:(NSInteger)targetIndex {
    NSArray *protoConCansets = [sceneFo getConCansets:targetIndex];
    NSArray *sorts = [SMGUtils sortBig2Small:protoConCansets compareBlock:^double(AIKVPointer *canset) {
        return [TOUtils getEffectScore:sceneFo effectIndex:targetIndex solutionFo:canset];
    }];
    NSInteger limit = MAX(3, protoConCansets.count * 0.2f);//取20% & 至少尝试取3条;
    return ARR_SUB(sorts, 0, limit);
}

/**
 *  MARK:--------------------二次识别过滤器--------------------
 */
+(void) secondRecognitonFilter:(AIShortMatchModel*)inModel {
    //1. 获取V重要性字典;
    NSDictionary *importanceDic = [TCRecognitionUtil getVImportanceDic:inModel];
    
    //2. 根据重要性加权计算二次过滤匹配度 (参考29107-步骤2);
    NSMutableDictionary *secondMatchValueDic = [[NSMutableDictionary alloc] init];
    for (AIMatchAlgModel *item in inModel.matchAlgs) {
        CGFloat secondMatchValue = 1;
        AIAlgNodeBase *matchAlg = [SMGUtils searchNode:item.matchAlg];
        for (AIKVPointer *protoV_p in inModel.protoAlg.content_ps) {
            for (AIKVPointer *matchV_p in matchAlg.content_ps) {
                if ([protoV_p.identifier isEqualToString:matchV_p.identifier]) {
                    
                    //3. 二次过滤V相近度 = 原V相近度 的 重要性次方 (参考29107-步骤2);
                    CGFloat nearV = [AIAnalyst compareCansetValue:matchV_p protoValue:protoV_p];
                    double importance = NUMTOOK_DV([importanceDic objectForKey:protoV_p.identifier],1).doubleValue;
                    secondMatchValue *= powf(nearV, importance);
                }
            }
        }
        [secondMatchValueDic setObject:@(secondMatchValue) forKey:@(matchAlg.pId)];
    }
    
    //4. 概念识别的二次排序过滤 (保留60% & 至少保留4条) (参考29107-todo1);
    NSArray *sort = [SMGUtils sortBig2Small:inModel.matchAlgs compareBlock:^double(AIMatchAlgModel *obj) {
        return NUMTOOK([secondMatchValueDic objectForKey:@(obj.matchAlg.pointerId)]).floatValue;
    }];
    sort = ARR_SUB(sort, 0, MAX(sort.count * 0.6f, 4));
    
    
    //TODOTOMORROW20230530: 测下这么排出来符合预期先,然后写29107-todo2;
    
    
    
}

/**
 *  MARK:--------------------Scene求解过滤器 (参考2908a-todo2)--------------------
 *  @param type : protoScene的类型,i时向抽象取ports,father时向具象取ports;
 *  @version
 *      2023.05.08: BUG_father没conCanset被过滤,导致它的brother全没机会激活 (改为仅brother时才要求必须有cansets指向);
 *      2023.05.15: 改为强度为主,匹配度为辅进行过滤 (参考29094-BUG3-方案2);
 */
+(NSArray*) solutonSceneFilter:(AIFoNodeBase*)protoScene type:(SceneType)type {
    //1. 数据准备: 向着isAbs方向取得抽具关联场景;
    BOOL toAbs = type != SceneTypeFather;
    NSArray *otherScenePorts = toAbs ? [AINetUtils absPorts_All:protoScene] : [AINetUtils conPorts_All:protoScene];
    
    //2. 根据是否有conCanset过滤 (目前仅支持R任务,所以直接用fo.count做targetIndex) (参考29089-解答1-补充 & 2908a-todo5);
    otherScenePorts = [SMGUtils filterArr:otherScenePorts checkValid:^BOOL(AIPort *item) {
        AIFoNodeBase *fo = [SMGUtils searchNode:item.target_p];
        BOOL mvIdenOK = [fo.cmvNode_p.identifier isEqualToString:protoScene.cmvNode_p.identifier];//mv要求必须同区;
        BOOL havCansetsOK = type != SceneTypeBrother || ARRISOK([fo getConCansets:fo.count]);//brother时要求必须有cansets;
        return mvIdenOK && havCansetsOK;
    }];
    
    //3. 根据强度为主,匹配度为辅进行过滤: 取20% & 至少尝试取3条 (参考29094-BUG3-方案2);
    otherScenePorts = [self filterTwice:otherScenePorts mainBlock:^double(AIPort *item) {
        //4. 根据强度,进行主要过滤 (参考29094-BUG3-方案2);
        return item.strong.value;
    } subBlock:^double(AIPort *item) {
        //5. 根据indexDic复用匹配度进行辅助过滤 (参考2908a-todo2);
        if (toAbs) {
            return [AINetUtils getMatchByIndexDic:[protoScene getAbsIndexDic:item.target_p] absFo:item.target_p conFo:protoScene.pointer callerIsAbs:false];
        }
        return [AINetUtils getMatchByIndexDic:[protoScene getConIndexDic:item.target_p] absFo:protoScene.pointer conFo:item.target_p callerIsAbs:true];
    } radio:0.2f resultNum:4];
    return Ports2Pits(otherScenePorts);
}

//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================

/**
 *  MARK:--------------------同时符合两项过滤器的前xx% (参考28152-方案3)--------------------
 *  @desc 公式说明:
 *      1. 要求: 总过滤数20 = 总数30 - 结果数10;
 *      2. 主辅任务力度: 等于4:1时: 主过滤掉16条,辅过滤掉4条 即可;
 *      3. 主辅过滤条数: 主过滤后,剩下14(30-16)条; 辅过滤后剩下10(14-4)条;
 *      4. 主辅过滤率: "主过滤率 = 剩下14 / 总数30","辅过滤率 = 剩下10 / 剩下14";
 *      5. 最终成功留下结果10条;
 *  @desc 可配置项 (注:每项数字可调):
 *      1. 结果数: 越大返回越多;
 *      2. 主辅任务比例: 越大主过滤器作用越大;
 *      3. 最小条数百分比: 值越小越准;
 *  @desc 现配置: 结果数为16%,主辅过滤力度20:1,即主过滤掉80%,辅再过滤掉剩下的20%;
 *  @param radio : 过滤率 (传值范围0-1),越小越精准,但剩余结果越少,反之其效亦反;
 *  @param resultNum : 建议返回条数;
 *
 *  @version
 *      2023.03.06: 过滤前20%改为35% (参考28152-方案3-todo2);
 *      2023.03.07: 减少过滤结果条数(从10到3),避免过滤器久久不生效 (参考28152b-todo1);
 *      2023.03.07: 过滤率改成动态计算,使其条数少时,两个过滤器也都能生效 (参考28152b-todo2);
 *      2023.03.07: 修改主辅过滤器为嵌套执行 (参考28152b-todo3);
 *      2023.03.07: 结果保留改为16%,将主辅力度调整为20:1 (因为实测4:1时,真实主过滤率=37%左右,太高了);
 *      2023.03.18: 加上radio参数,方便对概念和时序的过滤器分别指定不同的过滤度 (参考28186-方案1-结果);
 */
+(NSArray*) filterTwice:(NSArray*)protoArr mainBlock:(double(^)(id item))mainBlock subBlock:(double(^)(id item))subBlock radio:(CGFloat)radio resultNum:(NSInteger)resultNum{
    //0. 数据准备;
    if (!ARRISOK(protoArr)) return protoArr;
    
    //1. 条数 (参考注释公式说明-1);
    NSInteger protoCount = protoArr.count;                          //总数 (如30);
    CGFloat minResultNum = radio * protoCount;                      //最小条数 (建议16%,值越小越准);
    resultNum = MAX(minResultNum, MIN(resultNum, protoCount));      //结果需要 大于20% 且 小于100%;
    
    //2. 过滤任务和力度 (参考注释公式说明-2);
    NSInteger filterNum = protoCount - resultNum;                   //总过滤任务 (比如共30条,剩10条,过滤任务就是20条);
    CGFloat zuFilterForce = 20, fuFilterForce = 1;                  //主辅两过滤器的力度权重 (一般主力度要大于辅力度多倍);
    CGFloat totalForce = zuFilterForce + fuFilterForce;             //总过滤力量份数 (比如: 主4 + 辅1 = 总力5份);
    
    //3. 主辅过滤条数 (参考注释公式说明-3);
    CGFloat fuFilterNum = filterNum / totalForce * fuFilterForce;   //辅过滤条数;
    CGFloat zuFilterNum = filterNum - fuFilterNum;                  //主过滤条数;
    
    //4. 主辅过滤率 (参考注释公式说明-4);
    CGFloat zuRate = (protoCount - zuFilterNum) / protoCount;       //主过滤率;
    CGFloat fuRate = resultNum / (protoCount - zuFilterNum);        //辅过滤率;
    
    //5. 主中辅,嵌套过滤 (参考28152b-todo3);
    NSArray *filter1 = ARR_SUB([SMGUtils sortBig2Small:protoArr compareBlock:mainBlock], 0, protoArr.count * zuRate);
    NSArray *filter2 = ARR_SUB([SMGUtils sortBig2Small:filter1 compareBlock:subBlock], 0, filter1.count * fuRate);
    NSLog(@"过滤器: 总%ld需%ld 主:%.2f => 剩:%ld 辅:%.2f => 剩:%ld",protoCount,resultNum,zuRate,filter1.count,fuRate,filter2.count);
    
    //6. 返回结果 (参考注释公式说明-5);
    return filter2;
}

@end
