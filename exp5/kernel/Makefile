include ../Makefile.header

OBJS = printk.o panic.o traps.o asm.o serial.o

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
