#pragma once


static const float TEXTURE_LUMINANCE_WAVEFORM_SCALE_FACTOR_X = (TEXTURE_LUMINANCE_WAVEFORM_SCALE_WIDTH - 1.f)
                                                             / float(TEXTURE_LUMINANCE_WAVEFORM_WIDTH  - 1);

static const float TEXTURE_LUMINANCE_WAVEFORM_SCALE_FACTOR_Y = (TEXTURE_LUMINANCE_WAVEFORM_SCALE_HEIGHT     - 1.f)
                                                             / float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT - 1);

texture2D TextureLuminanceWaveform
<
  pooled = true;
>
{
  Width  = TEXTURE_LUMINANCE_WAVEFORM_WIDTH;
  Height = TEXTURE_LUMINANCE_WAVEFORM_HEIGHT;
  Format = RGBA8;
};

sampler2D<float4> SamplerLuminanceWaveform
{
  Texture = TextureLuminanceWaveform;
  MagFilter = POINT;
};

storage2D<float4> StorageLuminanceWaveform
{
  Texture = TextureLuminanceWaveform;
};

texture2D TextureLuminanceWaveformFinal
<
  pooled = true;
>
{
  Width  = TEXTURE_LUMINANCE_WAVEFORM_SCALE_WIDTH;
  Height = TEXTURE_LUMINANCE_WAVEFORM_SCALE_HEIGHT;
  Format = RGBA8;
};

sampler2D<float4> SamplerLuminanceWaveformFinal
{
  Texture   = TextureLuminanceWaveformFinal;
  MagFilter = POINT;
};


void RenderLuminanceWaveform(
  const int2 FetchPos)
{
  float curPixelNits = tex2Dfetch(StorageNitsValues, FetchPos);

#ifdef IS_HDR_CSP
  float encodedPixel = Csp::Trc::NitsTo::Pq(curPixelNits);
#elif (ACTUAL_COLOUR_SPACE == CSP_SRGB)
  float encodedPixel = ENCODE_SDR(curPixelNits / 100.f);
#endif

  int2 coord = float2(float(FetchPos.x)
                  / TEXTURE_LUMINANCE_WAVEFORM_BUFFER_WIDTH_FACTOR,
                    float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT)
                  - (encodedPixel * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) + 0.5f;

  float3 waveformColour = WaveformRgbValues(curPixelNits);
  waveformColour = sqrt(waveformColour);

  tex2Dstore(StorageLuminanceWaveform,
             coord,
             float4(waveformColour, 1.f));
}


namespace Waveform
{

  struct SWaveformData
  {
    int   borderSize;
    int   frameSize;
    int2  charDimensions;
#ifndef IS_HDR_CSP
    int   charDimensionXForPercent;
#endif
    int2  atlasOffset;
    int2  waveformArea;
#ifdef IS_HDR_CSP
    int   cutoffOffset;
    #define WAVEDAT_CUTOFFSET waveDat.cutoffOffset
    int   tickPoints[16];
#else
    #define WAVEDAT_CUTOFFSET 0
    int   tickPoints[14];
#endif
    int   fontSpacer;
    int2  offsetToFrame;
    int2  textOffset;
    int   tickXOffset;
    int   lowerFrameStart;
    int2  endXY;
    int   endYminus1;
  };

