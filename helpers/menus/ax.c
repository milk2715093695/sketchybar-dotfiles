#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "ax.h"

// 私有 SLS 接口声明
extern int SLSMainConnectionID(void);
extern void SLSSetMenuBarVisibilityOverrideOnDisplay(int cid, int did, bool enabled);
extern void SLSSetMenuBarInsetAndAlpha(int cid, double u1, double u2, float alpha);
extern void _SLPSGetFrontProcess(ProcessSerialNumber* psn);
extern void SLSGetConnectionIDForPSN(int cid, ProcessSerialNumber* psn, int* cid_out);
extern void SLSConnectionGetPID(int cid, pid_t* pid_out);

// 执行辅助功能点击操作
static void ax_perform_click(AXUIElementRef element) {
    if (!element) return;

    AXUIElementPerformAction(element, kAXCancelAction);
    usleep(150000);
    AXUIElementPerformAction(element, kAXPressAction);
}

// 获取辅助功能元素标题
static CFStringRef ax_copy_title(AXUIElementRef element) {
    CFTypeRef title = NULL;
    AXError error   = AXUIElementCopyAttributeValue(
        element,
        kAXTitleAttribute,
        &title
    );

    if (error != kAXErrorSuccess) return NULL;
    return title;
}

// 获取指定别名对应的菜单栏额外项目
static AXUIElementRef ax_copy_extra_menu_item(const char* alias) {
    if (!alias) return NULL;

    pid_t pid    = 0;
    CGRect bounds = CGRectNull;

    CFArrayRef window_list = CGWindowListCopyWindowInfo(
        kCGWindowListOptionAll,
        kCGNullWindowID
    );

    if (!window_list) return NULL;

    char owner_buffer[256];
    char name_buffer[256];
    char alias_buffer[512];

    // 遍历窗口并匹配 "owner,name" 形式的 alias
    CFIndex window_count = CFArrayGetCount(window_list);
    for (CFIndex i = 0; i < window_count; ++i) {
        CFDictionaryRef dictionary = CFArrayGetValueAtIndex(window_list, i);
        if (!dictionary) continue;

        CFStringRef owner_ref        = CFDictionaryGetValue(dictionary, kCGWindowOwnerName);
        CFNumberRef owner_pid_ref    = CFDictionaryGetValue(dictionary, kCGWindowOwnerPID);
        CFStringRef name_ref         = CFDictionaryGetValue(dictionary, kCGWindowName);
        CFNumberRef layer_ref        = CFDictionaryGetValue(dictionary, kCGWindowLayer);
        CFDictionaryRef bounds_ref   = CFDictionaryGetValue(dictionary, kCGWindowBounds);

        if (!name_ref || !owner_ref || !owner_pid_ref || !layer_ref || !bounds_ref)
            continue;

        int64_t layer = 0;
        if (!CFNumberGetValue(layer_ref, kCFNumberSInt64Type, &layer)) continue;

        pid_t owner_pid = 0;
        if (!CFNumberGetValue(owner_pid_ref, kCFNumberIntType, &owner_pid)) continue;

        if (layer != 0x19) continue;

        bounds = CGRectNull;
        if (!CGRectMakeWithDictionaryRepresentation(bounds_ref, &bounds)) continue;

        bool owner_ok = CFStringGetCString(owner_ref, owner_buffer, sizeof(owner_buffer), kCFStringEncodingUTF8);
        bool name_ok  = CFStringGetCString(name_ref, name_buffer, sizeof(name_buffer), kCFStringEncodingUTF8);

        if (!owner_ok || !name_ok) continue;

        snprintf(alias_buffer, sizeof(alias_buffer), "%s,%s", owner_buffer, name_buffer);

        if (strcmp(alias_buffer, alias) == 0) {
            pid = owner_pid;
            break;
        }
    }

    CFRelease(window_list);
    if (!pid) return NULL;

    // 根据窗口所属 pid 创建 AX 应用对象
    AXUIElementRef app = AXUIElementCreateApplication(pid);
    if (!app) return NULL;

    AXUIElementRef result   = NULL;
    CFTypeRef extras        = NULL;
    CFArrayRef children_ref = NULL;

    AXError error = AXUIElementCopyAttributeValue(
        app,
        kAXExtrasMenuBarAttribute,
        &extras
    );

    if (error == kAXErrorSuccess) {
        error = AXUIElementCopyAttributeValue(
            extras,
            kAXVisibleChildrenAttribute,
            (CFTypeRef*)&children_ref
        );

        if (error == kAXErrorSuccess) {
            CFIndex count = CFArrayGetCount(children_ref);

            // 遍历 Extras Menu Bar 中的可见项目，根据位置匹配对应窗口
            for (CFIndex i = 0; i < count; ++i) {
                AXUIElementRef item    = CFArrayGetValueAtIndex(children_ref, i);
                CFTypeRef position_ref = NULL;
                CFTypeRef size_ref     = NULL;

                AXUIElementCopyAttributeValue(item, kAXPositionAttribute, &position_ref);
                AXUIElementCopyAttributeValue(item, kAXSizeAttribute, &size_ref);

                if (!position_ref || !size_ref) {
                    if (position_ref) CFRelease(position_ref);
                    if (size_ref) CFRelease(size_ref);
                    continue;
                }

                CGPoint position = CGPointZero;
                CGSize size      = CGSizeZero;

                bool position_ok = AXValueGetValue(position_ref, kAXValueCGPointType, &position);
                bool size_ok     = AXValueGetValue(size_ref, kAXValueCGSizeType, &size);

                CFRelease(position_ref);
                CFRelease(size_ref);

                if (!position_ok || !size_ok) continue;

                // position 用于匹配窗口位置，size 用于确认元素具备完整几何信息
                if (error == kAXErrorSuccess && fabs(position.x - bounds.origin.x) <= 10) {
                    result = CFRetain(item);
                    break;
                }
            }
        }
        if (children_ref) CFRelease(children_ref);
    }
    if (extras) CFRelease(extras);

    CFRelease(app);
    return result;
}

