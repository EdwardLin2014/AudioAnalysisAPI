//
//  AudioAnalyzer.m
//  AudioAnalysisAPI
//
//  Created by Edward on 1/11/14.
//  Copyright (c) 2014 Edward. All rights reserved.
//

#import "AudioAnalyzer.h"

@implementation AudioAnalyzer

/* 
 * Implement Matlab audioread()
 * FIXME: For the time being, it only reads wave file with PCM 16 bits and one channel
 * Note: caller is obligated to free the memory of retval._samples
 */
+ (AudioReadOutput)audioread:(NSString*)inFileName
{
    AudioReadOutput retval;
    retval._errCode = 0;
    
    AudioFileID AudioFileID;
    NSString* FilePath = [[NSBundle mainBundle] pathForResource:inFileName ofType:@"wav"];
    NSURL* URL = [NSURL fileURLWithPath:FilePath];

    if(AudioFileOpenURL((__bridge CFURLRef) URL, kAudioFileReadPermission, 0, &AudioFileID))
        return retval;

    // Check File Format
    UInt32 fileFormatSize = 0;
    UInt32 FileFormat;
    if(!(retval._errCode = AudioFileGetPropertyInfo(AudioFileID,kAudioFilePropertyFileFormat,&fileFormatSize,0)))
    {
        if((retval._errCode = AudioFileGetProperty(AudioFileID,kAudioFilePropertyFileFormat,&fileFormatSize,&FileFormat)))
           return retval;
    }
    else
           return retval;
    if (FileFormat != kAudioFileWAVEType)
        return retval;
    
    // Check Sampling Rate
    AudioStreamBasicDescription bsd;
    UInt32 ps = sizeof(AudioStreamBasicDescription) ;
    if( (retval._errCode = AudioFileGetProperty(AudioFileID, kAudioFilePropertyDataFormat, &ps, &bsd)) )
    {
        puts( "error retriving af basic description" );
        return retval;
    }
    retval._samplesRate = bsd.mSampleRate;
    
    // Check File Size in Bytes
    UInt32 fileSize = 0;
    if(!(retval._errCode = AudioFileGetPropertyInfo(AudioFileID,kAudioFilePropertyAudioDataByteCount,&fileSize,0)))
    {
        if((retval._errCode = AudioFileGetProperty(AudioFileID,kAudioFilePropertyAudioDataByteCount,&fileSize,&retval._FileSize)))
            return retval;
    }
    else
        return retval;
    
    // Obtain the audio samples from wave file
    int16_t *data16 = (int16_t*) malloc(retval._FileSize);
    retval._samples = (Float32*) malloc(retval._FileSize*2);
    
    if((retval._errCode = AudioFileReadBytes(AudioFileID, false, 0, &retval._FileSize, data16)))
        return retval;
    
    for (int i=0; i<retval._FileSize/2; i++)
        retval._samples[i] = (Float32)data16[i]/(Float32)32768;
    
    memset(data16,0,retval._FileSize);
    free(data16);
    
    return retval;
}

/*
 * Implement Matlab abs(fft())
 * NOTE caller is obligated to free the memory of the return value
 */
+ (Float32*)abs_fft:(Float32*)samples FFTLength:(int)FFTLength
{
    if (samples == NULL)
        return NULL;
    
    Float32* retval = (Float32*) calloc(FFTLength, sizeof(Float32));
    
    UInt32 HalfFFTLength = FFTLength/2;
    UInt32 Log2N = Log2Ceil(FFTLength);
    FFTSetup SpectrumAnalysis = vDSP_create_fftsetup(Log2N, kFFTRadix2);
    
    DSPSplitComplex DspSplitComplex;
    DspSplitComplex.realp = (Float32*) calloc(HalfFFTLength, sizeof(Float32));
    DspSplitComplex.imagp = (Float32*) calloc(HalfFFTLength, sizeof(Float32));
    
    //Generate a split complex vector from the real data
    vDSP_ctoz((COMPLEX *)samples, 2, &DspSplitComplex, 1, HalfFFTLength);
    
    //Take the fft and scale appropriately
    vDSP_fft_zrip(SpectrumAnalysis, &DspSplitComplex, 1, Log2N, kFFTDirection_Forward);
    
    // Scale the fft result by 0.5
    for (UInt32 i=0; i<HalfFFTLength; i++)
    {
        DspSplitComplex.realp[i] *= 0.5;
        DspSplitComplex.imagp[i] *= 0.5;
    }
    
    //Zero out the nyquist value
    DspSplitComplex.imagp[0] = 0.0;
    
    //Convert the fft result: abs(fft)
    vDSP_zvabs(&DspSplitComplex, 1, retval, 1, FFTLength);
    
    //Mirror the first half result
    for (UInt32 i=0; i<HalfFFTLength-1; i++)
        retval[FFTLength-1-i] = retval[i+1];
    retval[HalfFFTLength] = retval[HalfFFTLength-1];
    
    // Clear the temporary storage
    memset(DspSplitComplex.realp, 0, HalfFFTLength*sizeof(Float32));
    memset(DspSplitComplex.imagp, 0, HalfFFTLength*sizeof(Float32));
    free(DspSplitComplex.realp);
    free(DspSplitComplex.imagp);
    
    vDSP_destroy_fftsetup(SpectrumAnalysis);
    
    return retval;
}

