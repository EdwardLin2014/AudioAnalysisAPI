//
//  AudioAnalyzer.h
//  AudioAnalysisAPI
//
//  Created by Edward on 1/11/14.
//  Copyright (c) 2014 Edward. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Accelerate/Accelerate.h>

#include <math.h>
#include "CABitOperations.h"

@interface AudioAnalyzer : NSObject
{
    
}

typedef struct
{
    float* _samples;
    int    _samplesRate;
    int    _errCode;
} AudioReadOutput;

+ (AudioReadOutput)audioread:(NSString*)inFileName;
+ (Float32*)abs_fft:(Float32*)samples FFTLength:(int)FFTLength;
+ (Float32*)abs_rcep:(Float32*)samples FFTLength:(int)FFTLength;

@end
