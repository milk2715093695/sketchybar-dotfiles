#ifndef NETWORK_H
#define NETWORK_H

#include <net/if.h>
#include <net/if_mib.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/select.h>
#include <sys/sysctl.h>
#include <time.h>

// 定义网络速度单位
static const char* const unit_str[] = {
    " Bps",
    "KBps",
    "MBps",
    "GBps",
};

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
static inline bool ifdata(uint32_t net_row, struct ifmibdata* data) {
    size_t size = sizeof(struct ifmibdata);
    int mib[] = { CTL_NET, PF_LINK, NETLINK_GENERIC, IFMIB_IFDATA, (int)net_row, IFDATA_GENERAL };
    return sysctl(mib, 6, data, &size, NULL, 0) == 0;
}

// 初始化网络信息
static inline void network_init(struct network* net, const char* ifname) {
    memset(net, 0, sizeof(struct network));
    net->row = if_nametoindex(ifname);
    if (net->row == 0) {
        fprintf(stderr, "Error: Interface '%s' not found\n", ifname);
        exit(1);
    }
}

// 格式化网络速度
static inline void format_rate(double bytes_per_sec, int* value, enum unit* unit) {
    if (bytes_per_sec < 1000.0) {
        *unit = UNIT_BPS;
        *value = (int)(bytes_per_sec + 0.5);
    } else if (bytes_per_sec < 1000000.0) {
        *unit = UNIT_KBPS;
        *value = (int)(bytes_per_sec / 1000.0 + 0.5);
    } else if (bytes_per_sec < 1000000000.0) {
        *unit = UNIT_MBPS;
        *value = (int)(bytes_per_sec / 1000000.0 + 0.5);
    } else {
        *unit = UNIT_GBPS;
        *value = (int)(bytes_per_sec / 1000000000.0 + 0.5);
    }
}

// 更新网络信息
static inline void network_update(struct network* net) {
    clock_gettime(CLOCK_MONOTONIC, &net->ts_n);
    net->ts_delta.tv_sec  = net->ts_n.tv_sec  - net->ts_nm1.tv_sec;
    net->ts_delta.tv_nsec = net->ts_n.tv_nsec - net->ts_nm1.tv_nsec;
    if (net->ts_delta.tv_nsec < 0) {
        net->ts_delta.tv_sec  -= 1;
        net->ts_delta.tv_nsec += 1000000000L;
    }
    net->ts_nm1 = net->ts_n;

    uint64_t ibytes_nm1 = net->data.ifmd_data.ifi_ibytes;
    uint64_t obytes_nm1 = net->data.ifmd_data.ifi_obytes;
    if (!ifdata(net->row, &net->data)) return;

    if (net->data.ifmd_data.ifi_ibytes < ibytes_nm1 || net->data.ifmd_data.ifi_obytes < obytes_nm1) {
        net->down = 0;
        net->up   = 0;
        return;
    }

    double time_scale = net->ts_delta.tv_sec + 1e-9 * net->ts_delta.tv_nsec;
    if (time_scale < 1e-6 || time_scale > 1e2) return;

    double delta_ibytes = (double)(net->data.ifmd_data.ifi_ibytes - ibytes_nm1) / time_scale;
    double delta_obytes = (double)(net->data.ifmd_data.ifi_obytes - obytes_nm1) / time_scale;

    format_rate(delta_ibytes, &net->down, &net->down_unit);
    format_rate(delta_obytes, &net->up,   &net->up_unit);
}

#endif
