//实现部分内存管理的功能。
#include <linux/kernel.h>

//内联汇编；用于使 TLB(页表缓存)失效，刷新缓存。
#define invalidate() \
    __asm__ volatile("mov %%eax, %%cr3" ::"a"(0))

//释放物理内存 addr 开始的一页内存。修改页面映射数组 mem_map[] 中引用次数的信息。
unsigned long put_page(unsigned long page, unsigned long address);

void testoom()
{
    for (int i = 0; i < 20 * 1024 * 1024; i += 4096)
        do_no_page(0, i); //处理缺页异常
    //此处不应该返回！
    return;
}

void test_put_page()
{
    char *b = 0x100000;
    calc_mem();
    //put_page(0x200000, 0x100000);
    calc_mem();
    *b = 'k';
    while (1)
        ;
}

// 线性地址通过页表转化为物理地址
// 若成功，返回指向页表项的指针
// 若失败，返回 NULL(0)
unsigned long *linear_to_pte(unsigned long addr)
{
    // 参数 addr 是线性地址，22～31位索引页目录，12～21位索引页表，0～11位是页内偏移
    // 本函数只获得指向页表项的指针，不尝试访问页，页表项也不一定存在，addr 的最后 12 位没有被使用

    // ** 实验 4 Step 1 ** //
    // ** 请在此处键入你的代码 ** //
    // 提示：首先使用无符号长整型(32位)指针 *pde 获取页目录项地址
    // 页目录范围 0x00000000~0x00000fff，每个页目录项 4 字节

    // unsigned long *pde = (unsigned long *) ?


    // 然后判断，若 pde 指向的页表不存在(根据present位判断) 或者
    // 该地址不在页目录地址范围内，返回 0
    // if ?
    //     return 0;

    // 获得页目录项地址后，可获得 addr 所在页的所属页表的地址
    // 要计算页表的物理地址，需要将 *pde 后 12 位置为 0，即使得页内偏移为 0
    // 页表地址 + 页表索引 = 页表项



}

void disable_linear(unsigned long addr)
{

    //修改现有PTE，使得 present 位为0
    unsigned long *pte = linear_to_pte(addr);
    *pte = 0;
    invalidate();
    return;
}

void mm_read_only(unsigned long addr)
{
    unsigned long *pte = linear_to_pte(addr);
    printk("PTE before read_only: 0x%x\n", *pte);
    *pte = *pte & 0xfffffffd; // 修改页表项 Read/Write 位为 0
    printk("PTE after read_only: 0x%x\n", *pte);
    invalidate();
    return;
}

//显示页的信息
void mm_print_pageinfo(unsigned long addr)
{
    unsigned long *pte = linear_to_pte(addr);
    printk("Linear address: 0x%x, PTE address = 0x%x. Flags [ ", addr, pte);

    // ** 实验 4 Step 2 ** //
    // ** 请在此处键入你的代码 ** //


    printk("]\n");
    printk("Physical address = %x\n", (*pte & 0xfffff000));
}

int mmtest_main(void)
{
    int i = 0;
    printk("*** Running memory function tests ***\n\n");
    printk("1. Make linear address 0xdad233 unavailable\n");

    disable_linear(0xdad233);
    // 不要修改上面的代码
    // 使线性地址 0xdad233 可用，并添加页表项，将页 (0x300000) 存储在线性地址 0xdad233 处

    printk("2. Put page (0x300000) at linear address 0xdad233\n");
    put_page(0x300000, 0xdad233); // 将物理页面与线性地址挂接

    unsigned long *x = 0xdad233; // x 指向 0xdad233，
    *x = 0x23333333;             // 线性地址 0xdad233 的内容改为 0x23333333
    printk("X = %x\n", *x);

    // 然后使线性地址 0xdad233 对应的页只读
    printk("3. Make 0xdad233 READ ONLY\n");
    mm_read_only(0xdad233); // 修改页表项 R/W 位
    x = 0xdad233;

    // 下面这句汇编会使 cr0 寄存器中的 WP 位生效；WP 位开启时，特权级 0 也不能对只读页进行操作
    asm volatile("mov %%cr0, %%eax\n\t"
                 "orl $0x00010000, %%eax\n\t"
                 "mov %%eax, %%cr0\n\t" ::);

    // ** 实验 4 Step 3 ** //
    // ** 请在此处键入你的代码 ** //
    // 编写一段内联汇编，尝试修改线性地址 0xdad233 处的内容
    // 这会触发页的写入保护，由于 WP 位开启，下面这段代码正常的结果是引发错误


    printk("4. Print the page info of 0xdad233 in human readable mode\n");
    mm_print_pageinfo(0xdad233);
}
