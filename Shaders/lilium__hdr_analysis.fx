#if ((__RENDERER__ >= 0xB000 && __RENDERER__ < 0x10000) \
  || __RENDERER__ >= 0x20000)


#include "lilium__include\hdr_analysis.fxh"
#include "lilium__include\draw_text_fix.fxh"

//#define _DEBUG
//#define _TESTY

#ifndef ENABLE_CLL_FEATURES
  #define ENABLE_CLL_FEATURES YES
#endif

#ifndef ENABLE_CIE_FEATURES
  #define ENABLE_CIE_FEATURES YES
#endif

#ifndef ENABLE_CSP_FEATURES
  #define ENABLE_CSP_FEATURES YES
#endif


#if (ENABLE_CLL_FEATURES == YES \
  || ENABLE_CSP_FEATURES == YES)
uniform float2 MOUSE_POSITION
<
  source = "mousepoint";
>;
#else
  static const float2 MOUSE_POSITION = float2(0.f, 0.f);
#endif

#if (ENABLE_CLL_FEATURES == YES)
uniform float2 NIT_PINGPONG0
<
  source    = "pingpong";
  min       = 0.f;
  max       = 1.75f;
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
  step      = 1.f;
  smoothing = 0.f;
>;
#else
  static const float2 NIT_PINGPONG0 = float2(0.f, 0.f);
  static const float2 NIT_PINGPONG1 = float2(0.f, 0.f);
  static const float2 NIT_PINGPONG2 = float2(0.f, 0.f);
#endif


#define CSP_SRGB_TEXT  "sRGB (sRGB transfer function / gamma 2.2 + BT.709 primaries)"
#define CSP_SCRGB_TEXT "scRGB (linear + BT.709 primaries)"
#define CSP_HDR10_TEXT "HDR10 (PQ + BT.2020 primaries)"
#define CSP_HLG_TEXT   "HLG (HLG + BT.2020 primaries)"

#if (BUFFER_COLOR_BIT_DEPTH == 8)
  #define BACK_BUFFER_FORMAT_TEXT "RGBA8_UNORM or BGRA8_UNORM"
#elif (BUFFER_COLOR_BIT_DEPTH == 10)
  // d3d11 and d3d12 only allow rgb10a2 to be used for HDR10
  #if (__RENDERER__ >= 0xB000 && __RENDERER__ < 0x10000)
    #define BACK_BUFFER_FORMAT_TEXT "RGB10A2_UNORM"
  #else
    #define BACK_BUFFER_FORMAT_TEXT "RGB10A2_UNORM or BGR10A2_UNORM"
  #endif
#elif (BUFFER_COLOR_BIT_DEPTH == 16)
  #define BACK_BUFFER_FORMAT_TEXT "RGBA16_FLOAT"
#else
  #define BACK_BUFFER_FORMAT_TEXT "unknown"
#endif


#define CSP_UNSET_TEXT "colour space unset! likely "

#if (BUFFER_COLOR_SPACE == CSP_SCRGB)
  #define BACK_BUFFER_COLOUR_SPACE_TEXT CSP_SCRGB_TEXT
#elif (BUFFER_COLOR_SPACE == CSP_HDR10)
  #define BACK_BUFFER_COLOUR_SPACE_TEXT CSP_HDR10_TEXT
#elif (BUFFER_COLOR_SPACE == CSP_HLG)
  #define BACK_BUFFER_COLOUR_SPACE_TEXT CSP_HLG_TEXT
#elif (BUFFER_COLOR_SPACE == CSP_SRGB \
    && defined(IS_POSSIBLE_SCRGB_BIT_DEPTH))
  #define BACK_BUFFER_COLOUR_SPACE_TEXT CSP_UNSET_TEXT CSP_SCRGB_TEXT
#elif (BUFFER_COLOR_SPACE == CSP_UNKNOWN \
    && defined(IS_POSSIBLE_SCRGB_BIT_DEPTH))
  #define BACK_BUFFER_COLOUR_SPACE_TEXT CSP_UNSET_TEXT CSP_SCRGB_TEXT
#elif (BUFFER_COLOR_SPACE == CSP_UNKNOWN \
    && defined(IS_POSSIBLE_HDR10_BIT_DEPTH))
  #define BACK_BUFFER_COLOUR_SPACE_TEXT CSP_UNSET_TEXT CSP_HDR10_TEXT
#elif (BUFFER_COLOR_SPACE == CSP_SRGB)
  #define BACK_BUFFER_COLOUR_SPACE_TEXT CSP_SRGB_TEXT
#else
  #define BACK_BUFFER_COLOUR_SPACE_TEXT "unknown"
#endif


#if (CSP_OVERRIDE == CSP_SRGB)
  #define CSP_OVERRIDE_TEXT CSP_SRGB_TEXT
#elif (CSP_OVERRIDE == CSP_SCRGB)
  #define CSP_OVERRIDE_TEXT CSP_SCRGB_TEXT
#elif (CSP_OVERRIDE == CSP_HDR10)
  #define CSP_OVERRIDE_TEXT CSP_HDR10_TEXT
#elif (CSP_OVERRIDE == CSP_HLG)
  #define CSP_OVERRIDE_TEXT CSP_HLG_TEXT
#else
  #define CSP_OVERRIDE_TEXT "unset"
#endif


#if (ACTUAL_COLOUR_SPACE == CSP_SRGB)
  #define ACTUAL_CSP_TEXT CSP_SRGB_TEXT
#elif (ACTUAL_COLOUR_SPACE == CSP_SCRGB)
  #define ACTUAL_CSP_TEXT CSP_SCRGB_TEXT
#elif (ACTUAL_COLOUR_SPACE == CSP_HDR10)
  #define ACTUAL_CSP_TEXT CSP_HDR10_TEXT
#elif (ACTUAL_COLOUR_SPACE == CSP_HLG)
  #define ACTUAL_CSP_TEXT CSP_HLG_TEXT
#else
  #define ACTUAL_CSP_TEXT "unknown"
#endif

#define INFO_TEXT \
  "detected back buffer format:       " BACK_BUFFER_FORMAT_TEXT       "\n" \
  "detected back buffer color space:  " BACK_BUFFER_COLOUR_SPACE_TEXT "\n" \
  "colour space overwritten to:       " CSP_OVERRIDE_TEXT             "\n" \
  "colour space in use by the shader: " ACTUAL_CSP_TEXT               "\n" \
                                                                      "\n" \
  "Use the \"Preprocessor definition\" CSP_OVERRIDE below to override "    \
  "the colour space in case the auto detection doesn't work."         "\n" \
  "Possible values are:"                                              "\n" \
  "- CSP_HDR10"                                                       "\n" \
  "- CSP_SCRGB"                                                       "\n" \
  "Hit ENTER to apply."


uniform int GLOBAL_INFO
<
  ui_category = "info";
  ui_label    = " ";
  ui_type     = "radio";
  ui_text     = INFO_TEXT;
>;

uniform float FONT_SIZE
<
  ui_category = "global";
  ui_label    = "font size";
  ui_type     = "slider";
  ui_min      = 30.f;
  ui_max      = 40.f;
  ui_step     = 1.f;