  SWaveformData GetData()
  {
    SWaveformData waveDat;

    const float2 waveformScaleFactorXY = clamp(_LUMINANCE_WAVEFORM_SIZE / 100.f, 0.5f, float2(1.f, 2.f));

    const float waveformScaleFactor =
#ifdef IS_HDR_CSP
      (waveformScaleFactorXY.x + waveformScaleFactorXY.y) / 2.f;
#else
      waveformScaleFactorXY.y / (LUMINANCE_WAVEFORM_DEFAULT_HEIGHT / 100.f);
#endif

    const float borderAndFrameSizeFactor = max(waveformScaleFactor, 0.75f);
#ifdef IS_HDR_CSP
    const float fontSizeFactor = max(waveformScaleFactor, 0.85f);
#else
    #define fontSizeFactor waveformScaleFactor
#endif

    static const int maxBorderSize = TEXTURE_LUMINANCE_WAVEFORM_SCALE_BORDER;
    static const int maxFrameSize  = TEXTURE_LUMINANCE_WAVEFORM_SCALE_FRAME;

    waveDat.borderSize = clamp(int(TEXTURE_LUMINANCE_WAVEFORM_BUFFER_FACTOR * 35.f * borderAndFrameSizeFactor + 0.5f), 10, maxBorderSize);
    waveDat.frameSize  = clamp(int(TEXTURE_LUMINANCE_WAVEFORM_BUFFER_FACTOR *  7.f * borderAndFrameSizeFactor + 0.5f),  4, maxFrameSize);

    static const uint maxFontSize =
      clamp(uint(((TEXTURE_LUMINANCE_WAVEFORM_BUFFER_FACTOR *
#ifdef IS_HDR_CSP
                                                              27.f + 5.f
#else
                                                              28.f + 3.f
#endif
                                                                        ) / 2.f + 0.5f)) * 2, 12, 32);

    const uint fontSize =
      clamp(uint(((TEXTURE_LUMINANCE_WAVEFORM_BUFFER_FACTOR *
#ifdef IS_HDR_CSP
                                                              27.f + 5.f
#else
                                                              28.f + 3.f
#endif
                                                                        ) / 2.f * fontSizeFactor + 0.5f)) * 2, 12, maxFontSize);

    const uint charArrayEntry = 32 - fontSize;

    const uint atlasEntry = charArrayEntry / 2;

#ifndef IS_HDR_CSP
    waveDat.charDimensionXForPercent = WaveCharSize[charArrayEntry];

    waveDat.charDimensions = int2(waveDat.charDimensionXForPercent - 2, WaveCharSize[charArrayEntry + 1]);
#else
    waveDat.charDimensions = int2(WaveCharSize[charArrayEntry] - 2, WaveCharSize[charArrayEntry + 1]);
#endif

    waveDat.atlasOffset = int2(WaveAtlasXOffset[atlasEntry], WAVE_TEXTURE_OFFSET.y);

#ifdef IS_HDR_CSP
    const int maxChars = LUMINANCE_WAVEFORM_CUTOFF_POINT == 0 ? 8
                                                              : 7;
#else
    const int maxChars = 7;
#endif

    const int textWidth  = waveDat.charDimensions.x * maxChars;
    const int tickSpacer = int(float(waveDat.charDimensions.x) / 2.f + 0.5f);

    waveDat.fontSpacer = int(float(waveDat.charDimensions.y) / 2.f - float(waveDat.frameSize) + 0.5f);

    waveDat.offsetToFrame = int2(waveDat.borderSize + textWidth + tickSpacer + waveDat.frameSize,
                                 waveDat.borderSize + waveDat.fontSpacer);

#ifdef IS_HDR_CSP
    static const int cutoffPoints[16] = {
      int(0),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (Csp::Trc::NitsTo::Pq(4000.f  ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (Csp::Trc::NitsTo::Pq(2000.f  ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (Csp::Trc::NitsTo::Pq(1000.f  ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (Csp::Trc::NitsTo::Pq( 400.f  ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (Csp::Trc::NitsTo::Pq( 203.f  ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (Csp::Trc::NitsTo::Pq( 100.f  ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (Csp::Trc::NitsTo::Pq(  50.f  ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (Csp::Trc::NitsTo::Pq(  25.f  ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (Csp::Trc::NitsTo::Pq(  10.f  ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (Csp::Trc::NitsTo::Pq(   5.f  ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (Csp::Trc::NitsTo::Pq(   2.5f ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (Csp::Trc::NitsTo::Pq(   1.f  ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (Csp::Trc::NitsTo::Pq(   0.25f) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (Csp::Trc::NitsTo::Pq(   0.05f) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int(                                                                                   float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT)   * waveformScaleFactorXY.y + 0.5f) };
#else
    waveDat.tickPoints = {
      int(0),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (ENCODE_SDR(0.875f ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (ENCODE_SDR(0.75f  ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (ENCODE_SDR(0.6f   ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (ENCODE_SDR(0.5f   ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (ENCODE_SDR(0.35f  ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (ENCODE_SDR(0.25f  ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (ENCODE_SDR(0.18f  ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (ENCODE_SDR(0.1f   ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (ENCODE_SDR(0.05f  ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (ENCODE_SDR(0.025f ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (ENCODE_SDR(0.01f  ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
#if (OVERWRITE_SDR_GAMMA == GAMMA_UNSET \
  || OVERWRITE_SDR_GAMMA == GAMMA_22    \
  || OVERWRITE_SDR_GAMMA == GAMMA_24)
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (ENCODE_SDR(0.0025f) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
#else
      int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT) - (ENCODE_SDR(0.004f ) * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT))) * waveformScaleFactorXY.y + 0.5f),
#endif
      int(                                                                        float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT)   * waveformScaleFactorXY.y + 0.5f) };
#endif

    waveDat.waveformArea =
      int2(TEXTURE_LUMINANCE_WAVEFORM_WIDTH * waveformScaleFactorXY.x,
#ifdef IS_HDR_CSP
           cutoffPoints[15] - cutoffPoints[LUMINANCE_WAVEFORM_CUTOFF_POINT]
#else
           waveDat.tickPoints[13]
#endif
           );

#ifdef IS_HDR_CSP
    if (LUMINANCE_WAVEFORM_CUTOFF_POINT == 0)
    {
      waveDat.cutoffOffset = 0;

      waveDat.tickPoints = {
        int(0),
        int(cutoffPoints[ 1]),
        int(cutoffPoints[ 2]),
        int(cutoffPoints[ 3]),
        int(cutoffPoints[ 4]),
        int(cutoffPoints[ 5]),
        int(cutoffPoints[ 6]),
        int(cutoffPoints[ 7]),
        int(cutoffPoints[ 8]),
        int(cutoffPoints[ 9]),
        int(cutoffPoints[10]),
        int(cutoffPoints[11]),
        int(cutoffPoints[12]),
        int(cutoffPoints[13]),
        int(cutoffPoints[14]),
        int(cutoffPoints[15]) };
    }
    else if (LUMINANCE_WAVEFORM_CUTOFF_POINT == 1)
    {
      waveDat.cutoffOffset = cutoffPoints[1];

      waveDat.tickPoints = {
        int(-100),
        int(0),
        int(cutoffPoints[ 2] - waveDat.cutoffOffset),
        int(cutoffPoints[ 3] - waveDat.cutoffOffset),
        int(cutoffPoints[ 4] - waveDat.cutoffOffset),
        int(cutoffPoints[ 5] - waveDat.cutoffOffset),
        int(cutoffPoints[ 6] - waveDat.cutoffOffset),
        int(cutoffPoints[ 7] - waveDat.cutoffOffset),
        int(cutoffPoints[ 8] - waveDat.cutoffOffset),
        int(cutoffPoints[ 9] - waveDat.cutoffOffset),
        int(cutoffPoints[10] - waveDat.cutoffOffset),
        int(cutoffPoints[11] - waveDat.cutoffOffset),
        int(cutoffPoints[12] - waveDat.cutoffOffset),
        int(cutoffPoints[13] - waveDat.cutoffOffset),
        int(cutoffPoints[14] - waveDat.cutoffOffset),
        int(cutoffPoints[15] - waveDat.cutoffOffset) };
    }
    else if (LUMINANCE_WAVEFORM_CUTOFF_POINT == 2)
    {
      waveDat.cutoffOffset = cutoffPoints[2];

      waveDat.tickPoints = {
        int(-100),
        int(-100),
        int(0),
        int(cutoffPoints[ 3] - waveDat.cutoffOffset),
        int(cutoffPoints[ 4] - waveDat.cutoffOffset),
        int(cutoffPoints[ 5] - waveDat.cutoffOffset),
        int(cutoffPoints[ 6] - waveDat.cutoffOffset),
        int(cutoffPoints[ 7] - waveDat.cutoffOffset),
        int(cutoffPoints[ 8] - waveDat.cutoffOffset),
        int(cutoffPoints[ 9] - waveDat.cutoffOffset),
        int(cutoffPoints[10] - waveDat.cutoffOffset),
        int(cutoffPoints[11] - waveDat.cutoffOffset),
        int(cutoffPoints[12] - waveDat.cutoffOffset),
        int(cutoffPoints[13] - waveDat.cutoffOffset),
        int(cutoffPoints[14] - waveDat.cutoffOffset),
        int(cutoffPoints[15] - waveDat.cutoffOffset) };
    }
    else //if (LUMINANCE_WAVEFORM_CUTOFF_POINT == 3)
    {
      waveDat.cutoffOffset = cutoffPoints[3];

      waveDat.tickPoints = {
        int(-100),
        int(-100),
        int(-100),
        int(0),
        int(cutoffPoints[ 4] - waveDat.cutoffOffset),
        int(cutoffPoints[ 5] - waveDat.cutoffOffset),
        int(cutoffPoints[ 6] - waveDat.cutoffOffset),
        int(cutoffPoints[ 7] - waveDat.cutoffOffset),
        int(cutoffPoints[ 8] - waveDat.cutoffOffset),
        int(cutoffPoints[ 9] - waveDat.cutoffOffset),
        int(cutoffPoints[10] - waveDat.cutoffOffset),
        int(cutoffPoints[11] - waveDat.cutoffOffset),
        int(cutoffPoints[12] - waveDat.cutoffOffset),
        int(cutoffPoints[13] - waveDat.cutoffOffset),
        int(cutoffPoints[14] - waveDat.cutoffOffset),
        int(cutoffPoints[15] - waveDat.cutoffOffset) };
    }
#endif

    waveDat.textOffset = int2(0, int(float(waveDat.charDimensions.y) / 2.f + 0.5f));

    waveDat.tickXOffset = waveDat.borderSize
                        + textWidth
                        + tickSpacer;

    waveDat.lowerFrameStart = waveDat.frameSize
                            + waveDat.waveformArea.y;

    waveDat.endXY = waveDat.frameSize * 2
                  + waveDat.waveformArea;

    waveDat.endYminus1 = waveDat.endXY.y - 1;

    return waveDat;
  }

  int2 GetActiveArea()
  {
    SWaveformData waveDat = GetData();

    return waveDat.offsetToFrame
         + waveDat.frameSize
         + waveDat.waveformArea
         + waveDat.frameSize
         + int2(0, waveDat.fontSpacer)
         + waveDat.borderSize;
  }

  int2 GetNitsOffset(
    const int ActiveBorderSize,
    const int ActiveFrameSize,
    const int ActiveFontSpacer,
    const int YOffset)
  {
    return int2(ActiveBorderSize,
                ActiveBorderSize + ActiveFontSpacer + ActiveFrameSize + YOffset);
  } //GetNitsOffset

  void DrawCharToScale(
    const int  Char,
    const int2 CharDim,
    const int2 AtlasOffset,
    const int2 Pos,
    const int  CharCount)
  {
    const int2 charOffset = int2(AtlasOffset.x,
                                 AtlasOffset.y + (Char * CharDim.y));

    int charDimX = CharDim.x;

    if (Char == _percent_w)
    {
      charDimX -= 2;
    }

    const int2 currentPos = Pos + int2(CharCount * charDimX, 0);

    int startX = 1;
    int stopX  = CharDim.x + 1;

    if (Char == _percent_w)
    {
      startX = 0;
      stopX  = CharDim.x;
    }

    for (int x = startX; x < stopX; x++)
    {
      for (int y = 0; y < CharDim.y; y++)
      {
        int2 currentOffset = int2(x, y);

        float4 currentPixel = tex2Dfetch(SamplerFontAtlasConsolidated, charOffset + currentOffset);

        int2 currentDrawOffset = currentPos + currentOffset;
        currentDrawOffset.y += TEXTURE_OVERLAY_HEIGHT;

        tex2Dstore(StorageTextOverlayAndLuminanceWaveformScale, currentDrawOffset, currentPixel);
      }
    }
    return;
  } //DrawCharToScale

}


void RenderLuminanceWaveformScale()
{
  if (tex1Dfetch(StorageConsolidated, COORDS_LUMINANCE_WAVEFORM_LAST_SIZE_X)       != _LUMINANCE_WAVEFORM_SIZE.x
   || tex1Dfetch(StorageConsolidated, COORDS_LUMINANCE_WAVEFORM_LAST_SIZE_Y)       != _LUMINANCE_WAVEFORM_SIZE.y
#ifdef IS_HDR_CSP
   || tex1Dfetch(StorageConsolidated, COORDS_LUMINANCE_WAVEFORM_LAST_CUTOFF_POINT) != LUMINANCE_WAVEFORM_CUTOFF_POINT
#endif
  )
  {
    //make background all black
    for (int x = 0; x < TEXTURE_LUMINANCE_WAVEFORM_SCALE_WIDTH; x++)
    {
      for (int y = TEXTURE_OVERLAY_HEIGHT; y < TEXTURE_TEXT_OVERLAY_AND_LUMINANCE_WAVEFORM_SCALE_HEIGHT; y++)
      {
        tex2Dstore(StorageTextOverlayAndLuminanceWaveformScale, int2(x, y), float4(0.f, 0.f, 0.f, 0.f));
      }
    }

    Waveform::SWaveformData waveDat = Waveform::GetData();

#ifdef IS_HDR_CSP

    const int2 nits10000_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 0]);
    const int2 nits_4000_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 1]);
    const int2 nits_2000_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 2]);
    const int2 nits_1000_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 3]);
    const int2 nits__400_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 4]);
    const int2 nits__203_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 5]);
    const int2 nits__100_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 6]);
    const int2 nits___50_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 7]);
    const int2 nits___25_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 8]);
    const int2 nits___10_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 9]);
    const int2 nits____5_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[10]);
    const int2 nits____2_50Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[11]);
    const int2 nits____1_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[12]);
    const int2 nits____0_25Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[13]);
    const int2 nits____0_05Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[14]);
    const int2 nits____0_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[15]);


    const int2 text10000_00Offset = nits10000_00Offset - waveDat.textOffset;
    const int2 text_4000_00Offset = nits_4000_00Offset - waveDat.textOffset;
    const int2 text_2000_00Offset = nits_2000_00Offset - waveDat.textOffset;
    const int2 text_1000_00Offset = nits_1000_00Offset - waveDat.textOffset;
    const int2 text__400_00Offset = nits__400_00Offset - waveDat.textOffset;
    const int2 text__203_00Offset = nits__203_00Offset - waveDat.textOffset;
    const int2 text__100_00Offset = nits__100_00Offset - waveDat.textOffset;
    const int2 text___50_00Offset = nits___50_00Offset - waveDat.textOffset;
    const int2 text___25_00Offset = nits___25_00Offset - waveDat.textOffset;
    const int2 text___10_00Offset = nits___10_00Offset - waveDat.textOffset;
    const int2 text____5_00Offset = nits____5_00Offset - waveDat.textOffset;
    const int2 text____2_50Offset = nits____2_50Offset - waveDat.textOffset;
    const int2 text____1_00Offset = nits____1_00Offset - waveDat.textOffset;
    const int2 text____0_25Offset = nits____0_25Offset - waveDat.textOffset;
    const int2 text____0_05Offset = nits____0_05Offset - waveDat.textOffset;
    const int2 text____0_00Offset = nits____0_00Offset - waveDat.textOffset;

    int charOffsets[8];

    if (LUMINANCE_WAVEFORM_CUTOFF_POINT == 0)
    {
      charOffsets = {
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7 };
    }
    else //if (LUMINANCE_WAVEFORM_CUTOFF_POINT > 0)
    {
      charOffsets = {
        0,
        0,
        1,
        2,
        3,
        4,
        5,
        6 };
    }

    if (LUMINANCE_WAVEFORM_CUTOFF_POINT == 0)
    {
      Waveform::DrawCharToScale(  _1_w, waveDat.charDimensions, waveDat.atlasOffset, text10000_00Offset, charOffsets[0]);
      Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text10000_00Offset, charOffsets[1]);
      Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text10000_00Offset, charOffsets[2]);
      Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text10000_00Offset, charOffsets[3]);
      Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text10000_00Offset, charOffsets[4]);
      Waveform::DrawCharToScale(_dot_w, waveDat.charDimensions, waveDat.atlasOffset, text10000_00Offset, charOffsets[5]);
      Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text10000_00Offset, charOffsets[6]);
      Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text10000_00Offset, charOffsets[7]);
    }

    if (LUMINANCE_WAVEFORM_CUTOFF_POINT <= 1)
    {
      Waveform::DrawCharToScale(  _4_w, waveDat.charDimensions, waveDat.atlasOffset, text_4000_00Offset, charOffsets[1]);
      Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text_4000_00Offset, charOffsets[2]);
      Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text_4000_00Offset, charOffsets[3]);
      Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text_4000_00Offset, charOffsets[4]);
      Waveform::DrawCharToScale(_dot_w, waveDat.charDimensions, waveDat.atlasOffset, text_4000_00Offset, charOffsets[5]);
      Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text_4000_00Offset, charOffsets[6]);
      Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text_4000_00Offset, charOffsets[7]);
    }

    if (LUMINANCE_WAVEFORM_CUTOFF_POINT <= 2)
    {
      Waveform::DrawCharToScale(  _2_w, waveDat.charDimensions, waveDat.atlasOffset, text_2000_00Offset, charOffsets[1]);
      Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text_2000_00Offset, charOffsets[2]);
      Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text_2000_00Offset, charOffsets[3]);
      Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text_2000_00Offset, charOffsets[4]);
      Waveform::DrawCharToScale(_dot_w, waveDat.charDimensions, waveDat.atlasOffset, text_2000_00Offset, charOffsets[5]);
      Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text_2000_00Offset, charOffsets[6]);
      Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text_2000_00Offset, charOffsets[7]);
    }

    Waveform::DrawCharToScale(  _1_w, waveDat.charDimensions, waveDat.atlasOffset, text_1000_00Offset, charOffsets[1]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text_1000_00Offset, charOffsets[2]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text_1000_00Offset, charOffsets[3]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text_1000_00Offset, charOffsets[4]);
    Waveform::DrawCharToScale(_dot_w, waveDat.charDimensions, waveDat.atlasOffset, text_1000_00Offset, charOffsets[5]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text_1000_00Offset, charOffsets[6]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text_1000_00Offset, charOffsets[7]);

    Waveform::DrawCharToScale(  _4_w, waveDat.charDimensions, waveDat.atlasOffset, text__400_00Offset, charOffsets[2]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text__400_00Offset, charOffsets[3]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text__400_00Offset, charOffsets[4]);
    Waveform::DrawCharToScale(_dot_w, waveDat.charDimensions, waveDat.atlasOffset, text__400_00Offset, charOffsets[5]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text__400_00Offset, charOffsets[6]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text__400_00Offset, charOffsets[7]);

    Waveform::DrawCharToScale(  _2_w, waveDat.charDimensions, waveDat.atlasOffset, text__203_00Offset, charOffsets[2]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text__203_00Offset, charOffsets[3]);
    Waveform::DrawCharToScale(  _3_w, waveDat.charDimensions, waveDat.atlasOffset, text__203_00Offset, charOffsets[4]);
    Waveform::DrawCharToScale(_dot_w, waveDat.charDimensions, waveDat.atlasOffset, text__203_00Offset, charOffsets[5]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text__203_00Offset, charOffsets[6]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text__203_00Offset, charOffsets[7]);

    Waveform::DrawCharToScale(  _1_w, waveDat.charDimensions, waveDat.atlasOffset, text__100_00Offset, charOffsets[2]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text__100_00Offset, charOffsets[3]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text__100_00Offset, charOffsets[4]);
    Waveform::DrawCharToScale(_dot_w, waveDat.charDimensions, waveDat.atlasOffset, text__100_00Offset, charOffsets[5]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text__100_00Offset, charOffsets[6]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text__100_00Offset, charOffsets[7]);

    Waveform::DrawCharToScale(  _5_w, waveDat.charDimensions, waveDat.atlasOffset, text___50_00Offset, charOffsets[3]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text___50_00Offset, charOffsets[4]);
    Waveform::DrawCharToScale(_dot_w, waveDat.charDimensions, waveDat.atlasOffset, text___50_00Offset, charOffsets[5]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text___50_00Offset, charOffsets[6]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text___50_00Offset, charOffsets[7]);

    Waveform::DrawCharToScale(  _2_w, waveDat.charDimensions, waveDat.atlasOffset, text___25_00Offset, charOffsets[3]);
    Waveform::DrawCharToScale(  _5_w, waveDat.charDimensions, waveDat.atlasOffset, text___25_00Offset, charOffsets[4]);
    Waveform::DrawCharToScale(_dot_w, waveDat.charDimensions, waveDat.atlasOffset, text___25_00Offset, charOffsets[5]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text___25_00Offset, charOffsets[6]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text___25_00Offset, charOffsets[7]);

    Waveform::DrawCharToScale(  _1_w, waveDat.charDimensions, waveDat.atlasOffset, text___10_00Offset, charOffsets[3]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text___10_00Offset, charOffsets[4]);
    Waveform::DrawCharToScale(_dot_w, waveDat.charDimensions, waveDat.atlasOffset, text___10_00Offset, charOffsets[5]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text___10_00Offset, charOffsets[6]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text___10_00Offset, charOffsets[7]);

    Waveform::DrawCharToScale(  _5_w, waveDat.charDimensions, waveDat.atlasOffset, text____5_00Offset, charOffsets[4]);
    Waveform::DrawCharToScale(_dot_w, waveDat.charDimensions, waveDat.atlasOffset, text____5_00Offset, charOffsets[5]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text____5_00Offset, charOffsets[6]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text____5_00Offset, charOffsets[7]);

    Waveform::DrawCharToScale(  _2_w, waveDat.charDimensions, waveDat.atlasOffset, text____2_50Offset, charOffsets[4]);
    Waveform::DrawCharToScale(_dot_w, waveDat.charDimensions, waveDat.atlasOffset, text____2_50Offset, charOffsets[5]);
    Waveform::DrawCharToScale(  _5_w, waveDat.charDimensions, waveDat.atlasOffset, text____2_50Offset, charOffsets[6]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text____2_50Offset, charOffsets[7]);

    Waveform::DrawCharToScale(  _1_w, waveDat.charDimensions, waveDat.atlasOffset, text____1_00Offset, charOffsets[4]);
    Waveform::DrawCharToScale(_dot_w, waveDat.charDimensions, waveDat.atlasOffset, text____1_00Offset, charOffsets[5]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text____1_00Offset, charOffsets[6]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text____1_00Offset, charOffsets[7]);

    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text____0_25Offset, charOffsets[4]);
    Waveform::DrawCharToScale(_dot_w, waveDat.charDimensions, waveDat.atlasOffset, text____0_25Offset, charOffsets[5]);
    Waveform::DrawCharToScale(  _2_w, waveDat.charDimensions, waveDat.atlasOffset, text____0_25Offset, charOffsets[6]);
    Waveform::DrawCharToScale(  _5_w, waveDat.charDimensions, waveDat.atlasOffset, text____0_25Offset, charOffsets[7]);

    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text____0_05Offset, charOffsets[4]);
    Waveform::DrawCharToScale(_dot_w, waveDat.charDimensions, waveDat.atlasOffset, text____0_05Offset, charOffsets[5]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text____0_05Offset, charOffsets[6]);
    Waveform::DrawCharToScale(  _5_w, waveDat.charDimensions, waveDat.atlasOffset, text____0_05Offset, charOffsets[7]);

    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text____0_00Offset, charOffsets[4]);
    Waveform::DrawCharToScale(_dot_w, waveDat.charDimensions, waveDat.atlasOffset, text____0_00Offset, charOffsets[5]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text____0_00Offset, charOffsets[6]);
    Waveform::DrawCharToScale(  _0_w, waveDat.charDimensions, waveDat.atlasOffset, text____0_00Offset, charOffsets[7]);

