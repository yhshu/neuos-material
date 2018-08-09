#################################################################
#                                                               #
#  将操作系统装载到正确的地址，设置GDT, IDT后                   #
#  切换到保护模式                                               #
#                                                               #
#                                                               #
#################################################################

# 以下代码将操作系统完整的装载到内存中 Layout 为:
# 0x9000:0000 bootsect
# 0x9000:0200 setup
# 0x1000:0000 system

	.code16        # 指定语法为 十六位汇编
	.equ SYSSIZE, 0x3000 # 要加载的系统模块长度，单位为节，一节为16字节，0x3000为0x30000字节=196kb

	.global _start # 程序开始处
	.global begtext, begdata, begbss, endtext, enddata, endbss
	.text
	begtext:
	.data
	begdata:
	.bss
	begbss:
	.text

	.equ SETUPLEN, 0x04			# Setup 程序占用的扇区数
	.equ BOOTSEG, 0x07c0		# 当此扇区被BIOS识别为启动扇区装载到内存中时，装载到0x07c0段处
	.equ INITSEG, 0x9000		# 我们的bootsector代码会被移动到这里
	.equ SETUPSEG, 0x9020		# setup.s的代码会被移动到这里(Bootsector 之后的一个扇区)
	.equ SYSSEG, 0x1000		    # system 程序的装载地址
								# 此时我们处于实模式(REAL MODE)中，对内存的寻址方式为
								# (段地址 << 4 + 偏移量) 可以寻址的线性空间为 20 位
	.equ ROOT_DEV, 0x301		# 指定/dev/fda为系统镜像所在的设备的设备号，代表第1个盘的第1个分区具体其他分区的设备号可自行了解
	.equ ENDSEG, SYSSEG + SYSSIZE

	ljmp    $BOOTSEG, $_start   # 修改cs寄存器为BOOTSEG, 并跳转到_start处执行我们的代码

_start:
	mov $BOOTSEG, %ax			# 这里我们将使用rep movsw将启动扇区从0x07c0:0000处移动到0x9000:0000
	mov %ax, %ds				# 该命令用法如下
	mov $INITSEG, %ax			# ds:si中存储源地址
	mov %ax, %es				# es:di中存储目的地址
	mov $256, %cx				# %cx中存储移动次数
	xor %si, %si				# 设置好上述地址及计数器后执行rep movsw便会将ds:si所指向地址中内容复制到es:di指向地址处
	xor %di, %di				# 每次复制后cx自动减1直到为0结束
	rep movsw					# 进行移动


	ljmp $INITSEG, $go			# 长跳转同时切换CS:IP，这里我们会跳转到移动后的地址处继续执行
go:
	mov %cs,%ax				# 对DS, ES, SS寄存器进行初始化
	mov %ax, %ds
	mov %ax, %es			# 设置好 ES 寄存器，为后续输出字符串准备
	mov %ax, %ss
	mov $0xFF00, %sp		# 设置好栈

load_setup:
	# 这里我们需要将软盘中的内容加载到内存中，并且跳转到相应地址执行代码
	mov $0x0000, %dx		# 选择磁盘号0，磁头号0进行读取
	mov $0x0002, %cx		# 从二号扇区，0轨道开始读(注意扇区是从1开始编号的)
	mov $INITSEG, %ax		# ES:BX 指向装载目的地址
	mov %ax, %es
	mov $0x0200, %bx
	mov $02, %ah			# Service 2: Read Disk Sectors
	mov $4, %al				# 读取的扇区数
	int $0x13				# 调用BIOS中断读取
	jnc demo_load_ok		# 没有异常，加载成功
	mov $0x0000, %dx
	mov $0x0000, %ax		# Service 0: Reset the Disk
	int $0x13
	jmp load_setup			# 并一直重试，直到加载成功

demo_load_ok:				# Here will jump to where the demo program is
	mov $0x00, %dl
	mov $0x0800, %ax
	int $0x13
	mov $0x00, %ch
	mov %cx, %cs:sectors+0
	mov $INITSEG, %ax
	mov %ax, %es

# 下面的程序用来显示一行信息
# ** 实验 2 Step 1 **
# 可参考 https://en.wikipedia.org/wiki/INT_10H
print_msg:
	mov	$0x03, %ah
	xor	%bh, %bh
	int	$0x10

	mov	$20, %cx
	mov	$0x0007, %bx
	mov $msg1, %bp
	mov	$0x1301, %ax
	int	$0x10


# 接下来将整个系统镜像装载到0x1000:0000开始的内存中
	mov $SYSSEG, %ax
	mov %ax, %es			# ES 作为参数
	call read_it			# 读取磁盘上的system模块
	call kill_motor			# 关闭磁盘驱动器马达


	mov %cs:root_dev,%ax	# 这里要检查使用哪个根文件系统设备，即如果未定义设备号，则需要通过检测扇区数来确定设备号
	cmp $0, %ax
	jne root_defined		# ROOT_DEV != 0, Defined root
	mov %cs:sectors+0, %bx    # else check for the root dev,
	mov $0x0208, %ax		# 1.2Mb软驱设备号为0x0208
	cmp $15, %bx
	je	root_defined		# Sector = 15, 1.2Mb Floopy Driver
	mov $0x021c, %ax		# 1.44Mb软驱设备号为0x021c
	cmp $18, %bx			# Sector = 18 1.44Mb Floppy Driver
	je root_defined