// 初始化辅助功能权限
void ax_init(void) {
    const void* keys[]   = { kAXTrustedCheckOptionPrompt };
    const void* values[] = { kCFBooleanTrue };

    CFDictionaryRef options = CFDictionaryCreate(
        kCFAllocatorDefault,
        keys,
        values,
        sizeof(keys) / sizeof(*keys),
        &kCFCopyStringDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks
    );

    if (!options) exit(1);

    bool trusted = AXIsProcessTrustedWithOptions(options);
    CFRelease(options);

    if (!trusted) exit(1);
}

// 获取当前前台 App 的辅助功能元素
AXUIElementRef ax_create_front_app(void) {
    ProcessSerialNumber psn;
    _SLPSGetFrontProcess(&psn);

    int target_cid;
    SLSGetConnectionIDForPSN(SLSMainConnectionID(), &psn, &target_cid);

    pid_t pid;
    SLSConnectionGetPID(target_cid, &pid);

    return AXUIElementCreateApplication(pid);
}

// 打印前台 App 菜单栏中的菜单项
void ax_print_menu_options(AXUIElementRef app) {
    AXUIElementRef menubar_ref = NULL;
    CFArrayRef children_ref    = NULL;

    if (!app) return;

    AXError error = AXUIElementCopyAttributeValue(
        app,
        kAXMenuBarAttribute,
        (CFTypeRef*)&menubar_ref
    );

    if (error != kAXErrorSuccess) goto cleanup;

    error = AXUIElementCopyAttributeValue(
        menubar_ref,
        kAXVisibleChildrenAttribute,
        (CFTypeRef*)&children_ref
    );

    if (error != kAXErrorSuccess) goto cleanup;

    CFIndex count = CFArrayGetCount(children_ref);
    for (CFIndex i = 1; i < count; ++i) {
        AXUIElementRef item = CFArrayGetValueAtIndex(children_ref, i);
        CFTypeRef title     = ax_copy_title(item);

        if (title) {
            CFIndex length    = CFStringGetLength(title);
            CFIndex max_size  = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8) + 1;
            char buffer[max_size];

            if (CFStringGetCString(title, buffer, max_size, kCFStringEncodingUTF8)) {
                printf("%s\n", buffer);
            }

            CFRelease(title);
        }
    }

cleanup:
    if (children_ref) CFRelease(children_ref);
    if (menubar_ref) CFRelease(menubar_ref);
}

// 选择前台 App 菜单栏中的指定菜单项
void ax_select_menu_option(AXUIElementRef app, int menu_id) {
    AXUIElementRef menubar_ref = NULL;
    CFArrayRef children_ref    = NULL;

    if (!app) return;

    AXError error = AXUIElementCopyAttributeValue(
        app,
        kAXMenuBarAttribute,
        (CFTypeRef*)&menubar_ref
    );

    if (error != kAXErrorSuccess) goto cleanup;

    error = AXUIElementCopyAttributeValue(
        menubar_ref,
        kAXVisibleChildrenAttribute,
        (CFTypeRef*)&children_ref
    );

    if (error != kAXErrorSuccess) goto cleanup;

    CFIndex count = CFArrayGetCount(children_ref);
    CFIndex idx   = (CFIndex)menu_id;

    if (idx >= 0 && idx < count) {
        AXUIElementRef item = CFArrayGetValueAtIndex(children_ref, idx);
        ax_perform_click(item);
    }

cleanup:
    if (children_ref) CFRelease(children_ref);
    if (menubar_ref) CFRelease(menubar_ref);
}

// 选择指定别名对应的菜单栏额外项目
void ax_select_menu_extra(const char* alias) {
    if (!alias) return;

    AXUIElementRef item = ax_copy_extra_menu_item(alias);
    if (!item) return;

    int cid = SLSMainConnectionID();

    // 让菜单栏额外项目暂时可见以便 Accessibility 点击
    SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 0.0);
    SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, true);
    SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 0.0);

    ax_perform_click(item);

    // 恢复菜单栏默认状态
    SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, false);
    SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 1.0);

    CFRelease(item);
}
