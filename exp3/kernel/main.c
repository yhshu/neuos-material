// head.s后默认运行的程序 //

#include <linux/kernel.h>

extern int video_x;
extern int video_y;

void main()
{
    int i;
    video_init();
    printk("Welcome to neuos.\n");
    printk("When you see this text, the printk function has been successfully implemented.\n");
    /* 测试滚屏
      for(int i = 0; i < 25; i++)
          for(int j = 0; j < 16; j++)
              printk("neuos");
    */
    s_printk("\n\nWelcome to neuos.\n");
    s_printk("When you see this text, the s_printk function has been successfully implemented.\n");
    echo("\\033[4;5m1");
    while (1)
        ;
}