undef_root:					# If no root found, loop forever
	jmp undef_root

root_defined:

	mov %ax, %cs:root_dev+0

# Now everything loaded into memory, we jump to the setup-routine
# which is now located at 0x9020:0000

	ljmp $SETUPSEG, $0


# Here is the read_it routine and kill_motor routine
# read_it 和 kill_motor 是两个子函数，用来快速读取软盘中的内容，以及关闭软驱
# 电机使用，下面是他们的代码

# 首先定义一些变量， 用于读取软盘信息使用

sread:  .word 1 + SETUPLEN		# 当前轨道读取的扇区数
head:   .word 0					# 当前读头
track:	.word 0					# 当前轨道

# ** 实验 2 Step 2 **
read_it:
	mov %es, %ax
	test $0x0fff, %ax   # AX为0x1000时执行结果为0，ZF为0，jne才不成立
die:
	jne die				# ES值必须位于64KB边界地址
	xor %bx, %bx
rp_read:
	mov %es, %ax
	cmp $ENDSEG, %ax    # 检测是否已经加载全部数据
	jb ok1_read			# If $ENDSEG > %ES, then continue reading, else just return
	ret
ok1_read:
	mov %cs:sectors+0, %ax	# 取每个磁道的扇区数
	sub sread, %ax
	mov %ax, %cx		# cx为当前磁道未读的扇区数
	shl $9, %cx			# cx = cx * 512B + 段内当前的偏移
	add %bx, %cx		# cx中的值也是当前一共读入的字节数
	jnc ok2_read		# If not bigger than 64K, continue to ok_2
	je ok2_read
	xor %ax, %ax
	sub %bx, %ax		# 超过则计算此时最多能读的字节数
	shr $9, %ax
ok2_read:
	call read_track		# 调用read_track读取当前磁道上需要读取的数据
	mov %ax, %cx		# cx = 本次操作读取的扇区数
	add sread, %ax
	cmp %cs:sectors+0, %ax	# 当前磁道是否读完，未读完则跳转ok3_read
	jne ok3_read
	mov $1, %ax
	sub head, %ax		# 判断磁头号
	jne ok4_read		# 磁头号为0，接着读1磁头
	incw track			# 磁头号为1，读下一磁道
ok4_read:
	mov %ax, head		# 保存当前磁头号
	xor %ax, %ax        # 清除已读扇区数
ok3_read:
	mov %ax, sread      # 保存已读扇区数
	shl $9, %cx
	add %cx, %bx		# 调整数据读取开始位置
	jnc rp_read			# If shorter than 64KB, then read the data again, else, adjust ES to next 64KB segment, then read again
	mov %es, %ax
	add $0x1000, %ax
	mov %ax, %es		# Change the Segment to next 64KB
	xor %bx, %bx
	jmp rp_read

# Comment for routine 0x13 service 2
# AH = 02
# AL = number of sectors to read	(1-128 dec.)
# CH = track/cylinder number  (0-1023 dec., see below)
# CL = sector number  (1-17 dec.)
# DH = head number  (0-15 dec.)
# DL = drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)
# ES:BX = pointer to buffer

read_track:				# This routine do the actual read
	push %ax			# 调用INT 0x13,2中断读盘，详见(http://stanislavs.org/helppc/int_13-2.html)
	push %bx
	push %cx
	push %dx
	mov track, %dx		# Set the track number $track, disk number 0
	mov sread, %cx
	inc %cx
	mov %dl, %ch
	mov head, %dx
	mov %dl, %dh
	mov $0, %dl
	and $0x0100, %dx
	mov $2, %ah
	int $0x13
	jc bad_rt
	pop %dx
	pop %cx
	pop %bx
	pop %ax
	ret

bad_rt:					# 读盘出错，则执行int 0x13,0中断复位磁盘驱动器
	mov $0, %ax
	mov $0, %dx
	int $0x13
	pop %dx
	pop %cx
	pop %bx
	pop %ax
	jmp read_track

kill_motor:				# 向端口输出信息关闭马达
	push %dx
	mov $0x3f2, %dx
	mov $0, %al
	outsb
	pop %dx
	ret

sectors:
	.word 0

msg1:
	.byte 13,10
	.ascii "Hello NEU-OS!!"
	.byte 13,10,13,10

	.= 508  	# 这里是对齐语法 等价于 .org 表示在该处补零，一直补到 地址为 510 的地方 (即第一扇区的最后两字节)
				# 然后在这里填充好0xaa55魔术值，BIOS会识别硬盘中第一扇区以0xaa55结尾的为启动扇区，于是BIOS会装载
				# 代码并且运行

root_dev:
	.word ROOT_DEV
boot_flag:
	.word 0xAA55

.text
	endtext:
.data
	enddata:
.bss
	endbss:
