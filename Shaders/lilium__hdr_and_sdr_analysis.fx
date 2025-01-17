#include "lilium__include/colour_space.fxh"


#if defined(IS_HDR_COMPATIBLE_API)

#undef TEXT_BRIGHTNESS

#if (defined(API_IS_VULKAN) \
  && (BUFFER_WIDTH > 1280   \
   || BUFFER_HEIGHT > 800))
  #warning "If you are on the Steam Deck and want to use this shader, you need to switch to a resolution that is 1280x800 or lower!"
  #warning "The Steam Deck also has my HDR analysis shaders built in. They are available throught developer options."
#endif

#ifndef GAMESCOPE
  //#define _DEBUG
  //#define _TESTY
#endif

#if (BUFFER_WIDTH  >= 2560) \
 && (BUFFER_HEIGHT >= 1440)
  #define IS_QHD_OR_HIGHER_RES
#endif


#define DEFAULT_BRIGHTNESS 80.f

#define DEFAULT_ALPHA_LEVEL 75.f

uniform int2 MOUSE_POSITION
<
  source = "mousepoint";
>;

uniform float2 NIT_PINGPONG0
<
  source    = "pingpong";
  min       = 0.f;
  max       = 2.f;
  step      = 1.f;
  smoothing = 0.f;
>;

uniform float2 NIT_PINGPONG1
<
  source    = "pingpong";
  min       =  0.f;
  max       =  3.f;
  step      =  1.f;
  smoothing =  0.f;
>;

uniform float2 NIT_PINGPONG2
<
  source    = "pingpong";
  min       = 0.f;
  max       = 1.f;
  step      = 3.f;
  smoothing = 0.f;
>;

#if ((defined(GAMESCOPE) || defined(POSSIBLE_DECK_VULKAN_USAGE)) \
  && BUFFER_HEIGHT <= 800)
  static const uint TEXT_SIZE_DEFAULT = 0;
#else
  // 2160 height gives 42
  //  800 height gives 16
  //  720 height gives 14
  static const uint TEXT_SIZE_DEFAULT = (uint((BUFFER_HEIGHT / 2160.f) * 42.f + 0.5f) - 12) / 2;
#endif


#ifndef IS_HDR_CSP
  #define _TEXT_SIZE                              SDR_TEXT_SIZE
  #define _TEXT_BRIGHTNESS                        SDR_TEXT_BRIGHTNESS
  #define _TEXT_BG_ALPHA                          SDR_TEXT_BG_ALPHA
  #define _TEXT_POSITION                          SDR_TEXT_POSITION
  #define _ACTIVE_AREA_ENABLE                     SDR_ACTIVE_AREA_ENABLE
  #define _TACTIVE_AREA_CROP_LEFT                 SDR_ACTIVE_AREA_CROP_LEFT
  #define _ACTIVE_AREA_CROP_TOP                   SDR_ACTIVE_AREA_CROP_TOP
  #define _ACTIVE_AREA_CROP_RIGHT                 SDR_ACTIVE_AREA_CROP_RIGHT
  #define _ACTIVE_AREA_CROP_BOTTOM                SDR_ACTIVE_AREA_CROP_BOTTOM
  #define _SHOW_NITS_VALUES                       SDR_SHOW_NITS_VALUES
  #define _SHOW_NITS_FROM_CURSOR                  SDR_SHOW_NITS_FROM_CURSOR
  #define _SHOW_CIE                               SDR_SHOW_CIE
  #define _CIE_DIAGRAM_TYPE                       SDR_CIE_DIAGRAM_TYPE
  #define _CIE_DIAGRAM_BRIGHTNESS                 SDR_CIE_DIAGRAM_BRIGHTNESS
  #define _CIE_DIAGRAM_ALPHA                      SDR_CIE_DIAGRAM_ALPHA
  #define _CIE_DIAGRAM_SIZE                       SDR_CIE_DIAGRAM_SIZE
  #define _CIE_SHOW_CIE_CSP_BT709_OUTLINE         SDR_SHOW_CIE_CSP_BT709_OUTLINE
  #define _SHOW_HEATMAP                           SDR_SHOW_HEATMAP
  #define _HEATMAP_BRIGHTNESS                     SDR_HEATMAP_BRIGHTNESS
  #define _SHOW_LUMINANCE_WAVEFORM                SDR_SHOW_LUMINANCE_WAVEFORM
  #define _LUMINANCE_WAVEFORM_BRIGHTNESS          SDR_LUMINANCE_WAVEFORM_BRIGHTNESS
  #define _LUMINANCE_WAVEFORM_ALPHA               SDR_LUMINANCE_WAVEFORM_ALPHA
  #define _LUMINANCE_WAVEFORM_SIZE                SDR_LUMINANCE_WAVEFORM_SIZE
  #define _LUMINANCE_WAVEFORM_SHOW_MIN_NITS_LINE  SDR_LUMINANCE_WAVEFORM_SHOW_MIN_NITS_LINE
  #define _LUMINANCE_WAVEFORM_SHOW_MAX_NITS_LINE  SDR_LUMINANCE_WAVEFORM_SHOW_MAX_NITS_LINE
  #define _HIGHLIGHT_NIT_RANGE                    SDR_HIGHLIGHT_NIT_RANGE
  #define _HIGHLIGHT_NIT_RANGE_BRIGHTNESS         SDR_HIGHLIGHT_NIT_RANGE_BRIGHTNESS
  #define _HIGHLIGHT_NIT_RANGE_START_POINT        SDR_HIGHLIGHT_NIT_RANGE_START_POINT
  #define _HIGHLIGHT_NIT_RANGE_END_POINT          SDR_HIGHLIGHT_NIT_RANGE_END_POINT
  #define _DRAW_ABOVE_NITS_AS_BLACK               SDR_DRAW_ABOVE_NITS_AS_BLACK
  #define _ABOVE_NITS_AS_BLACK                    SDR_ABOVE_NITS_AS_BLACK
  #define _DRAW_BELOW_NITS_AS_BLACK               SDR_DRAW_BELOW_NITS_AS_BLACK
  #define _BELOW_NITS_AS_BLACK                    SDR_BELOW_NITS_AS_BLACK