#else

    const int2 nits100_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 0]);
    const int2 nits_87_50Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 1]);
    const int2 nits_75_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 2]);
    const int2 nits_60_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 3]);
    const int2 nits_50_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 4]);
    const int2 nits_35_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 5]);
    const int2 nits_25_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 6]);
    const int2 nits_18_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 7]);
    const int2 nits_10_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 8]);
    const int2 nits__5_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[ 9]);
    const int2 nits__2_50Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[10]);
    const int2 nits__1_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[11]);
#if (OVERWRITE_SDR_GAMMA == GAMMA_UNSET \
  || OVERWRITE_SDR_GAMMA == GAMMA_22    \
  || OVERWRITE_SDR_GAMMA == GAMMA_24)
    const int2 nits__0_25Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[12]);
#else
    const int2 nits__0_40Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[12]);
#endif
    const int2 nits__0_00Offset = Waveform::GetNitsOffset(waveDat.borderSize, waveDat.frameSize, waveDat.fontSpacer, waveDat.tickPoints[13]);

    const int2 text100_00Offset = nits100_00Offset - waveDat.textOffset;
    const int2 text_87_50Offset = nits_87_50Offset - waveDat.textOffset;
    const int2 text_75_00Offset = nits_75_00Offset - waveDat.textOffset;
    const int2 text_60_00Offset = nits_60_00Offset - waveDat.textOffset;
    const int2 text_50_00Offset = nits_50_00Offset - waveDat.textOffset;
    const int2 text_35_00Offset = nits_35_00Offset - waveDat.textOffset;
    const int2 text_25_00Offset = nits_25_00Offset - waveDat.textOffset;
    const int2 text_18_00Offset = nits_18_00Offset - waveDat.textOffset;
    const int2 text_10_00Offset = nits_10_00Offset - waveDat.textOffset;
    const int2 text__5_00Offset = nits__5_00Offset - waveDat.textOffset;
    const int2 text__2_50Offset = nits__2_50Offset - waveDat.textOffset;
    const int2 text__1_00Offset = nits__1_00Offset - waveDat.textOffset;
