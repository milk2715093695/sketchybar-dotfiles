#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#include "cpu.h"
#include "../sketchybar.h"

int main(int argc, char** argv) {
    float update_freq;          // 处理传入参数：更新频率
    struct cpu cpu;             // CPU 信息结构体
    char event_message[512];    // 用来注册事件的消息
    char trigger_message[512];  // 用来触发事件的消息
    struct timespec ts;         // 用来控制更新频率的定时器

    // 保证参数数量与格式
    if (argc < 3 || (sscanf(argv[2], "%f", &update_freq) != 1)) {
        fprintf(stderr, "Usage: %s \"<event-name>\" \"<event_freq>\"\n", argv[0]);
        exit(1);
    }

    // update_freq 边界检查
    if (update_freq <= 0) {
        fprintf(stderr, "Error: event_freq must be greater than 0\n");
        exit(1);
    }

    alarm(0);

    // 初始化 CPU 信息并预热采样一次
    cpu_init(&cpu);
    cpu_update(&cpu);

    // 在 SketchyBar 中注册事件
    snprintf(event_message, sizeof(event_message), "--add event '%s'", argv[1]);
    sketchybar(event_message);

    // 每隔 update_freq 秒更新一次 CPU 信息并触发事件
    for (;;) {
        ts.tv_sec  = (time_t)update_freq;
        ts.tv_nsec = (long)((update_freq - ts.tv_sec) * 1e9);
        nanosleep(&ts, NULL);

        cpu_update(&cpu);

        // 构造触发事件的消息
        snprintf(
            trigger_message,
            sizeof(trigger_message),
            "--trigger '%s' user_load='%d' sys_load='%02d' total_load='%02d'",
            argv[1],
            cpu.user_load,
            cpu.sys_load,
            cpu.total_load
        );
        sketchybar(trigger_message);
    }

    // 释放 CPU 资源
    cpu_deinit(&cpu);
    return 0;
}
