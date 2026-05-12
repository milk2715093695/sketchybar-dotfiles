#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ax.h"

int main(int argc, char** argv) {
    // 保证参数数量与格式
    if (argc == 1) {
        printf("Usage: %s [-l | -s id/alias]\n", argv[0]);
        exit(0);
    }

    // 初始化辅助功能权限
    ax_init();

    // 打印当前前台 App 的菜单项
    if (strcmp(argv[1], "-l") == 0) {
        AXUIElementRef app = ax_create_front_app();
        if (!app) return 1;

        ax_print_menu_options(app);
        CFRelease(app);

    // 选择当前前台 App 的菜单项或菜单栏额外项目
    } else if (argc == 3 && strcmp(argv[1], "-s") == 0) {
        int id = 0;

        if (sscanf(argv[2], "%d", &id) == 1) {
            AXUIElementRef app = ax_create_front_app();
            if (!app) return 1;

            ax_select_menu_option(app, id);
            CFRelease(app);
        } else {
            ax_select_menu_extra(argv[2]);
        }
    }

    return 0;
}
