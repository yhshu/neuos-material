#ifndef _KERNEL_H
#define _KERNEL_H

//VGA
void printk(char *fmt, ...); // printk相对于 Linux v0.11 简化
void video_putchar_at(char ch, int x, int y, char attr);
void video_putchar(char ch);
void video_clear();
void video_init();
int video_getx();
int video_gety();
void roll_screen();
void memcpy1(char *dest, char *src, int count, int size);
void printnum(int num, int base, int sign);
int get_cursor();
void update_cursor(int row, int col);

//串口
extern void s_putchar(char a);
extern void s_puts(char *s);
extern void s_printnum(int num, int base, int sign);
extern void s_printk(char *fmt, ...);

int video_x, video_y;

#endif
