/*
 * Copyright 2011-2013 Jason Rush and John Flanagan. All rights reserved.
 * Mdified by Frank Hausmann 2020-2021
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "ImageFactory.h"

//#define NUM_IMAGES 74

@interface ImageFactory ()
@property (nonatomic, strong) NSMutableArray *standardImages;
@property (nonatomic) NSInteger numOfImages;
@end

@implementation ImageFactory

- (id)init {
    self = [super init];
    if (self) {
        self.numOfImages = 74; //Comes from asset
        self.standardImages = [[NSMutableArray alloc] initWithCapacity:self.numOfImages];
        for (NSUInteger i = 0; i < self.numOfImages; i++) {
            [self.standardImages addObject:[NSNull null]];
        }
    }
    return self;
}

+ (ImageFactory *)sharedInstance {
    static ImageFactory *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ImageFactory alloc] init];
    });
    return sharedInstance;
}

- (void)reInit {
    [self.standardImages removeAllObjects];
    
    self.numOfImages = 74; //Comes from asset
    self.standardImages = [[NSMutableArray alloc] initWithCapacity:self.numOfImages];
    for (NSUInteger i = 0; i < self.numOfImages; i++) {
        [self.standardImages addObject:[NSNull null]];
    }
}

- (NSArray *)images {
    // Make sure all the standard images are loaded
    for (NSUInteger i = 0; i < self.numOfImages; i++) {
        [self imageForIndex:i];
    }
    return self.standardImages;
}

- (UIImage *)imageForGroup:(KPKGroup *)group {
    return [self imageForIndex:group.iconId];
}

- (UIImage *)imageForEntry:(KPKEntry *)entry {
    return [self imageForIndex:entry.iconId];
}

- (UIImage *)imageForIndex:(NSInteger)index {
    if (index >= self.numOfImages) {
        return nil;
    }

    id image = [self.standardImages objectAtIndex:index];
    if (image == [NSNull null]) {
        image = [UIImage imageNamed:[NSString stringWithFormat:@"%ld", (long)index]];
        [self.standardImages replaceObjectAtIndex:index withObject:image];
    }

    return image;
}
- (void)appendimage:(UIImage *)image {
    if(image == NULL)
        return;
    
    if(image.size.width != 24 || image.size.height != 24){
        CGSize newSize = CGSizeMake(24, 24);  //whaterver size
        UIGraphicsBeginImageContext(newSize);
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self.standardImages addObject:newImage];
        self.numOfImages += 1;
    }else{
        [self.standardImages addObject:image];
        self.numOfImages += 1;
    }
   
    
    
}
@end
