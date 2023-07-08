//
//  TCAction.m
//  SMG_NothingIsAll
//
//  Created by jia on 2021/11/28.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import "TCAction.h"
#import "TOFoModel.h"

@implementation TCAction

/**
 *  MARK:--------------------新螺旋架构action--------------------
 *  @desc 解决方案fo即(加工目标),转_Fo()行为化 (参考24132-行为化1);
 *  @param foModel : notnull
 *  @version
 *      2021.11.17: 需调用者自行对foModel进行FRS稳定性竞争评价,本方法不再进行 (因为fo间的竞争,需由外界,fo内部问题在此方法内解决);
 *      2021.11.25: 迭代为功能架构 (参考24154-单轮示图);
 *      2021.11.25: H类型在Action后,最终行为化完毕后,调用hActYes后,在feedbackTOR反馈,并重组反思,下轮循环;
 *      2021.11.xx: 废弃outReflect反思功能 (全部待到inReflect统一再反思);
 *      2021.11.28: 时间不急评价,改为: 紧急情况 = 解决方案所需时间 > 父任务能给的时间 (参考24171-7);
 *      2021.12.01: 支持hAction;
 *      2021.12.26: action将foModel执行到spIndex之前一帧 (25032-4);
 *      2021.12.26: hSolution达到目标帧转hActYes的处理 (参考25031-9);
 *      2021.12.26: 下标不急(弄巧成拙)评价,支持isOut=true的情况 (参考25031-10);
 *      2022.05.19: 废弃ARSTime评价 (参考26051);
 *      2022.12.09: 修复少执行了一帧的问题 (后16号又发现多了一帧,把target也执行了,这里9号时的情况已经忘了);
 *      2022.12.16: 修复多执行了一帧的问题 (即target帧不必行为化,自然发生即可);
 *      2023.07.08: 为避免输出行为捡了芝麻丢了西瓜,在行为化之前,先调用一下反思 (参考30054);
 *  @callers : 可以供_Demand和_Hav等调用;
 */
+(void) action:(TOFoModel*)foModel{
    //1. 数据准备
    AIFoNodeBase *curFo = [SMGUtils searchNode:foModel.content_p];
    [theTC updateOperCount:kFILENAME];
    Debug();
    OFTitleLog(@"行为化Fo", @"\n时序:%@->%@ 类型:(%@)",Fo2FStr(curFo),Mvp2Str(curFo.cmvNode_p),curFo.pointer.typeStr);
    
    //2. Alg转移 (下帧),每次调用action立马先跳下actionIndex为当前正准备行为化的那一帧;
    foModel.actionIndex++;
    
    //3. 进行反思识别,如果不通过时,回到TCScore可能会尝试先解决子任务,通过时继续行为化;
    [TCRegroup actionRegroup:foModel];
    BOOL refrection = [TCRefrection actionRefrection:foModel];
    if (!refrection) {
        [TCScore score];
        return;
    }
    
    //4. 跳转下帧 (最后一帧为目标,自然发生即可,此前帧则需要行为化实现);
    if (foModel.actionIndex < foModel.targetSPIndex - 1) {
        NSLog(@"_Fo行为化第 %ld/%ld 个: %@",(long)foModel.actionIndex,foModel.targetSPIndex,Fo2FStr(curFo));
        
        //@desc: 下标不急评价说明: R模式_Hav首先是为了避免forecastAlg,其次才是为了达成curFo解决方案 (参考22153);
        //5. 下标不急(弄巧成拙)评价_数据准备 (参考24171-12);
        //TODO: 考虑改成,取base最近的一个R任务;
        //6. 只有R类型,才参与下标不急评价;
        //ReasonDemandModel *baseDemand = (ReasonDemandModel*)foModel.baseOrGroup;
        //if(ISOK(baseDemand, ReasonDemandModel.class)){
        //    BOOL arsTime = [AIScore ARS_Time:foModel demand:baseDemand];
        //    if (!arsTime) {
        //        //7. 评价不通过,则直接ActYes,等待其自然出现 (参考22153-A2);
        //        DebugE();
        //        NSLog(@"==> arsTime弄巧成拙评价,子弹再飞一会儿");
        //        moveAlg.status = TOModelStatus_ActYes;
        //        [TCActYes arsTimeActYes:moveAlg];
        //        return;
        //    }
        //}
        //6. 转下帧: 理性帧则生成TOAlgModel;
        AIKVPointer *move_p = ARR_INDEX(curFo.content_ps, foModel.actionIndex);
        TOAlgModel *moveAlg = [TOAlgModel newWithAlg_p:move_p group:foModel];
        
        //7. 调用frameActYes();
        [TCActYes frameActYes:foModel];
        
        //8. 当前帧是理性帧时: 尝试行为当前帧;
        DebugE();
        [TCOut out:moveAlg];
    }else{
        //8. R成功,转actYes等待反馈 & 触发反省 (原递归参考流程控制Finish的注释version-20200916 / 参考22061-7);
        DebugE();
        NSLog(@"_Fo行为化: Finish %ld/%ld 到ActYes",(long)foModel.actionIndex,(long)curFo.count);
        
        if (ISOK(foModel.baseOrGroup, ReasonDemandModel.class)) {
            [TCActYes frameActYes:foModel];
            //[TCScore score];//r输出完成时,继续决策;
        }else if(ISOK(foModel.baseOrGroup, HDemandModel.class)){
            //9. H目标帧只需要等 (转hActYes) (参考25031-9);
            AIKVPointer *hTarget_p = ARR_INDEX(curFo.content_ps, foModel.actionIndex);
            [TOAlgModel newWithAlg_p:hTarget_p group:foModel];
            [TCActYes frameActYes:foModel];//h输出成功时,等待反馈;
        }else if(ISOK(foModel.baseOrGroup, PerceptDemandModel.class)){
            [TCActYes frameActYes:foModel];//p输出成功时,等待反馈;
        }
    }
}

@end
