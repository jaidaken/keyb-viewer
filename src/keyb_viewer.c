#include <zmk/event_manager.h>
#include <zmk/events/layer_state_changed.h>
#include <zmk/events/position_state_changed.h>
#include <zmk/keymap.h>

#include <raw_hid/events.h>

#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <zephyr/sys/util.h>
#include <zephyr/sys/byteorder.h>

#define KV_REPORT_LAYER 0x01
#define KV_REPORT_KEY 0x02
#define KV_MAX_LAYERS 32

static uint8_t hid_buf[CONFIG_NICE_OLED_WIDGET_RAW_HID_REPORT_SIZE];

static void kv_send_layer_state(void) {
    uint32_t active = 0;
    uint8_t highest = 0;
    for (uint8_t i = 0; i < KV_MAX_LAYERS; i++) {
        if (zmk_keymap_layer_active(i)) {
            active |= BIT(i);
            highest = i;
        }
    }

    memset(hid_buf, 0, sizeof(hid_buf));
    hid_buf[0] = KV_REPORT_LAYER;
    sys_put_le32(active, &hid_buf[1]);
    hid_buf[5] = highest;
    raise_raw_hid_sent_event((struct raw_hid_sent_event){.data = hid_buf, .length = sizeof(hid_buf)});
}

static void kv_send_key(uint32_t position, bool pressed) {
    if (position > UINT8_MAX) {
        return;
    }

    memset(hid_buf, 0, sizeof(hid_buf));
    hid_buf[0] = KV_REPORT_KEY;
    hid_buf[1] = (uint8_t)position;
    hid_buf[2] = pressed ? 1 : 0;
    raise_raw_hid_sent_event((struct raw_hid_sent_event){.data = hid_buf, .length = sizeof(hid_buf)});
}

static int kv_layer_listener(const zmk_event_t *eh) {
    ARG_UNUSED(eh);
    kv_send_layer_state();
    return ZMK_EV_EVENT_BUBBLE;
}

static int kv_key_listener(const zmk_event_t *eh) {
    const struct zmk_position_state_changed *ev = as_zmk_position_state_changed(eh);
    if (ev == NULL) {
        return ZMK_EV_EVENT_BUBBLE;
    }
    kv_send_key(ev->position, ev->state);
    return ZMK_EV_EVENT_BUBBLE;
}

ZMK_LISTENER(kv_layer, kv_layer_listener);
ZMK_SUBSCRIPTION(kv_layer, zmk_layer_state_changed);

ZMK_LISTENER(kv_key, kv_key_listener);
ZMK_SUBSCRIPTION(kv_key, zmk_position_state_changed);
