//
//  main.m
//  HQLCreateiPadIconDemo
//
//  Created by 何启亮 on 2018/8/22.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *png = @"png";
static NSString *sign = @"@3x";
static NSString *iPadDirectory = @"iPadDirectory";

NSString * createiPadDirectory(NSString *directory);
BOOL CGImageWriteToFile(CGImageRef image, NSString *path);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        NSString *pngDirectory = @"/Users/heqiliang/Desktop/pngDirectory";
        // 遍历目录下所有@3x的png图片
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSError *contentError = nil;
        NSArray *contentArray = [fileManager contentsOfDirectoryAtPath:pngDirectory error:&contentError];
        if (contentError) {
            NSLog(@"%@ 获取目录失败 ： %@", pngDirectory, contentError);
            return 0; // 直接结束
        }
        if (contentArray.count == 0) {
            NSLog(@"%@ 目录为空", pngDirectory);
            return 0;
        }
        
        for (NSString *string in contentArray) {
            if (![string.pathExtension isEqualToString:png]) { // 不是png格式
                continue;
            }
            // 是png格式
            NSString *name = [string stringByDeletingPathExtension];
            // 去除.
            name = [name stringByReplacingOccurrencesOfString:@"." withString:@""];
            if (![name containsString:sign]) { // 不是@3x
                continue;
            }
            name = [name stringByReplacingOccurrencesOfString:sign withString:@""];
            
            // 符合条件 ---
            NSString *ipadPath = createiPadDirectory(pngDirectory);
            if (ipadPath.length <= 0) {
                NSLog(@"创建文件夹失败");
                return 0;
            }
            
            // 获取图片
            NSURL *file = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", pngDirectory, string]];
            CGDataProviderRef dataRef = CGDataProviderCreateWithURL((CFURLRef)file);
            CGImageRef imageRef = CGImageCreateWithPNGDataProvider(dataRef, NULL, NO, kCGRenderingIntentDefault);
            CGSize originSize = CGSizeMake(CGImageGetWidth(imageRef) / 3, CGImageGetHeight(imageRef) / 3);
            
            size_t bpc = CGImageGetBitsPerComponent(imageRef);
            size_t bpr = CGImageGetBytesPerRow(imageRef);
            CGColorSpaceRef cs = CGImageGetColorSpace(imageRef);
            CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
            
            // 创建图片
            CGSize targetSize = CGSizeMake(originSize.width * 1.5, originSize.height * 1.5);
            for (int i = 0; i < 2; i++) {
                NSString *targetName = [NSString stringWithFormat:@"%@_iPad%@.png", name, (i == 0 ? @"@2x" : @"@3x")];
                NSString *targetPath = [NSString stringWithFormat:@"%@/%@", ipadPath, targetName];
                // 创建图片
                CGFloat multiple = i == 0 ? 2 : 3;
                CGContextRef contextRef = CGBitmapContextCreate(NULL, (targetSize.width * multiple), (targetSize.height * multiple), bpc, 0, cs, kCGImageAlphaPremultipliedLast);
                CGContextDrawImage(contextRef, CGRectMake(0, 0, (targetSize.width * multiple), (targetSize.height * multiple)), imageRef);
                CGContextSetInterpolationQuality(contextRef, kCGInterpolationHigh);
                CGImageRef targetImage = CGBitmapContextCreateImage(contextRef);
                
                CGContextRelease(contextRef);
                
                // 写入
                BOOL yesOrNo = CGImageWriteToFile(targetImage, targetPath);
                
                CGImageRelease(targetImage);
                
                if (!yesOrNo) {
                    NSLog(@"%@ 写入失败", targetPath);
                    continue;
                }
                
                NSLog(@"%@ 写入成功", targetPath);
            }
            
            CGColorSpaceRelease(cs);
            CGDataProviderRelease(dataRef);
            CGImageRelease(imageRef);
        }
        
    }
    return 0;
}

NSString * createiPadDirectory(NSString *directory) {
    if (directory.length <= 0) {
        NSLog(@"空的父文件夹");
        return nil;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [directory stringByAppendingString:[NSString stringWithFormat:@"/%@", iPadDirectory]];
    
    // 判断是否存在
    if (![fileManager fileExistsAtPath:path]) {
        // 不存在
        NSError *error = nil;
        BOOL yesOrNo = [fileManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
        if (!yesOrNo || error) {
            NSLog(@"创建文件夹失败");
            return nil;
        }
    }
    
    return path;
}

BOOL CGImageWriteToFile(CGImageRef image, NSString *path) {
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    if (!destination) {
        NSLog(@"Failed to create CGImageDestination for %@", path);
        return NO;
    }
    
    CGImageDestinationAddImage(destination, image, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
        CFRelease(destination);
        return NO;
    }
    
    CFRelease(destination);
    return YES;
}
