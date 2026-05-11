#include "prj_nanoprintf.h"

// Compile nanoprintf in this translation unit.
#define NANOPRINTF_IMPLEMENTATION
#include "nanoprintf.h"

#include "sim_extensions.h"

int your_project_snprintf_(char *buffer, size_t bufsz, char const *fmt, ...) {
    va_list val;
    va_start(val, fmt);
    // npf_vsnprintf works here because float args in the va_list are already
    // wrapped in npf_float_t by the NPF_MAP_ARGS macro at the call site.
    int const rv = npf_vsnprintf(buffer, bufsz, fmt, val);
    va_end(val);
    return rv;
}

int prjprintf_(char const *fmt, ...) {
    char buffer[64];
    va_list val;
    va_start(val, fmt);
    // npf_vsnprintf works here because float args in the va_list are already
    // wrapped in npf_float_t by the NPF_MAP_ARGS macro at the call site.
    int const rv = npf_vsnprintf(buffer, sizeof(buffer), fmt, val);
    va_end(val);

    sim_putstring(buffer);

    return rv;
}
