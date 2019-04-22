#include <mach/mach_time.h>
#include "arch/sys_arch.h"
#include "lwip/sys.h"

u32_t sys_now(void) {
    uint64_t now = mach_absolute_time();
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    now = now * info.numer / info.denom / NSEC_PER_MSEC;
    
    return (u32_t)(now);
}

void
sys_init(void)
{
}