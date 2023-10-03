//
//  TCRethink.m
//  SMG_NothingIsAll
//
//  Created by jia on 2021/12/25.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import "TCRethink.h"

@implementation TCRethink

/**
 *  MARK:--------------------IR反省器--------------------
 *  @version
 *      2023.03.04: 修复反省未保留以往帧cutIndex (参考28144-另外);
 */
+(void) reasonInRethink:(AIMatchFoModel*)model cutIndex:(NSInteger)cutIndex type:(AnalogyType)type{
    AIFoNodeBase *matchFo = [SMGUtils searchNode:model.matchFo];
    [theTC updateOperCount:kFILENAME];
    Debug();
    IFTitleLog(@"IR反省", @"\n%@ spIndex:%ld -> (%@)",Fo2FStr(matchFo),cutIndex + 1,ATType2Str(type));
    [matchFo updateSPStrong:cutIndex + 1 type:type];
    //2. 抽象也更新 (参考29069-todo11.4);
    [TCRethinkUtil spEff4Abs:matchFo curFoIndex:cutIndex + 1 itemRunBlock:^(AIFoNodeBase *absFo, NSInteger absIndex) {
        [absFo updateSPStrong:absIndex type:type];
    }];
    DebugE();
}

+(void) perceptInRethink:(AIMatchFoModel*)model type:(AnalogyType)type{
    AIFoNodeBase *matchFo = [SMGUtils searchNode:model.matchFo];
    [theTC updateOperCount:kFILENAME];
    Debug();
    IFTitleLog(@"IP反省", @"\n%@ spIndex:%ld -> (%@)",Fo2FStr(matchFo),matchFo.count,ATType2Str(type));
    [matchFo updateSPStrong:matchFo.count type:type];
    //2. 抽象也更新 (参考29069-todo11.4);
    [TCRethinkUtil spEff4Abs:matchFo curFoIndex:matchFo.count itemRunBlock:^(AIFoNodeBase *absFo, NSInteger absIndex) {
        [absFo updateSPStrong:absIndex type:type];
    }];
    DebugE();
}

/**
 *  MARK:--------------------OR反省器--------------------
 *  @version
 *      2023.03.04: 修复反省未保留以往帧actionIndex,导致反省时错误的BUG (参考28144-todo);
 *      2023.04.19: 支持canset迁移时的SP统计 (参考29069-todo11);
 *      2023.09.15: 增强SP可解释性 & 为rCanset生成hCanset (参考30131-todo1);
 */
+(void) reasonOutRethink:(TOFoModel*)model actionIndex:(NSInteger)actionIndex type:(AnalogyType)type{
    [theTC updateOperCount:kFILENAME];
    Debug();
    NSArray *tModels = [model getRethinkEffectCansets];
    for (AITransferModel *tModel in tModels) {
        AIFoNodeBase *canset = [SMGUtils searchNode:tModel.canset];
        IFTitleLog(@"OR反省", @"\n%@ spIndex:%ld -> (%@)",FoP2FStr(tModel.canset),actionIndex,ATType2Str(type));
        [canset updateSPStrong:actionIndex type:type];
        
        //2. 抽象也更新 (参考29069-todo11.4);
        [TCRethinkUtil spEff4Abs:canset curFoIndex:actionIndex itemRunBlock:^(AIFoNodeBase *absFo, NSInteger absIndex) {
            [absFo updateSPStrong:absIndex type:type];
        }];
        
        //3. 收集真实发生realMaskFo,收集成hCanset (参考30131-todo1 & 30132-方案);
        if (ISOK(model.basePFoOrTargetFoModel, AIMatchFoModel.class)) {
            AIMatchFoModel *basePFo = (AIMatchFoModel*)model.basePFoOrTargetFoModel;
            NSArray *order = [basePFo convertOrders4NewCansetV2];
            if (ARRISOK(order)) {
                AIFoNodeBase *hCanset = [theNet createConFo:order];
                [canset updateConCanset:hCanset.pointer targetIndex:actionIndex];
                NSLog(@"\nOR反省(%@ 第%ld帧)为rCanset:%@... \n\t> 生成hCanset:%@",ATType2Str(type),actionIndex + 1,SUBSTR2INDEX(Fo2FStr(canset), 100),Fo2FStr(hCanset));
            }
        }
    }
    DebugE();
}

+(void) perceptOutRethink:(TOFoModel*)model type:(AnalogyType)type{
    [theTC updateOperCount:kFILENAME];
    Debug();
    NSArray *tModels = [model getRethinkEffectCansets];
    for (AITransferModel *tModel in tModels) {
        AIFoNodeBase *canset = [SMGUtils searchNode:tModel.canset];
        IFTitleLog(@"OP反省", @"\n%@ spIndex:%ld -> (%@)",FoP2FStr(tModel.canset),canset.count,ATType2Str(type));
        [canset updateSPStrong:canset.count type:type];
        //2. 抽象也更新 (参考29069-todo11.4);
        [TCRethinkUtil spEff4Abs:canset curFoIndex:canset.count itemRunBlock:^(AIFoNodeBase *absFo, NSInteger absIndex) {
            [absFo updateSPStrong:absIndex type:type];
        }];
    }
    DebugE();
}

@end
