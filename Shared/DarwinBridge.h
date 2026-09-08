// ObjC 桥：iOS SDK 的 CoreFoundation 头文件未声明 CFNotificationCenterGetDarwinNotificationCenter
// （仅 macOS 头文件有），因此 Swift/ObjC 都"看不到"它；但符号在 libCoreFoundation 中导出，
// iOS 进程可正常调用——自行声明原型即可（iOS Darwin 通知的标准用法）。
#import <CoreFoundation/CoreFoundation.h>

CFNotificationCenterRef CFNotificationCenterGetDarwinNotificationCenter(void);

CFNotificationCenterRef YiEyeDarwinNotificationCenter(void);