> = 30;

#define TEXT_POSITION_TOP_LEFT  0
#define TEXT_POSITION_TOP_RIGHT 1

uniform uint TEXT_POSITION
<
  ui_category = "global";
  ui_label    = "text position";
  ui_type     = "combo";
  ui_items    = "top left\0"
                "top right\0";
> = 0;

// CLL
#if (ENABLE_CLL_FEATURES == YES)
uniform bool SHOW_CLL_VALUES
<
  ui_category = "Content Light Level analysis";
  ui_label    = "show CLL values";
  ui_tooltip  = "shows max/avg/min Content Light Level";
> = true;

uniform bool SHOW_CLL_FROM_CURSOR
<
  ui_category = "Content Light Level analysis";
  ui_label    = "show CLL value from cursor position";
> = true;

uniform bool CLL_ROUNDING_WORKAROUND
<
  ui_category = "Content Light Level analysis";
  ui_label    = "work around rounding errors for displaying maxCLL";
  ui_tooltip  = "a value of 0.005 is added to the maxCLL value";
> = false;
#else
  static const bool SHOW_CLL_VALUES         = false;
  static const bool SHOW_CLL_FROM_CURSOR    = false;
  static const bool CLL_ROUNDING_WORKAROUND = false;
#endif

// CIE
#if (ENABLE_CIE_FEATURES == YES)
uniform bool SHOW_CIE
<
  ui_category = "CIE diagram visualisation";
  ui_label    = "show CIE diagram";
  ui_tooltip  = "change diagram type via the macro";
> = true;

#if (CIE_DIAGRAM == CIE_1931)
  static const uint CIE_BG_X = CIE_1931_BG_X;
  static const uint CIE_BG_Y = CIE_1931_BG_Y;
#else
  static const uint CIE_BG_X = CIE_1976_BG_X;
  static const uint CIE_BG_Y = CIE_1976_BG_Y;
#endif

uniform float CIE_DIAGRAM_BRIGHTNESS
<
  ui_category    = "CIE diagram visualisation";
  ui_label       = "CIE diagram brightness";
  ui_type        = "slider";
  ui_units = " nits";
  ui_min         = 10.f;
  ui_max         = 250.f;
  ui_step        = 0.5f;
> = 80.f;

uniform float CIE_DIAGRAM_SIZE
<
  ui_category    = "CIE diagram visualisation";
  ui_label       = "CIE diagram size (in %)";
  ui_type        = "slider";
  ui_units = "%%";
  ui_min         = 50.f;
  ui_max         = 100.f;
  ui_step        = 0.1f;
> = 100.f;
#else
  static const bool  SHOW_CIE               = false;
  static const float CIE_DIAGRAM_BRIGHTNESS = 0.f;
  static const float CIE_DIAGRAM_SIZE       = 0.f;
#endif

// Texture_CSPs
#if (ENABLE_CSP_FEATURES == YES)
uniform bool SHOW_CSPS
<
  ui_category = "Colour Space analysis";
  ui_label    = "show colour spaces used";
  ui_tooltip  = "in %";
> = true;

uniform bool SHOW_CSP_MAP
<
  ui_category = "Colour Space analysis";
  ui_label    = "show colour space map";
  ui_tooltip  = "        colours:\n"
                "black and white: BT.709\n"
                "           teal: DCI-P3\n"
                "         yellow: BT.2020\n"
                "           blue: AP1\n"
                "            red: AP0\n"
                "           pink: invalid";
> = false;

uniform bool SHOW_CSP_FROM_CURSOR
<
  ui_category = "Colour Space analysis";
  ui_label    = "show colour space from cursor position";
> = true;
#else
  static const bool SHOW_CSPS            = false;
  static const bool SHOW_CSP_MAP         = false;
  static const bool SHOW_CSP_FROM_CURSOR = false;
#endif

// heatmap
#if (ENABLE_CLL_FEATURES == YES)
uniform bool SHOW_HEATMAP
<
  ui_category = "Heatmap visualisation";
  ui_label    = "show heatmap";
  ui_tooltip  = "         colours:   10000 nits:   1000 nits:\n"
                " black and white:       0-  100       0- 100\n"
                "  teal to green:      100-  203     100- 203\n"
                " green to yellow:     203-  400     203- 400\n"
                "yellow to red:        400- 1000     400- 600\n"
                "   red to pink:      1000- 4000     600- 800\n"
                "  pink to blue:      4000-10000     800-1000";
> = false;

uniform uint HEATMAP_CUTOFF_POINT
<
  ui_category = "Heatmap visualisation";
  ui_label    = "heatmap cutoff point";
  ui_type     = "combo";
  ui_items    = "10000 nits\0"
                " 1000 nits\0";
> = 0;

uniform float HEATMAP_BRIGHTNESS
<
  ui_category    = "Heatmap visualisation";
  ui_label       = "heatmap brightness (in nits)";
  ui_type        = "slider";
  ui_units = " nits";
  ui_min         = 10.f;
  ui_max         = 250.f;
  ui_step        = 0.5f;
> = 80.f;

uniform bool SHOW_BRIGHTNESS_HISTOGRAM
<
  ui_category = "Brightness histogram";
  ui_label    = "show brightness histogram";
  ui_tooltip  = "bightness histogram paid for by Aemony";
> = true;

uniform float BRIGHTNESS_HISTOGRAM_BRIGHTNESS
<
  ui_category    = "Brightness histogram";
  ui_label       = "brightness histogram brightness (in nits)";
  ui_type        = "slider";
  ui_units = " nits";
  ui_min         = 10.f;
  ui_max         = 250.f;
  ui_step        = 0.5f;
> = 80.f;

uniform float BRIGHTNESS_HISTOGRAM_SIZE
<
  ui_category    = "Brightness histogram";
  ui_label       = "brightness histogram size (in %)";
  ui_type        = "slider";
  ui_units = "%%";
  ui_min         = 50.f;
  ui_max         = 100.f;
  ui_step        = 0.1f;
> = 70.f;

// highlight a certain nit range
uniform bool HIGHLIGHT_NIT_RANGE
<
  ui_category = "Highlight brightness range visualisation";
  ui_label    = "enable highlighting brightness levels in a certain range";
  ui_tooltip  = "in nits";
> = false;

uniform float HIGHLIGHT_NIT_RANGE_START_POINT
<
  ui_category  = "Highlight brightness range visualisation";
  ui_label     = "brightness highlight range start point (in nits)";
  ui_type      = "drag";
  ui_units = " nits";
  ui_min       = 0.f;
  ui_max       = 10000.f;
  ui_step      = 0.001f;
> = 0.f;

uniform float HIGHLIGHT_NIT_RANGE_END_POINT
<
  ui_category  = "Highlight brightness range visualisation";
  ui_label     = "brightness highlight range end point (in nits)";
  ui_type      = "drag";
  ui_units = " nits";
  ui_min       = 0.f;
  ui_max       = 10000.f;
  ui_step      = 0.001f;
> = 0.f;

uniform float HIGHLIGHT_NIT_RANGE_BRIGHTNESS
<
  ui_category    = "Highlight brightness range visualisation";
  ui_label       = "brightness highlight range brightness (in nits)";
  ui_type        = "slider";
  ui_units = " nits";
  ui_min         = 10.f;
  ui_max         = 250.f;
  ui_step        = 0.5f;
> = 80.f;

// draw pixels as black depending on their nits
uniform bool DRAW_ABOVE_NITS_AS_BLACK
<
  ui_category = "Draw certain brightness levels as black";
  ui_label    = "enable drawing above this brightness as black";
> = false;

uniform float ABOVE_NITS_AS_BLACK
<
  ui_category  = "Draw certain brightness levels as black";
  ui_label     = "draw above this brightness as black (in nits)";
  ui_type      = "drag";
  ui_units = " nits";
  ui_min       = 0.f;
  ui_max       = 10000.f;
  ui_step      = 0.001f;
> = 10000.f;

uniform bool DRAW_BELOW_NITS_AS_BLACK
<
  ui_category = "Draw certain brightness levels as black";
  ui_label    = "enable drawing below this brightness as black";
> = false;

uniform float BELOW_NITS_AS_BLACK
<
  ui_category  = "Draw certain brightness levels as black";
  ui_label     = "draw below this brightness as black (in nits)";
  ui_type      = "drag";
  ui_units = " nits";
  ui_min       = 0.f;
  ui_max       = 10000.f;
  ui_step      = 1.f;
> = 0.f;
#else
  static const bool  SHOW_HEATMAP                    = false;
  static const uint  HEATMAP_CUTOFF_POINT            = 0;
  static const float HEATMAP_BRIGHTNESS              = 0.f;
  static const bool  SHOW_BRIGHTNESS_HISTOGRAM       = false;
  static const float BRIGHTNESS_HISTOGRAM_BRIGHTNESS = 0.f;
  static const float BRIGHTNESS_HISTOGRAM_SIZE       = 0.f;
  static const bool  HIGHLIGHT_NIT_RANGE             = false;
  static const float HIGHLIGHT_NIT_RANGE_START_POINT = 0.f;
  static const float HIGHLIGHT_NIT_RANGE_END_POINT   = 0.f;
  static const float HIGHLIGHT_NIT_RANGE_BRIGHTNESS  = 0.f;
  static const bool  DRAW_ABOVE_NITS_AS_BLACK        = false;
  static const float ABOVE_NITS_AS_BLACK             = 0.f;
  static const bool  DRAW_BELOW_NITS_AS_BLACK        = false;
  static const float BELOW_NITS_AS_BLACK             = 0.f;
#endif

#ifdef _TESTY
uniform bool ENABLE_TEST_THINGY
<
  ui_category = "TESTY";
  ui_label    = "enable test thingy";
> = false;

uniform float TEST_THINGY
<
  ui_category = "TESTY";
  ui_label    = "test thingy";
  ui_type     = "drag";
  ui_min      = -125.f;
  ui_max      = 125.f;
  ui_step     = 0.001f;
> = 0.f;
#endif


//void draw_maxCLL(float4 position : POSITION, float2 txcoord : TEXCOORD) : COLOR
//void draw_maxCLL(float4 VPos : SV_Position, float2 TexCoord : TEXCOORD, out float4 fragment : SV_Target0)
//{
//  const uint int_maxCLL = int(round(maxCLL));
//  uint digit1;
//  uint digit2;
//  uint digit3;
//  uint digit4;
//  uint digit5;
//  
//  if (maxCLL < 10)
//  {
//    digit1 = 0;
//    digit2 = 0;
//    digit3 = 0;
//    digit4 = 0;
//    digit5 = int_maxCLL;
//  }
//  else if (maxCLL < 100)
//  {
//    digit1 = 0;
//    digit2 = 0;
//    digit3 = 0;
//    digit4 = int_maxCLL / 10;
//    digit5 = int_maxCLL % 10;
//  }
//  else if (maxCLL < 1000)
//  {
//    digit1 = 0;
//    digit2 = 0;
//    digit3 = int_maxCLL / 100;
//    digit4 = (int_maxCLL % 100) / 10;
//    digit5 = (int_maxCLL % 10);
//  }
//  else if (maxCLL < 10000)
//  {
//    digit1 = 0;
//    digit2 = int_maxCLL / 1000;
//    digit3 = (int_maxCLL % 1000) / 100;
//    digit4 = (int_maxCLL % 100) / 10;
//    digit5 = (int_maxCLL % 10);
//  }
//  else
//  {
//    digit1 = int_maxCLL / 10000;
//    digit2 = (int_maxCLL % 10000) / 1000;
//    digit3 = (int_maxCLL % 1000) / 100;
//    digit4 = (int_maxCLL % 100) / 10;
//    digit5 = (int_maxCLL % 10);
//  }

  //res += tex2D(samplerText, (frac(uv) + float2(index % 14.0, trunc(index / 14.0))) /
  //            float2(_DRAWTEXT_GRID_X, _DRAWTEXT_GRID_Y)).x;

//  float4 hud = tex2D(samplerNumbers, TexCoord);
//  fragment = lerp(tex2Dfetch(ReShade::BackBuffer, TexCoord), hud, 1.f);
//
//}

#ifdef _TESTY
void Testy(
      float4 VPos     : SV_Position,
      float2 TexCoord : TEXCOORD,
  out float4 Output   : SV_Target0)
{
  if(ENABLE_TEST_THINGY == true)
  {
    const float xTest = TEST_THINGY;
    const float xxx = BUFFER_WIDTH  / 2.f - 100.f;
    const float xxe = (BUFFER_WIDTH  - xxx);
    const float yyy = BUFFER_HEIGHT / 2.f - 100.f;
    const float yye = (BUFFER_HEIGHT - yyy);
    if (TexCoord.x > xxx / BUFFER_WIDTH
     && TexCoord.x < xxe / BUFFER_WIDTH
     && TexCoord.y > yyy / BUFFER_HEIGHT
     && TexCoord.y < yye / BUFFER_HEIGHT)
      Output = float4(0.f, xTest, 0.f, 1.f);
    else
      Output = float4(0.f, 0.f, 0.f, 0.f);
  }
  else
    Output = float4(tex2D(ReShade::BackBuffer, TexCoord).rgb, 1.f);
}
#endif

///text stuff

// max/avg/min CLL
static const uint text_maxCLL[26] = { __m, __a, __x, __C, __L, __L, __Colon, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __n, __i, __t, __s };
static const uint text_avgCLL[26] = { __a, __v, __g, __C, __L, __L, __Colon, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __n, __i, __t, __s };
static const uint text_minCLL[26] = { __m, __i, __n, __C, __L, __L, __Colon, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __n, __i, __t, __s };

// CLL from cursor position
static const uint text_cursorCLL[28] = { __c, __u, __r, __s, __o, __r, __C, __L, __L, __Colon, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __n, __i, __t, __s };

static const uint text_X[2] = { __x, __Colon };
static const uint text_Y[2] = { __y, __Colon };

