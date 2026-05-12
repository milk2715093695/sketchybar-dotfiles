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
void cpu_init(struct cpu* cpu);

// 释放 CPU 资源
void cpu_deinit(struct cpu* cpu);

// 更新 CPU 负载
void cpu_update(struct cpu* cpu);

#endif
