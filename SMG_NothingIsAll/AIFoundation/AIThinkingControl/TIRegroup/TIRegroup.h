//
//  TIRegroup.h
//  SMG_NothingIsAll
//
//  Created by jia on 2021/11/28.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TIRegroup : NSObject

+(void) rRegroup:(AIShortMatchModel*)model;
+(void) pRegroup:(NSArray*)algsArr;
+(void) hRegroup;

@end