// RGB value from cursor position
static const uint text_R[2] = { __R, __Colon };
static const uint text_G[2] = { __G, __Colon };
static const uint text_B[2] = { __B, __Colon };

static const uint text_signNegative[1] = { __Minus };

#if (ACTUAL_COLOUR_SPACE == CSP_HDR10 \
  || ACTUAL_COLOUR_SPACE == CSP_HLG   \
  || ACTUAL_COLOUR_SPACE == CSP_SRGB)

static const uint RGB_Text_Offset = 4;

#else

static const uint RGB_Text_Offset = 10;

#endif

// colour space percentages
static const uint text_BT709[18]   = { __B, __T, __Dot, __7,     __0,     __9,     __Colon, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Percent };
static const uint text_DCI_P3[18]  = { __D, __C, __I,   __Minus, __P,     __3,     __Colon, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Percent };
static const uint text_BT2020[18]  = { __B, __T, __Dot, __2,     __0,     __2,     __0,     __Colon, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Percent };
static const uint text_AP1[18]     = { __A, __P, __1,   __Colon, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Percent };
static const uint text_AP0[18]     = { __A, __P, __0,   __Colon, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Percent };
static const uint text_invalid[18] = { __i, __n, __v,   __a,     __l,     __i,     __d,     __Colon, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Space, __Percent };

// colour space from cursor position
static const uint text_cursor_BT709[17]   = { __c, __u, __r, __s, __o, __r, __C, __S, __P, __Colon, __Space, __B, __T, __Dot, __7,     __0, __9 };
static const uint text_cursor_DCI_P3[17]  = { __c, __u, __r, __s, __o, __r, __C, __S, __P, __Colon, __Space, __D, __C, __I,   __Minus, __P, __3 };
static const uint text_cursor_BT2020[18]  = { __c, __u, __r, __s, __o, __r, __C, __S, __P, __Colon, __Space, __B, __T, __Dot, __2,     __0, __2, __0 };
static const uint text_cursor_AP1[14]     = { __c, __u, __r, __s, __o, __r, __C, __S, __P, __Colon, __Space, __A, __P, __1 };
static const uint text_cursor_AP0[14]     = { __c, __u, __r, __s, __o, __r, __C, __S, __P, __Colon, __Space, __A, __P, __0 };
static const uint text_cursor_invalid[18] = { __c, __u, __r, __s, __o, __r, __C, __S, __P, __Colon, __Space, __i, __n, __v,   __a,     __l, __i, __d };

// colour space not supported
static const uint text_Error[26] = { __C, __O, __L, __O, __U, __R, __Space, __S, __P, __A, __C, __E, __Space,
                                     __N, __O, __T, __Space,
                                     __S, __U, __P, __P, __O, __R, __T, __E, __D};


void HDR_analysis(
      float4 VPos     : SV_Position,
      float2 TexCoord : TEXCOORD,
  out float4 Output   : SV_Target0)
{
  const float3 input = tex2D(ReShade::BackBuffer, TexCoord).rgb;

  Output = float4(input, 1.f);


#if (ACTUAL_COLOUR_SPACE == CSP_SCRGB \
  || ACTUAL_COLOUR_SPACE == CSP_HDR10 \
  || ACTUAL_COLOUR_SPACE == CSP_HLG   \
  || ACTUAL_COLOUR_SPACE == CSP_PS5)

  //float maxCLL = float(uint(tex2Dfetch(Sampler_Max_Avg_Min_CLL_Values, int2(0, 0)).r*10000.f+0.5)/100)/100.f;
  //float avgCLL = float(uint(tex2Dfetch(Sampler_Max_Avg_Min_CLL_Values, int2(1, 0)).r*10000.f+0.5)/100)/100.f;
  //float minCLL = float(uint(tex2Dfetch(Sampler_Max_Avg_Min_CLL_Values, int2(2, 0)).r*10000.f+0.5)/100)/100.f;

  const float fontWidth = FONT_SIZE / 2.f;

  static const float textOffset = TEXT_POSITION == TEXT_POSITION_TOP_LEFT ? 0.f
                                : BUFFER_WIDTH - (fontWidth * 28 + 10);

  if (SHOW_CSP_MAP
   || SHOW_HEATMAP
   || HIGHLIGHT_NIT_RANGE)
  {
    float pixelCLL = tex2D(Sampler_CLL_Values, TexCoord).r;

#if (ENABLE_CSP_FEATURES == YES)

    if (SHOW_CSP_MAP)
    {
      Output = float4(Create_CSP_Map(tex2D(Sampler_CSPs, TexCoord).r * 255.f,
                                     pixelCLL), 1.f);
    }

#endif

#if (ENABLE_CLL_FEATURES == YES)

    if (SHOW_HEATMAP)
    {
      Output = float4(Heatmap_RGB_Values(pixelCLL,
                                         HEATMAP_CUTOFF_POINT,
                                         HEATMAP_BRIGHTNESS,
                                         false), 1.f);
    }

    if (HIGHLIGHT_NIT_RANGE)
    {
      float pingpong0 = NIT_PINGPONG0.x + 0.25f;
      float pingpong1 = NIT_PINGPONG1.y == 1 ? NIT_PINGPONG1.x
                                             : 6.f - NIT_PINGPONG1.x;

      if (pixelCLL >= HIGHLIGHT_NIT_RANGE_START_POINT
       && pixelCLL <= HIGHLIGHT_NIT_RANGE_END_POINT
       && pingpong0 >= 1.f)
      {
        float3 out3;
        float breathing = saturate(pingpong0 - 1.f);
        //float breathing = 1.f;

        if (pingpong1 >= 0.f
         && pingpong1 <= 1.f)
        {
          out3 = float3(1.f, NIT_PINGPONG2.x, 0.f);
        }
        else if (pingpong1 > 1.f
              && pingpong1 <= 2.f)
        {
          out3 = float3(NIT_PINGPONG2.x, 1.f, 0.f);
        }
        else if (pingpong1 > 2.f
              && pingpong1 <= 3.f)
        {
          out3 = float3(0.f, 1.f, NIT_PINGPONG2.x);
        }
        else if (pingpong1 > 3.f
              && pingpong1 <= 4.f)
        {
          out3 = float3(0.f, NIT_PINGPONG2.x, 1.f);
        }
        else if (pingpong1 > 4.f
              && pingpong1 <= 5.f)
        {
          out3 = float3(NIT_PINGPONG2.x, 0.f, 1.f);
        }
        else if (pingpong1 > 5.f
              && pingpong1 <= 6.f)
        {
          out3 = float3(1.f, 0.f, NIT_PINGPONG2.x);
        }

        out3 *= breathing * HIGHLIGHT_NIT_RANGE_BRIGHTNESS;

#if (ACTUAL_COLOUR_SPACE == CSP_SCRGB)

        out3 = Csp::Map::Bt709Into::Scrgb(out3);

#elif (ACTUAL_COLOUR_SPACE == CSP_HDR10)

        out3 = Csp::Map::Bt709Into::Hdr10(out3);

#elif (ACTUAL_COLOUR_SPACE == CSP_HLG)

        out3 = Csp::Map::Bt709Into::Hlg(out3);

#elif (ACTUAL_COLOUR_SPACE == CSP_PS5)

        out3 = Csp::Map::Bt709Into::Ps5(out3);

#endif

        if (breathing > 0.f)
        {
          //Output = float4(out3, 1.f);
          Output = float4(lerp(Output.rgb, out3, breathing), 1.f);
        }
      }
    }

#endif
  }

