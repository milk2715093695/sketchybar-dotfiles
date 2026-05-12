#ifndef NETWORK_H
#define NETWORK_H

#include <net/if.h>
#include <net/if_mib.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>

// 定义网络速度单位
extern const char* const unit_str[];

// 定义网络速度单位枚举
enum unit {
    UNIT_BPS,
    UNIT_KBPS,
    UNIT_MBPS,
    UNIT_GBPS,
};

// 定义网络信息结构体
struct network {
    uint32_t row;
    struct ifmibdata data;
    struct timespec ts_nm1, ts_n, ts_delta;

    int up;
    int down;
    enum unit up_unit, down_unit;
};

// 获取网络信息
bool ifdata(uint32_t net_row, struct ifmibdata* data);

// 初始化网络信息
void network_init(struct network* net, const char* ifname);

// 格式化网络速度
void format_rate(double bytes_per_sec, int* value, enum unit* unit);

// 更新网络信息
void network_update(struct network* net);

#endif
