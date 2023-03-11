//
//  TCRegroup.h
//  SMG_NothingIsAll
//
//  Created by jia on 2021/11/28.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCRegroup : NSObject

+(void) rRegroup:(AIShortMatchModel*)shortModel;
+(void) pRegroup:(AICMVNode*)mv shortModel:(AIShortMatchModel*)shortModel;
+(void) feedbackRegroup:(TOFoModel*)foModel feedbackFrameOfMatchAlgs:(NSArray*)feedbackFrameOfMatchAlgs;

@end
