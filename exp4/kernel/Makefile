AS=as --32
CC=gcc
LD=ld -m elf_i386
OBJCOPY=objcopy
QEMU=qemu-system-i386
BOCHS=bochs
STRIP=strip
_ALLWARN=-Wall -Wextra -Waddress -Wconversion
CFLAGS=-g -m32 -fno-builtin -fno-stack-protector -fomit-frame-pointer -fstrength-reduce $(_ALLWARN)

OBJS = printk.o main.o panic.o

LDFLAGS	+= -r
CFLAGS += -I../include

.PHONY=clean run all

all: kernel.o

kernel.o: $(OBJS)
	$(LD) $(LDFLAGS) -o kernel.o $(OBJS)

.c.o: 
	@$(CC) $(CFLAGS) \
		-c -o $*.o $<

clean:
	rm -f $(OBJS) kernel.o
