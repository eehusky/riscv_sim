#include <sys/types.h>          //Needed for caddr_t
#include <sys/reent.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stddef.h>


char *heap_end = 0;

void* _sbrk_r(struct _reent *r, ptrdiff_t incr)
{
    extern unsigned long _heap_bottom;
    extern unsigned long _heap_top;
    static char *prev_heap_end;

    if (heap_end == 0) {
        heap_end = (caddr_t)&_heap_bottom;
    }

    prev_heap_end = heap_end;

    if (heap_end + incr > (caddr_t)&_heap_top) {
        return (caddr_t)0;
    }

    heap_end += incr;

    return (caddr_t) prev_heap_end;
}

int _close_r(struct _reent *r, int file)
{
    return -1;
}

int _fstat_r(struct _reent *r, int file, struct stat *)
{
    return -1;
}

int _isatty_r(struct _reent *r, int file)
{
    return -1;
}

_off_t _lseek_r(struct _reent *r, int file, _off_t ptr, int dir)
{
    return -1;
}

int _open_r(struct _reent *r, const char *name, int flags, int mode)
{
    return -1;
}

int _read_r(struct _reent *r, int file, void *ptr, size_t len)
{
    return -1;
}


#define CSR_SIM_CTRL_EXIT (0 << 24)
#define CSR_SIM_CTRL_PUTC (1 << 24)

static inline void sim_exit(int exitcode)
{
    unsigned int arg = CSR_SIM_CTRL_EXIT | ((unsigned char)exitcode);
    asm volatile ("csrw dscratch,%0": : "r" (arg));
}

static inline void sim_putc(int ch)
{
    unsigned int arg = CSR_SIM_CTRL_PUTC | (ch & 0xFF);
    asm volatile ("csrw dscratch,%0": : "r" (arg));
}


//int _write_r(int file, char *ptr, unsigned int len)
ssize_t _write_r(struct _reent *r, int fd, const void *ptr, size_t len)
{
    unsigned int i;
    for(i = 0; i < len; i++){
        sim_putc(((char *)ptr)[i]);
    }
    return i;
}
