; BIOS boot sector for lesOS (16-bit real mode -> 32-bit protected mode).
; Loads 32 kernel sectors from a 1.44 MB floppy to physical 0x10000.
bits 16
org 0x7C00
start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    mov [drive], dl
    mov ax, 0x1000
    mov es, ax
    xor bx, bx
    mov byte [cylinder], 0
    mov byte [head], 0
    mov byte [sector], 2
    mov byte [sectors_left], 32
.read_sector:
    mov ah, 0x02
    mov al, 1
    mov ch, [cylinder]
    mov cl, [sector]
    mov dh, [head]
    mov dl, [drive]
    push bx
    int 0x13
    pop bx
    jc disk_error
    add bx, 512
    inc byte [sector]
    cmp byte [sector], 19
    jb .next
    mov byte [sector], 1
    inc byte [head]
    cmp byte [head], 2
    jb .next
    mov byte [head], 0
    inc byte [cylinder]
.next:
    dec byte [sectors_left]
    jnz .read_sector
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08:protected_mode

disk_error:
    mov si, error_message
.print:
    lodsb
    test al, al
    jz .halt
    mov ah, 0x0E
    int 0x10
    jmp .print
.halt:
    cli
    hlt
    jmp .halt

bits 32
protected_mode:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000
    jmp 0x08:0x10000

bits 16
drive: db 0
cylinder: db 0
head: db 0
sector: db 0
sectors_left: db 0
error_message: db 'lesOS: kernel read failed', 0
gdt_start:
    dq 0
    dw 0xFFFF, 0x0000
    db 0x00, 0x9A, 0xCF, 0x00
    dw 0xFFFF, 0x0000
    db 0x00, 0x92, 0xCF, 0x00
gdt_end:
gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start
times 510 - ($ - $$) db 0
dw 0xAA55
