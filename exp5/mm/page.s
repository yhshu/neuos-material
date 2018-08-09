# page.s 程序包含底层页异常处理代码

.code32

.global page_fault

page_fault:
						# 将错误码存入eax中，并将eax压栈。错误码存在堆栈顶端，即(%esp)中
						# 这里可以使用xchgl命令直接交换eax与堆栈
	pushl %ecx
	pushl %edx
	push %ds
	push %es
	push %fs
	movl $0x10, %edx	# 置内核数据段选择符
	mov %dx, %ds
	mov %dx, %es
	mov %dx, %fs
						# 取CR2中内容到edx，即引起异常的线性地址
						# 将eax，edx中内容(错误码和线性地址)压栈作为调用函数的参数
						# 这里需要注意压栈顺序
						# 测试错误码存在标志位P(位0)
						# 如果不是，则跳转执行do_wp_page函数
						# 如果是，则执行do_no_page函数，执行后跳转到2处
	jmp 2f

2:	addl $8, %esp		# 丢弃压栈的2个参数，弹出栈中寄存器
	pop %fs
	pop %es
	pop %ds
	popl %edx
	popl %ecx
	popl %eax
	iret