/*
 * Implement Matlab abs(rcep())
 * NOTE caller is obligated to free the memory of the return value
 */
+ (Float32*)abs_rcep:(Float32*)samples FFTLength:(int)FFTLength
{
    if (samples == NULL)
        return NULL;

    UInt32 HalfFFTLength = FFTLength/2;
    UInt32 Log2N = Log2Ceil(FFTLength);
    FFTSetup SpectrumAnalysis = vDSP_create_fftsetup(Log2N, kFFTRadix2);
    
    DSPSplitComplex DspSplitComplex;
    DspSplitComplex.realp = (Float32*) calloc(HalfFFTLength, sizeof(Float32));
    DspSplitComplex.imagp = (Float32*) calloc(HalfFFTLength, sizeof(Float32));
    
    //-------------------------------abs(fft())--------------------------------------- Begin //
    Float32* FFTResult = (Float32*) calloc(FFTLength, sizeof(Float32));
    
    //Generate a split complex vector from the real data
    vDSP_ctoz((COMPLEX *)samples, 2, &DspSplitComplex, 1, HalfFFTLength);
    
    //Take the fft and scale appropriately
    vDSP_fft_zrip(SpectrumAnalysis, &DspSplitComplex, 1, Log2N, kFFTDirection_Forward);
    
    // Scale the fft result by 0.5
    for (UInt32 i=0; i<HalfFFTLength; i++)
    {
        DspSplitComplex.realp[i] *= 0.5;
        DspSplitComplex.imagp[i] *= 0.5;
    }
    
    //Zero out the nyquist value
    DspSplitComplex.imagp[0] = 0.0;
    
    //Convert the fft result: abs(fft)
    vDSP_zvabs(&DspSplitComplex, 1, FFTResult, 1, FFTLength);
    
    //Mirror the first half result
    for (UInt32 i=0; i<HalfFFTLength-1; i++)
        FFTResult[FFTLength-1-i] = FFTResult[i+1];
    FFTResult[HalfFFTLength] = FFTResult[HalfFFTLength-1];
    //-------------------------------abs(fft())--------------------------------------- End //
    
    //-------------------------------log(abs(fft()))-------------------------------- Begin //
    Float32* LogFFT = (Float32*) calloc(FFTLength, sizeof(Float32));
    
    // Take the log of the FFT result
    for (UInt32 i=0; i<FFTLength; i++)
        LogFFT[i] = logf(FFTResult[i]);
    //-------------------------------log(abs(fft()))-------------------------------- End //
    
    //-------------------------------(abs(fft(log(abs(fft())))))/FFTLength-------- Begin //
    Float32* CepstrumResult = (Float32*) calloc(FFTLength, sizeof(Float32));
    
    //Generate a split complex vector from the real data
    vDSP_ctoz((COMPLEX *)LogFFT, 2, &DspSplitComplex, 1, HalfFFTLength);
    
    //Take the fft and scale appropriately
    vDSP_fft_zrip(SpectrumAnalysis, &DspSplitComplex, 1, Log2N, kFFTDirection_Forward);
    
    // Scale the fft result by 0.5
    for (UInt32 i=0; i<HalfFFTLength; i++)
    {
        DspSplitComplex.realp[i] *= 0.5;
        DspSplitComplex.imagp[i] *= 0.5;
    }
    
    //Zero out the nyquist value
    DspSplitComplex.imagp[0] = 0.0;
    
    //Convert the inverse fft result: abs(ifft)
    vDSP_zvabs(&DspSplitComplex, 1, CepstrumResult, 1, FFTLength);
    
    //Mirror the first half result
    for (UInt32 i=0; i<HalfFFTLength-1; i++)
        CepstrumResult[FFTLength-1-i] = CepstrumResult[i+1];
    CepstrumResult[HalfFFTLength] = CepstrumResult[HalfFFTLength-1];
    
    // Divide each element by FFTLength
    for (UInt32 i=0; i<FFTLength; i++)
        CepstrumResult[i] = CepstrumResult[i]/FFTLength;
    //-------------------------------(abs(fft(log(abs(fft())))))/FFTLength-------- End //
    
    // Clear the temporary storage
    memset(DspSplitComplex.realp, 0, HalfFFTLength*sizeof(Float32));
    memset(DspSplitComplex.imagp, 0, HalfFFTLength*sizeof(Float32));
    free(DspSplitComplex.realp);
    free(DspSplitComplex.imagp);
    
    memset(FFTResult, 0, FFTLength*sizeof(Float32));
    memset(LogFFT, 0, FFTLength*sizeof(Float32));
    free(FFTResult);
    free(LogFFT);
    
    vDSP_destroy_fftsetup(SpectrumAnalysis);
    
    return CepstrumResult;
}

@end