#else
  #define _TEXT_SIZE                              TEXT_SIZE
  #define _TEXT_BRIGHTNESS                        TEXT_BRIGHTNESS
  #define _TEXT_BG_ALPHA                          TEXT_BG_ALPHA
  #define _TEXT_POSITION                          TEXT_POSITION
  #define _ACTIVE_AREA_ENABLE                     ACTIVE_AREA_ENABLE
  #define _ACTIVE_AREA_CROP_LEFT                  ACTIVE_AREA_CROP_LEFT
  #define _ACTIVE_AREA_CROP_TOP                   ACTIVE_AREA_CROP_TOP
  #define _ACTIVE_AREA_CROP_RIGHT                 ACTIVE_AREA_CROP_RIGHT
  #define _ACTIVE_AREA_CROP_BOTTOM                ACTIVE_AREA_CROP_BOTTOM
  #define _SHOW_NITS_VALUES                       SHOW_NITS_VALUES
  #define _SHOW_NITS_FROM_CURSOR                  SHOW_NITS_FROM_CURSOR
  #define _SHOW_CIE                               SHOW_CIE
  #define _CIE_DIAGRAM_TYPE                       CIE_DIAGRAM_TYPE
  #define _CIE_DIAGRAM_BRIGHTNESS                 CIE_DIAGRAM_BRIGHTNESS
  #define _CIE_DIAGRAM_ALPHA                      CIE_DIAGRAM_ALPHA
  #define _CIE_DIAGRAM_SIZE                       CIE_DIAGRAM_SIZE
  #define _SHOW_CIE_CSP_BT709_OUTLINE             SHOW_CIE_CSP_BT709_OUTLINE
  #define _SHOW_HEATMAP                           SHOW_HEATMAP
  #define _HEATMAP_BRIGHTNESS                     HEATMAP_BRIGHTNESS
  #define _SHOW_LUMINANCE_WAVEFORM                SHOW_LUMINANCE_WAVEFORM
  #define _LUMINANCE_WAVEFORM_BRIGHTNESS          LUMINANCE_WAVEFORM_BRIGHTNESS
  #define _LUMINANCE_WAVEFORM_ALPHA               LUMINANCE_WAVEFORM_ALPHA
  #define _LUMINANCE_WAVEFORM_SIZE                LUMINANCE_WAVEFORM_SIZE
  #define _LUMINANCE_WAVEFORM_SHOW_MIN_NITS_LINE  LUMINANCE_WAVEFORM_SHOW_MIN_NITS_LINE
  #define _LUMINANCE_WAVEFORM_SHOW_MAX_NITS_LINE  LUMINANCE_WAVEFORM_SHOW_MAX_NITS_LINE
  #define _HIGHLIGHT_NIT_RANGE                    HIGHLIGHT_NIT_RANGE
  #define _HIGHLIGHT_NIT_RANGE_BRIGHTNESS         HIGHLIGHT_NIT_RANGE_BRIGHTNESS
  #define _HIGHLIGHT_NIT_RANGE_START_POINT        HIGHLIGHT_NIT_RANGE_START_POINT
  #define _HIGHLIGHT_NIT_RANGE_END_POINT          HIGHLIGHT_NIT_RANGE_END_POINT
  #define _DRAW_ABOVE_NITS_AS_BLACK               DRAW_ABOVE_NITS_AS_BLACK
  #define _ABOVE_NITS_AS_BLACK                    ABOVE_NITS_AS_BLACK
  #define _DRAW_BELOW_NITS_AS_BLACK               DRAW_BELOW_NITS_AS_BLACK
  #define _BELOW_NITS_AS_BLACK                    BELOW_NITS_AS_BLACK
#endif


uniform uint _TEXT_SIZE
<
  ui_category = "Global";
  ui_label    = "text size";
  ui_type     = "combo";
  ui_items    = "13\0"
                "14\0"
                "16\0"
                "18\0"
                "20\0"
                "22\0"
                "24\0"
                "26\0"
                "28\0"
                "30\0"
                "32\0"
                "34\0"
                "36\0"
                "38\0"
                "40\0"
                "42\0"
                "44\0"
                "46\0"
                "48\0"
                "50\0"
                "52\0"
                "54\0"
                "56\0"
                "58\0";
> = TEXT_SIZE_DEFAULT;

uniform float _TEXT_BRIGHTNESS
<
  ui_category = "Global";
  ui_label    = "text brightness";
  ui_type     = "slider";
#ifdef IS_HDR_CSP
  ui_units    = " nits";
  ui_min      = 10.f;
  ui_max      = 250.f;
#else
  ui_units    = "%%";
  ui_min      = 10.f;
  ui_max      = 100.f;
#endif
  ui_step     = 0.5f;
#if defined(IS_HDR_CSP)
> = 140.f;
#elif (defined(GAMESCOPE) \
    && defined(IS_HDR_CSP))
> = GAMESCOPE_SDR_ON_HDR_NITS;
#else
> = DEFAULT_BRIGHTNESS;
#endif

uniform float _TEXT_BG_ALPHA
<
  ui_category = "Global";
  ui_label    = "text background transparency";
  ui_type     = "slider";
  ui_units    = "%%";
  ui_min      = 0.f;
  ui_max      = 100.f;
  ui_step     = 0.5f;
> = DEFAULT_ALPHA_LEVEL;

#define TEXT_POSITION_TOP_LEFT  0
#define TEXT_POSITION_TOP_RIGHT 1

uniform uint _TEXT_POSITION
<
  ui_category = "Global";
  ui_label    = "text position";
  ui_type     = "combo";
  ui_items    = "top left\0"
                "top right\0";
> = 0;


// Active Area
uniform bool _ACTIVE_AREA_ENABLE
<
  ui_category = "Set Active Area for analysis";
  ui_label    = "enable setting the active area";
> = false;

uniform float _ACTIVE_AREA_CROP_LEFT
<
  ui_category = "Set Active Area for analysis";
  ui_label    = "% to crop from the left side";
  ui_type     = "slider";
  ui_units    = "%%";
  ui_min      = 0.f;
  ui_max      = 100.f;
  ui_step     = 0.1f;
> = 0.f;

uniform float _ACTIVE_AREA_CROP_TOP
<
  ui_category = "Set Active Area for analysis";
  ui_label    = "% to crop from the top side";
  ui_type     = "slider";
  ui_units    = "%%";
  ui_min      = 0.f;
  ui_max      = 100.f;
  ui_step     = 0.1f;
> = 0.f;

uniform float _ACTIVE_AREA_CROP_RIGHT
<
  ui_category = "Set Active Area for analysis";
  ui_label    = "% to crop from the right side";
  ui_type     = "slider";
  ui_units    = "%%";
  ui_min      = 0.f;
  ui_max      = 100.f;
  ui_step     = 0.1f;
> = 0.f;

uniform float _ACTIVE_AREA_CROP_BOTTOM
<
  ui_category = "Set Active Area for analysis";
  ui_label    = "% to crop from the bottom side";
  ui_type     = "slider";
  ui_units    = "%%";
  ui_min      = 0.f;
  ui_max      = 100.f;
  ui_step     = 0.1f;
> = 0.f;


// Nit Values
uniform bool _SHOW_NITS_VALUES
<
  ui_category = "Luminance analysis";
  ui_label    = "show max/avg/min luminance values";
> = true;

uniform bool _SHOW_NITS_FROM_CURSOR
<
  ui_category = "Luminance analysis";
  ui_label    = "show luminance value from cursor position";
> = true;


// TextureCsps
#ifdef IS_HDR_CSP
uniform bool SHOW_CSPS
<
  ui_category = "Colour Space analysis";
  ui_label    = "show colour spaces used";
  ui_tooltip  = "in %";
> = true;

uniform bool SHOW_CSP_FROM_CURSOR
<
  ui_category = "Colour Space analysis";
  ui_label    = "show colour space from cursor position";
> = true;

uniform bool SHOW_CSP_MAP
<
  ui_category = "Colour Space analysis";
  ui_label    = "show colour space map";
  ui_tooltip  = "        colours:"
           "\n" "black and white: BT.709"
           "\n" "         yellow: DCI-P3"
           "\n" "           blue: BT.2020"
           "\n" "            red: AP0"
           "\n" "           pink: invalid";
> = false;
#endif // IS_HDR_CSP

// CIE
uniform bool _SHOW_CIE
<
  ui_category = "CIE diagram visualisation";
  ui_label    = "show CIE diagram";
> = true;

#define CIE_1931 0
#define CIE_1976 1

uniform uint _CIE_DIAGRAM_TYPE
<
  ui_category = "CIE diagram visualisation";
  ui_label    = "CIE diagram type";
  ui_type     = "combo";
  ui_items    = "CIE 1931 xy\0"
                "CIE 1976 UCS u'v'\0";
> = CIE_1931;

uniform float _CIE_DIAGRAM_BRIGHTNESS
<
  ui_category = "CIE diagram visualisation";
  ui_label    = "CIE diagram brightness";
  ui_type     = "slider";
#ifdef IS_HDR_CSP
  ui_units    = " nits";
  ui_min      = 10.f;
  ui_max      = 250.f;
#else
  ui_units    = "%%";
  ui_min      = 10.f;
  ui_max      = 100.f;
