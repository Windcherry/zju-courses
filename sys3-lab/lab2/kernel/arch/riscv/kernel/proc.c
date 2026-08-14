#include <mm.h>
#include <proc.h>
#include <private_kdefs.h>
#include <printk.h>
#include <stddef.h>
#include <stdlib.h>


static struct task_struct *task[NR_TASKS];
static struct task_struct *idle;
struct task_struct *current;

void __dummy(void);
void __switch_to(struct task_struct *prev, struct task_struct *next);

void task_init(void){
    srand(2025);

    idle = alloc_page();
    idle->pid = 0;
    idle->state = TASK_RUNNING;
    idle->priority = 0;
    idle->counter = 0;

    current = idle;
    task[0] = idle;

    int i;
    for(i = 1; i < NR_TASKS; i++){
        task[i] = alloc_page();
        task[i]->pid = i;
        task[i]->state = TASK_RUNNING;
        task[i]->priority = (rand() % (PRIORITY_MAX - PRIORITY_MIN + 1)) + PRIORITY_MIN;
        task[i]->counter = task[i]->priority;  // 初始化时设为priority，避免第一次调度时所有counter为0
        task[i]->thread.ra = (uint64_t)__dummy;
        task[i]->thread.sp = (uint64_t)task[i] + PGSIZE;
    }

    printk("...task_init done!\n");
}

void dummy_task(void) {
    unsigned local = 0;
    unsigned prev_cnt = 0;
    while (1) {
        if (current->counter != prev_cnt) {
            if (current->counter == 1) {
                current->counter = 0;
            }
            prev_cnt = current->counter;
            printk("[P = %lu] %u\n", current->pid, ++local);
        }
    }
}

void switch_to(struct task_struct *next) {
    if(next != current){
        // printk("switch to [%" PRIu64 ", %" PRIu64 ", %" PRIu64 "]\n", next->pid, next->priority, next->counter);
        struct task_struct *prev = current;
        current = next;
        __switch_to(prev, next);
    }
}

void do_timer(void) {

    // 1. 如果当前线程时间片耗尽，则直接进行调度
    if(current->counter == 0 || current == idle){
        schedule();
    }
    // 2. 否则将运行剩余时间减 1，若剩余时间仍然大于 0 则直接返回，否则进行调度
    else{
        current->counter--;
        if(current->counter == 0){
            schedule();
        }
        else return;
    }
}

void schedule(void) {
    struct task_struct *next = NULL;

    while(1){
        int max_counter = 0;
        next = NULL;
        
        // 1. 寻找 counter 最大的线程作为下一个运行线程
        for(int i = 1; i < NR_TASKS; i++){
            if(task[i]->counter > (uint64_t)max_counter && task[i]->state == TASK_RUNNING){
                max_counter = task[i]->counter;
                next = task[i];
            }
        }

        if(next != NULL) break;

        // 2. 如果所有线程的 counter 均为 0，则将所有线程的 counter 设置为其 priority，然后重复第 1 步
        for(int i = 1; i < NR_TASKS; i++){
            task[i]->counter = task[i]->priority;
            printk("SET [%" PRIu64 ", %" PRIu64 ", %" PRIu64 "]\n", 
                    task[i]->pid, task[i]->priority, task[i]->counter);
        }
    }

    // 3. 调用 switch_to 进行线程切换
    switch_to(next);
}