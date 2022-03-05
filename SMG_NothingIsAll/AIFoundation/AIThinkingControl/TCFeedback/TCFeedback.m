//
//  TCFeedback.m
//  SMG_NothingIsAll
//
//  Created by jia on 2021/12/2.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import "TCFeedback.h"

@implementation TCFeedback

/**
 *  MARK:--------------------"外层输入" 推进 "中层循环" 决策--------------------
 *  @title 外层输入对In短时记忆的影响处理 (参考22052-2);
 *  @version
 *      2021.01.24: 多时序识别支持,使之更全面的支持每个matchFo的status更新 (参考22073-todo6);
 *      2021.10.17: 支持IRT的理性失效,场景更新时,状态设为OutBackReason (参考24059&24061-方案2);
 *      2021.12.25: 针对理性IRT反省的支持 (判断非末位为理性预测中) (参考25021-②);
 *      2022.03.05: BUG_将仅末位才反馈,改成非末位才反馈 (原来逻辑写反了);
 *  @status
 *      xxxx.xx.xx: 非启动状态,因为时序识别中,未涵盖HNGL类型,所以并未对HNGL进行预测;
 *      2021.10.17: 启动,支持对IRT的理性失效 (参考24059&24061-方案2);
 */
+(void) feedbackTIR:(AIShortMatchModel*)model{
    //1. 取所有lastWait模型,并与新输入的概念做mIsC判断;
    NSArray *inModels = theTC.inModelManager.models;
    IFTitleLog(@"feedbackTIR", @"\n输入M:%@\n输入P:%@",Alg2FStr(model.matchAlg),Alg2FStr(model.protoAlg));
    
    //2. IRT理性失效 (旧有IRT触发器等待中的fo,在场景情况更新时,标记OutBackReason);
    for (AIShortMatchModel *inModel in inModels) {
        
        //3. 对pFos+rFos都做理性反馈;
        for (AIMatchFoModel *waitModel in inModel.fos4RForecast) {
            //4. 取出等待中的_非wait状态的,不处理;
            if (waitModel.status != TIModelStatus_LastWait) continue;
            if (Log4TIROPushM) NSLog(@"==> checkTIModel=MatchFo: %@",Fo2FStr(waitModel.matchFo));
            
            //5. 末位跳过,不需要反馈 (参考25031-2 & 25134-方案2);
            NSInteger maxCutIndex = waitModel.matchFo.count - 1;
            if (waitModel.cutIndex2 >= maxCutIndex) {
                WLog(@"回测此处判断continue的逻辑是否改对了: 已达到末帧,跳过不计反馈 (已发生:%ld 末帧值:%ld)",waitModel.cutIndex2,maxCutIndex);
            }else{
                WLog(@"回测此处判断continue的逻辑是否改对了: 未达到末帧,跳过不计反馈 (已发生:%ld 末帧值:%ld)",waitModel.cutIndex2,maxCutIndex);
            }
            if (waitModel.cutIndex2 >= maxCutIndex) continue;
            
            //6. 判断protoAlg与waitAlg之间mIsC,成立则OutBackYes;
            AIKVPointer *waitAlg_p = ARR_INDEX(waitModel.matchFo.content_ps, waitModel.cutIndex2 + 1);
            BOOL mIsC = [TOUtils mIsC_1:model.protoAlg.pointer c:waitAlg_p];
            if (mIsC) {
                waitModel.status = TIModelStatus_OutBackReason;
                NSLog(@"tir_OPushM: waitFo场景更新,原IRT理性失效");
            }
        }
    }
    
    //7. 传给TOR,做下一步处理: R任务_预测mv价值变化;
    //2021.12.01: R任务(新架构应在forecastIRT之后,调用rForecastBack.rDemand,但旧架构在前面,先不动,等测没影响再改后面);
    //2021.12.05: 将tor移到概念识别后了,此处front和back合并 (参考24171-9);
    [TCForecast rForecast:model];
    
    //8. IRT触发器;
    [TCForecast forecastReasonIRT:model];
    [TCForecast forecastPerceptIRT:model];
}

/**
 *  MARK:--------------------"外层输入" 推进 "中层循环" 认知--------------------
 *  @title 外层输入对In短时记忆的影响处理 (参考22052-2);
 *  @version
 *      2021.01.24: 对多时序识别结果支持,及时全面的改变status为OutBackYes (参考22073-todo5);
 *      2021.02.04: In反省支持虚mv,所以此处也要支持虚mv的OPush判断 (参考22108);
 *      2021.12.25: 废弃虚mv的代码 (因为虚mv早已不在时序识别的结果中,并且整个dsFo都已废弃掉了) (参考Note24);
 *      2021.12.25: 针对感性IRT反省的支持 (判断末位为感性预测中) (参考25022-②);
 *  @bug
 *      2021.01.25: 修复witMatchFo.cmvNode_p空判断逻辑反了,导致无法执行修改状态为OutBackYes,从而反省类比永远为"逆";
 */