#endif
  ui_step     = 0.5f;
#if (defined(GAMESCOPE) \
  && defined(IS_HDR_CSP))
> = GAMESCOPE_SDR_ON_HDR_NITS;
#else
> = DEFAULT_BRIGHTNESS;
#endif

uniform float _CIE_DIAGRAM_ALPHA
<
  ui_category = "CIE diagram visualisation";
  ui_label    = "CIE diagram transparency";
  ui_type     = "slider";
  ui_units    = "%%";
  ui_min      = 0.f;
  ui_max      = 100.f;
  ui_step     = 0.5f;
> = DEFAULT_ALPHA_LEVEL;

#ifdef IS_QHD_OR_HIGHER_RES
  #define CIE_TEXTURE_FILE_NAME   "lilium__cie_1000x1000_consolidated.png"
  #define CIE_TEXTURE_WIDTH       5016
  #define CIE_TEXTURE_HEIGHT      1626
  #define CIE_BG_BORDER             50

  #define CIE_ORIGINAL_DIM        1000

  #define CIE_1931_WIDTH           736
  #define CIE_1931_HEIGHT          837
  #define CIE_1931_BG_WIDTH        836
  #define CIE_1931_BG_HEIGHT       937

  #define CIE_1976_WIDTH           625
  #define CIE_1976_HEIGHT          589
  #define CIE_1976_BG_WIDTH        725
  #define CIE_1976_BG_HEIGHT       689
#else
  #define CIE_TEXTURE_FILE_NAME   "lilium__cie_500x500_consolidated.png"
  #define CIE_TEXTURE_WIDTH       2520
  #define CIE_TEXTURE_HEIGHT       817
  #define CIE_BG_BORDER             25

  #define CIE_ORIGINAL_DIM         500

  #define CIE_1931_WIDTH           370
  #define CIE_1931_HEIGHT          420
  #define CIE_1931_BG_WIDTH        420
  #define CIE_1931_BG_HEIGHT       470

  #define CIE_1976_WIDTH           314
  #define CIE_1976_HEIGHT          297
  #define CIE_1976_BG_WIDTH        364
  #define CIE_1976_BG_HEIGHT       347
#endif

static const float2 CIE_CONSOLIDATED_TEXTURE_SIZE = float2(CIE_TEXTURE_WIDTH, CIE_TEXTURE_HEIGHT);

static const int2 CIE_1931_SIZE = int2(CIE_1931_WIDTH, CIE_1931_HEIGHT);
static const int2 CIE_1976_SIZE = int2(CIE_1976_WIDTH, CIE_1976_HEIGHT);

static const float CIE_BG_WIDTH[2]  = { CIE_1931_BG_WIDTH,  CIE_1976_BG_WIDTH };
static const float CIE_BG_HEIGHT[2] = { CIE_1931_BG_HEIGHT, CIE_1976_BG_HEIGHT };

static const int CIE_BG_WIDTH_AS_INT[2]  = { CIE_1931_BG_WIDTH,  CIE_1976_BG_WIDTH };
static const int CIE_BG_HEIGHT_AS_INT[2] = { CIE_1931_BG_HEIGHT, CIE_1976_BG_HEIGHT };

static const float CIE_DIAGRAM_DEFAULT_SIZE = (float(BUFFER_HEIGHT) * 0.375f)
                                              / CIE_1931_BG_HEIGHT
                                              * 100.f;

uniform float _CIE_DIAGRAM_SIZE
<
  ui_category = "CIE diagram visualisation";
  ui_label    = "CIE diagram size";
  ui_type     = "slider";
  ui_units    = "%%";
  ui_min      = 50.f;
  ui_max      = 100.f;
  ui_step     = 0.1f;
> = CIE_DIAGRAM_DEFAULT_SIZE;

uniform bool _SHOW_CIE_CSP_BT709_OUTLINE
<
  ui_category = "CIE diagram visualisation";
  ui_label    = "show BT.709 colour space outline";
> = true;

#ifdef IS_HDR_CSP
uniform bool SHOW_CIE_CSP_DCI_P3_OUTLINE
<
  ui_category = "CIE diagram visualisation";
  ui_label    = "show DCI-P3 colour space outline";
> = true;

uniform bool SHOW_CIE_CSP_BT2020_OUTLINE
<
  ui_category = "CIE diagram visualisation";
  ui_label    = "show BT.2020 colour space outline";
> = true;

#ifdef IS_FLOAT_HDR_CSP
uniform bool SHOW_CIE_CSP_AP0_OUTLINE
<
  ui_category = "CIE diagram visualisation";
  ui_label    = "show AP0 colour space outline";
> = true;
#endif //IS_FLOAT_HDR_CSP
#endif //IS_HDR_CSP

// heatmap
uniform bool _SHOW_HEATMAP
<
  ui_category = "Heatmap visualisation";
  ui_label    = "show heatmap";
#ifndef IS_HDR_CSP
  ui_tooltip  = "         colours: |     % nits:"
           "\n" "------------------|------------"
           "\n" " black to white:  |   0.0-  1.0"
           "\n" "  teal to green:  |   1.0- 18.0"
           "\n" " green to yellow: |  18.0- 50.0"
           "\n" "yellow to red:    |  50.0- 75.0"
           "\n" "   red to pink:   |  75.0- 87.5"
           "\n" "  pink to blue:   |  87.5-100.0"
           "\n" "-------------------------------"
           "\n"
           "\n" "extra cases:"
           "\n" "highly saturated red:  above the cutoff point"
           "\n" "highly saturated blue: below 0 nits";
#endif
> = false;

uniform float _HEATMAP_BRIGHTNESS
<
  ui_category = "Heatmap visualisation";
  ui_label    = "heatmap brightness";
  ui_type     = "slider";
#ifdef IS_HDR_CSP
  ui_units    = " nits";
  ui_min      = 10.f;
  ui_max      = 250.f;
#else
  ui_units    = "%%";
  ui_min      = 10.f;
  ui_max      = 100.f;
#endif
  ui_step     = 0.5f;
> = DEFAULT_BRIGHTNESS;

#ifdef IS_HDR_CSP
uniform uint HEATMAP_CUTOFF_POINT
<
  ui_category = "Heatmap visualisation";
  ui_label    = "heatmap cutoff point";
  ui_type     = "combo";
  ui_items    = "10000 nits\0"
                " 4000 nits\0"
                " 2000 nits\0"
                " 1000 nits\0";
  ui_tooltip  = "         colours: | 10000 nits: | 4000 nits: | 2000 nits: | 1000 nits:"
           "\n" "------------------|-------------|------------|------------|-----------"
           "\n" " black to white:  |     0-  100 |     0- 100 |     0- 100 |     0- 100"
           "\n" "  teal to green:  |   100-  203 |   100- 203 |   100- 203 |   100- 203"
           "\n" " green to yellow: |   203-  400 |   203- 400 |   203- 400 |   203- 400"
           "\n" "yellow to red:    |   400- 1000 |   400-1000 |   400-1000 |   400- 600"
           "\n" "   red to pink:   |  1000- 4000 |  1000-2000 |  1000-1500 |   600- 800"
           "\n" "  pink to blue:   |  4000-10000 |  2000-4000 |  1500-2000 |   800-1000"
           "\n" "----------------------------------------------------------------------"
           "\n"
           "\n" "extra cases:"
           "\n" "highly saturated red:  above the cutoff point"
           "\n" "highly saturated blue: below 0 nits";
> = 0;
#endif //IS_HDR_CSP

uniform bool _SHOW_LUMINANCE_WAVEFORM
<
  ui_category = "Luminance waveform";
  ui_label    = "show luminance waveform";
  ui_tooltip  = "Luminance waveform paid for by Aemony.";
