// printk 是内核态格式化输出函数。neuos 中的 printk 函数相较于 Linux 作了简化。

#include <linux/kernel.h>
#include <asm/io.h>
#include <stdarg.h> //这个库实现了C语言的不定参数函数
#include <stddef.h>

#define PAGE_SIZE 4096
#define VIDEO_MEM 0xB8000 //显存地址首位
#define VIDEO_X_SZ 80
#define VIDEO_Y_SZ 25
#define CALC_MEM(x, y) (2 * ((x) + 80 * (y)))

long user_stack[PAGE_SIZE >> 2];

extern int video_x;
extern int video_y;

char *video_buffer = VIDEO_MEM; //指向显存地址首位

struct
{
    long *a;
    short b;
} stack_start = {&user_stack[PAGE_SIZE >> 2], 0x10};

struct video_info
{
    unsigned int retval;    // 返回值
    unsigned int colormode; // 颜色
    unsigned int feature;   // 特征设定
};

void video_init()
{
    struct video_info *info = 0x9000;

    video_x = 0;
    video_y = 0;
    video_clear();
    update_cursor(video_y, video_x);
}

int video_getx()
{
    return video_x;
}

int video_gety()
{
    return video_y;
}

void update_cursor(int row, int col) //更新光标
{
    unsigned int pos = (row * VIDEO_X_SZ) + col;
    // LOW Cursor端口到VGA索引寄存器
    outb(0x3D4, 0x0F);
    outb(0x3D5, (unsigned char)(pos & 0xFF));
    // High Cursor端口到VGA索引寄存器
    outb(0x3D4, 0x0E);
    outb(0x3D5, (unsigned char)((pos >> 8) & 0xFF));
    return;
}

int get_cursor()
{
    int offset;
    outb(0x3D4, 0xF);
    offset = inb(0x3D5) << 8;
    outb(0x3D4, 0xE);
    offset += inb(0x3D5);
    return offset;
}

void video_putchar_at(char ch, int x, int y, char attr)
//video_clear() 和 video_putchar() 函数中调用了本函数。
//本函数用于在屏幕指定位置(x,y)输出指定字符串 ch，并且通过颜色代码 attr 指定其颜色.
//参考网站：http://wiki.osdev.org/Printing_To_Screen
{
    //** 请在此处键入你的代码 **//

    // *(video_buffer + ?) = ch;
    // *(video_buffer + ?) = attr;
    return;
}

void video_putchar(char ch)
{
    if (ch == '\n')
    {
        video_x = 0;
        video_y++;
    }
    else
    {
        video_putchar_at(ch, video_x, video_y, 0x0F);
        video_x++;
    }
    if (video_x >= VIDEO_X_SZ)
    {
        video_x = 0;
        video_y++;
    }
    if (video_y >= VIDEO_Y_SZ)
    {
        roll_screen();
        video_x = 0;
        video_y = VIDEO_Y_SZ - 1;
    }

    update_cursor(video_y, video_x);
    return;
}

void printk(char *fmt, ...) //不定参数函数
{
    //参考网站：https://msdn.microsoft.com/zh-cn/library/kb57fad8.aspx
    va_list ap;        //参数列表
    va_start(ap, fmt); //设定 ap 是以 fmt 为第一个参数的列表

    char c, *s, *ch;

    while (*fmt) //每读取一个字符循环一次
    {
        c = *fmt++; // c即当前需要处理的字符
	if(c == '\0')
		break;
        //** 请在此处键入你的代码 **//

        //如果 c 不是 %，输出字符，跳转下一循环

        //如果 c 是 %，这可能是一个数字、字符或字符串，读取 % 后面的字符
    }
    return;
}

