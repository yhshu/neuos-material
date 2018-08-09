//**实验 5 拓展学习**//
//任务：改写 memory.c 的函数 get_free_page 中的内联汇编为 C 语言//
//函数功能：通过找到 mem_map 数组中为 0 的一项，获取空闲的页。
//若成功：返回空闲页的物理地址；若失败：返回 0.


// 以下是 memory.c 中的原函数
/*
unsigned long get_free_page(void) {
   register unsigned long __res asm("ax");

   __asm__ volatile ("std; repne; scasb\n\t"
                "jne 1f\n\t"
                "movb $1, 1(%%edi)\n\t"
                "sall $12, %%ecx\n\t"
                "addl %2, %%ecx\n\t"
                "movl %%ecx, %%edx\n\t"
                "movl $1024, %%ecx\n\t"
                "leal 4092(%%edx), %%edi\n\t"
                "rep; stosl;\n\t"
                "movl %%edx, %%eax\n"
                "1: cld"
                : "=a" (__res)
                : "0" (0), "i" (LOW_MEM), "c" (PAGING_PAGES), "D" (mem_map + PAGING_PAGES - 1));    // 从尾端开始检查是否有可用的物理页
   return __res;
}
*/
