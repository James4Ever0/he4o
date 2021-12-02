//
//  TIForecast.m
//  SMG_NothingIsAll
//
//  Created by jia on 2021/11/28.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import "TIForecast.h"

@implementation TIForecast

+(void) rForecastFront:(AIShortMatchModel*)model{
    //6. 传给TOR,做下一步处理: R任务_预测mv价值变化;
    [TODemand rDemandFront:model];
}

+(void) rForecastBack:(AIShortMatchModel*)model pushOldDemand:(BOOL)pushOldDemand{
    //TODOTOMORROW20211202: 新架构应在末尾调用TODemand,但旧架构代码放在头部,先不动,等发现放末尾没影响时再放末尾;
    //6. 此处推进不成功,则运行TOP四模式;
    if (!pushOldDemand) {
        [TODemand rDemandBack:model];
    }
}

+(void) pForecast:(AICMVNode*)cmvNode{
    [TODemand pDemand:cmvNode];
}

/**
 *  MARK:--------------------预测--------------------
 *  @desc
 *      1. 对预测的处理,进行生物钟触发器;
 *      2. 支持:
 *          a.HNGL(因为时序识别处关闭,所以假启用状态);
 *          b.MV(启用);
 *  @version
 *      2021.01.27: 非末位也支持mv触发器 (参考22074-BUG2);
 *      2021.02.01: 支持反向反馈外类比 (参考22107);
 *      2021.02.04: 虚mv不会触发In反省,否则几乎永远为逆 (因为本来虚mv就不会有输入的);
 *      2021.02.04: 虚mv也要支持In反省,否则无法形成对R-模式助益 (参考22108);
 *      2021.10.12: SP的定义由顺逆改为好坏,所以此处相应触发SP的反省改正 (参考24054-实践);
 *      2021.10.17: IRT触发器理性失效时,不进行反省 (参考24061-方案2);
 *  @todo
 *      2021.03.22: 迭代提高预测的准确性(1.以更具象为准(猴子怕虎,悟空不怕) 2.以更全面为准(猴子有麻醉枪不怕虎)) (参考22182);
 *  @status
 *      1. 后半部分"有mv判断"生效中;
 *      2. 前半部分"HNGL末位判断"未启用 (因为matchFos中未涵盖HNGL类型);
 */
+(void) forecastIRT:(AIShortMatchModel*)model {
    
    //TODOTOMORROW20211130: 考虑将IRT触发器,交由任务树来完成,即每一条输入都很更新到任务树,任务树里的每一个分支都自带IRT预测;
    
    //1. 数据检查;
    if (!inModel) return;
    AIFoNodeBase *protoFo = inModel.protoFo;
    IFTitleLog(@"预测",@"\nprotoFo:%@",Fo2FStr(protoFo));
    
    //3. 预测处理_反向反馈类比_生物钟触发器;
    for (AIMatchFoModel *item in inModel.matchPFos) {
        AIFoNodeBase *matchFo = item.matchFo;
        BOOL isHNGL = [TOUtils isHNGL:matchFo.pointer];
        if (isHNGL) {
            ////末位判断;
            //if (item.cutIndex2 == matchFo.count - 2) {
            //    item.status = TIModelStatus_LastWait;
            //    double deltaTime = [NUMTOOK(ARR_INDEX_REVERSE(matchFo.deltaTimes, 0)) doubleValue];
            //    [AITime setTimeTrigger:deltaTime trigger:^{
            //        //4. 反向反馈类比(成功/未成功)的主要原因;
            //        AnalogyType type = (item.status == TIModelStatus_LastWait) ? ATSub : ATPlus;
            //        NSLog(@"---//触发器HNGL_触发: %@ (%@)",Fo2FStr(matchFo),ATType2Str(type));
            //        [AIAnalogy analogy_InRethink:item shortFo:protoFo type:type];
            //
            //        //5. 失败状态标记;
            //        if (item.status == TIModelStatus_LastWait) item.status = TIModelStatus_OutBackNone;
            //    }];
            //}
        }else{
            //有mv判断;
            if (matchFo.cmvNode_p) {
                item.status = TIModelStatus_LastWait;
                double deltaTime = [TOUtils getSumDeltaTime2Mv:matchFo cutIndex:item.cutIndex2];
                NSLog(@"---//IRT触发器新增:%p %@ (%@ | useTime:%.2f)",matchFo,Fo2FStr(matchFo),TIStatus2Str(item.status),deltaTime);
                [AITime setTimeTrigger:deltaTime trigger:^{
                    //3. 如果状态已改成OutBackReason,触发器失效,不进行反省;
                    if (item.status == TIModelStatus_OutBackReason) {
                        return;
                    }
                    
                    //4. 反向反馈类比(成功/未成功)的主要原因 (参考tip_OPushM());
                    AnalogyType type = ATDefault;
                    if ([AINetUtils isVirtualMv:matchFo.cmvNode_p]) {
                        //a. 虚mv反馈反向:S,未反馈:P;
                        type = (item.status == TIModelStatus_OutBackDiffDelta) ? ATSub : ATPlus;
                    }else{
                        CGFloat score = [AIScore score4MV:matchFo.cmvNode_p ratio:1.0f];
                        if (score > 0) {
                            //b. 实mv+反馈同向:P(好),未反馈:S(坏);
                            type = (item.status == TIModelStatus_OutBackSameDelta) ? ATPlus : ATSub;
                        }else if(score < 0){
                            //b. 实mv-反馈同向:S(坏),未反馈:P(好);
                            type = (item.status == TIModelStatus_OutBackSameDelta) ? ATSub : ATPlus;
                        }
                    }
                    NSLog(@"---//IRT触发器执行:%p %@ (%@ | %@)",matchFo,Fo2FStr(matchFo),TIStatus2Str(item.status),ATType2Str(type));
                    
                    //4. 输入期反省类比 (有OutBack,SP类型时执行);
                    [AIAnalogy analogy_InRethink:item shortFo:protoFo type:type];
                    
                    //5. 反向反馈外类比 (无OutBack,为Wait时执行);
                    if (item.status == TIModelStatus_LastWait) {
                        [AIAnalogy analogy_Feedback_Diff:protoFo mModel:item];
                    }
                    
                    //5. 失败状态标记;
                    if (item.status == TIModelStatus_LastWait) item.status = TIModelStatus_OutBackNone;
                }];
            }
        }
    }
}

+(void) forecastSubDemand:(AIShortMatchModel*)model{
    [TODemand subDemand:model];
}

@end