#if (OVERWRITE_SDR_GAMMA == GAMMA_UNSET \
  || OVERWRITE_SDR_GAMMA == GAMMA_22    \
  || OVERWRITE_SDR_GAMMA == GAMMA_24)
    const int2 text__0_25Offset = nits__0_25Offset - waveDat.textOffset;
#else
    const int2 text__0_40Offset = nits__0_40Offset - waveDat.textOffset;
#endif
    const int2 text__0_00Offset = nits__0_00Offset - waveDat.textOffset;

    const int2 charDimensionsForPercent = int2(waveDat.charDimensionXForPercent, waveDat.charDimensions.y);

    Waveform::DrawCharToScale(      _1_w, waveDat.charDimensions,   waveDat.atlasOffset, text100_00Offset, 0);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text100_00Offset, 1);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text100_00Offset, 2);
    Waveform::DrawCharToScale(    _dot_w, waveDat.charDimensions,   waveDat.atlasOffset, text100_00Offset, 3);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text100_00Offset, 4);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text100_00Offset, 5);
    Waveform::DrawCharToScale(_percent_w, charDimensionsForPercent, waveDat.atlasOffset, text100_00Offset, 6);

    Waveform::DrawCharToScale(      _8_w, waveDat.charDimensions,   waveDat.atlasOffset, text_87_50Offset, 1);
    Waveform::DrawCharToScale(      _7_w, waveDat.charDimensions,   waveDat.atlasOffset, text_87_50Offset, 2);
    Waveform::DrawCharToScale(    _dot_w, waveDat.charDimensions,   waveDat.atlasOffset, text_87_50Offset, 3);
    Waveform::DrawCharToScale(      _5_w, waveDat.charDimensions,   waveDat.atlasOffset, text_87_50Offset, 4);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text_87_50Offset, 5);
    Waveform::DrawCharToScale(_percent_w, charDimensionsForPercent, waveDat.atlasOffset, text_87_50Offset, 6);

    Waveform::DrawCharToScale(      _7_w, waveDat.charDimensions,   waveDat.atlasOffset, text_75_00Offset, 1);
    Waveform::DrawCharToScale(      _5_w, waveDat.charDimensions,   waveDat.atlasOffset, text_75_00Offset, 2);
    Waveform::DrawCharToScale(    _dot_w, waveDat.charDimensions,   waveDat.atlasOffset, text_75_00Offset, 3);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text_75_00Offset, 4);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text_75_00Offset, 5);
    Waveform::DrawCharToScale(_percent_w, charDimensionsForPercent, waveDat.atlasOffset, text_75_00Offset, 6);

    Waveform::DrawCharToScale(      _6_w, waveDat.charDimensions,   waveDat.atlasOffset, text_60_00Offset, 1);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text_60_00Offset, 2);
    Waveform::DrawCharToScale(    _dot_w, waveDat.charDimensions,   waveDat.atlasOffset, text_60_00Offset, 3);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text_60_00Offset, 4);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text_60_00Offset, 5);
    Waveform::DrawCharToScale(_percent_w, charDimensionsForPercent, waveDat.atlasOffset, text_60_00Offset, 6);

    Waveform::DrawCharToScale(      _5_w, waveDat.charDimensions,   waveDat.atlasOffset, text_50_00Offset, 1);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text_50_00Offset, 2);
    Waveform::DrawCharToScale(    _dot_w, waveDat.charDimensions,   waveDat.atlasOffset, text_50_00Offset, 3);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text_50_00Offset, 4);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text_50_00Offset, 5);
    Waveform::DrawCharToScale(_percent_w, charDimensionsForPercent, waveDat.atlasOffset, text_50_00Offset, 6);

    Waveform::DrawCharToScale(      _3_w, waveDat.charDimensions,   waveDat.atlasOffset, text_35_00Offset, 1);
    Waveform::DrawCharToScale(      _5_w, waveDat.charDimensions,   waveDat.atlasOffset, text_35_00Offset, 2);
    Waveform::DrawCharToScale(    _dot_w, waveDat.charDimensions,   waveDat.atlasOffset, text_35_00Offset, 3);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text_35_00Offset, 4);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text_35_00Offset, 5);
    Waveform::DrawCharToScale(_percent_w, charDimensionsForPercent, waveDat.atlasOffset, text_35_00Offset, 6);

    Waveform::DrawCharToScale(      _2_w, waveDat.charDimensions,   waveDat.atlasOffset, text_25_00Offset, 1);
    Waveform::DrawCharToScale(      _5_w, waveDat.charDimensions,   waveDat.atlasOffset, text_25_00Offset, 2);
    Waveform::DrawCharToScale(    _dot_w, waveDat.charDimensions,   waveDat.atlasOffset, text_25_00Offset, 3);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text_25_00Offset, 4);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text_25_00Offset, 5);
    Waveform::DrawCharToScale(_percent_w, charDimensionsForPercent, waveDat.atlasOffset, text_25_00Offset, 6);

    Waveform::DrawCharToScale(      _1_w, waveDat.charDimensions,   waveDat.atlasOffset, text_18_00Offset, 1);
    Waveform::DrawCharToScale(      _8_w, waveDat.charDimensions,   waveDat.atlasOffset, text_18_00Offset, 2);
    Waveform::DrawCharToScale(    _dot_w, waveDat.charDimensions,   waveDat.atlasOffset, text_18_00Offset, 3);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text_18_00Offset, 4);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text_18_00Offset, 5);
    Waveform::DrawCharToScale(_percent_w, charDimensionsForPercent, waveDat.atlasOffset, text_18_00Offset, 6);

    Waveform::DrawCharToScale(      _1_w, waveDat.charDimensions,   waveDat.atlasOffset, text_10_00Offset, 1);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text_10_00Offset, 2);
    Waveform::DrawCharToScale(    _dot_w, waveDat.charDimensions,   waveDat.atlasOffset, text_10_00Offset, 3);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text_10_00Offset, 4);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text_10_00Offset, 5);
    Waveform::DrawCharToScale(_percent_w, charDimensionsForPercent, waveDat.atlasOffset, text_10_00Offset, 6);

    Waveform::DrawCharToScale(      _5_w, waveDat.charDimensions,   waveDat.atlasOffset, text__5_00Offset, 2);
    Waveform::DrawCharToScale(    _dot_w, waveDat.charDimensions,   waveDat.atlasOffset, text__5_00Offset, 3);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text__5_00Offset, 4);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text__5_00Offset, 5);
    Waveform::DrawCharToScale(_percent_w, charDimensionsForPercent, waveDat.atlasOffset, text__5_00Offset, 6);

    Waveform::DrawCharToScale(      _2_w, waveDat.charDimensions,   waveDat.atlasOffset, text__2_50Offset, 2);
    Waveform::DrawCharToScale(    _dot_w, waveDat.charDimensions,   waveDat.atlasOffset, text__2_50Offset, 3);
    Waveform::DrawCharToScale(      _5_w, waveDat.charDimensions,   waveDat.atlasOffset, text__2_50Offset, 4);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text__2_50Offset, 5);
    Waveform::DrawCharToScale(_percent_w, charDimensionsForPercent, waveDat.atlasOffset, text__2_50Offset, 6);

    Waveform::DrawCharToScale(      _1_w, waveDat.charDimensions,   waveDat.atlasOffset, text__1_00Offset, 2);
    Waveform::DrawCharToScale(    _dot_w, waveDat.charDimensions,   waveDat.atlasOffset, text__1_00Offset, 3);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text__1_00Offset, 4);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text__1_00Offset, 5);
    Waveform::DrawCharToScale(_percent_w, charDimensionsForPercent, waveDat.atlasOffset, text__1_00Offset, 6);

