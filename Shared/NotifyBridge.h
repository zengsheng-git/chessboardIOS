// C 桥：iOS SDK 的 C 头文件里有 <notify.h>，但 Swift 的 Darwin 模块未映射这些符号，
// 经本桥接暴露给 Swift（libsystem_notify 为 iOS 公开 API，符号必然存在）。
#import <dispatch/dispatch.h>
#import <stdint.h>

uint32_t YiEyeNotifyPost(const char *name);
uint32_t YiEyeNotifyRegisterDispatch(const char *name, int *outToken,
                                     dispatch_queue_t queue, void (^handler)(int token));
void YiEyeNotifyCancel(int token);
