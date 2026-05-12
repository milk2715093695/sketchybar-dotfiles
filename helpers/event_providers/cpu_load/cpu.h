#ifndef CPU_H
#define CPU_H

#include <mach/mach.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

// 定义 CPU 结构体
struct cpu {
    host_t host;
    mach_msg_type_number_t count;
    host_cpu_load_info_data_t load;
    host_cpu_load_info_data_t prev_load;
    bool has_prev_load;

    int user_load;
    int sys_load;
    int total_load;
};

// 初始化 CPU
static inline void cpu_init(struct cpu* cpu) {
    if (!cpu) return;

    cpu->host = mach_host_self();
    cpu->count = HOST_CPU_LOAD_INFO_COUNT;
    cpu->has_prev_load = false;

    cpu->user_load  = 0;
    cpu->sys_load   = 0;
    cpu->total_load = 0;
}

// 释放 CPU 资源
static inline void cpu_deinit(struct cpu* cpu) {
    if (!cpu) return;

    mach_port_deallocate(mach_task_self(), cpu->host);
}

// 更新 CPU 负载
static inline void cpu_update(struct cpu* cpu) {
    if (!cpu) return;

    cpu->count = HOST_CPU_LOAD_INFO_COUNT;

    kern_return_t error = host_statistics(
        cpu->host,
        HOST_CPU_LOAD_INFO,
        (host_info_t)&cpu->load,
        &cpu->count
    );

    if (error != KERN_SUCCESS) {
        fprintf(stderr, "Error: Could not read cpu host statistics.\n");
        return;
    }

    if (cpu->has_prev_load) {
        uint32_t delta_user   = cpu->load.cpu_ticks[CPU_STATE_USER]   - cpu->prev_load.cpu_ticks[CPU_STATE_USER];
        uint32_t delta_system = cpu->load.cpu_ticks[CPU_STATE_SYSTEM] - cpu->prev_load.cpu_ticks[CPU_STATE_SYSTEM];
        uint32_t delta_idle   = cpu->load.cpu_ticks[CPU_STATE_IDLE]   - cpu->prev_load.cpu_ticks[CPU_STATE_IDLE];
        uint32_t delta_nice   = cpu->load.cpu_ticks[CPU_STATE_NICE]   - cpu->prev_load.cpu_ticks[CPU_STATE_NICE];

        uint32_t total = delta_user + delta_system + delta_idle + delta_nice;
        if (total > 0) {
            cpu->user_load  = (int)((double)delta_user   / total * 100.0 + 0.5);
            cpu->sys_load   = (int)((double)delta_system / total * 100.0 + 0.5);
            cpu->total_load = (int)((double)(delta_user + delta_system + delta_nice) / total * 100.0 + 0.5);
        }
    }

    cpu->prev_load    = cpu->load;
    cpu->has_prev_load = true;
}

#endif
