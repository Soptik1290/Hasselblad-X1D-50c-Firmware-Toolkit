#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <linux/futex.h>
#include <sys/syscall.h>

struct xshmfence {
    int v;
};

int xshmfence_trigger(struct xshmfence *f) {
    if (!f) return -1;
    __sync_val_compare_and_swap(&f->v, 0, 1);
    syscall(SYS_futex, &f->v, FUTEX_WAKE, 0x7fffffff, 0, 0, 0);
    return 0;
}

int xshmfence_await(struct xshmfence *f) {
    if (!f) return -1;
    while (!f->v) {
        syscall(SYS_futex, &f->v, FUTEX_WAIT, 0, 0, 0, 0);
    }
    return 0;
}

int xshmfence_query(struct xshmfence *f) {
    return f ? f->v : 0;
}

void xshmfence_reset(struct xshmfence *f) {
    if (f) f->v = 0;
}

int xshmfence_alloc_shm(void) {
    int fd = syscall(385, "xshmfence", 1);
    if (fd < 0) {
        char tmppath[] = "/tmp/shmfence-XXXXXX";
        fd = mkstemp(tmppath);
        if (fd >= 0) unlink(tmppath);
    }
    if (fd >= 0) {
        if (ftruncate(fd, sizeof(struct xshmfence)) < 0) {}
    }
    return fd;
}

struct xshmfence *xshmfence_map_shm(int fd) {
    return (struct xshmfence *)mmap(NULL, sizeof(struct xshmfence), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
}

void xshmfence_unmap_shm(struct xshmfence *f) {
    if (f) munmap(f, sizeof(struct xshmfence));
}