#if (OVERWRITE_SDR_GAMMA == GAMMA_UNSET \
  || OVERWRITE_SDR_GAMMA == GAMMA_22    \
  || OVERWRITE_SDR_GAMMA == GAMMA_24)

    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text__0_25Offset, 2);
    Waveform::DrawCharToScale(    _dot_w, waveDat.charDimensions,   waveDat.atlasOffset, text__0_25Offset, 3);
    Waveform::DrawCharToScale(      _2_w, waveDat.charDimensions,   waveDat.atlasOffset, text__0_25Offset, 4);
    Waveform::DrawCharToScale(      _5_w, waveDat.charDimensions,   waveDat.atlasOffset, text__0_25Offset, 5);
    Waveform::DrawCharToScale(_percent_w, charDimensionsForPercent, waveDat.atlasOffset, text__0_25Offset, 6);
#else
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text__0_40Offset, 2);
    Waveform::DrawCharToScale(    _dot_w, waveDat.charDimensions,   waveDat.atlasOffset, text__0_40Offset, 3);
    Waveform::DrawCharToScale(      _4_w, waveDat.charDimensions,   waveDat.atlasOffset, text__0_40Offset, 4);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text__0_40Offset, 5);
    Waveform::DrawCharToScale(_percent_w, charDimensionsForPercent, waveDat.atlasOffset, text__0_40Offset, 6);
