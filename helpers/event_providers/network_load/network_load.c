#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#include "network.h"
#include "../sketchybar.h"

int main(int argc, char** argv) {
    float update_freq;          // 处理传入参数：更新频率
    struct network network;     // 网络接口信息
    char event_message[512];    // 用来注册事件的消息
    char trigger_message[512];  // 用来触发事件的消息
    struct timespec ts;         // 用来控制更新频率的定时器

    // 保证参数数量与格式
    if (argc < 4 || (sscanf(argv[3], "%f", &update_freq) != 1)) {
        fprintf(stderr, "Usage: %s \"<interface>\" \"<event-name>\" \"<event_freq>\"\n", argv[0]);
        exit(1);
    }

    // update_freq 边界检查
    if (update_freq <= 0) {
        fprintf(stderr, "Error: event_freq must be greater than 0\n");
        exit(1);
    }

    alarm(0);

    // 在 SketchyBar 中注册事件
    snprintf(event_message, sizeof(event_message), "--add event '%s'", argv[2]);
    sketchybar(event_message);

    // 初始化网络信息
    network_init(&network, argv[1]);

    // 每隔 update_freq 秒更新一次网络信息并触发事件
    for (;;) {
        // 获取新数据
        network_update(&network);

        // 构造触发事件的消息
        snprintf(
            trigger_message,
            sizeof(trigger_message),
            "--trigger '%s' upload='%03d%s' download='%03d%s'",
            argv[2],
            network.up,
            unit_str[network.up_unit],
            network.down,
            unit_str[network.down_unit]
        );
        sketchybar(trigger_message);

        ts.tv_sec  = (time_t)update_freq;
        ts.tv_nsec = (long)((update_freq - ts.tv_sec) * 1e9);
        nanosleep(&ts, NULL);
    }

    return 0;
}
