#include <furi.h>

int32_t hello_app(void* p) {
    UNUSED(p);
    FURI_LOG_I("ExampleHello", "Hello from Flipper Zero!");
    return 0;
}
