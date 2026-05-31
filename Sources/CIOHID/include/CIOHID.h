#ifndef CIOHID_H
#define CIOHID_H

#include <CoreFoundation/CoreFoundation.h>
#include <stdint.h>

// Private IOKit / IOHIDFamily declarations used to read Apple Silicon
// thermal (and related) sensors without elevated privileges. These symbols
// live inside IOKit.framework but are not exposed in any public header.
// This is the same mechanism used by tools such as Stats and btop.

typedef struct __IOHIDEventSystemClient *IOHIDEventSystemClientRef;
typedef struct __IOHIDServiceClient    *IOHIDServiceClientRef;
typedef struct __IOHIDEvent            *IOHIDEventRef;

IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
void  IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef matching);
CFArrayRef IOHIDEventSystemClientCopyServices(IOHIDEventSystemClientRef client);

CFTypeRef    IOHIDServiceClientCopyProperty(IOHIDServiceClientRef service, CFStringRef key);
IOHIDEventRef IOHIDServiceClientCopyEvent(IOHIDServiceClientRef service,
                                          int64_t type,
                                          int32_t options,
                                          int64_t timestamp);

double IOHIDEventGetFloatValue(IOHIDEventRef event, int32_t field);

// kIOHIDEventTypeTemperature == 15. The field passed to IOHIDEventGetFloatValue
// is IOHIDEventFieldBase(type) == (type << 16).
#define CIOHID_EVENT_TYPE_TEMPERATURE 15
#define CIOHID_EVENT_FIELD_TEMPERATURE (CIOHID_EVENT_TYPE_TEMPERATURE << 16)

// Apple HID vendor usage page / usage used to match on-die temperature sensors.
#define CIOHID_PAGE_APPLE_VENDOR 0xff00
#define CIOHID_USAGE_TEMPERATURE 0x0005

#endif /* CIOHID_H */
