#include "lv2/core/lv2.h"

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define MY_PLUGIN_URI "http://6510.nu/plugins/bitcrusher"

typedef enum {
PORT_GAIN,
PORT_DEPTH,
PORT_INPUT,
PORT_OUTPUT,
} PortIndex;

typedef struct {
    const float* gain;
    const float* depth;
    const float* input;
    float* output;
} MyPlugin;

static LV2_Handle
instantiate(const LV2_Descriptor* descriptor,
            double rate,
            const char* bundle_path,
            const LV2_Feature* const* features) {
   MyPlugin* self = (MyPlugin*)calloc(1, sizeof(MyPlugin));
    return (LV2_Handle)self;
}

static void
connect_port(LV2_Handle instance,
             uint32_t port,
             void* data) {
    MyPlugin* self = (MyPlugin*)instance;
    switch ((PortIndex)port) {
        case PORT_GAIN:
            self->gain = (const float*)data;
            break;
        case PORT_DEPTH:
            self->depth = (const float*)data;
            break;
        case PORT_INPUT:
            self->input = (const float*)data;
            break;
        case PORT_OUTPUT:
            self->output = (float*)data;
            break;
    }
}

static void
activate(LV2_Handle instance) {
}

// Convert gain in dB to a coefficient
#define DB_CO(g) ((g) > -90.0f ? powf(10.0f, (g) * 0.05f) : 0.0f)

static void
run(LV2_Handle instance, uint32_t n_samples) {
    const MyPlugin* self = (const MyPlugin*)instance;
    const float gain = *(self->gain);
    const float depth = *(self->depth);
    const float* const input = self->input;
    float* const output = self->output;
    const float coef = DB_CO(gain);
    int32_t idepth = (int32_t)depth;
    idepth = idepth < 0 ? 0 : (idepth > 32 ? 32 : idepth);

    for (uint32_t pos = 0; pos < n_samples; ++pos) {
        // transpose input [-1, 1] to [0, 1]
        double val = ((double)input[pos] + 1.0) * 0.5;
        // transpose to [0, 1<<depth]
        val = val * (double)(1 << idepth);
        // crush
        val = round(val);
        // transpose back to [0, 1]
        val = val / (double)(1 << idepth);
        // transpose back to [-1, 1]
        val = (val * 2.0) - 1.0;
        // amplify by multiplying with coef
        float fval = (float)val * coef;
        // hard clamp to [-1, 1]
        if (fval < -1.0)
            fval = -1.0;
        else if (fval > 1.0)
            fval = 1.0;
        output[pos] = fval;
    }
}

static void
deactivate(LV2_Handle instance) {
}

static void
cleanup(LV2_Handle instance) {
    free(instance);
}

static const void*
extension_data(const char* uri) {
        return NULL;
}

static const LV2_Descriptor descriptor = {
        MY_PLUGIN_URI,
        instantiate,
        connect_port,
        activate,
        run,
        deactivate,
        cleanup,
        extension_data
};

LV2_SYMBOL_EXPORT
const LV2_Descriptor*
lv2_descriptor(uint32_t index)
{
        switch (index) {
        case 0:  return &descriptor;
        default: return NULL;
        }
}
