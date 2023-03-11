//
//  TCRegroup.m
//  SMG_NothingIsAll
//
//  Created by jia on 2021/11/28.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import "TCRegroup.h"

@implementation TCRegroup

+(void) rRegroup:(AIShortMatchModel*)shortModel{
    //1. 构建时序 (把每次dic输入,都作为一个新的内存时序);
    [theTC updateOperCount:kFILENAME];
    Debug();
    NSArray *matchAShortMem = [theTC.inModelManager shortCache:true];
    shortModel.matchAFo = [theNet createConFo:matchAShortMem];
    NSArray *protoAShortMem = [theTC.inModelManager shortCache:false];
    shortModel.protoFo = [theNet createConFo:protoAShortMem];
    DebugE();
}

/**
 *  MARK:--------------------入口--------------------
 *  @version
 *      20200120 - 构建protoFo后,瞬时记忆改为不清空,为解决外层死循环问题 (因为外层循环需要行为输出后,将时序连起来) 参考n18p5-BUG9
 *      20200416 - 将先"mv需求处理"后"学习",改为先"学习"后"mv需求处理",因为外层死循环 (参考n19p5-B组BUG2);
 *      20210120 - 支持tir_OPush()反向反馈类比;
 */
+(void) pRegroup:(AICMVNode*)mv shortModel:(AIShortMatchModel*)shortModel{
    //1. 联想到mv时,创建CmvModel取到FoNode;
    [theTC updateOperCount:kFILENAME];
    Debug();
    
    //2. 创建CmvModel取到FoNode;
    shortModel.protoFo = [theNet createCMVFo:shortModel.inputTime order:[theTC.inModelManager shortCache:false] mv:mv];
    //[self.shortMemory clear] (参考注释2020.01.20);
    DebugE();
}

/**
 *  MARK:--------------------feedbackTOR后重组--------------------
 *  @desc
 *      说明: 在foModel下找到subAlgModel,其中feedbackAlg有值的,替换到foModel中,并重组成新的时序;
 *      例如: [我要吃水果],结果反馈了榴莲,重组成[我要吃榴莲];
 *  @param feedbackFrameOfMatchAlgs : 触发调用此反馈重组方法的protoAlg的识别matchAlgs结果 (参考28103-2.2);
 */
+(void) feedbackRegroup:(TOFoModel*)foModel feedbackFrameOfMatchAlgs:(NSArray*)feedbackFrameOfMatchAlgs {
    //1. 数据准备;
    [theTC updateOperCount:kFILENAME];
    Debug();
    
    //3. 数据准备 (收集除末位外的content为order);
    NSArray *order = [foModel getOrderUseMatchAndFeedbackAlg:true];
    
    //6. 将时序元素生成新时序;
    AIFoNodeBase *regroupFo = [theNet createConFo:order];
    
    //7. 识别时序 (预测到鸡蛋变脏,或者cpu损坏) (理性预测影响评价即理性评价);
    DebugE();
    [TCRecognition feedbackRecognition:regroupFo foModel:foModel feedbackFrameOfMatchAlgs:feedbackFrameOfMatchAlgs];
}

@end
