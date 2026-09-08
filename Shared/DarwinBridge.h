// ObjC 桥：iOS 18 SDK 起 CFNotificationCenterGetDarwinNotificationCenter 对
// Swift 不可见（模块接口不含该符号），但 ObjC/C 侧始终可用。
// 本文件仅替 Swift 取一次 Darwin 通知中心句柄，其余 CF API Swift 直接调用。
// 注意：本头文件只依赖 CoreFoundation，勿使用 Foundation 的宏（如 NS_ASSUME_NONNULL）。
#import <CoreFoundation/CoreFoundation.h>

CFNotificationCenterRef YiEyeDarwinNotificationCenter(void);
