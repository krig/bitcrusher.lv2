#include "lv2/lv2plug.in/ns/lv2core/lv2.h"

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define MY_PLUGIN_URI "http://6510.nu/plugins/bitcrusher"

typedef enum {
PORT_GAIN,
PORT_DEPTH,
PORT_SAMPLERATE,
PORT_INPUT,
PORT_OUTPUT,
} PortIndex;

typedef struct {
    const float* gain;
    const float* depth;
    const float* samplerate;
    const float* input;
    float* output;
    int sample_counter;
    float last_sample;
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
        case PORT_SAMPLERATE:
            self->samplerate = (const float*)data;
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
    MyPlugin* self = (MyPlugin*)instance;
    self->sample_counter = 0;
    self->last_sample = 0.f;
}

// Convert gain in dB to a coefficient
#define DB_CO(g) ((g) > -90.0f ? powf(10.0f, (g) * 0.05f) : 0.0f)

static float
crush(float sample, uint32_t depth) {
    // transpose input [-1, 1] to [0, 1]
    double val = ((double)sample + 1.0) * 0.5;
    // transpose to [0, 1<<depth]
    val = val * (double)(((uint64_t)1 << depth) - 1);
    // crush
    val = floor(val + 0.5);
    // transpose back to [0, 1]
    val = val / (double)(((uint64_t)1 << depth) - 1);
    // transpose back to [-1, 1]
    return (float)(val * 2.0) - 1.0;
}

static int
samplerate_hold(const float samplerate_hold_index) {
    switch ((const int)samplerate_hold_index) {
        case 0: return 0;
        case 1: return 1;
        case 2: return 3;
        case 3: return 7;
        default: return 0;
    }
}

static void
run(LV2_Handle instance, uint32_t n_samples) {
    MyPlugin* self = (MyPlugin*)instance;
    const float gain = *(self->gain);
    const float depth = *(self->depth);
    const float* const input = self->input;
    float* const output = self->output;
    const float coef = DB_CO(gain);
    uint32_t idepth = (uint32_t)depth;
    idepth = idepth < 1 ? 1 : (idepth > 24 ? 24 : idepth);
    const int hold = samplerate_hold(*(self->samplerate));

    for (uint32_t pos = 0; pos < n_samples; ++pos) {
        // reduce sample rate
        float inval = input[pos];
        if (self->sample_counter == 0) {
            self->sample_counter++;
        } else if (self->sample_counter > hold)  {
            self->sample_counter = 0;
        } else {
            inval = self->last_sample;
            self->sample_counter++;
        }

        float gval = inval * coef;
        // gain and clamp
        gval = gval > 1.f ? 1.f : (gval < -1.f ? -1.f : gval);
        float outval = 0.f;

        // crush bits
        if (idepth < 24) {
            float lo = crush(gval, idepth);
            float hi = crush(gval, idepth + 1);
            float delta = depth - (float)idepth;
            outval = lo + ((hi - lo) * 0.5f) * delta;
        } else {
            outval = crush(gval, idepth);
        }
        self->last_sample = inval;
        output[pos] = outval;
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
