//
//  AINetService.h
//  SMG_NothingIsAll
//
//  Created by air on 2020/5/21.
//  Copyright © 2020年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------网络数据服务类--------------------
 *  1. 用于网络联想的快捷封装方法;
 *  2. 用于类比构建成果的取用封闭方法;
 */
@interface AINetService : NSObject

/**
 *  MARK:--------------------获取HAlg/GLAlg--------------------
 *  @desc 获取概念的内类比结果,比如概念的GLHN
 *  @param pAlg : 取alg的大小有无;
 *  @param vAT & vDS : 此内类比类型的微信息at&ds (GL时,为变大小稀疏码的at&ds) (HN时,为变有无的概念的at&ds);
 */
+(AIKVPointer*) getInner1Alg:(AIAlgNodeBase*)pAlg vAT:(NSString*)vAT vDS:(NSString*)vDS type:(AnalogyType)type except_ps:(NSArray*)except_ps;

/**
 *  MARK:--------------------从Alg中获取指定标识稀疏码的值--------------------
 */
+(double) getValueDataFromAlg:(AIKVPointer*)alg_p valueIdentifier:(NSString*)valueIdentifier;

/**
 *  MARK:--------------------获取glConAlg_ps--------------------
 *  @desc 联想路径说明: (glConAlg_ps = glValue.refPorts->glAlg.conPorts->glConAlgs);
 */
+(NSArray*) getHNGLConAlg_ps:(AnalogyType)type vAT:(NSString*)vAT vDS:(NSString*)vDS;

@end
