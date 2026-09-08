#import "NotifyBridge.h"
#import <notify.h>

uint32_t YiEyeNotifyPost(const char *name) {
    return notify_post(name);
}

uint32_t YiEyeNotifyRegisterDispatch(const char *name, int *outToken,
                                     dispatch_queue_t queue, void (^handler)(int token)) {
    return notify_register_dispatch(name, outToken, queue, handler);
}

void YiEyeNotifyCancel(int token) {
    notify_cancel(token);
}
