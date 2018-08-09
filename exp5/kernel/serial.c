// ** 实验 5 Step 4 ** //

#include <asm/io.h>
#include <stdarg.h>
#include <linux/kernel.h>
#define PORT 0x3f8

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
    //** 请在此处键入你的代码 **//
}

int serial_debugstr(char *str)
{
    s_puts(str);
    return 0;
}

void s_printnum(int num, int base, int sign)
{
    //** 请在此处键入你的代码 **//
}

void s_printk(char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);

    //** 请在此处键入你的代码 **//

}

int serial_received()
{
    return inb(PORT + 5) & 1;
}

char read_serial()
{
    while (serial_received() == 0)
        return inb(PORT);
}