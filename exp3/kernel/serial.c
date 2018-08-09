#include <asm/io.h>
#include <stdarg.h> //这个库实现了C语言的不定参数函数
#include <linux/kernel.h>
#define PORT 0x3f8

// Step 2 & Step 2.5 参考网站：http://wiki.osdev.org/Serial_Ports

int is_transmit_empty() //可以传输则返回0
{
    return inb(PORT + 5) & 0x20;
}

void s_putchar(char a)
{
    //** 请在此处键入你的代码 **//
}

void s_puts(char *a)
{
    while (*a)
    {
        s_putchar(*a++);
    }
}

int serial_debugstr(char *str)
{
    s_puts(str);
    return 0;
}

void s_printnum(int num, int base, int sign)
{
    char digits[] = "0123456789ABCDEF";
    char buf[50] = "";
    int cnt = 0;
    int i;

    if (sign && num < 0)
    { //检查正负符号
        s_putchar('-');
        num = -num;
    }

    if (num == 0)
    {
        s_putchar('0');
        return;
    }
    while (num)
    {
        buf[cnt++] = digits[num % base];
        num = num / base;
    }

    for (i = cnt - 1; i >= 0; i--)
    {
        s_putchar(buf[i]);
    }
    return;
}

void s_printk(char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);

    //** 请在此处键入你的代码 **//

    return;
}

// ** Step 2.5 ** //
// ** 请在此处键入你的代码 ** //
// 不必实现最终效果，仅完成读取串行端口的代码。
int serial_received()
{

}

char read_serial()
{

}