> = true;

#ifdef IS_HDR_CSP
uniform uint LUMINANCE_WAVEFORM_CUTOFF_POINT
<
  ui_category = "Luminance waveform";
  ui_label    = "luminance waveform cutoff point";
  ui_type     = "combo";
  ui_items    = "10000 nits\0"
                " 4000 nits\0"
                " 2000 nits\0"
                " 1000 nits\0";
> = 0;
#endif //IS_HDR_CSP

uniform float _LUMINANCE_WAVEFORM_BRIGHTNESS
<
  ui_category = "Luminance waveform";
  ui_label    = "luminance waveform brightness";
  ui_type     = "slider";
#ifdef IS_HDR_CSP
  ui_units    = " nits";
  ui_min      = 10.f;
  ui_max      = 250.f;
#else
  ui_units    = "%%";
  ui_min      = 10.f;
  ui_max      = 100.f;
#endif
  ui_step     = 0.5f;
#if (defined(GAMESCOPE) \
  && defined(IS_HDR_CSP))
> = GAMESCOPE_SDR_ON_HDR_NITS;
#else
> = DEFAULT_BRIGHTNESS;
#endif

uniform float _LUMINANCE_WAVEFORM_ALPHA
<
  ui_category = "Luminance waveform";
  ui_label    = "luminance waveform transparency";
  ui_type     = "slider";
  ui_units    = "%%";
  ui_min      = 0.f;
  ui_max      = 100.f;
  ui_step     = 0.5f;
> = DEFAULT_ALPHA_LEVEL;

static const uint TEXTURE_LUMINANCE_WAVEFORM_WIDTH = uint(float(BUFFER_WIDTH) / 4.f) * 2;

#ifdef IS_HDR_CSP
  #if (BUFFER_HEIGHT <= (512 * 5 / 2))
    static const uint TEXTURE_LUMINANCE_WAVEFORM_HEIGHT = 512;
  #elif (BUFFER_HEIGHT <= (768 * 5 / 2))
    static const uint TEXTURE_LUMINANCE_WAVEFORM_HEIGHT = 768;
  #elif (BUFFER_HEIGHT <= (1024 * 5 / 2))
    static const uint TEXTURE_LUMINANCE_WAVEFORM_HEIGHT = 1024;
  #elif (BUFFER_HEIGHT <= (1536 * 5 / 2) \
      || defined(IS_HDR10_LIKE_CSP))
    static const uint TEXTURE_LUMINANCE_WAVEFORM_HEIGHT = 1536;
  #elif (BUFFER_HEIGHT <= (2048 * 5 / 2))
    static const uint TEXTURE_LUMINANCE_WAVEFORM_HEIGHT = 2048;
  #elif (BUFFER_HEIGHT <= (3072 * 5 / 2))
    static const uint TEXTURE_LUMINANCE_WAVEFORM_HEIGHT = 3072;
  #else //(BUFFER_HEIGHT <= (4096 * 5 / 2))
    static const uint TEXTURE_LUMINANCE_WAVEFORM_HEIGHT = 4096;
  #endif
#else
  #if (BUFFER_COLOR_BIT_DEPTH == 10)
    #if (BUFFER_HEIGHT <= (512 * 5 / 2))
      static const uint TEXTURE_LUMINANCE_WAVEFORM_HEIGHT = 512;
    #elif (BUFFER_HEIGHT <= (768 * 5 / 2))
      static const uint TEXTURE_LUMINANCE_WAVEFORM_HEIGHT = 768;
    #elif (BUFFER_HEIGHT <= (1024 * 5 / 2))
      static const uint TEXTURE_LUMINANCE_WAVEFORM_HEIGHT = 1024;
    #elif (BUFFER_HEIGHT <= (1280 * 5 / 2))
      static const uint TEXTURE_LUMINANCE_WAVEFORM_HEIGHT = 1280;
    #else //(BUFFER_HEIGHT <= (1536 * 5 / 2))
      static const uint TEXTURE_LUMINANCE_WAVEFORM_HEIGHT = 1536;
    #endif
  #else
    static const uint TEXTURE_LUMINANCE_WAVEFORM_HEIGHT = 384;
  #endif
#endif

static const uint TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT = TEXTURE_LUMINANCE_WAVEFORM_HEIGHT - 1;

static const int UGH = uint(float(BUFFER_HEIGHT) * 0.35f
                          / float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT)
                          * 10000.f);
// "minimum of 2 variables" without using functions...
// https://guru.multimedia.cx/category/optimization/
#ifdef IS_HDR_CSP
  static const uint UGH2 = int(10000) + ((UGH - int(10000)) & ((UGH - int(10000)) >> 31));
#else
  static const uint UGH2 = int(20000) + ((UGH - int(20000)) & ((UGH - int(20000)) >> 31));
#endif

static const precise float LUMINANCE_WAVEFORM_DEFAULT_HEIGHT = UGH2
                                                             / 100.f;

uniform float2 _LUMINANCE_WAVEFORM_SIZE
<
  ui_category = "Luminance waveform";
  ui_label    = "luminance waveform size";
  ui_type     = "slider";
  ui_units    = "%%";
  ui_min      =  50.f;
#ifdef IS_HDR_CSP
  ui_max      = 100.f;
#else
  ui_max      = 200.f;
#endif
  ui_step     =   0.1f;
> = float2(70.f, LUMINANCE_WAVEFORM_DEFAULT_HEIGHT);

uniform bool _LUMINANCE_WAVEFORM_SHOW_MIN_NITS_LINE
<
  ui_category = "Luminance waveform";
  ui_label    = "show the minimum nits line";
  ui_tooltip  = "Show a horizontal line where the minimum nits is on the waveform."
           "\n" "The line is invisible when the minimum nits hits 0 nits.";
> = true;

uniform bool _LUMINANCE_WAVEFORM_SHOW_MAX_NITS_LINE
<
  ui_category = "Luminance waveform";
  ui_label    = "show the maximum nits line";
  ui_tooltip  = "Show a horizontal line where the maximum nits is on the waveform."
           "\n" "The line is invisible when the maximum nits hits above 10000 nits.";
> = true;

// highlight a certain nit range
uniform bool _HIGHLIGHT_NIT_RANGE
<
  ui_category = "Highlight brightness range visualisation";
  ui_label    = "enable highlighting brightness levels in a certain range";
  ui_tooltip  = "in nits";
> = false;

uniform float _HIGHLIGHT_NIT_RANGE_BRIGHTNESS
<
  ui_category = "Highlight brightness range visualisation";
  ui_label    = "highlighted range brightness";
  ui_type     = "slider";
#ifdef IS_HDR_CSP
  ui_units    = " nits";
  ui_min      = 10.f;
  ui_max      = 250.f;
#else
  ui_units    = "%%";
  ui_min      = 10.f;
  ui_max      = 100.f;
#endif
> = DEFAULT_BRIGHTNESS;

uniform float _HIGHLIGHT_NIT_RANGE_START_POINT
<
  ui_category = "Highlight brightness range visualisation";
  ui_label    = "range starting point";
  ui_tooltip  = "CTRL + LEFT CLICK on the value to input an exact value.";
  ui_type     = "drag";
#ifdef IS_HDR_CSP
  ui_units    = " nits";
  ui_min      = 0.f;
  ui_max      = 10000.f;
  ui_step     = 0.0000001f;
#else
  ui_units    = "%%";
  ui_min      = 0.f;
  ui_max      = 100.f;
  ui_step     = 0.00001f;
#endif
> = 0.f;

uniform float _HIGHLIGHT_NIT_RANGE_END_POINT
<
  ui_category = "Highlight brightness range visualisation";
  ui_label    = "range end point";
  ui_tooltip  = "CTRL + LEFT CLICK on the value to input an exact value.";
  ui_type     = "drag";
