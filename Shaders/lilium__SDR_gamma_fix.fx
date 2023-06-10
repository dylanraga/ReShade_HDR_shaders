#include "ReShade.fxh"
#include "lilium__colorspace.fxh"

//#define _DEBUG

uniform uint INPUT_GAMMA
<
  ui_label = "input Gamma";
  ui_type  = "combo";
  ui_items = "sRGB\0"
             "power Gamma\0";
> = 0;

uniform uint TARGET_GAMMA
<
  ui_label = "target Gamma";
  ui_type  = "combo";
  ui_items = "power Gamma\0"
             "sRGB\0";
> = 0;

uniform float INPUT_POWER_GAMMA
<
  ui_label = "input power Gamma";
  ui_type  = "drag";
  ui_min   = 1.f;
  ui_max   = 3.f;
  ui_step  = 0.01f;
> = 2.2f;

uniform float TARGET_POWER_GAMMA
<
  ui_label = "target power Gamma";
  ui_type  = "drag";
  ui_min   = 1.f;
  ui_max   = 3.f;
  ui_step  = 0.01f;
> = 2.2f;

uniform bool USE_BT1886
<
  ui_category = "BT.1886";
  ui_label    = "use BT.1886 gamma for blackpoint correction";
> = false;

uniform float TARGET_WHITEPOINT
<
  ui_category = "BT.1886";
  ui_label    = "target whitepoint (in nits)";
  ui_type     = "drag";
  ui_min      = 1.f;
  ui_max      = 1000.f;
  ui_step     = 0.5f;
> = 100.f;

uniform float TARGET_BLACKPOINT
<
  ui_category = "BT.1886";
  ui_label    = "target blackpoint (in nits)";
  ui_type     = "drag";
  ui_min      = 0.f;
  ui_max      = 1.f;
  ui_step     = 0.001f;
> = 0.f;


float3 BT1886_gamma(
  const float3 V,
  const float  targetWhitepoint,
  const float  targetBlackpoint,
  const float  targetGamma,
  const float  targetInverseGamma)
{
  const float Lw = targetWhitepoint;
  const float Lb = targetBlackpoint;

  const float powLw = pow(Lw, targetInverseGamma);
  const float powLb = pow(Lb, targetInverseGamma);

  const float powLw_minus_powLb = powLw - powLb;

  const float a = pow(powLw_minus_powLb, targetGamma);
  const float b = powLb /
                  (powLw_minus_powLb);

  const float3 L = a * pow(max(V + b.xxx, 0.f.xxx), targetGamma);

  return pow(L / targetWhitepoint, targetInverseGamma);
}


void SDR_gamma_fix(
      float4 vpos     : SV_Position,
      float2 texcoord : TEXCOORD,
  out float4 output   : SV_Target0)
{
  const float3 input = tex2D(ReShade::BackBuffer, texcoord).rgb;

  float3 fixedGamma;

  if (INPUT_GAMMA == 0)
    fixedGamma = sRGB_EOTF(input);
  else
    fixedGamma = pow(input, INPUT_POWER_GAMMA);

  if (TARGET_GAMMA == 0)
  {
    const float targetInverseGamma = 1.f / TARGET_POWER_GAMMA;

    fixedGamma = pow(fixedGamma, targetInverseGamma);
    if (USE_BT1886)
      fixedGamma = BT1886_gamma(fixedGamma, TARGET_WHITEPOINT, TARGET_BLACKPOINT, TARGET_POWER_GAMMA, targetInverseGamma);
  }
  else
    sRGB_inverse_EOTF(fixedGamma);

  output = float4(fixedGamma, 1.f);
}


technique lilium__SDR_gamma_fix
{
  pass SDR_gamma_fix
  {
    VertexShader = PostProcessVS;
     PixelShader = SDR_gamma_fix;
  }
}