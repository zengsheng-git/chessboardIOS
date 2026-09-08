#import "DarwinBridge.h"

CFNotificationCenterRef YiEyeDarwinNotificationCenter(void) {
    return CFNotificationCenterGetDarwinNotificationCenter();
}
