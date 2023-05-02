//!HOOK MAIN
//!BIND HOOKED
//!SAVE PASS1
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * >
//!DESC alt upscale pass1

////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 1 (sigmoidize)
//
// CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 3" below
//
//sigmoidal curve
#define C 6.5 //contrast, equivalent to mpv's --sigmoid-slope
#define M 0.75 //midpoint, equivalent to mpv's --sigmoid-center
//
////////////////////////////////////////////////////////////////////////

//based on https://github.com/ImageMagick/ImageMagick/blob/main/MagickCore/enhance.c
#define sigmoidize(rgba) (M - log(1.0 / ((1.0 / (1.0 + exp(C * (M - 1.0))) - 1.0 / (1.0 + exp(C * M))) * rgba + 1.0 / (1.0 + exp(C * M))) - 1.0) / C)

vec4 hook() {
    return sigmoidize(clamp(linearize(textureLod(HOOKED_raw, HOOKED_pos, 0.0) * HOOKED_mul), 0.0, 1.0));
}

//!HOOK MAIN
//!BIND PASS1
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * >
//!DESC alt upscale pass2

////////////////////////////////////////////////////////////////////////
// KERNEL FILTERS LIST
//
#define GINSENG 1
#define GARAMOND 2
#define COSINE 3
#define BLACKMAN 4
#define GNW 5
#define SAID 6
//
////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 2 (upsample in y axis)
//
// CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 3" below
//
#define K GINSENG //kernel filter, see "KERNEL FILTERS LIST"
#define R 2.0 //kernel radius, (0.0, 10.0+]
#define B 1.0 //kernel blur, 1.0 means no effect, (0.0, 1.5+]
#define AR 1.0 //antiringing strenght, [0.0, 1.0]
//
//kernel parameters
#define P1 0.0 //BLACKMAN: a, GNW: s, SAID: chi, BCSPLINE: B, BICUBIC: alpha
#define P2 0.0 //GNW: n, SAID: eta, BCSPLINE: C
//
// CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 1" above
//
#define C 6.5 //contrast, equivalent to mpv's --sigmoid-slope
#define M 0.75 //midpoint, equivalent to mpv's --sigmoid-center
//
////////////////////////////////////////////////////////////////////////

#define M_PI 3.14159265358979323846
#define M_PI_2 1.57079632679489661923
#define M_PI_4 0.785398163397448309616
#define EPSILON 1.192093e-7

#define J1(x) (x < 2.1416671258565 ? (x / 2.0) - (x * x * x / 16.0) + (x * x * x * x * x / 384.0) - (x * x * x * x * x * x * x / 16384.0) : sqrt(2.0 / (M_PI * x)) * (1.0 + 3.0 / (16.0 * x * x) - 99.0 / (512.0 * x * x * x * x)) * cos(x - 3.0 * M_PI_4 + 3.0 / (8.0 * x) - 21.0 / (128.0 * x * x * x)))

#define jinc(x) (x < EPSILON ? M_PI_2 : J1(M_PI / B * x) * B / x)

#if K == GINSENG
    #define k(x) (jinc(x) * (x < EPSILON ? M_PI : sin(M_PI / R * x) * R / x))
#elif K == GARAMOND
    #define k(x) (jinc(x) * (1.0 - pow(x / R, P1)))
#elif K == COSINE
    #define k(x) (jinc(x) * pow(cos(M_PI_2 / R * x), P1))
#elif K == BLACKMAN
    #define k(x) (jinc(x) * ((1.0 - P1) / 2.0 + 0.5 * cos(M_PI / R * x) + P1 / 2.0 * cos(2.0 * M_PI / R * x)))
#elif K == GNW
    #define k(x) (jinc(x) * exp(-pow(x / P1, P2)))
#elif K == SAID
    #define k(x) (jinc(x) * cosh(sqrt(2.0 * P2) * M_PI * P1 / (2.0 - P2) * x) * exp(-M_PI * M_PI * P1 * P1 / ((2.0 - P2) * (2.0 - P2)) * x * x))
#endif

#define get_weight(x) (x < R ? k(x) : 0.0)

//based on https://github.com/ImageMagick/ImageMagick/blob/main/MagickCore/enhance.c
#define desigmoidize(rgba) (1.0 / (1.0 + exp(C * (M - rgba))) - 1.0 / (1.0 + exp(C * M))) / ( 1.0 / (1.0 + exp(C * (M - 1.0))) - 1.0 / (1.0 + exp(C * M)))

vec4 hook() {
    vec2 fcoord = fract(PASS1_pos * input_size - 0.5);
    vec2 base = PASS1_pos - fcoord * PASS1_pt;
    vec4 color;
    float weight;
    vec4 csum = vec4(0.0);
    float wsum = 0.0;
    vec4 low = vec4(1e9);
    vec4 high = vec4(-1e9);
    for (float y = 1.0 - ceil(R); y <= ceil(R); ++y) {
        for (float x = 1.0 - ceil(R); x <= ceil(R); ++x) {
            weight = get_weight(length(vec2(x, y) - fcoord));
            color = textureLod(PASS1_raw, base + PASS1_pt * vec2(x, y), 0.0) * PASS1_mul;
            csum += color * weight;
            wsum += weight;
            if (AR > 0.0 && y >= 0.0 && x >= 0.0 && y <= 1.0 && x <= 1.0) {
                low = min(low, color);
                high = max(high, color);
            }
        }
    }
    csum /= wsum;
    if (AR > 0.0)
        csum = mix(csum, clamp(csum, low, high), AR);
    return delinearize(desigmoidize(csum));
}