#if (ENABLE_CLL_FEATURES == YES)

  if (DRAW_ABOVE_NITS_AS_BLACK)
  {
    float pixelCLL = tex2D(Sampler_CLL_Values, TexCoord).r;
    if (pixelCLL > ABOVE_NITS_AS_BLACK)
    {
      Output = (0.f, 0.f, 0.f, 0.f);
    }
  }
  if (DRAW_BELOW_NITS_AS_BLACK)
  {
    float pixelCLL = tex2D(Sampler_CLL_Values, TexCoord).r;
    if (pixelCLL < BELOW_NITS_AS_BLACK)
    {
      Output = (0.f, 0.f, 0.f, 0.f);
    }
  }

#endif

#if (ENABLE_CIE_FEATURES == YES)

  if (SHOW_CIE)
  {
    uint current_x_coord = TexCoord.x * BUFFER_WIDTH;  // expand to actual pixel values
    uint current_y_coord = TexCoord.y * BUFFER_HEIGHT; // ^

    const int2 textureDisplaySize =
      int2(round(float(CIE_BG_X) * CIE_DIAGRAM_SIZE / 100.f),
           round(float(CIE_BG_Y) * CIE_DIAGRAM_SIZE / 100.f));

    // draw the diagram in the bottom left corner
    if (current_x_coord <  textureDisplaySize.x
     && current_y_coord >= (BUFFER_HEIGHT - textureDisplaySize.y))
    {
      // get coords for the sampler
      float2 currentSamplerCoords = float2(
        (current_x_coord + 0.5f) / textureDisplaySize.x,
        (current_y_coord - (BUFFER_HEIGHT - textureDisplaySize.y) + 0.5f) / textureDisplaySize.y);

#if (CIE_DIAGRAM == CIE_1931)
      float3 currentPixelToDisplay = pow(tex2D(Sampler_CIE_1931_Current, currentSamplerCoords).rgb, 2.2f);
#else
      float3 currentPixelToDisplay = pow(tex2D(Sampler_CIE_1976_Current, currentSamplerCoords).rgb, 2.2f);
#endif

#if (ACTUAL_COLOUR_SPACE == CSP_SCRGB)

      Output = float4(Csp::Map::Bt709Into::Scrgb(currentPixelToDisplay * CIE_DIAGRAM_BRIGHTNESS), 1.f);

#elif (ACTUAL_COLOUR_SPACE == CSP_HDR10)

      Output = float4(Csp::Map::Bt709Into::Hdr10(currentPixelToDisplay * CIE_DIAGRAM_BRIGHTNESS), 1.f);

#elif (ACTUAL_COLOUR_SPACE == CSP_HLG)

      Output = float4(Csp::Map::Bt709Into::Hlg(currentPixelToDisplay * CIE_DIAGRAM_BRIGHTNESS), 1.f);

#elif (ACTUAL_COLOUR_SPACE == CSP_PS5)

      Output = float4(Csp::Map::Bt709Into::Ps5(currentPixelToDisplay * CIE_DIAGRAM_BRIGHTNESS), 1.f);

#endif
    }
  }

#endif

#if (ENABLE_CLL_FEATURES == YES)

  if (SHOW_CLL_VALUES)
  {
    float maxCLL_show = tex2Dfetch(Sampler_Consolidated, COORDS_SHOW_MAXCLL).r;
    float avgCLL_show = tex2Dfetch(Sampler_Consolidated, COORDS_SHOW_AVGCLL).r;
    float minCLL_show = tex2Dfetch(Sampler_Consolidated, COORDS_SHOW_MINCLL).r;

    //float maxCLL_show = tex2Dfetch(Sampler_Max_Avg_Min_CLL_Values, int2(0, 0)).r;
    //float avgCLL_show = tex2Dfetch(Sampler_Max_Avg_Min_CLL_Values, int2(1, 0)).r;
    //float minCLL_show = tex2Dfetch(Sampler_Max_Avg_Min_CLL_Values, int2(2, 0)).r;

    if (CLL_ROUNDING_WORKAROUND)
    {
      maxCLL_show += 0.005f;
      //avgCLL_show += 0.005f;
      //minCLL_show += 0.005f;
    }

    DrawTextString(float2(0.f + textOffset, FONT_SIZE * 0), FONT_SIZE, 1, TexCoord, text_maxCLL, 26, Output, FONT_BRIGHTNESS);
    DrawTextString(float2(0.f + textOffset, FONT_SIZE * 1), FONT_SIZE, 1, TexCoord, text_avgCLL, 26, Output, FONT_BRIGHTNESS);
    DrawTextString(float2(0.f + textOffset, FONT_SIZE * 2), FONT_SIZE, 1, TexCoord, text_minCLL, 26, Output, FONT_BRIGHTNESS);

    DrawTextDigit(float2(fontWidth * 14 + textOffset, FONT_SIZE * 0), FONT_SIZE, 1, TexCoord, 6, maxCLL_show, Output, FONT_BRIGHTNESS);
    DrawTextDigit(float2(fontWidth * 14 + textOffset, FONT_SIZE * 1), FONT_SIZE, 1, TexCoord, 6, avgCLL_show, Output, FONT_BRIGHTNESS);
    DrawTextDigit(float2(fontWidth * 14 + textOffset, FONT_SIZE * 2), FONT_SIZE, 1, TexCoord, 6, minCLL_show, Output, FONT_BRIGHTNESS);
  }

