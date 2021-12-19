//
//  TCScore.m
//  SMG_NothingIsAll
//
//  Created by jia on 2021/12/19.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import "TCScore.h"

@implementation TCScore

/**
 *  MARK:--------------------新螺旋架构score方法--------------------
 */
+(void) score{
    //1. 取当前任务 (参考24195-1);
    DemandModel *demand = [theTC.outModelManager getCanDecisionDemand];
    
    //2. 对firstRootDemand取得分字典 (参考24195-2);
    NSMutableDictionary *scoreDic = [[NSMutableDictionary alloc] init];
    TOFoModel *foModel = [self score_Multi:demand.actionFoModels scoreDic:scoreDic];
    
    //3. 转给TCPlan取最优路径;
    [TCPlan plan:demand rootFo:foModel scoreDic:scoreDic];
}

//MARK:===============================================================
//MARK:                     < 综合评分 >
//MARK:===============================================================

/**
 *  MARK:--------------------短时记忆树综合评分--------------------
 *  @desc 对解决方案S进行综合评分 (参考24192);
 *  @desc
 *      1. 缩写说明: 1.sr=SubRDemand 2.ss=SubSolution 3.sa=SubAlgModel 4.sh=SubHDemand
 *      2. 每执行一次single方法,则scoreDic中收集一条model的得分 <foModel,score>;
 *      3. S竞争方法由_Best方法实现;
 *      4. R求和方法主要在_Single中实现;
 *      5. 先将所有得分算完后,再重新从root开始算最优路径,因为只有子枝算完,父枝才能知道怎么算最优路径;
 *  _result 将model及其下有效的分枝评分计算,并收集到评分字典 <K=foModel,V=score>;
 */
+(void) score_Single:(TOFoModel*)model scoreDic:(NSMutableDictionary*)scoreDic{
    //1. 数据检查;
    if (!scoreDic) scoreDic = [[NSMutableDictionary alloc] init];
    double modelScore = 0;
    
    //===== 第一部分: RDemand在FoModel.subDemands下 (有解决方案:参与求和 & 无解决方案:理性淘汰);
    //2. 用每个sa取sh子任务 (求和);
    for (TOAlgModel *sa in model.subModels) {
        
        //3. 取出sh (一条sa最多只能生成一个sh任务);
        HDemandModel *sh = ARR_INDEX(sa.subDemands, 0);
        if (sh) {
            //4. H有解决方案时,对S竞争,并将最高分计入modelScore;
            if (ARRISOK(sh.actionFoModels)) {
                
                //a. 对S竞争;
                TOFoModel *bestSS = [self score_Multi:sh.actionFoModels scoreDic:scoreDic];
                
                //b. 将竞争胜者计入modelScore;
                modelScore += [NUMTOOK([scoreDic objectForKey:bestSS.content_p]) doubleValue];
            }else{
                //5. H无解决方案时,则理性淘汰 (参考24192-H14);
                [scoreDic setObject:@(INT_MIN) forKey:model.content_p];
                return;
            }
        }
    }
    
    //===== 第二部分: HDemand在AlgModel.subDemands下 (有解决方案:参与求和 & 无解决方案:R自身计入综合评分中);
    //10. 取出subRDemands子任务 (求和);
    for (ReasonDemandModel *sr in model.subDemands) {
        
        //11. R有解决方案时,对S竞争,并将最高分计入modelScore;
        if (ARRISOK(sr.actionFoModels)) {
            
            //a. 对S竞争;
            TOFoModel *bestSS = [self score_Multi:sr.actionFoModels scoreDic:scoreDic];
            
            //b. 将竞争胜者计入modelScore;
            modelScore += [NUMTOOK([scoreDic objectForKey:bestSS.content_p]) doubleValue];
        }else{
            //12. R无解决方案时,直接将sr评分计入modelScore;
            double score = [AIScore score4MV:sr.algsType urgentTo:sr.urgentTo delta:sr.delta ratio:1.0f];
            modelScore += score;
        }
    }
    
    //13. 将求和得分,计入dic (当没有sr也没有sa子任务 = 0分);
    [scoreDic setObject:@(modelScore) forKey:model.content_p];
}

/**
 *  MARK:--------------------S解决方案竞争--------------------
 *  @desc 感性竞争 (参考24192-R9);
 *  @param foModels : 解决方案S数,single传入>=1条,plan传入可能为0条;
 *  @param scoreDic : notnull
 *  @result 将bestFo返回;
 */
+(TOFoModel*) score_Multi:(NSArray*)foModels scoreDic:(NSMutableDictionary*)scoreDic{
    //1. 取出子任务的每个解决方案S (竞争);
    TOFoModel *bestFoModel = nil;
    for (TOFoModel *foModel in foModels) {
        
        //2. 评分
        [self score_Single:foModel scoreDic:scoreDic];
        
        //3. 竞争
        if (!bestFoModel) {
            bestFoModel = foModel;
        }else{
            double oldScore = [NUMTOOK([scoreDic objectForKey:bestFoModel.content_p]) doubleValue];
            double newScore = [NUMTOOK([scoreDic objectForKey:foModel.content_p]) doubleValue];
            if (newScore > oldScore) {
                bestFoModel = foModel;
            }
        }
    }
    
    //4. 将最优S返回;
    return bestFoModel;
}

@end
