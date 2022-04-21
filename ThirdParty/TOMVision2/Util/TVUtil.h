//
//  TVUtil.h
//  SMG_NothingIsAll
//
//  Created by jia on 2022/3/26.
//  Copyright © 2022年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TOMVisionItemModel;
@interface TVUtil : NSObject

/**
 *  MARK:--------------------获取所有帧工作记忆的两两更新比对--------------------
 */
+(NSMutableDictionary*) getChange_List:(NSArray*)models;

/**
 *  MARK:--------------------获取两帧工作记忆的更新处--------------------
 */
+(NSArray*) getChange_Item:(TOMVisionItemModel*)itemA itemB:(TOMVisionItemModel*)itemB;

/**
 *  MARK:--------------------changeDic的变化总数--------------------
 */
+(NSInteger) countOfChangeDic:(NSDictionary*)changeDic;

/**
 *  MARK:--------------------changeIndex转index--------------------
 */
+(NSInteger) mainIndexOfChangeIndex:(NSInteger)changeIndex changeDic:(NSDictionary*)changeDic;
+(NSInteger) subIndexOfChangeIndex:(NSInteger)changeIndex changeDic:(NSDictionary*)changeDic;
+(NSRange) indexOfChangeIndex:(NSInteger)changeIndex changeDic:(NSDictionary*)changeDic;

@end