#endif

  if (SHOW_CLL_FROM_CURSOR || SHOW_CSP_FROM_CURSOR)
  {
    float mousePositionX = clamp(MOUSE_POSITION.x, 0.f, BUFFER_WIDTH  - 1);
    float mousePositionY = clamp(MOUSE_POSITION.y, 0.f, BUFFER_HEIGHT - 1);
    int2  mouseXY        = int2(mousePositionX, mousePositionY);

#if (ENABLE_CLL_FEATURES == YES)

    if (SHOW_CLL_FROM_CURSOR)
    {
      float cursorCLL = tex2Dfetch(Sampler_CLL_Values, mouseXY).r;

      DrawTextString(float2(fontWidth * 8 + textOffset, FONT_SIZE * 4), FONT_SIZE, 1, TexCoord, text_X, 2, Output, FONT_BRIGHTNESS);
      DrawTextString(float2(fontWidth * 8 + textOffset, FONT_SIZE * 5), FONT_SIZE, 1, TexCoord, text_Y, 2, Output, FONT_BRIGHTNESS);

      DrawTextDigit(float2(fontWidth * 16 + textOffset, FONT_SIZE * 4), FONT_SIZE, 1, TexCoord, -1, mousePositionX, Output, FONT_BRIGHTNESS);
      DrawTextDigit(float2(fontWidth * 16 + textOffset, FONT_SIZE * 5), FONT_SIZE, 1, TexCoord, -1, mousePositionY, Output, FONT_BRIGHTNESS);

      DrawTextString(float2(0.f + textOffset, FONT_SIZE * 6), FONT_SIZE, 1, TexCoord, text_cursorCLL, 28, Output, FONT_BRIGHTNESS);

      DrawTextDigit(float2(fontWidth * 16 + textOffset, FONT_SIZE * 6), FONT_SIZE, 1, TexCoord, 6, cursorCLL, Output, FONT_BRIGHTNESS);

      float3 cursorRGB = tex2Dfetch(ReShade::BackBuffer, mouseXY).rgb;

#if (ACTUAL_COLOUR_SPACE == CSP_SCRGB \
  || ACTUAL_COLOUR_SPACE == CSP_PS5)

      const bool cursorRIsNeg = cursorRGB.r >= 0.f ? false
                                                   : true;
      const bool cursorGIsNeg = cursorRGB.g >= 0.f ? false
                                                   : true;
      const bool cursorBIsNeg = cursorRGB.b >= 0.f ? false
                                                   : true;

      cursorRGB = abs(cursorRGB);

#endif

      DrawTextString(float2(0.f + textOffset, FONT_SIZE *  8), FONT_SIZE, 1, TexCoord, text_R, 2, Output, FONT_BRIGHTNESS);
      DrawTextString(float2(0.f + textOffset, FONT_SIZE *  9), FONT_SIZE, 1, TexCoord, text_G, 2, Output, FONT_BRIGHTNESS);
      DrawTextString(float2(0.f + textOffset, FONT_SIZE * 10), FONT_SIZE, 1, TexCoord, text_B, 2, Output, FONT_BRIGHTNESS);

      DrawTextDigit(float2(fontWidth * RGB_Text_Offset + textOffset, FONT_SIZE *  8), FONT_SIZE, 1, TexCoord, 8, cursorRGB.r, Output, FONT_BRIGHTNESS);
      DrawTextDigit(float2(fontWidth * RGB_Text_Offset + textOffset, FONT_SIZE *  9), FONT_SIZE, 1, TexCoord, 8, cursorRGB.g, Output, FONT_BRIGHTNESS);
      DrawTextDigit(float2(fontWidth * RGB_Text_Offset + textOffset, FONT_SIZE * 10), FONT_SIZE, 1, TexCoord, 8, cursorRGB.b, Output, FONT_BRIGHTNESS);

#if (ACTUAL_COLOUR_SPACE == CSP_SCRGB \
  || ACTUAL_COLOUR_SPACE == CSP_PS5)

      if (cursorRIsNeg) {
        const float offset = cursorRGB.r <    10.f ? fontWidth * 8
                           : cursorRGB.r <   100.f ? fontWidth * 7
                           : cursorRGB.r <  1000.f ? fontWidth * 6
                           : cursorRGB.r < 10000.f ? fontWidth * 5
                                                   : fontWidth * 4;
        DrawTextString(float2(offset + textOffset, FONT_SIZE *  8), FONT_SIZE, 1, TexCoord, text_signNegative, 1, Output, FONT_BRIGHTNESS);
      }
      if (cursorGIsNeg) {
        const float offset = cursorRGB.g <    10.f ? fontWidth * 8
                           : cursorRGB.g <   100.f ? fontWidth * 7
                           : cursorRGB.g <  1000.f ? fontWidth * 6
                           : cursorRGB.g < 10000.f ? fontWidth * 5
                                                   : fontWidth * 4;
        DrawTextString(float2(offset + textOffset, FONT_SIZE *  9), FONT_SIZE, 1, TexCoord, text_signNegative, 1, Output, FONT_BRIGHTNESS);
      }
      if (cursorBIsNeg) {
        const float offset = cursorRGB.b <    10.f ? fontWidth * 8
                           : cursorRGB.b <   100.f ? fontWidth * 7
                           : cursorRGB.b <  1000.f ? fontWidth * 6
                           : cursorRGB.b < 10000.f ? fontWidth * 5
                                                   : fontWidth * 4;
        DrawTextString(float2(offset + textOffset, FONT_SIZE * 10), FONT_SIZE, 1, TexCoord, text_signNegative, 1, Output, FONT_BRIGHTNESS);
      }

#endif

    }

#endif

#if (ENABLE_CSP_FEATURES == YES)

    if (SHOW_CSP_FROM_CURSOR)
    {
      uint cursorCSP = tex2Dfetch(Sampler_CSPs, mouseXY).r * 255.f;

      switch(cursorCSP)
      {

#if (ACTUAL_COLOUR_SPACE == CSP_SRGB)

  #define CURSOR_CLL_TEXT_POS 14

#elif (ACTUAL_COLOUR_SPACE == CSP_HDR10 \
    || ACTUAL_COLOUR_SPACE == CSP_HLG)

  #define CURSOR_CLL_TEXT_POS 16

#else

  #define CURSOR_CLL_TEXT_POS 19

#endif

        case 0:
        {
          DrawTextString(float2(0.f + textOffset, FONT_SIZE * CURSOR_CLL_TEXT_POS), FONT_SIZE, 1, TexCoord, text_cursor_BT709,   17, Output, FONT_BRIGHTNESS);
        } break;
        case 1:
        {
          DrawTextString(float2(0.f + textOffset, FONT_SIZE * CURSOR_CLL_TEXT_POS), FONT_SIZE, 1, TexCoord, text_cursor_DCI_P3,  17, Output, FONT_BRIGHTNESS);
        } break;
        case 2:
        {
          DrawTextString(float2(0.f + textOffset, FONT_SIZE * CURSOR_CLL_TEXT_POS), FONT_SIZE, 1, TexCoord, text_cursor_BT2020,  18, Output, FONT_BRIGHTNESS);
        } break;
        case 3:
        {
          DrawTextString(float2(0.f + textOffset, FONT_SIZE * CURSOR_CLL_TEXT_POS), FONT_SIZE, 1, TexCoord, text_cursor_AP1,     14, Output, FONT_BRIGHTNESS);
        } break;
        case 4:
        {
          DrawTextString(float2(0.f + textOffset, FONT_SIZE * CURSOR_CLL_TEXT_POS), FONT_SIZE, 1, TexCoord, text_cursor_AP0,     14, Output, FONT_BRIGHTNESS);
        } break;
        default:
        {
          DrawTextString(float2(0.f + textOffset, FONT_SIZE * CURSOR_CLL_TEXT_POS), FONT_SIZE, 1, TexCoord, text_cursor_invalid, 18, Output, FONT_BRIGHTNESS);
        } break;

#undef CURSOR_CLL_TEXT_POS

      }
    }

#endif
  }