#endif

    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text__0_00Offset, 2);
    Waveform::DrawCharToScale(    _dot_w, waveDat.charDimensions,   waveDat.atlasOffset, text__0_00Offset, 3);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text__0_00Offset, 4);
    Waveform::DrawCharToScale(      _0_w, waveDat.charDimensions,   waveDat.atlasOffset, text__0_00Offset, 5);
    Waveform::DrawCharToScale(_percent_w, charDimensionsForPercent, waveDat.atlasOffset, text__0_00Offset, 6);

#endif

    // draw the frame, ticks and horizontal lines
    for (int y = 0; y < waveDat.endXY.y; y++)
    {
      int2 curPos = waveDat.offsetToFrame
                  + int2(0, y);

      float curGrey = lerp(0.5f, 0.4f, (float(y + WAVEDAT_CUTOFFSET) / float(waveDat.endYminus1 + WAVEDAT_CUTOFFSET)));
      curGrey = pow(curGrey, 2.2f);
      // using gamma 2 as intermediate gamma space
      curGrey = sqrt(curGrey);

      float4 curColour = float4(curGrey, 1.f.xxx);

      // draw top and bottom part of the frame
      if (y <  waveDat.frameSize
       || y >= waveDat.lowerFrameStart)
      {
        for (int x = 0; x < waveDat.endXY.x; x++)
        {
          int2 curXPos = int2(curPos.x + x,
                              curPos.y + TEXTURE_OVERLAY_HEIGHT);
          tex2Dstore(StorageTextOverlayAndLuminanceWaveformScale, curXPos, curColour);
        }
      }
      // draw left and right part of the frame
      else
      {
        for (int x = 0; x < waveDat.frameSize; x++)
        {
          int2 curLeftPos  = int2(curPos.x + x,
                                  curPos.y + TEXTURE_OVERLAY_HEIGHT);
          int2 curRightPos = int2(curLeftPos.x + waveDat.waveformArea.x + waveDat.frameSize, curLeftPos.y);
          tex2Dstore(StorageTextOverlayAndLuminanceWaveformScale, curLeftPos,  curColour);
          tex2Dstore(StorageTextOverlayAndLuminanceWaveformScale, curRightPos, curColour);
        }
      }

      // draw top tick and bottom tick
#ifdef IS_HDR_CSP
  #ifdef IS_QHD_OR_HIGHER_RES
      if ((LUMINANCE_WAVEFORM_CUTOFF_POINT == 0 && ((nits10000_00Offset.y - 1) == curPos.y || nits10000_00Offset.y == curPos.y || (nits10000_00Offset.y + 1) == curPos.y))
       || (LUMINANCE_WAVEFORM_CUTOFF_POINT == 1 && ((nits_4000_00Offset.y - 1) == curPos.y || nits_4000_00Offset.y == curPos.y || (nits_4000_00Offset.y + 1) == curPos.y))
       || (LUMINANCE_WAVEFORM_CUTOFF_POINT == 2 && ((nits_2000_00Offset.y - 1) == curPos.y || nits_2000_00Offset.y == curPos.y || (nits_2000_00Offset.y + 1) == curPos.y))
       || (LUMINANCE_WAVEFORM_CUTOFF_POINT == 3 && ((nits_1000_00Offset.y - 1) == curPos.y || nits_1000_00Offset.y == curPos.y || (nits_1000_00Offset.y + 1) == curPos.y))
       || (nits____0_00Offset.y - 1) == curPos.y || nits____0_00Offset.y == curPos.y || (nits____0_00Offset.y + 1) == curPos.y)
  #else
      if ((LUMINANCE_WAVEFORM_CUTOFF_POINT == 0 && nits10000_00Offset.y == curPos.y)
       || (LUMINANCE_WAVEFORM_CUTOFF_POINT == 1 && nits_4000_00Offset.y == curPos.y)
       || (LUMINANCE_WAVEFORM_CUTOFF_POINT == 2 && nits_2000_00Offset.y == curPos.y)
       || (LUMINANCE_WAVEFORM_CUTOFF_POINT == 3 && nits_1000_00Offset.y == curPos.y)
       || nits____0_00Offset.y == curPos.y)
  #endif
#else
  #ifdef IS_QHD_OR_HIGHER_RES
      if ((nits100_00Offset.y - 1) == curPos.y || nits100_00Offset.y == curPos.y || (nits100_00Offset.y + 1) == curPos.y
       || (nits__0_00Offset.y - 1) == curPos.y || nits__0_00Offset.y == curPos.y || (nits__0_00Offset.y + 1) == curPos.y)
  #else
      if (nits100_00Offset.y == curPos.y
       || nits__0_00Offset.y == curPos.y)
  #endif
#endif
      {
        for (int x = waveDat.tickXOffset; x < (waveDat.tickXOffset + waveDat.frameSize); x++)
        {
          int2 curTickPos = int2(x,
                                 curPos.y + TEXTURE_OVERLAY_HEIGHT);
          tex2Dstore(StorageTextOverlayAndLuminanceWaveformScale, curTickPos, curColour);
        }
      }

      // draw ticks + draw horizontal lines
#ifdef IS_HDR_CSP
  #ifdef IS_QHD_OR_HIGHER_RES
      if ((LUMINANCE_WAVEFORM_CUTOFF_POINT < 1 && ((nits_4000_00Offset.y - 1) == curPos.y || nits_4000_00Offset.y == curPos.y || (nits_4000_00Offset.y + 1) == curPos.y))
       || (LUMINANCE_WAVEFORM_CUTOFF_POINT < 2 && ((nits_2000_00Offset.y - 1) == curPos.y || nits_2000_00Offset.y == curPos.y || (nits_2000_00Offset.y + 1) == curPos.y))
       || (LUMINANCE_WAVEFORM_CUTOFF_POINT < 3 && ((nits_1000_00Offset.y - 1) == curPos.y || nits_1000_00Offset.y == curPos.y || (nits_1000_00Offset.y + 1) == curPos.y))
       || (nits__400_00Offset.y - 1) == curPos.y || nits__400_00Offset.y == curPos.y || (nits__400_00Offset.y + 1) == curPos.y
       || (nits__203_00Offset.y - 1) == curPos.y || nits__203_00Offset.y == curPos.y || (nits__203_00Offset.y + 1) == curPos.y
       || (nits__100_00Offset.y - 1) == curPos.y || nits__100_00Offset.y == curPos.y || (nits__100_00Offset.y + 1) == curPos.y
       || (nits___50_00Offset.y - 1) == curPos.y || nits___50_00Offset.y == curPos.y || (nits___50_00Offset.y + 1) == curPos.y
       || (nits___25_00Offset.y - 1) == curPos.y || nits___25_00Offset.y == curPos.y || (nits___25_00Offset.y + 1) == curPos.y
       || (nits___10_00Offset.y - 1) == curPos.y || nits___10_00Offset.y == curPos.y || (nits___10_00Offset.y + 1) == curPos.y
       || (nits____5_00Offset.y - 1) == curPos.y || nits____5_00Offset.y == curPos.y || (nits____5_00Offset.y + 1) == curPos.y
       || (nits____2_50Offset.y - 1) == curPos.y || nits____2_50Offset.y == curPos.y || (nits____2_50Offset.y + 1) == curPos.y
       || (nits____1_00Offset.y - 1) == curPos.y || nits____1_00Offset.y == curPos.y || (nits____1_00Offset.y + 1) == curPos.y
       || (nits____0_25Offset.y - 1) == curPos.y || nits____0_25Offset.y == curPos.y || (nits____0_25Offset.y + 1) == curPos.y
       || (nits____0_05Offset.y - 1) == curPos.y || nits____0_05Offset.y == curPos.y || (nits____0_05Offset.y + 1) == curPos.y)
  #else
      if ((LUMINANCE_WAVEFORM_CUTOFF_POINT < 1 && nits_4000_00Offset.y == curPos.y)
       || (LUMINANCE_WAVEFORM_CUTOFF_POINT < 2 && nits_2000_00Offset.y == curPos.y)
       || (LUMINANCE_WAVEFORM_CUTOFF_POINT < 3 && nits_1000_00Offset.y == curPos.y)
       || nits__400_00Offset.y == curPos.y
       || nits__203_00Offset.y == curPos.y
       || nits__100_00Offset.y == curPos.y
       || nits___50_00Offset.y == curPos.y
       || nits___25_00Offset.y == curPos.y
       || nits___10_00Offset.y == curPos.y
       || nits____5_00Offset.y == curPos.y
       || nits____2_50Offset.y == curPos.y
       || nits____1_00Offset.y == curPos.y
       || nits____0_25Offset.y == curPos.y
       || nits____0_05Offset.y == curPos.y)
  #endif
#else
  #ifdef IS_QHD_OR_HIGHER_RES
      if ((nits_87_50Offset.y - 1) == curPos.y || nits_87_50Offset.y == curPos.y || (nits_87_50Offset.y + 1) == curPos.y
       || (nits_75_00Offset.y - 1) == curPos.y || nits_75_00Offset.y == curPos.y || (nits_75_00Offset.y + 1) == curPos.y
       || (nits_60_00Offset.y - 1) == curPos.y || nits_60_00Offset.y == curPos.y || (nits_60_00Offset.y + 1) == curPos.y
       || (nits_50_00Offset.y - 1) == curPos.y || nits_50_00Offset.y == curPos.y || (nits_50_00Offset.y + 1) == curPos.y
       || (nits_35_00Offset.y - 1) == curPos.y || nits_35_00Offset.y == curPos.y || (nits_35_00Offset.y + 1) == curPos.y
       || (nits_25_00Offset.y - 1) == curPos.y || nits_25_00Offset.y == curPos.y || (nits_25_00Offset.y + 1) == curPos.y
       || (nits_18_00Offset.y - 1) == curPos.y || nits_18_00Offset.y == curPos.y || (nits_18_00Offset.y + 1) == curPos.y
       || (nits_10_00Offset.y - 1) == curPos.y || nits_10_00Offset.y == curPos.y || (nits_10_00Offset.y + 1) == curPos.y
       || (nits__5_00Offset.y - 1) == curPos.y || nits__5_00Offset.y == curPos.y || (nits__5_00Offset.y + 1) == curPos.y
       || (nits__2_50Offset.y - 1) == curPos.y || nits__2_50Offset.y == curPos.y || (nits__2_50Offset.y + 1) == curPos.y
       || (nits__1_00Offset.y - 1) == curPos.y || nits__1_00Offset.y == curPos.y || (nits__1_00Offset.y + 1) == curPos.y
    #if (OVERWRITE_SDR_GAMMA == GAMMA_UNSET \
      || OVERWRITE_SDR_GAMMA == GAMMA_22    \
      || OVERWRITE_SDR_GAMMA == GAMMA_24)
       || (nits__0_25Offset.y - 1) == curPos.y || nits__0_25Offset.y == curPos.y || (nits__0_25Offset.y + 1) == curPos.y
    #else
       || (nits__0_40Offset.y - 1) == curPos.y || nits__0_40Offset.y == curPos.y || (nits__0_40Offset.y + 1) == curPos.y
    #endif
      )
  #else
      if (nits_87_50Offset.y == curPos.y
       || nits_75_00Offset.y == curPos.y
       || nits_60_00Offset.y == curPos.y
       || nits_50_00Offset.y == curPos.y
       || nits_35_00Offset.y == curPos.y
       || nits_25_00Offset.y == curPos.y
       || nits_18_00Offset.y == curPos.y
       || nits_10_00Offset.y == curPos.y
       || nits__5_00Offset.y == curPos.y
       || nits__2_50Offset.y == curPos.y
       || nits__1_00Offset.y == curPos.y
    #if (OVERWRITE_SDR_GAMMA == GAMMA_UNSET \
      || OVERWRITE_SDR_GAMMA == GAMMA_22    \
      || OVERWRITE_SDR_GAMMA == GAMMA_24)
       || nits__0_25Offset.y == curPos.y
    #else
       || nits__0_40Offset.y == curPos.y
    #endif
      )
  #endif
