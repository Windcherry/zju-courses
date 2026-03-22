#include <mm.h>
#include <proc.h>
#include <private_kdefs.h>
#include <printk.h>
#include <stddef.h>
#include <stdlib.h>

_Static_assert(
    offsetof(struct task_struct, thread) == OFFSET_THREAD_STRUCT,
    "OFFSET_THREAD_STRUCT in private_kdefs.h is incorrect!"
);

static struct task_struct *task[NR_TASKS]; // 线程数组，所有的线程都保存在此
static struct task_struct *idle;           // idle 线程
struct task_struct *current;               // 当前运行线程

void __dummy(void);
void __switch_to(struct task_struct *prev, struct task_struct *next);
void task_init(void){
    srand(2025);

  // 1. 调用 alloc_page() 为 idle 分配一个物理页
    idle = alloc_page();

  // 2. 初始化 idle 线程：
  //   - state 为 TASK_RUNNING
  //   - pid 为 0
  //   - 由于其不参与调度，可以将 priority 和 counter 设为 0
    idle->pid = 0;
    idle->state = TASK_RUNNING;
    idle->priority = 0;
    idle->counter = 0;

  // 3. 将 current 和 task[0] 指向 idle
    current = idle;
    task[0] = idle;

  // 4. 初始化 task[1..NR_TASKS - 1]：
  //    - 分配一个物理页
  //    - state 为 TASK_RUNNING
  //    - pid 为对应线程在 task 数组中的索引
  //    - priority 为 rand() 产生的随机数，控制范围在 [PRIORITY_MIN, PRIORITY_MAX]
  //    - counter 为 0
  //    - 设置 thread_struct 中的 ra 和 sp：
  //      - ra 设置为 __dummy 的地址（见 4.3.2 节）
  //      - sp 设置为该线程申请的物理页的高地址
    int i;
    for(i = 1; i < NR_TASKS; i++){
        task[i] = alloc_page();
        task[i]->pid = i;
        task[i]->state = TASK_RUNNING;
        task[i]->priority = (rand() % (PRIORITY_MAX - PRIORITY_MIN + 1)) + PRIORITY_MIN;
        task[i]->counter = 0;
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
        // 若 priority 为 1，则线程可见的 counter 永远为 1（为什么？）
        // 通过设置 counter 为 0，避免信息无法打印的问题
        current->counter = 0;
      }
      prev_cnt = current->counter;
      printk("[PID = %" PRIu64 "] Running. local = %u\n", current->pid, ++local);
    }
  }
}

void switch_to(struct task_struct *next) {
  if(next != current){
    printk("switch to [PID = %" PRIu64 ", PRIORITY = %" PRIu64 ", COUNTER = %" PRIu64 "]\n", 
           next->pid, next->priority, next->counter);
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
      if(task[i]->counter > max_counter && task[i]->state == TASK_RUNNING){
        max_counter = task[i]->counter;
        next = task[i];
      }
    }

    if(next != NULL) break;

    // 2. 如果所有线程的 counter 均为 0，则将所有线程的 counter 设置为其 priority，然后重复第 1 步
    for(int i = 1; i < NR_TASKS; i++){
      task[i]->counter = task[i]->priority;
      printk("SET [PID = %" PRIu64 ", PRIORITY = %" PRIu64 ", COUNTER = %" PRIu64 "]\n", 
             task[i]->pid, task[i]->priority, task[i]->counter);
    }
  }

  // 3. 调用 switch_to 进行线程切换
  switch_to(next);
}