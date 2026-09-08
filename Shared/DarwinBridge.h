// ObjC 桥：iOS 18 SDK 起 CFNotificationCenterGetDarwinNotificationCenter 对
// Swift 不可见（模块接口不含该符号），但 ObjC/C 侧始终可用。
// 本文件仅替 Swift 取一次 Darwin 通知中心句柄，其余 CF API Swift 直接调用。
#import <CoreFoundation/CoreFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 等价于 CFNotificationCenterGetDarwinNotificationCenter()
CFNotificationCenterRef YiEyeDarwinNotificationCenter(void);

NS_ASSUME_NONNULL_END
