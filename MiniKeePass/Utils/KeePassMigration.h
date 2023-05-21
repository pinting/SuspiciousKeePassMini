//
//  KeePaaaMigration.h
//  IOSKeePass
//
//  Created by Frank Hausmann on 11.04.21.
//  Copyright © 2021 Self. All rights reserved.
//

#ifndef KeePaaaMigration_h
#define KeePaaaMigration_h

@interface StringFieldOld : NSObject <NSCopying>

@property(nonatomic, copy) NSString *key;
@property(nonatomic, copy) NSString *value;
@property(nonatomic, assign) BOOL protected;

- (id)initWithKey:(NSString *)key andValue:(NSString *)value;
- (id)initWithKey:(NSString *)key andValue:(NSString *)value andProtected:(BOOL)protected;

+ (id)stringFieldWithKey:(NSString *)key andValue:(NSString *)value;

@end

#endif /* KeePaaaMigration_h */