+(void) feedbackTIP:(AICMVNode*)cmvNode{
    //1. 数据检查
    NSArray *inModels = theTC.inModelManager.models;
    IFTitleLog(@"feedbackTIP", @"\n输入MV:%@",Mv2FStr(cmvNode));
    
    //2. 判断最近一次input是否与等待中outModel相匹配 (匹配,比如吃,确定自己是否真吃了);
    for (AIShortMatchModel *inModel in inModels) {
        for (AIMatchFoModel *waitModel in inModel.fos4PForecast) {
            
            //3. 数据准备;
            AIFoNodeBase *waitMatchFo = waitModel.matchFo;
            NSInteger maxCutIndex = waitModel.matchFo.count - 1;
            
            //4. 非等待中的跳过;
            if (Log4OPushM) NSLog(@"==> checkTIModel=MatchFo: %@ (%@)",Fo2FStr(waitMatchFo),TIStatus2Str(waitModel.status));
            if (waitModel.status != TIModelStatus_LastWait) continue;
            
            //5. 非末位跳过 (参考25031-2);
            if (waitModel.cutIndex2 < maxCutIndex) continue;
            
            //6. 等待中的inModel_判断hope(wait)和real(new)之间是否相符 (仅标记同区同向反馈);
            if ([AIScore sameIdenSameScore:waitMatchFo.cmvNode_p mv2:cmvNode.pointer]) {
                waitModel.status = TIModelStatus_OutBackSameDelta;
                NSLog(@"tip_OPushM: 实MV 正向反馈");
            }
        }
    }
}

/**
 *  MARK:--------------------"外层输入" 推进 "中层循环" 决策--------------------
 *  @title 外层输入对Out短时记忆的ReasonDemandModel影响处理 (参考22061-8);
 *  @version
 *      2021.02.04: 将R同区同向(会导致永远为false因为虚mv得分为0)判断,改为同区反向判断 (参考22115BUG & 22108虚mv反馈判断方法);
 *      2021.12.23: feedback时,将root设回runing状态 (参考24212-8);
 *      2021.12.24: 应对整个工作记忆树进行支持,而不是仅rootDemands (参考25032-6);
 *      2021.12.26: 针对rSolution的感性反馈 (参考25031-11 & 25032-6);
 */
+(void) feedbackTOP:(AICMVNode*)cmvNode{
    //1. 数据检查
    NSInteger delta = [NUMTOOK([AINetIndex getData:cmvNode.delta_p]) integerValue];
    if (delta == 0) return;
    IFTitleLog(@"feedbackTOP", @"\n输入MV:%@",Mv2FStr(cmvNode));
    
    //2. 对所有等待中的任务尝试处理 (R-任务);
    for (ReasonDemandModel *root in theTC.outModelManager.getAllDemand) {
        NSArray *waitModels = [TOUtils getSubOutModels_AllDeep:root validStatus:@[@(TOModelStatus_ActYes)]];
        for (TOFoModel *waitModel in waitModels) {
            
            //3. wait不为fo解决方案时不处理;
            if (!ISOK(waitModel, TOFoModel.class)) continue;
            
            //4. 非R也非P任务时,不处理;
            if (!ISOK(waitModel.baseOrGroup, ReasonDemandModel.class) && !ISOK(waitModel.baseOrGroup, PerceptDemandModel.class)) continue;
            
            //5. 非actYes状态不处理;
            if (waitModel.status != TOModelStatus_ActYes) continue;
            
            //6. 判断hope(wait)和real(new)之间是否相符 (当反馈了"同区反向"时,即表明任务失败,为S) (匹配,比如撞疼,确定疼了);
            AIFoNodeBase *waitFo = [SMGUtils searchNode:waitModel.content_p];
            if ([AIScore sameIdenSameScore:waitFo.cmvNode_p mv2:cmvNode.pointer]) {
                waitModel.status = TOModelStatus_OuterBack;
                NSLog(@"top_OPushM: 实MV 正向反馈");
                
                //7. root设回runing
                root.status = TOModelStatus_Runing;
                
                //8. solutionFo反馈好时,baseDemand为完成状态;
                CGFloat score = [AIScore score4MV:waitFo.cmvNode_p ratio:1.0f];
                if (score > 0) {
                    waitModel.baseOrGroup.status = TOModelStatus_Finish;
                }
            }
        }
    }
    
    //3. p任务;
    [TCForecast pForecast:cmvNode];
}

@end