void printnum(int num, int base, int sign) // base是数字的进制，sign是数字的符号
{
    char digits[] = "0123456789ABCDEF";
    char buf[50] = "";
    int cnt = 0;
    int i;

    if (sign && num < 0) //检查是有符号数或是无符号数
    {
        video_putchar('-');
        num = -num;
    }

    if (num == 0)
    {
        video_putchar('0');
        return;
    }
    //如果num != 0
    while (num)
    {
        buf[cnt++] = digits[num % base]; //处理进制
        num = num / base;
    }

    for (i = cnt - 1; i >= 0; i--)
    {
        video_putchar(buf[i]);
    }
    return;
}

void video_clear() //清屏
{
    int i;
    int j;
    video_x = 0;
    video_y = 0;
    for (i = 0; i < VIDEO_X_SZ; i++)
    {
        for (j = 0; j < VIDEO_Y_SZ; j++)
        {
            video_putchar_at(' ', i, j, 0x0F); // 0x0F是亮白色；此处不要使用0x00，是黑色，你会失去闪烁的光标。
        }
    }
    return;
}

void memcpy(char *dest, char *src, int count, int size)
{
    int i;
    int j;
    for (i = 0; i < count; i++)
    {
        for (j = 0; j < size; j++)
        {
            *(dest + i * size + j) = *(src + i * size + j);
        }
    }
    return;
}

void roll_screen() //滚屏函数
{
    // ** Step 1.5 ** //
    // ** 请在此处键入你的代码 ** //

    // 通过 memcpy 函数，从屏幕第二行到最后一行，将每一行向上移动一行。

    // 通过 video_putchar_at 函数输出空格的方式，清除屏幕最后一行。

    return;
}

//** 以下是 拓展学习 部分**//
// 需要实现函数 echo；以下的其他函数可以在 echo 调用，或作参考
void video_putchar_color(char ch, char attr)
{
    if (ch == '\n')
    {
        video_x = 0;
        video_y++;
    }
    else
    {
        video_putchar_at(ch, video_x, video_y, attr);
        video_x++;
    }
    if (video_x >= VIDEO_X_SZ)
    {
        video_x = 0;
        video_y++;
    }
    if (video_y >= VIDEO_Y_SZ)
    {
        roll_screen();
        video_x = 0;
        video_y = VIDEO_Y_SZ - 1;
    }

    update_cursor(video_y, video_x);
    return;
}

void video_puts_color(char *ch, char attr)
{
    while (*ch)
        video_putchar_color(*ch++, attr);
}

char compute_attr(char foreground, char background)
{
    char attr = 0x00;
    if (foreground - '0' == 0)
        attr += 0x00;
    else if (foreground - '0' == 1)
        attr += 0x0C;
    else if (foreground - '0' == 2)
        attr += 0x0A;
    else if (foreground - '0' == 3)
        attr += 0x0E;
    else if (foreground - '0' == 4)
        attr += 0x09;
    else if (foreground - '0' == 5)
        attr += 0x0D;
    else if (foreground - '0' == 6)
        attr += 0x0B;
    else if (foreground - '0' == 7)
        attr += 0x0F;
    if (background - '0' == 0)
        attr += 0x00;
    else if (background - '0' == 1)
        attr += 0x40;
    else if (background - '0' == 2)
        attr += 0x20;
    else if (background - '0' == 3)
        attr += 0x60;
    else if (background - '0' == 4)
        attr += 0x10;
    else if (background - '0' == 5)
        attr += 0x50;
    else if (background - '0' == 6)
        attr += 0x30;
    else if (background - '0' == 7)
        attr += 0x70;
    return attr;
}

void echo(char *str)
{
    //** 请在此处键入你的代码 **
    /* 假设str是 "\033[x;ymneuos"（没有考虑转义字符）
     * 这段代码应实现的功能是以指定的颜色输出 "neuos" 这串字符
     * 其中 x 和 y 是两个数字，都是 0-7 的整数，m是数字后的后缀。
     * 该函数应能根据 x 和 y，在调用 video_putchar_color 时指定不同的 attr （包含颜色的属性值）
     * 注意，'\0'是NULL的转义字符，'\\'是斜杠的转义字符。
     */

}
