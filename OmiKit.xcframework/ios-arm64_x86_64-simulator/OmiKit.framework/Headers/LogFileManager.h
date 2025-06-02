//
//  LogFileManager.h
//  OmiKit
//
//  Created by H-Solutions on 12/3/25.
//

#ifndef LogFileManager_h
#define LogFileManager_h


#endif /* LogFileManager_h */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LogFileManager : NSObject

// Trả về instance chung (singleton)
+ (instancetype)sharedManager;

// Lấy đường dẫn file log hiện tại
- (NSString *)currentLogFilePath;

// Ghi log vào file (append)
- (void)appendLog:(NSString *)logString;

// Gửi file log lên server
- (void)uploadLogFileWithCompletion:(void(^)(BOOL success, NSError * _Nullable error))completion;

// Reset tên file log (sinh file mới)
- (void)resetLogFileName;

@end

NS_ASSUME_NONNULL_END