#if (ENABLE_CSP_FEATURES == YES)

  if (SHOW_CSPS)
  {

#if (ACTUAL_COLOUR_SPACE == CSP_SRGB)

    float precentage_BT709  = 100.f;

#else

    float precentage_BT709  = tex2Dfetch(Sampler_Consolidated, COORDS_SHOW_PERCENTAGE_BT709).r;
    float precentage_DCI_P3 = tex2Dfetch(Sampler_Consolidated, COORDS_SHOW_PERCENTAGE_DCI_P3).r;
    float precentage_BT2020 = tex2Dfetch(Sampler_Consolidated, COORDS_SHOW_PERCENTAGE_BT2020).r;
    //float precentage_BT709  = tex2Dfetch(Sampler_CSP_Counter_Final, int2(0, IS_CSP_BT709)).r  * 100.0001f;
    //float precentage_DCI_P3 = tex2Dfetch(Sampler_CSP_Counter_Final, int2(0, IS_CSP_DCI_P3)).r * 100.0001f;
    //float precentage_BT2020 = tex2Dfetch(Sampler_CSP_Counter_Final, int2(0, IS_CSP_BT2020)).r * 100.0001f;

#endif

#if (ACTUAL_COLOUR_SPACE != CSP_HDR10 \
  && ACTUAL_COLOUR_SPACE != CSP_HLG)

    float precentage_AP1     = tex2Dfetch(Sampler_Consolidated, COORDS_SHOW_PERCENTAGE_AP1).r;
    float precentage_AP0     = tex2Dfetch(Sampler_Consolidated, COORDS_SHOW_PERCENTAGE_AP0).r;
    float precentage_invalid = tex2Dfetch(Sampler_Consolidated, COORDS_SHOW_PERCENTAGE_INVALID).r;
    //float precentage_AP1     = tex2Dfetch(Sampler_CSP_Counter_Final, int2(0, IS_CSP_AP1)).r     * 100.0001f;
    //float precentage_AP0     = tex2Dfetch(Sampler_CSP_Counter_Final, int2(0, IS_CSP_AP0)).r     * 100.0001f;
    //float precentage_invalid = tex2Dfetch(Sampler_CSP_Counter_Final, int2(0, IS_CSP_INVALID)).r * 100.0001f;

#endif

    DrawTextString(float2(0.f + textOffset, FONT_SIZE * 12), FONT_SIZE, 1, TexCoord, text_BT709,   18, Output, FONT_BRIGHTNESS);

#if (ACTUAL_COLOUR_SPACE != CSP_SRGB)

    DrawTextString(float2(0.f + textOffset, FONT_SIZE * 13), FONT_SIZE, 1, TexCoord, text_DCI_P3,  18, Output, FONT_BRIGHTNESS);
    DrawTextString(float2(0.f + textOffset, FONT_SIZE * 14), FONT_SIZE, 1, TexCoord, text_BT2020,  18, Output, FONT_BRIGHTNESS);

#endif

#if (ACTUAL_COLOUR_SPACE != CSP_HDR10 \
  && ACTUAL_COLOUR_SPACE != CSP_HLG \
  && ACTUAL_COLOUR_SPACE != CSP_SRGB)

    DrawTextString(float2(0.f + textOffset, FONT_SIZE * 15), FONT_SIZE, 1, TexCoord, text_AP1,     18, Output, FONT_BRIGHTNESS);
    DrawTextString(float2(0.f + textOffset, FONT_SIZE * 16), FONT_SIZE, 1, TexCoord, text_AP0,     18, Output, FONT_BRIGHTNESS);
    DrawTextString(float2(0.f + textOffset, FONT_SIZE * 17), FONT_SIZE, 1, TexCoord, text_invalid, 18, Output, FONT_BRIGHTNESS);

#endif

    DrawTextDigit(float2(FONT_SIZE * 6 + textOffset, FONT_SIZE * 12), FONT_SIZE, 1, TexCoord, 4, precentage_BT709,  Output, FONT_BRIGHTNESS);
#if (ACTUAL_COLOUR_SPACE != CSP_SRGB)

    DrawTextDigit(float2(FONT_SIZE * 6 + textOffset, FONT_SIZE * 13), FONT_SIZE, 1, TexCoord, 4, precentage_DCI_P3, Output, FONT_BRIGHTNESS);
    DrawTextDigit(float2(FONT_SIZE * 6 + textOffset, FONT_SIZE * 14), FONT_SIZE, 1, TexCoord, 4, precentage_BT2020, Output, FONT_BRIGHTNESS);
#endif

#if (ACTUAL_COLOUR_SPACE != CSP_HDR10 \
  && ACTUAL_COLOUR_SPACE != CSP_HLG   \
  && ACTUAL_COLOUR_SPACE != CSP_SRGB)

    DrawTextDigit(float2(FONT_SIZE * 6 + textOffset, FONT_SIZE * 15), FONT_SIZE, 1, TexCoord, 4, precentage_AP0,     Output, FONT_BRIGHTNESS);
    DrawTextDigit(float2(FONT_SIZE * 6 + textOffset, FONT_SIZE * 16), FONT_SIZE, 1, TexCoord, 4, precentage_AP1,     Output, FONT_BRIGHTNESS);
    DrawTextDigit(float2(FONT_SIZE * 6 + textOffset, FONT_SIZE * 17), FONT_SIZE, 1, TexCoord, 4, precentage_invalid, Output, FONT_BRIGHTNESS);

#endif
    }


  if (SHOW_BRIGHTNESS_HISTOGRAM)
  {

    uint current_x_coord = TexCoord.x * BUFFER_WIDTH;  // expand to actual pixel values
    uint current_y_coord = TexCoord.y * BUFFER_HEIGHT; // ^

    const int2 textureDisplaySize =
      int2(round(float(TEXTURE_BRIGHTNESS_HISTOGRAM_SCALE_WIDTH)  * BRIGHTNESS_HISTOGRAM_SIZE / 100.f),
           round(float(TEXTURE_BRIGHTNESS_HISTOGRAM_SCALE_HEIGHT) * BRIGHTNESS_HISTOGRAM_SIZE / 100.f));

    // draw the histogram in the bottom right corner
    if (current_x_coord >= (BUFFER_WIDTH  - textureDisplaySize.x)
     && current_y_coord >= (BUFFER_HEIGHT - textureDisplaySize.y))
    {
      // get coords for the sampler
      float2 currentSamplerCoords = float2(
        (textureDisplaySize.x - (BUFFER_WIDTH - current_x_coord)  + 0.5f) / textureDisplaySize.x,
        (current_y_coord - (BUFFER_HEIGHT - textureDisplaySize.y) + 0.5f) / textureDisplaySize.y);

      float3 currentPixelToDisplay =
        tex2D(Sampler_Brightness_Histogram_Final, currentSamplerCoords).rgb;

#if (ACTUAL_COLOUR_SPACE == CSP_SCRGB)

      Output = float4(Csp::Map::Bt709Into::Scrgb(currentPixelToDisplay * BRIGHTNESS_HISTOGRAM_BRIGHTNESS), 1.f);

#elif (ACTUAL_COLOUR_SPACE == CSP_HDR10)

      Output = float4(Csp::Map::Bt709Into::Hdr10(currentPixelToDisplay * BRIGHTNESS_HISTOGRAM_BRIGHTNESS), 1.f);

#elif (ACTUAL_COLOUR_SPACE == CSP_HLG)

      Output = float4(Csp::Map::Bt709Into::Hlg(currentPixelToDisplay * BRIGHTNESS_HISTOGRAM_BRIGHTNESS), 1.f);

#elif (ACTUAL_COLOUR_SPACE == CSP_PS5)

      Output = float4(Csp::Map::Bt709Into::Ps5(currentPixelToDisplay * BRIGHTNESS_HISTOGRAM_BRIGHTNESS), 1.f);

#endif
    }
  }