#ifdef IS_HDR_CSP
  ui_units    = " nits";
  ui_min      = 0.f;
  ui_max      = 10000.f;
  ui_step     = 0.0000001f;
#else
  ui_units    = "%%";
  ui_min      = 0.f;
  ui_max      = 100.f;
  ui_step     = 0.00001f;
#endif
> = 0.f;

// draw pixels as black depending on their nits
uniform bool _DRAW_ABOVE_NITS_AS_BLACK
<
  ui_category = "Draw certain brightness levels as black";
  ui_label    = "enable drawing above this brightness as black";
> = false;

uniform float _ABOVE_NITS_AS_BLACK
<
  ui_category = "Draw certain brightness levels as black";
  ui_label    = "draw above this brightness as black";
  ui_type     = "slider";
#ifdef IS_HDR_CSP
  ui_units    = " nits";
  ui_min      = 0.f;
  ui_max      = 10000.f;
  ui_step     = 0.0000001f;
#else
  ui_units    = "%%";
  ui_min      = 0.f;
  ui_max      = 100.f;
  ui_step     = 0.00001f;
#endif
#ifdef IS_HDR_CSP
> = 10000.f;
#else
> = 100.f;
#endif

uniform bool _DRAW_BELOW_NITS_AS_BLACK
<
  ui_category = "Draw certain brightness levels as black";
  ui_label    = "enable drawing below this brightness as black";
> = false;

uniform float _BELOW_NITS_AS_BLACK
<
  ui_category = "Draw certain brightness levels as black";
  ui_label    = "draw below this brightness as black";
  ui_type     = "drag";
#ifdef IS_HDR_CSP
  ui_units    = " nits";
  ui_min      = 0.f;
  ui_max      = 10000.f;
  ui_step     = 1.f;
#else
  ui_units    = "%%";
  ui_min      = 0.f;
  ui_max      = 100.f;
  ui_step     = 0.5f;
#endif
#ifdef IS_HDR_CSP
> = 10000.f;
#else
> = 100.f;
#endif


#ifdef _TESTY
uniform bool ENABLE_TEST_THINGY
<
  ui_category = "TESTY";
  ui_label    = "enable test thingy";
> = false;

uniform float2 TEST_AREA_SIZE
<
  ui_category = "TESTY";
  ui_label    = "test area size";
  ui_type     = "drag";
  ui_min      = 0.f;
  ui_max      = BUFFER_WIDTH;
  ui_step     = 1.f;
> = float2(100.f, 100.f);

#define TESTY_MODE_RGB_BT709     0
#define TESTY_MODE_RGB_DCI_P3    1
#define TESTY_MODE_RGB_BT2020    2
#define TESTY_MODE_RGB_AP0D65    3
#define TESTY_MODE_xyY           4
#define TESTY_MODE_POS_INF_ON_R  5
#define TESTY_MODE_NEG_INF_ON_G  6
#define TESTY_MODE_NAN_ON_B      7

uniform uint TEST_MODE
<
  ui_category = "TESTY";
  ui_label    = "mode";
  ui_type     = "combo";
  ui_items    = " RGB BT.709\0"
                " RGB DCI-P3\0"
                " RGB BT.2020\0"
                " ACES AP0 (D65 white point)\0"
                " xyY\0"
                "+Inf (0x7F800000) on R (else is 0)\0"
                "-Inf (0xFF800000) on G (else is 0)\0"
                " NaN (0xFFFFFFFF) on B (else is 0)\0";
> = TESTY_MODE_RGB_BT709;

precise uniform float3 TEST_THINGY_RGB
<
  ui_category = "TESTY";
  ui_label    = "RGB (linear)";
  ui_type     = "drag";
  ui_min      = -10000.f;
  ui_max      =  10000.f;
  ui_step     =      0.000001f;
> = 80.f;

precise uniform float2 TEST_THINGY_xy
<
  ui_category = "TESTY";
  ui_label    = "xy";
  ui_type     = "drag";
  ui_min      = 0.f;
  ui_max      = 1.f;
  ui_step     = 0.000001f;
> = 0.f;

precise uniform float TEST_THINGY_Y
<
  ui_category = "TESTY";
  ui_label    = "Y";
  ui_type     = "drag";
  ui_units    = " nits";
  ui_min      =     0.f;
  ui_max      = 10000.f;
  ui_step     =     0.000001f;
> = 80.f;


void VS_Testy(
  in                  uint   Id         : SV_VertexID,
  out                 float4 VPos       : SV_Position,
  out                 float2 TexCoord   : TEXCOORD0,
  out nointerpolation float4 TestyStuff : TestyStuff)
{
  TexCoord.x = (Id == 2) ? 2.f
                         : 0.f;
  TexCoord.y = (Id == 1) ? 2.f
                         : 0.f;
  VPos = float4(TexCoord * float2(2.f, -2.f) + float2(-1.f, 1.f), 0.f, 1.f);

  float2 testAreaSizeDiv2 = TEST_AREA_SIZE / 2.f;

  TestyStuff.x = BUFFER_WIDTH  / 2.f - testAreaSizeDiv2.x - 1.f;
  TestyStuff.y = BUFFER_HEIGHT / 2.f - testAreaSizeDiv2.y - 1.f;
  TestyStuff.z = BUFFER_WIDTH  - TestyStuff.x;
  TestyStuff.w = BUFFER_HEIGHT - TestyStuff.y;
}

