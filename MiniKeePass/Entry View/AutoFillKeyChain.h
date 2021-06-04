//
//  AutoFillKeyChain.h
//  IOSKeePass
//
//  Created by Frank Hausmann on 23.05.21.
//  Copyright © 2021 Self. All rights reserved.
//

#ifndef AutoFillKeyChain_h
#define AutoFillKeyChain_h

#import <Foundation/Foundation.h>
typedef void (^KeychainOperationBlock)(BOOL successfulOperation, NSData *data, OSStatus status);

@interface AutoFillKeychain : NSObject


-(id) initWithService:(NSString *) service_ withGroup:(NSString*)group_;

-(void)insertKey:(NSString *)key withData:(NSData *)data withCompletion:(KeychainOperationBlock)completionBlock;
-(void)updateKey:(NSString*)key withData:(NSData*) data withCompletion:(KeychainOperationBlock)completionBlock;
-(void)removeDataForKey:(NSString*)key withCompletionBlock:(KeychainOperationBlock)completionBlock;
-(void)findDataForKey:(NSString*)key withCompletionBlock:(KeychainOperationBlock)completionBlock;
-(void)listALL; //:(KeychainOperationBlock)completionBlock;
@end
#endif /* AutoFillKeyChain_h */