#endif
}

#else

  Output = float4(input, 1.f);
  DrawTextString(float2(0.f, 0.f), 100.f, 1, TexCoord, text_Error, 26, Output, 1.f);
}

#endif

//technique lilium__HDR_analysis_CLL_OLD
//<
//  enabled = false;
//>
//{
//  pass CalcCLLvalues
//  {
//    VertexShader = PostProcessVS;
//     PixelShader = CalcCLL;
//    RenderTarget = Texture_CLL_Values;
//  }
//
//  pass GetMaxAvgMinCLLvalue0
//  {
//    ComputeShader = GetMaxAvgMinCLL0 <THREAD_SIZE1, 1>;
//    DispatchSizeX = DISPATCH_X1;
//    DispatchSizeY = 1;
//  }
//
//  pass GetMaxAvgMinCLLvalue1
//  {
//    ComputeShader = GetMaxAvgMinCLL1 <1, 1>;
//    DispatchSizeX = 1;
//    DispatchSizeY = 1;
//  }
//
//  pass GetMaxCLLvalue0
//  {
//    ComputeShader = getMaxCLL0 <THREAD_SIZE1, 1>;
//    DispatchSizeX = DISPATCH_X1;
//    DispatchSizeY = 1;
//  }
//
//  pass GetMaxCLLvalue1
//  {
//    ComputeShader = getMaxCLL1 <1, 1>;
//    DispatchSizeX = 1;
//    DispatchSizeY = 1;
//  }
//
//  pass GetAvgCLLvalue0
//  {
//    ComputeShader = getAvgCLL0 <THREAD_SIZE1, 1>;
//    DispatchSizeX = DISPATCH_X1;
//    DispatchSizeY = 1;
//  }
//
//  pass GetAvgCLLvalue1
//  {
//    ComputeShader = getAvgCLL1 <1, 1>;
//    DispatchSizeX = 1;
//    DispatchSizeY = 1;
//  }
//
//  pass GetMinCLLvalue0
//  {
//    ComputeShader = getMinCLL0 <THREAD_SIZE1, 1>;
//    DispatchSizeX = DISPATCH_X1;
//    DispatchSizeY = 1;
//  }
//
//  pass GetMinCLLvalue1
//  {
//    ComputeShader = getMinCLL1 <1, 1>;
//    DispatchSizeX = 1;
//    DispatchSizeY = 1;
//  }
//}

technique lilium__hdr_analysis
<
  ui_label = "Lilium's HDR analysis";
>
{

#ifdef _TESTY

  pass test_thing
  {
    VertexShader = PostProcessVS;
     PixelShader = Testy;
  }

#endif


//CLL
#if (ENABLE_CLL_FEATURES == YES)

  pass CalcCLLvalues
  {
    VertexShader = PostProcessVS;
     PixelShader = CalcCLL;
    RenderTarget = Texture_CLL_Values;
  }

  pass GetMaxAvgMinCLL0_NEW
  {
    ComputeShader = GetMaxAvgMinCLL0_NEW <THREAD_SIZE1, 1>;
    DispatchSizeX = DISPATCH_X1;
    DispatchSizeY = 2;
  }

  pass GetMaxAvgMinCLL1_NEW
  {
    ComputeShader = GetMaxAvgMinCLL1_NEW <1, 1>;
    DispatchSizeX = 2;
    DispatchSizeY = 2;
  }

  pass GetFinalMaxAvgMinCLL_NEW
  {
    ComputeShader = GetFinalMaxAvgMinCLL_NEW <1, 1>;
    DispatchSizeX = 1;
    DispatchSizeY = 1;
  }

#endif


#if (ENABLE_CIE_FEATURES == YES)

#if (CIE_DIAGRAM == CIE_1931)
  pass Copy_CIE_1931_BG
  {
    VertexShader = PostProcessVS;
     PixelShader = Copy_CIE_1931_BG;
    RenderTarget = Texture_CIE_1931_Current;
  }
#endif

#if (CIE_DIAGRAM == CIE_1976)
  pass Copy_CIE_1976_BG
  {
    VertexShader = PostProcessVS;
     PixelShader = Copy_CIE_1976_BG;
    RenderTarget = Texture_CIE_1976_Current;
  }
#endif

  pass Generate_CIE_Diagram
  {
    ComputeShader = Generate_CIE_Diagram <THREAD_SIZE1, THREAD_SIZE1>;
    DispatchSizeX = DISPATCH_X1;
    DispatchSizeY = DISPATCH_Y1;
  }

#endif


#if (ENABLE_CSP_FEATURES == YES \
  && ACTUAL_COLOUR_SPACE != CSP_SRGB)

  pass CalcCSPs
  {
    VertexShader = PostProcessVS;
     PixelShader = CalcCSPs;
    RenderTarget = Texture_CSPs;
  }

  pass CountCSPs_y
  {
    ComputeShader = CountCSPs_y <THREAD_SIZE0, 1>;
    DispatchSizeX = DISPATCH_X0;
    DispatchSizeY = 1;
  }

  pass CountCSPs_x
  {
    ComputeShader = CountCSPs_x <1, 1>;
    DispatchSizeX = 1;
    DispatchSizeY = 1;
  }

#endif

  pass ClearBrightnessHistogramTexture
  {
    VertexShader       = PostProcessVS;
     PixelShader       = ClearBrightnessHistogramTexture;
    RenderTarget       = Texture_Brightness_Histogram;
    ClearRenderTargets = true;
  }

  pass ComputeBrightnessHistogram
  {
    ComputeShader = ComputeBrightnessHistogram <THREAD_SIZE0, 1>;
    DispatchSizeX = DISPATCH_X0;
    DispatchSizeY = 1;
  }

  pass RenderBrightnessHistogramToScale
  {
    VertexShader = PostProcessVS;
     PixelShader = RenderBrightnessHistogramToScale;
    RenderTarget = Texture_Brightness_Histogram_Final;
  }

  pass CopyShowValues
  {
    ComputeShader = ShowValuesCopy <1, 1>;
    DispatchSizeX = 1;
    DispatchSizeY = 1;
  }

  pass HDR_analysis
  {
    VertexShader = PostProcessVS;
     PixelShader = HDR_analysis;
  }
}

#else

uniform int GLOBAL_INFO
<
  ui_category = "info";
  ui_label    = " ";
  ui_type     = "radio";
  ui_text     = "Only DirectX 11, 12 and Vulkan are supported!";
>;

#endif