#endif
      {
        for (int x = waveDat.tickXOffset; x < (waveDat.tickXOffset + waveDat.endXY.x); x++)
        {
          int2 curTickPos = int2(x,
                                 curPos.y + TEXTURE_OVERLAY_HEIGHT);
          tex2Dstore(StorageTextOverlayAndLuminanceWaveformScale, curTickPos, curColour);
        }
      }
    }

    tex1Dstore(StorageConsolidated, COORDS_LUMINANCE_WAVEFORM_LAST_SIZE_X,       _LUMINANCE_WAVEFORM_SIZE.x);
    tex1Dstore(StorageConsolidated, COORDS_LUMINANCE_WAVEFORM_LAST_SIZE_Y,       _LUMINANCE_WAVEFORM_SIZE.y);
#ifdef IS_HDR_CSP
    tex1Dstore(StorageConsolidated, COORDS_LUMINANCE_WAVEFORM_LAST_CUTOFF_POINT, LUMINANCE_WAVEFORM_CUTOFF_POINT);
#endif
  }

  return;
}


void PS_ClearLuminanceWaveformTexture(
  in  float4 VPos : SV_Position,
  out float4 Out  : SV_Target0)
{
  Out = 0.f;
  discard;
}


// Vertex shader generating a triangle covering the entire screen.
// Calculate values only "once" (3 times because it's 3 vertices)
// for the pixel shader.
void VS_PrepareRenderLuminanceWaveformToScale(
  in                  uint   Id       : SV_VertexID,
  out                 float4 VPos     : SV_Position,
  out                 float2 TexCoord : TEXCOORD0,
  out nointerpolation int4   WaveDat0 : WaveDat0,
#ifdef IS_HDR_CSP
  out nointerpolation int3   WaveDat1 : WaveDat1
#else
  out nointerpolation int2   WaveDat1 : WaveDat1
#endif
  )
{
  TexCoord.x = (Id == 2) ? 2.f
                         : 0.f;
  TexCoord.y = (Id == 1) ? 2.f
                         : 0.f;
  VPos = float4(TexCoord * float2(2.f, -2.f) + float2(-1.f, 1.f), 0.f, 1.f);

#define WaveformActiveArea   WaveDat0.xy
#define OffsetToWaveformArea WaveDat0.zw

#define MinNitsLineY WaveDat1.x
#define MaxNitsLineY WaveDat1.y

  WaveDat0     =  0;
  MinNitsLineY =  INT_MAX;
  MaxNitsLineY = -INT_MAX;

#ifdef IS_HDR_CSP
  #define WaveformCutoffOffset WaveDat1.z

  WaveformCutoffOffset = 0;
#else
  #define WaveformCutoffOffset 0
#endif

  if (_SHOW_LUMINANCE_WAVEFORM)
  {
    Waveform::SWaveformData waveDat = Waveform::GetData();

    WaveformActiveArea = waveDat.waveformArea;

    OffsetToWaveformArea = waveDat.offsetToFrame
                         + waveDat.frameSize;

#ifdef IS_HDR_CSP
    WaveformCutoffOffset = WAVEDAT_CUTOFFSET;
#endif

    const float waveformScaleFactorY = clamp(_LUMINANCE_WAVEFORM_SIZE.y / 100.f, 0.5f, 2.f);

    if (_LUMINANCE_WAVEFORM_SHOW_MIN_NITS_LINE)
    {
      const float minNits = tex1Dfetch(SamplerConsolidated, COORDS_MIN_NITS_VALUE);

#ifdef IS_HDR_CSP
  #define MAX_NITS_LINE_CUTOFF 10000.f
#else
  #define MAX_NITS_LINE_CUTOFF 100.f
#endif

      if (minNits > 0.f
       && minNits < MAX_NITS_LINE_CUTOFF)
      {
#ifdef IS_HDR_CSP
        float encodedMinNits = Csp::Trc::NitsTo::Pq(minNits);
#else
        float encodedMinNits = ENCODE_SDR(minNits / 100.f);
#endif
        MinNitsLineY =
          int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT)
             - (encodedMinNits * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT)))
            * waveformScaleFactorY + 0.5f)
        - WAVEDAT_CUTOFFSET;
      }
    }

    if (_LUMINANCE_WAVEFORM_SHOW_MAX_NITS_LINE)
    {
      const float maxNits = tex1Dfetch(SamplerConsolidated, COORDS_MAX_NITS_VALUE);

      if (maxNits >  0.f
       && maxNits < MAX_NITS_LINE_CUTOFF)
      {
#ifdef IS_HDR_CSP
        float encodedMaxNits = Csp::Trc::NitsTo::Pq(maxNits);
#else
        float encodedMaxNits = ENCODE_SDR(maxNits / 100.f);
#endif
        MaxNitsLineY =
          int((float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT)
             - (encodedMaxNits * float(TEXTURE_LUMINANCE_WAVEFORM_USED_HEIGHT)))
            * waveformScaleFactorY + 0.5f)
        - WAVEDAT_CUTOFFSET;
      }
    }
  }
}

