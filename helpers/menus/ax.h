#ifndef AX_H
#define AX_H

#include <Carbon/Carbon.h>

// 初始化辅助功能权限，未授权或创建配置失败时直接退出进程
void ax_init(void);

// 获取当前前台 App 的辅助功能元素
// 调用方负责 CFRelease 返回值
AXUIElementRef ax_create_front_app(void);

// 打印前台 App 菜单栏中的菜单项
void ax_print_menu_options(AXUIElementRef app);

// 选择前台 App 菜单栏中的指定菜单项
void ax_select_menu_option(AXUIElementRef app, int menu_id);

// 选择指定别名对应的菜单栏额外项目
void ax_select_menu_extra(const char* alias);

#endif
