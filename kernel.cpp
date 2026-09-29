static inline void outb(unsigned short port, unsigned char value) {
    asm volatile("outb %0, %1" : : "a"(value), "Nd"(port));
}

static inline unsigned char inb(unsigned short port) {
    unsigned char value;
    asm volatile("inb %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

static void serial_init() {
    outb(0x3F9, 0x00);
    outb(0x3FB, 0x80);
    outb(0x3F8, 0x01);
    outb(0x3F9, 0x00);
    outb(0x3FB, 0x03);
    outb(0x3FA, 0xC7);
    outb(0x3FC, 0x0B);
}

static void serial_write(char value) {
    while ((inb(0x3FD) & 0x20) == 0) {}
    outb(0x3F8, static_cast<unsigned char>(value));
}

static volatile unsigned short* const video =
    reinterpret_cast<volatile unsigned short*>(0xB8000);
static unsigned int cursor = 0;
static unsigned int line_start = 0;

static void put_char(char c) {
    if (c == '\n') {
        cursor = (cursor / 80 + 1) * 80;
    } else if (c == '\b') {
        if (cursor > line_start) {
            video[--cursor] = 0x0F20;
        }
    } else {
        video[cursor++] = 0x0F00 | static_cast<unsigned char>(c);
    }

    if (cursor >= 80 * 25) {
        for (unsigned int i = 0; i < 80 * 25; ++i) video[i] = 0x0F20;
        cursor = 0;
    }
}

static void prompt() {
    const char* text = "lesOS> ";
    for (unsigned int i = 0; text[i]; ++i) put_char(text[i]);
    line_start = cursor;
}

static char key_to_ascii(unsigned char code) {
    static const char keys[] = {
        0, 0, '1','2','3','4','5','6','7','8','9','0','-','=', '\b','\t',
        'q','w','e','r','t','y','u','i','o','p','[',']','\n',0,
        'a','s','d','f','g','h','j','k','l',';','\'', '`',0,'\\',
        'z','x','c','v','b','n','m',',','.','/',0,0,0,' '
    };
    return code < sizeof(keys) ? keys[code] : 0;
}

extern "C" [[noreturn]] void _start() {
    serial_init();
    for (unsigned int i = 0; i < 80 * 25; ++i) video[i] = 0x0F20;
    prompt();

    for (;;) {
        if ((inb(0x64) & 1) == 0) continue;
        unsigned char code = inb(0x60);
        if (code & 0x80) continue;

        char c = key_to_ascii(code);
        if (!c) continue;
        if (c == '\n') {
            put_char(c);
            serial_write('\r');
            serial_write('\n');
            prompt();
        } else if (c == '\b') {
            put_char(c);
        } else {
            put_char(c);
            serial_write(c);
        }
    }
}
