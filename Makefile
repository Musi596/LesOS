NASM ?= nasm
CXX ?= g++
LD ?= ld
CXXFLAGS = -m32 -std=c++17 -O2 -ffreestanding -fno-exceptions -fno-rtti \
	-fno-stack-protector -fno-pie -fno-pic -fno-use-cxa-atexit \
	-fno-asynchronous-unwind-tables -fno-unwind-tables
.PHONY: all run clean
all: lesos.img
boot.bin: boot.asm
	$(NASM) -f bin $< -o $@
kernel.o: kernel.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@
kernel.bin: kernel.o kernel.ld
	$(LD) -m elf_i386 -T kernel.ld -nostdlib --oformat binary $< -o $@
	@test "$$(wc -c < $@)" -le 16384 || (echo 'Kernel exceeds 16 KiB boot limit'; rm -f $@; exit 1)
lesos.img: boot.bin kernel.bin
	dd if=/dev/zero of=$@ bs=512 count=2880 status=none
	dd if=boot.bin of=$@ conv=notrunc status=none
	dd if=kernel.bin of=$@ bs=512 seek=1 conv=notrunc status=none
run: lesos.img
	qemu-system-i386 -boot order=a -display gtk -vga std -serial null -monitor none \
		-drive format=raw,file=lesos.img,if=floppy
clean:
	rm -f boot.bin kernel.o kernel.bin lesos.img
