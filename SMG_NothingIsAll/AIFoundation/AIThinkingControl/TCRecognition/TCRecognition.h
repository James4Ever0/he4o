//
//  TCRecognition.h
//  SMG_NothingIsAll
//
//  Created by jia on 2021/11/28.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------识别 & 学习--------------------
 */
@interface TCRecognition : NSObject

+(void) rRecognition:(AIShortMatchModel*)model;
+(void) reflectRecognition:(TOFoModel*)foModel;
+(void) pRecognition:(AIFoNodeBase*)protoFo;

@end