void PS_RenderLuminanceWaveformToScale(
  in                  float4 VPos     : SV_Position,
  in                  float2 TexCoord : TEXCOORD0,
  in  nointerpolation int4   WaveDat0 : WaveDat0,
#ifdef IS_HDR_CSP
  in  nointerpolation int3   WaveDat1 : WaveDat1,
#else
  in  nointerpolation int2   WaveDat1 : WaveDat1,
#endif
  out                 float4 Out      : SV_Target0)
{
  Out = 0.f;

  if (_SHOW_LUMINANCE_WAVEFORM)
  {
    const int2 pureCoordAsInt = int2(VPos.xy);

    const int2 scaleCoords = pureCoordAsInt
                           + int2(0, TEXTURE_OVERLAY_HEIGHT);

    const int2 waveformCoords = pureCoordAsInt - OffsetToWaveformArea;

    if (all(waveformCoords >= 0)
     && all(waveformCoords < WaveformActiveArea))
    {
#ifdef IS_QHD_OR_HIGHER_RES
      if (waveformCoords.y == MinNitsLineY
       || waveformCoords.y == MinNitsLineY - 1)
#else
      if (waveformCoords.y == MinNitsLineY)
#endif
      {
        Out = float4(1.f, 1.f, 1.f, 1.f);
        return;
      }
#ifdef IS_QHD_OR_HIGHER_RES
      if (waveformCoords.y == MaxNitsLineY
       || waveformCoords.y == MaxNitsLineY + 1)
#else
      if (waveformCoords.y == MaxNitsLineY)
#endif
      {
        Out = float4(1.f, 1.f, 0.f, 1.f);
        return;
      }
      const bool waveformCoordsGTEMaxNitsLine = waveformCoords.y >= MaxNitsLineY;
      const bool waveformCoordsSTEMinNitsLine = waveformCoords.y <= MinNitsLineY;

      const bool showMaxNitsLineActive = waveformCoordsGTEMaxNitsLine && _LUMINANCE_WAVEFORM_SHOW_MAX_NITS_LINE;
      const bool showMinNitsLineActive = waveformCoordsSTEMinNitsLine && _LUMINANCE_WAVEFORM_SHOW_MIN_NITS_LINE;

      if (( showMaxNitsLineActive                  &&  showMinNitsLineActive)
       || (!_LUMINANCE_WAVEFORM_SHOW_MAX_NITS_LINE &&  showMinNitsLineActive)
       || ( showMaxNitsLineActive                  && !_LUMINANCE_WAVEFORM_SHOW_MIN_NITS_LINE)
       || (!_LUMINANCE_WAVEFORM_SHOW_MAX_NITS_LINE && !_LUMINANCE_WAVEFORM_SHOW_MIN_NITS_LINE))
      {
        float2 waveformSamplerCoords = (float2(waveformCoords + int2(0, WaveformCutoffOffset)) + 0.5f)
                                      * (clamp(100.f / _LUMINANCE_WAVEFORM_SIZE, float2(1.f, 0.5f), 2.f))
                                      / float2(TEXTURE_LUMINANCE_WAVEFORM_WIDTH - 1, TEXTURE_LUMINANCE_WAVEFORM_HEIGHT - 1);

        float2 scaleColour = tex2Dfetch(SamplerTextOverlayAndLuminanceWaveformScale, scaleCoords).rg;
        // using gamma 2 as intermediate gamma space
        scaleColour.r *= scaleColour.r;

        float4 waveformColour = tex2D(SamplerLuminanceWaveform, waveformSamplerCoords);
        // using gamma 2 as intermediate gamma space
        waveformColour.rgb *= waveformColour.rgb;

        Out = scaleColour.rrrg
            + waveformColour;

        // using gamma 2 as intermediate gamma space
        Out.rgb = sqrt(Out.rgb);
        return;
      }
    }
    //else
    Out = tex2Dfetch(SamplerTextOverlayAndLuminanceWaveformScale, scaleCoords).rrrg;
    return;
  }
  discard;
}
