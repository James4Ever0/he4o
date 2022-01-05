//
//  TCForecast.m
//  SMG_NothingIsAll
//
//  Created by jia on 2021/11/28.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import "TCForecast.h"

@implementation TCForecast

/**
 *  MARK:--------------------r预测--------------------
 */
+(void) rForecast:(AIShortMatchModel*)model{
    //6. 传给TOR,做下一步处理: R任务_预测mv价值变化;
    [TCDemand rDemand:model];
}

+(void) pForecast:(AICMVNode*)cmvNode{
    [TCDemand pDemand:cmvNode];
}

/**
 *  MARK:--------------------IRT预测--------------------
 *  @desc
 *      1. 对预测的处理,进行生物钟触发器;
 *      2. 支持:
 *          a.HNGL(因为时序识别处关闭,所以假启用状态);
 *          b.MV(启用);
 *      3. 等待feedbackTIR反馈;
 *  @version
 *      2021.01.27: 非末位也支持mv触发器 (参考22074-BUG2);
 *      2021.02.01: 支持反向反馈外类比 (参考22107);
 *      2021.02.04: 虚mv不会触发In反省,否则几乎永远为逆 (因为本来虚mv就不会有输入的);
 *      2021.02.04: 虚mv也要支持In反省,否则无法形成对R-模式助益 (参考22108);
 *      2021.10.12: SP的定义由顺逆改为好坏,所以此处相应触发SP的反省改正 (参考24054-实践);
 *      2021.10.17: IRT触发器理性失效时,不进行反省 (参考24061-方案2);
 *      2021.11.30: 将IRT触发器交由任务树来完成,即每条输入更新到任务树,任务树里每个分支都自带IRT预测;
 *                  > 弃做,何必绕圈子,原有做法: 时序预测直接做触发器就行;
 *      2021.12.25: 支持理性IRT反省;
 *  @todo
 *      2021.03.22: 迭代提高预测的准确性(1.以更具象为准(猴子怕虎,悟空不怕) 2.以更全面为准(猴子有麻醉枪不怕虎)) (参考22182);
 *  @status
 *      1. 后半部分"有mv判断"生效中;
 *      2. 前半部分"HNGL末位判断"未启用 (因为matchFos中未涵盖HNGL类型);
 */
+(void) forecastIRT:(AIShortMatchModel*)model {
    //1. 数据检查 (参考25031-1);
    IFTitleLog(@"IRT预测",@"\nprotoFo:%@",Fo2FStr(model.protoFo));
    NSMutableArray *matchs = [[NSMutableArray alloc] init];
    [matchs addObjectsFromArray:model.matchRFos];
    [matchs addObjectsFromArray:model.matchPFos];
    
    //2. 预测下一帧 (参考25031-2);
    for (AIMatchFoModel *item in matchs) {
        
        //3. 非末位时,理性反省 (参考25031-2);
        AIFoNodeBase *matchFo = item.matchFo;
        NSInteger maxCutIndex = matchFo.count - 1;
        if (item.cutIndex2 < maxCutIndex) {
            
            //4. 设为等待反馈状态 & 构建反省触发器;
            item.status = TIModelStatus_LastWait;
            double deltaTime = [NUMTOOK(ARR_INDEX(matchFo.deltaTimes, item.cutIndex2 + 1)) doubleValue];
            
            NSLog(@"---//理性IRT触发器新增:%p %@ (%@ | useTime:%.2f)",matchFo,Fo2FStr(matchFo),TIStatus2Str(item.status),deltaTime);
            [AITime setTimeTrigger:deltaTime trigger:^{
                //5. 如果状态已改成OutBackReason,说明有反馈;
                AnalogyType type = item.status == TIModelStatus_LastWait ? ATSub : ATPlus;
                
                //6. 则进行理性IRT反省;
                [TCRethink reasonInRethink:item type:type];
                NSLog(@"---//理性IRT触发器执行:%p %@ (%@ | %@)",matchFo,Fo2FStr(matchFo),TIStatus2Str(item.status),ATType2Str(type));
                
                //7. 失败状态标记;
                if (item.status == TIModelStatus_LastWait) item.status = TIModelStatus_OutBackNone;
            }];
        }
        //8. 末位且有mv时,感性反省 (参考25031-2);
        else if(matchFo.cmvNode_p){
            
            //9. 设为等待反馈状态 & 构建反省触发器;
            item.status = TIModelStatus_LastWait;
            double deltaTime = matchFo.mvDeltaTime;
            
            NSLog(@"---//感性IRT触发器新增:%p %@ (%@ | useTime:%.2f)",matchFo,Fo2FStr(matchFo),TIStatus2Str(item.status),deltaTime);
            [AITime setTimeTrigger:deltaTime trigger:^{
                //10. 如果状态已改成OutBack,说明有反馈;
                AnalogyType type = ATDefault;
                CGFloat score = [AIScore score4MV:matchFo.cmvNode_p ratio:1.0f];
                if (score > 0) {
                    //b. 实mv+反馈同向:P(好),未反馈:S(坏);
                    type = (item.status == TIModelStatus_OutBackSameDelta) ? ATPlus : ATSub;
                }else if(score < 0){
                    //b. 实mv-反馈同向:S(坏),未反馈:P(好);
                    type = (item.status == TIModelStatus_OutBackSameDelta) ? ATSub : ATPlus;
                }
                
                //11. 则进行感性IRT反省;
                if (type != ATDefault) {
                    [TCRethink perceptInRethink:item type:type];
                    NSLog(@"---//感性IRT触发器执行:%p %@ (%@ | %@)",matchFo,Fo2FStr(matchFo),TIStatus2Str(item.status),ATType2Str(type));
                }
                
                //12. 失败状态标记;
                if (item.status == TIModelStatus_LastWait) item.status = TIModelStatus_OutBackNone;
            }];
        }
    }
}

+(void) feedbackForecast:(AIShortMatchModel*)model foModel:(TOFoModel*)foModel{
    [TCDemand feedbackDemand:model foModel:foModel];
}

@end
