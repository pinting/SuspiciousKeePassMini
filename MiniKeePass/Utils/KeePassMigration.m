//
//  KeePassMigration.m
//  IOSKeePass
//
//  Created by Frank Hausmann on 11.04.21.
//  Copyright © 2021 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeePassMigration.h"

@implementation StringFieldOld

- (id)initWithKey:(NSString *)key andValue:(NSString *)value {
    return [self initWithKey:key andValue:value andProtected:NO];
}

- (id)initWithKey:(NSString *)key andValue:(NSString *)value andProtected:(BOOL)protected {
    self = [super init];
    if (self) {
        _key = [key copy];
        _value = [value copy];
        _protected = protected;
    }
    return self;
}

+ (id)stringFieldWithKey:(NSString *)key andValue:(NSString *)value {
    return [[StringField alloc] initWithKey:key andValue:value];
}

- (id)copyWithZone:(NSZone *)zone {
    return [[StringField alloc] initWithKey:self.key andValue:self.value andProtected:self.protected];
}

@end
