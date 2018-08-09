###########################################################
#														  #
#	     	实验 2     设置GDT IDT  切换到保护模式            #
#													      #
###########################################################

.code16

.text

.equ SETUPSEG, 0x9020
.equ INITSEG, 0x9000
.equ SYSSEG, 0x1000
.equ LEN, 54

.global _start, begtext, begdata, begbss, endtext, enddata, endbss

.text
    begtext:
.data
    begdata:
.bss
    begbss:
.text


show_text:
    mov $SETUPSEG, %ax
    mov %ax, %es
    mov $0x03, %ah
    xor %bh, %bh
    int $0x10                   # these two line read the cursor position
    mov $0x000a, %bx            # Set video parameter
    mov $0x1301, %ax
    mov $LEN, %cx
    mov $msg, %bp
    int $0x10

# 下面的代码调用BIOS中断将硬件的一些状态保存在0x9000:0000开始的内存处
# （注意这里会覆盖bootsect，由于它已被执行，所以这并不重要)
    ljmp $SETUPSEG, $_start
_start:

# 保存光标位置
# Comment for routine 10 service 3
# AH = 03
# BH = video page
# on return:
# CH = cursor starting scan line (low order 5 bits)
# CL = cursor ending scan line (low order 5 bits)
# DH = row
# DL = column
    mov $INITSEG, %ax       # 调用int 0x10, 3中断获取光标位置，并存于0x90000位置
    mov %ax, %ds
    mov $0x03, %ah
    xor %bh, %bh
    int $0x10
    mov %dx, %ds:0

# 取扩展内存大小的值
# Comment for routine 0x15 service 0x88
# AH = 88h
# on return:
# CF = 80h for PC, PCjr
# = 86h for XT and Model 30
# = other machines, set for error, clear for success
# AX = number of contiguous 1k blocks of memory starting
# at address 1024k (100000h)
    mov $0x88, %ah           # 调用int 0x15,88中断获取内存大小值，并存于0x90002位置
    int $0x15
    mov %ax, %ds:2

# 取显卡显示模式
# Comment for routine 10 service 0xf
# AH = 0F
# on return:
# AH = number of screen columns
# AL = mode currently set (see VIDEO MODES)
# BH = current display page
    mov $0x0f, %ah          # 调用int 0x10,0f中断获取显示模式，当前显示页存于0x90004
    int $0x10               # 显示模式存于0x90006，字符列数存于0x90007
    mov %bx, %ds:4
    mov %ax, %ds:6

# 检查显示方式(EGA/VGA)并取参数
# Comment for routine 10 service 0x12
# We use bl 0x10
# BL = 10  return video configuration information
# on return:
# BH = 0 if color mode in effect
# = 1 if mono mode in effect
# BL = 0 if 64k EGA memory
# = 1 if 128k EGA memory
# = 2 if 192k EGA memory
# = 3 if 256k EGA memory
# CH = feature bits
# CL = switch settings
    mov $0x12, %ah
    mov $0x10, %bl
    int $0x10
    mov %ax, %ds:8
    mov %bx, %ds:10
    mov %cx, %ds:12

# 复制硬盘参数表信息
# 第一个硬盘参数表的首地址在0x41中断向量处，第二个硬盘参数表的首地址在0x46中断向量处，紧接着第一个参数表
# 每个参数表长度为 0x10 Byte

# 第一块硬盘参数表
    mov $0x0000, %ax
    mov %ax, %ds
    lds %ds:4*0x41, %si
    mov $INITSEG, %ax
    mov %ax, %es
    mov $0x0080, %di
    mov $0x10, %cx
    rep movsb

# 第二块硬盘参数表
    mov $0x0000, %ax
    mov %ax, %ds
    lds %ds:4*0x46, %si
    mov $INITSEG, %ax
    mov %ax, %es
    mov $0x0090, %di
    mov $0x10, %cx
    rep movsb

# 检查第二块硬盘是否存在，如果不存在的话就清空相应的参数表(
# Comment for routine 0x13 service 0x15
# AH = 15h
# DL = drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)
# on return:
# AH = 00 drive not present
# = 01 diskette, no change detection present
# = 02 diskette, change detection present
# = 03 fixed disk present
# CX:DX = number of fixed disk sectors; if 3 is returned in AH
# CF = 0 if successful
# = 1 if error
    mov $0x1500, %ax
    mov $0x81, %dl
    int $0x13
    jc no_disk1
    cmp $3, %ah
    je is_disk1
no_disk1:               # 没有第二块硬盘，则对第二个硬盘表清零，使用stosb
    mov $INITSEG, %ax
    mov %ax, %es
    mov $0x0090, %di
    mov $0x10, %cx
    mov $0x00, %ax
    rep stosb

is_disk1:

# 下面切换到保护模式了
# 进行切换保护模式的准备操作
    cli                 # 关中断

# 我们先将 system 从 0x1000:0000 移动到 0x0000:0000 处
    mov $0x0000, %ax
    cld                 # Direction = 0 move forward
do_move:
    mov %ax, %es
    add $0x1000, %ax
    cmp $0x9000, %ax    # Does we finish the move
    jz end_move
    mov %ax, %ds
    sub %di, %di
    sub %si, %si
    mov $0x8000, %cx    # Move 0x8000 word = 0x10000 Byte (64KB)
    rep movsw
    jmp do_move

# 下面加载 GDTR, IDTR 等

end_move:
    mov $SETUPSEG, %ax
    mov %ax, %ds
    lgdt gdt_48			# 加载全局描述符表寄存器
    lidt idt_48			# 加载中断描述符表寄存器

# 开启A20地址线，使得可以访问64KB以上的内存
    inb $0x92, %al              # 向I/O端口0x92输出1可开启A20端口。方法不止此一种，详情见(https://www.win.tue.nl/~aeb/linux/kbd/A20.html)
    orb $0b00000010, %al
    outb %al, $0x92

# ** 实验 2 Step 3 **

    mov %cr0, %eax
    bts $0, %eax
    mov %eax, %cr0

    .equ sel_cs0, 0x0008
    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    ljmp $sel_cs0, $0


gdt_48:                 # 全局描述符GDT，长6字节，前2字节为表长，后4字节为表的基地址
    .word 0x800         # 表长0x800
    .word 512+gdt, 0x9  # GDT表的线性基地址为 0x90200+gdt，这里需要自行填写汇编代码
                        # 提示：地址计算方式为高位地址左移16位加上地位偏移量

idt_48:                 # 中断描述符IDT
    .word 0             # 表长
    .word 0, 0          # 基地址


# 下面是全局描述符表的开始处。描述符表由多个8字节长的描述符项组成。
# 这里给出了3个描述符项。第1项无用，但必须存在。
# 第2项是系统代码段描述符，第3项是系统数据段描述符。
gdt:                    # GDT描述符的格式在 Intel 手册中介绍
    .word   0,0,0,0     # GDT表第1个描述符默认为0，不可用

# ** 实验 2 Step 4 **
	.word   0x07FF
    .word   0x0000
    .word   0x9A00
    .word   0x00C0

    .word   0x07FF
    .word   0x0000
    .word   0x9200
    .word   0x00C0

msg:
    .byte 13, 10
    .ascii "You've successfully loaded the floppy data into RAM."
    .byte 13, 10, 13, 10
