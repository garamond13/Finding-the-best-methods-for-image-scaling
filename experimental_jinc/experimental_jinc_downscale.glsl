//!HOOK MAIN
//!BIND HOOKED
//!SAVE PASS1
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * <
//!DESC alt downscale pass1

vec4 hook() {
    return linearize(textureLod(HOOKED_raw, HOOKED_pos, 0.0) * HOOKED_mul);
}

//!HOOK MAIN
//!BIND HOOKED
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * = !
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!DESC interpolation_based_image_scaling

#define GINSENG 1
#define COSINE 2
#define BLACKMAN 5
#define GARAMOND 6
#define GNW 7 //generalized normal window
#define SAID 8
#define BCSPLINE 9
#define FSR 10
#define BICUBIC 11

#define K GINSENG
#define R 2.9 //kernel radius
#define B 1.0 //blures or sharpens the kernel, 1.0 is no effect

#define P1 0.2
#define P2 0.5

#define M_PI 3.14159265358979323846
#define M_PI_2 1.57079632679489661923
#define M_PI_4 0.785398163397448309616

#define EPSILON 1.192093e-7

#define J1(x) (x < 2.1416671258565 ? (x / 2.0) - (x * x * x / 16.0) + (x * x * x * x * x / 384.0) - (x * x * x * x * x * x * x / 16384.0) : sqrt(2.0 / (M_PI * x)) * (1.0 + 3.0 / (16.0 * x * x) - 99.0 / (512.0 * x * x * x * x)) * cos(x - 3.0 * M_PI_4 + 3.0 / (8.0 * x) - 21.0 / (128.0 * x * x * x)))

#define jinc(x) (x < EPSILON ? M_PI_2 : J1(M_PI / B * x) * B / x)

#if K == GINSENG
    #define k(x) (jinc(x) * (x < EPSILON ? M_PI : sin(M_PI / R * x) * R / x))
#elif K == COSINE
    #define k(x) (jinc(x) * pow(cos(M_PI_2 / R * x), 0.4))
#elif K == GARAMOND
    #define k(x) (jinc(x) * (1.0 - pow(x / R, 3.8)))
#elif K == BLACKMAN
    #define k(x) (jinc(x) * ((1.0 - P1) / 2.0 + 0.5 * cos(M_PI / R * x) + P1 / 2.0 * cos(2.0 * M_PI / R * x)))
#elif K == GNW
    #define k(x) (jinc(x) * exp(-pow(x / P1, P2)))
#elif K == SAID
    #define k(x) (jinc(x) * cosh(sqrt(2.0 * P2) * M_PI * P1 / (2.0 - P2) * x) * exp(-M_PI * M_PI * P1 * P1 / ((2.0 - P2) * (2.0 - P2)) * x * x))
#elif K == FSR
    #undef R
    #define R 2.0
    #define k(x) ((1.0 / (2.0 * P1 - P1 * P1) * (P1 / (P2 * P2) * x * x - 1.0) * (P1 / (P2 * P2) * x * x - 1.0) - (1.0 / (2.0 * P1 - P1 * P1) - 1.0)) * (0.25 * x * x - 1.0) * (0.25 * x * x - 1.0))
#elif K == BCSPLINE
    #undef R
    #define R 2.0
    #define k(x) (x < 1.0 ? (12.0 - 9.0 * P1 - 6.0 * P2) * x * x * x + (-18.0 + 12.0 * P1 + 6.0 * P2) * x * x + (6.0 - 2.0 * P1) : (-P1 - 6.0 * P2) * x * x * x + (6.0 * P1 + 30.0 * P2) * x * x + (-12.0 * P1 - 48.0 * P2) * x + (8.0 * P1 + 24.0 * P2))
#elif K == BICUBIC
    #undef R
    #define R 2.0
    #define k(x) (x < 1.0 ? (P1 + 2.0) * x * x * x - (P1 + 3.0) * x * x + 1.0 : P1 * x * x * x - 5.0 * P1 * x * x + 8.0 * P1 * x - 4.0 * P1)
#endif

#define get_weight(x) (x < R ? k(x) : 0.0)

#define SCALE (max(input_size.y / target_size.y, input_size.x / target_size.x))

//main algorithm
vec4 hook()
{
    vec2 fcoord = fract(PASS1_pos * input_size - 0.5);
    vec2 base = PASS1_pos - fcoord * PASS1_pt;
    vec4 color;
    vec4 csum = vec4(0.0);
    float weight;
    float wsum = 0.0;
    for (float y = 1.0 - ceil(R * SCALE); y <= ceil(R * SCALE); ++y) {
        for (float x = 1.0 - ceil(R * SCALE); x <= ceil(R * SCALE); ++x) {
            weight = get_weight(length(vec2(x, y) - fcoord) / SCALE);
            color = textureLod(PASS1_raw, base + PASS1_pt * vec2(x, y), 0.0) * PASS1_mul;
            csum += color * weight;
            wsum += weight;
        }
    }
    csum /= wsum;
    return delinearize(csum);
}