void PS_Testy(
  in                          float4 VPos       : SV_Position,
  in                          float2 TexCoord   : TEXCOORD0,
  in  nointerpolation         float4 TestyStuff : TestyStuff,
  out                 precise float4 Output     : SV_Target0)
{
  const float2 pureCoord = floor(VPos.xy);

  if(ENABLE_TEST_THINGY
  && pureCoord.x > TestyStuff.x
  && pureCoord.x < TestyStuff.z
  && pureCoord.y > TestyStuff.y
  && pureCoord.y < TestyStuff.w)
  {
#if (ACTUAL_COLOUR_SPACE != CSP_SCRGB) \
 && (ACTUAL_COLOUR_SPACE != CSP_HDR10)
  Output = float4(0.f, 0.f, 0.f, 1.f);
  return;
#endif
    if (TEST_MODE == TESTY_MODE_RGB_BT709)
    {
#if (ACTUAL_COLOUR_SPACE == CSP_SCRGB)
      Output = float4(TEST_THINGY_RGB / 80.f, 1.f);
#elif (ACTUAL_COLOUR_SPACE == CSP_HDR10)
      Output = float4(Csp::Trc::LinearTo::Pq(Csp::Mat::Bt709To::Bt2020(TEST_THINGY_RGB / 10000.f)), 1.f);
#endif
      return;
    }
    else if (TEST_MODE == TESTY_MODE_RGB_DCI_P3)
    {
#if (ACTUAL_COLOUR_SPACE == CSP_SCRGB)
      Output = float4(Csp::Mat::DciP3To::Bt709(TEST_THINGY_RGB / 80.f), 1.f);
#elif (ACTUAL_COLOUR_SPACE == CSP_HDR10)
      Output = float4(Csp::Trc::LinearTo::Pq(Csp::Mat::DciP3To::Bt2020(TEST_THINGY_RGB / 10000.f)), 1.f);
#endif
      return;
    }
    else if (TEST_MODE == TESTY_MODE_RGB_BT2020)
    {
#if (ACTUAL_COLOUR_SPACE == CSP_SCRGB)
      Output = float4(Csp::Mat::Bt2020To::Bt709(TEST_THINGY_RGB / 80.f), 1.f);
#elif (ACTUAL_COLOUR_SPACE == CSP_HDR10)
      Output = float4(Csp::Trc::LinearTo::Pq(TEST_THINGY_RGB / 10000.f), 1.f);
#endif
      return;
    }
    else if (TEST_MODE == TESTY_MODE_RGB_AP0D65)
    {
#if (ACTUAL_COLOUR_SPACE == CSP_SCRGB)
      Output = float4(Csp::Mat::Ap0D65To::Bt709(TEST_THINGY_RGB / 80.f), 1.f);
#elif (ACTUAL_COLOUR_SPACE == CSP_HDR10)
      Output = float4(Csp::Trc::LinearTo::Pq(Csp::Mat::Ap0D65To::Bt2020(TEST_THINGY_RGB / 10000.f)), 1.f);
#endif
      return;
    }
    else if (TEST_MODE == TESTY_MODE_xyY)
    {

#if (ACTUAL_COLOUR_SPACE == CSP_SCRGB)
      precise float3 XYZ = GetXYZfromxyY(TEST_THINGY_xy, TEST_THINGY_Y / 80.f);
      Output = float4(Csp::Mat::XYZTo::Bt709(XYZ), 1.f);
#elif (ACTUAL_COLOUR_SPACE == CSP_HDR10)
      precise float3 XYZ = GetXYZfromxyY(TEST_THINGY_xy, TEST_THINGY_Y / 10000.f);
      Output = float4(Csp::Trc::LinearTo::Pq(Csp::Mat::XYZTo::Bt2020(XYZ)), 1.f);
#endif
      return;
    }
    else if (TEST_MODE == TESTY_MODE_POS_INF_ON_R)
    {
      static const precise float asFloat = asfloat(0x7F800000);
      Output = float4(asFloat, 0.f, 0.f, 1.f);
      return;
    }
    else if (TEST_MODE == TESTY_MODE_NEG_INF_ON_G)
    {
      static const precise float asFloat = asfloat(0xFF800000);
      Output = float4(0.f, asFloat, 0.f, 1.f);
      return;
    }
    else if (TEST_MODE == TESTY_MODE_NAN_ON_B)
    {
      static const precise float asFloat = asfloat(0xFFFFFFFF);
      Output = float4(0.f, 0.f, asFloat, 1.f);
      return;
    }
    else
    {
      Output = float4(0.f, 0.f, 0.f, 1.f);
      return;
    }
  }
  Output = float4(0.f, 0.f, 0.f, 1.f);
  return;
}
#endif //_TESTY


#define ANALYSIS_ENABLE

#include "lilium__include/hdr_and_sdr_analysis/main.fxh"


// Vertex shader generating a triangle covering the entire screen.
// Calculate values only "once" (3 times because it's 3 vertices)
// for the pixel shader.
void VS_PrepareHdrAnalysis(
  in                  uint   Id                : SV_VertexID,
  out                 float4 VPos              : SV_Position,
  out                 float2 TexCoord          : TEXCOORD0,
  out nointerpolation bool2  PingPongChecks    : PingPongChecks,
  out nointerpolation float4 HighlightNitRange : HighlightNitRange,
#if (!defined(GAMESCOPE) \
  && !defined(POSSIBLE_DECK_VULKAN_USAGE))
  out nointerpolation int4   TextureDisplaySizes : TextureDisplaySizes,
#else
  out nointerpolation int2   CurrentActiveOverlayArea                 : CurrentActiveOverlayArea,
  out nointerpolation int2   LuminanceWaveformTextureDisplayAreaBegin : LuminanceWaveformTextureDisplayAreaBegin,
#endif
  out nointerpolation float2 CieDiagramTextureActiveSize  : CieDiagramTextureActiveSize,
  out nointerpolation float2 CieDiagramTextureDisplaySize : CieDiagramTextureDisplaySize)
{
  TexCoord.x = (Id == 2) ? 2.f
                         : 0.f;
  TexCoord.y = (Id == 1) ? 2.f
                         : 0.f;
  VPos = float4(TexCoord * float2(2.f, -2.f) + float2(-1.f, 1.f), 0.f, 1.f);

#define pingpong0Above1   PingPongChecks[0]
#define breathingIsActive PingPongChecks[1]

#define highlightNitRangeOut HighlightNitRange.rgb
#define breathing            HighlightNitRange.w

#if (!defined(GAMESCOPE) \
  && !defined(POSSIBLE_DECK_VULKAN_USAGE))
  #define CurrentActiveOverlayArea                 TextureDisplaySizes.xy
  #define LuminanceWaveformTextureDisplayAreaBegin TextureDisplaySizes.zw
#endif

  pingpong0Above1                          = false;
  breathingIsActive                        = false;
  HighlightNitRange                        = 0.f;
  CurrentActiveOverlayArea                 = 0;
  LuminanceWaveformTextureDisplayAreaBegin = 0;
  CieDiagramTextureActiveSize              = 0.f;
  CieDiagramTextureDisplaySize             = 0.f;

  if (_HIGHLIGHT_NIT_RANGE)
  {
    float pingpong0 = NIT_PINGPONG0.x + 0.5f;

    pingpong0Above1 = pingpong0 >= 1.f;

    if (pingpong0Above1)
    {
      breathing = saturate(pingpong0 - 1.f);
      //breathing = 1.f;

      breathingIsActive = breathing > 0.f;

      float pingpong1 = NIT_PINGPONG1.y == 1 ?       NIT_PINGPONG1.x
                                             : 6.f - NIT_PINGPONG1.x;

      if (pingpong1 <= 1.f)
      {
        highlightNitRangeOut = float3(1.f, NIT_PINGPONG2.x, 0.f);
      }
      else if (pingpong1 <= 2.f)
      {
        highlightNitRangeOut = float3(NIT_PINGPONG2.x, 1.f, 0.f);
      }
      else if (pingpong1 <= 3.f)
      {
        highlightNitRangeOut = float3(0.f, 1.f, NIT_PINGPONG2.x);
      }
      else if (pingpong1 <= 4.f)
      {
        highlightNitRangeOut = float3(0.f, NIT_PINGPONG2.x, 1.f);
      }
      else if (pingpong1 <= 5.f)
      {
        highlightNitRangeOut = float3(NIT_PINGPONG2.x, 0.f, 1.f);
      }
      else //if (pingpong1 <= 6.f)
      {
        highlightNitRangeOut = float3(1.f, 0.f, NIT_PINGPONG2.x);
      }

      highlightNitRangeOut *= breathing;

      highlightNitRangeOut = MapBt709IntoCurrentCsp(highlightNitRangeOut, _HIGHLIGHT_NIT_RANGE_BRIGHTNESS);
    }
  }

  if (_SHOW_LUMINANCE_WAVEFORM)
  {
    LuminanceWaveformTextureDisplayAreaBegin = int2(BUFFER_WIDTH, BUFFER_HEIGHT) - Waveform::GetActiveArea();
  }

  if (_SHOW_CIE)
  {
    float cieDiagramSizeFrac = _CIE_DIAGRAM_SIZE / 100.f;

    CieDiagramTextureActiveSize =
      round(float2(CIE_BG_WIDTH[_CIE_DIAGRAM_TYPE], CIE_BG_HEIGHT[_CIE_DIAGRAM_TYPE]) * cieDiagramSizeFrac);

    CieDiagramTextureActiveSize.y = float(BUFFER_HEIGHT) - CieDiagramTextureActiveSize.y;

    CieDiagramTextureDisplaySize =
      float2(CIE_1931_BG_WIDTH, CIE_1931_BG_HEIGHT) * cieDiagramSizeFrac;
  }

  {
    uint activeLines = GetActiveLines();

    uint activeCharacters = GetActiveCharacters();

    static const uint charArrayEntry = GetCharArrayEntry();

    uint2 charSize = GetCharSize(charArrayEntry);

    uint outerSpacing = GetOuterSpacing(charSize.x);

    uint2 currentOverlayDimensions = charSize
                                   * uint2(activeCharacters, activeLines);

    currentOverlayDimensions.y += uint(max(_SHOW_NITS_VALUES
                                         + _SHOW_NITS_FROM_CURSOR
#ifdef IS_HDR_CSP
                                         + SHOW_CSPS
                                         + SHOW_CSP_FROM_CURSOR
#endif
                                         - 1, 0)
                                     * charSize.y * SPACING_MULTIPLIER);

    if (_SHOW_NITS_VALUES
     || _SHOW_NITS_FROM_CURSOR
#ifdef IS_HDR_CSP
     || SHOW_CSPS
     || SHOW_CSP_FROM_CURSOR
#endif
    )
    {
      currentOverlayDimensions.y += charSize.y * CSP_DESC_SPACING_MULTIPLIER;
    }

    currentOverlayDimensions += outerSpacing + outerSpacing;

    if (_TEXT_POSITION == TEXT_POSITION_TOP_RIGHT)
    {
      currentOverlayDimensions.x = uint(BUFFER_WIDTH) - currentOverlayDimensions.x;
    }

    CurrentActiveOverlayArea = int2(currentOverlayDimensions);
  }

}


void ExtendedReinhardTmo(
  inout float3 Colour,
  in    float  WhitePoint)
{
#ifdef IS_HDR_CSP
  float maxWhite = 10000.f / WhitePoint;
#else
  float maxWhite = 100.f / WhitePoint;
#endif

  Colour = (Colour * (1.f + (Colour / (maxWhite * maxWhite))))
         / (1.f + Colour);
}

void MergeOverlay(
  inout float3 Output,
  in    float3 Overlay,
  in    float  OverlayBrightness,
  in    float  Alpha)
{
#ifdef IS_HDR_CSP
  Overlay = Csp::Mat::Bt709To::Bt2020(Overlay);
#endif

  // tone map pixels below the overlay area
  //
  // first set 1.0 to be equal to OverlayBrightness
  float adjustFactor;

#if (ACTUAL_COLOUR_SPACE == CSP_SCRGB)

  adjustFactor = OverlayBrightness / 80.f;

  Output = Csp::Mat::Bt709To::Bt2020(Output / adjustFactor);

  // safety clamp colours outside of BT.2020
  Output = max(Output, 0.f);

#elif (ACTUAL_COLOUR_SPACE == CSP_HDR10)

  adjustFactor = OverlayBrightness / 10000.f;

  Output = Csp::Trc::PqTo::Linear(Output);

#elif (ACTUAL_COLOUR_SPACE == CSP_SRGB)

  adjustFactor = OverlayBrightness / 100.f;

  Output = DECODE_SDR(Output);

#endif

#if (ACTUAL_COLOUR_SPACE != CSP_SCRGB)

  Output /= adjustFactor;

#endif

  // then tone map to 1.0 at max
  ExtendedReinhardTmo(Output, OverlayBrightness);

#if (ACTUAL_COLOUR_SPACE == CSP_SCRGB)

  // safety clamp for the case that there are values that represent above 10000 nits
  Output.rgb = min(Output.rgb, 1.f);

#endif

  // apply the overlay
  Output = lerp(Output, Overlay, Alpha);

  // map everything back to the used colour space
  Output *= adjustFactor;

#if (ACTUAL_COLOUR_SPACE == CSP_SCRGB)

  Output = Csp::Mat::Bt2020To::Bt709(Output);

#elif (ACTUAL_COLOUR_SPACE == CSP_HDR10)

  Output = Csp::Trc::LinearTo::Pq(Output);

#elif (ACTUAL_COLOUR_SPACE == CSP_SRGB)

  Output = ENCODE_SDR(Output);

#endif
}


void PS_HdrAnalysis(
  in                  float4 VPos              : SV_Position,
  in                  float2 TexCoord          : TEXCOORD0,
  in  nointerpolation bool2  PingPongChecks    : PingPongChecks,
  in  nointerpolation float4 HighlightNitRange : HighlightNitRange,
#if (!defined(GAMESCOPE) \
  && !defined(POSSIBLE_DECK_VULKAN_USAGE))
  in  nointerpolation int4   TextureDisplaySizes : TextureDisplaySizes,
#else
  in  nointerpolation int2   CurrentActiveOverlayArea                 : CurrentActiveOverlayArea,
  in  nointerpolation int2   LuminanceWaveformTextureDisplayAreaBegin : LuminanceWaveformTextureDisplayAreaBegin,
#endif
  in  nointerpolation float2 CieDiagramTextureActiveSize  : CieDiagramTextureActiveSize,
  in  nointerpolation float2 CieDiagramTextureDisplaySize : CieDiagramTextureDisplaySize,
  out                 float4 Output                       : SV_Target0)
{
  const int2 pureCoordAsInt = int2(VPos.xy);

  Output = tex2Dfetch(ReShade::BackBuffer, pureCoordAsInt);

  if (_SHOW_HEATMAP
#ifdef IS_HDR_CSP
   || SHOW_CSP_MAP
#endif
   || _HIGHLIGHT_NIT_RANGE
   || _DRAW_ABOVE_NITS_AS_BLACK
   || _DRAW_BELOW_NITS_AS_BLACK)
  {
    const float pixelNits = tex2Dfetch(SamplerNitsValues, pureCoordAsInt);

    if (_SHOW_HEATMAP)
    {
      Output.rgb = HeatmapRgbValues(pixelNits,
#ifdef IS_HDR_CSP
                                    HEATMAP_CUTOFF_POINT,
#endif
                                    false);

      Output.rgb = MapBt709IntoCurrentCsp(Output.rgb, _HEATMAP_BRIGHTNESS);
    }

#ifdef IS_HDR_CSP
    if (SHOW_CSP_MAP)
    {
      Output.rgb = CreateCspMap(tex2Dfetch(SamplerCsps, pureCoordAsInt).x * 255.f, pixelNits);
    }
#endif

    if (_HIGHLIGHT_NIT_RANGE
     && pixelNits >= _HIGHLIGHT_NIT_RANGE_START_POINT
     && pixelNits <= _HIGHLIGHT_NIT_RANGE_END_POINT
     && pingpong0Above1
     && breathingIsActive)
    {
      //Output.rgb = HighlightNitRangeOut;
      Output.rgb = lerp(Output.rgb, highlightNitRangeOut, breathing);
    }

    if (_DRAW_ABOVE_NITS_AS_BLACK)
    {
      if (pixelNits > _ABOVE_NITS_AS_BLACK)
      {
        Output.rgba = 0.f;
      }
    }

    if (_DRAW_BELOW_NITS_AS_BLACK)
    {
      if (pixelNits < _BELOW_NITS_AS_BLACK)
      {
        Output.rgba = 0.f;
      }
    }
  }

  if (_SHOW_CIE)
  {
    // draw the diagram in the bottom left corner
    if (VPos.x <  CieDiagramTextureActiveSize.x
     && VPos.y >= CieDiagramTextureActiveSize.y)
    {
      // get coords for the sampler
      float2 currentSamplerCoords = float2(VPos.x,
                                           VPos.y - CieDiagramTextureActiveSize.y);

      float2 currentCieSamplerCoords = currentSamplerCoords / CieDiagramTextureDisplaySize;

      float3 currentPixelToDisplay = tex2D(SamplerCieCurrent, currentCieSamplerCoords).rgb;

      // using gamma 2 as intermediate gamma space
      currentPixelToDisplay *= currentPixelToDisplay;

      float alpha = min(ceil(MAXRGB(currentPixelToDisplay)) + _CIE_DIAGRAM_ALPHA / 100.f, 1.f);

      MergeOverlay(Output.rgb,
                   currentPixelToDisplay,
                   _CIE_DIAGRAM_BRIGHTNESS,
                   alpha);
    }
  }

  if (_SHOW_LUMINANCE_WAVEFORM)
  {
    // draw the waveform in the bottom right corner
    if (all(pureCoordAsInt.xy >= LuminanceWaveformTextureDisplayAreaBegin))
    {
      // get fetch coords
      int2 currentFetchCoords = pureCoordAsInt.xy - LuminanceWaveformTextureDisplayAreaBegin;

      float4 currentPixelToDisplay =
        tex2Dfetch(SamplerLuminanceWaveformFinal, currentFetchCoords);

      // using gamma 2 as intermediate gamma space
      currentPixelToDisplay.rgb *= currentPixelToDisplay.rgb;

      float alpha = min(_LUMINANCE_WAVEFORM_ALPHA / 100.f + currentPixelToDisplay.a, 1.f);

      MergeOverlay(Output.rgb,
                   currentPixelToDisplay.rgb,
                   _LUMINANCE_WAVEFORM_BRIGHTNESS,
                   alpha);
    }
  }

  {
    if (_TEXT_POSITION == TEXT_POSITION_TOP_LEFT)
    {
      if (all(pureCoordAsInt <= CurrentActiveOverlayArea))
      {
        float4 overlay = tex2Dfetch(SamplerTextOverlayAndLuminanceWaveformScale, pureCoordAsInt).rrrg;

        // using gamma 2 as intermediate gamma space
        overlay.rgb *= overlay.rgb;

        float alpha = min(_TEXT_BG_ALPHA / 100.f + overlay.a, 1.f);

        MergeOverlay(Output.rgb,
                     overlay.rgb,
                     _TEXT_BRIGHTNESS,
                     alpha);
      }
    }
    else
    {
      if (pureCoordAsInt.x >= CurrentActiveOverlayArea.x
       && pureCoordAsInt.y <= CurrentActiveOverlayArea.y)
      {
        float4 overlay = tex2Dfetch(SamplerTextOverlayAndLuminanceWaveformScale,
                                    int2(pureCoordAsInt.x - CurrentActiveOverlayArea.x, pureCoordAsInt.y)).rrrg;

        // using gamma 2 as intermediate gamma space
        overlay.rgb *= overlay.rgb;

        float alpha = min(_TEXT_BG_ALPHA / 100.f + overlay.a, 1.f);

        MergeOverlay(Output.rgb,
                     overlay.rgb,
                     _TEXT_BRIGHTNESS,
                     alpha);
      }
    }
  }

}


#ifdef _TESTY
technique lilium__hdr_and_sdr_analysis_TESTY
<
  ui_label = "Lilium's TESTY";
>
{
  pass PS_Testy
  {
    VertexShader       = VS_Testy;
     PixelShader       = PS_Testy;
    ClearRenderTargets = true;
  }
}
#endif //_TESTY

void CS_MakeOverlayBgAndWaveformScaleRedraw()
{
  tex1Dstore(StorageConsolidated, COORDS_CHECK_OVERLAY_REDRAW0, 3.f);
  tex1Dstore(StorageConsolidated, COORDS_LUMINANCE_WAVEFORM_LAST_SIZE_X, 0.f);
  return;
}

technique lilium__make_overlay_bg_redraw
<
  enabled = true;
  hidden  = true;
  timeout = 1;
>
{
  pass CS_MakeOverlayBgAndWaveformScaleRedraw
  {
    ComputeShader = CS_MakeOverlayBgAndWaveformScaleRedraw <1, 1>;
    DispatchSizeX = 1;
    DispatchSizeY = 1;
  }
}

technique lilium__hdr_and_sdr_analysis
<
#ifdef IS_HDR_CSP
  ui_label = "Lilium's HDR analysis";
#else
  ui_label = "Lilium's SDR analysis";
#endif
>
{

//Active Area
  pass PS_SetActiveArea
  {
    VertexShader = VS_PrepareSetActiveArea;
     PixelShader = PS_SetActiveArea;
  }


//Luminance Values
  pass PS_CalcNitsPerPixel
  {
    VertexShader = VS_PostProcess;
     PixelShader = PS_CalcNitsPerPixel;
    RenderTarget = TextureNitsValues;
  }


//CSP
#ifdef IS_HDR_CSP
  pass PS_CalcCsps
  {
    VertexShader = VS_PostProcess;
     PixelShader = PS_CalcCsps;
    RenderTarget = TextureCsps;
  }

  pass CS_CountCsps
  {
    ComputeShader = CS_CountCsps <WAVE64_THREAD_SIZE_X, WAVE64_THREAD_SIZE_Y>;
    DispatchSizeX = CSP_COUNTER_DISPATCH_X;
    DispatchSizeY = CSP_COUNTER_DISPATCH_Y;
  }
#endif


//Luminance Values
  pass CS_GetMaxAvgMinNits
  {
    ComputeShader = CS_GetMaxAvgMinNits <WAVE64_THREAD_SIZE_X, WAVE64_THREAD_SIZE_Y>;
    DispatchSizeX = GET_MAX_AVG_MIN_NITS_DISPATCH_X;
    DispatchSizeY = GET_MAX_AVG_MIN_NITS_DISPATCH_Y;
  }


//finalise things
  pass CS_Finalise
  {
    ComputeShader = CS_Finalise <1, 1>;
    DispatchSizeX = 1;
    DispatchSizeY = 1;
  }


//Waveform
  pass PS_ClearLuminanceWaveformTexture
  {
    VertexShader       = VS_PostProcessWithoutTexCoord;
     PixelShader       = PS_ClearLuminanceWaveformTexture;
    RenderTarget       = TextureLuminanceWaveform;
    ClearRenderTargets = true;
  }

//CIE
  pass PS_CopyCieBgAndOutlines
  {
    VertexShader = VS_PostProcess;
     PixelShader = PS_CopyCieBgAndOutlines;
    RenderTarget = TextureCieCurrent;
  }

//Waveform and CIE
  pass CS_RenderLuminanceWaveformAndGenerateCieDiagram
  {
    ComputeShader = CS_RenderLuminanceWaveformAndGenerateCieDiagram <WAVE64_THREAD_SIZE_X, WAVE64_THREAD_SIZE_Y>;
    DispatchSizeX = WAVE64_DISPATCH_X;
    DispatchSizeY = WAVE64_DISPATCH_Y;
  }

//Waveform
  pass PS_RenderLuminanceWaveformToScale
  {
    VertexShader = VS_PrepareRenderLuminanceWaveformToScale;
     PixelShader = PS_RenderLuminanceWaveformToScale;
    RenderTarget = TextureLuminanceWaveformFinal;
  }


  pass CS_DrawValuesToOverlay
  {
    ComputeShader = CS_DrawValuesToOverlay <1, 1>;
#ifdef IS_HDR_CSP
    DispatchSizeX = 70;
#else
    DispatchSizeX = 38;
#endif
    DispatchSizeY = 1;
  }

  pass PS_HdrAnalysis
  {
    VertexShader = VS_PrepareHdrAnalysis;
     PixelShader = PS_HdrAnalysis;
  }
}


#else //is hdr API and hdr colour space

ERROR_STUFF

technique lilium__hdr_and_sdr_analysis
<
#ifdef IS_HDR_CSP
  ui_label = "Lilium's HDR analysis (ERROR)";
#else
  ui_label = "Lilium's SDR analysis (ERROR)";
#endif
>
CS_ERROR

#endif //is hdr API and hdr colour space
