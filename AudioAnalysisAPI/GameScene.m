//
//  GameScene.m
//  AudioAnalysisAPI
//
//  Created by Edward on 31/10/14.
//  Copyright (c) 2014 Edward. All rights reserved.
//

#import "GameScene.h"

@implementation GameScene

-(void)didMoveToView:(SKView *)view
{
    /* Setup your scene here */
    AudioReadOutput AudioSamples;
    NSString* DocDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSLog(@"Document Path: %@", DocDirectory);
    
    int i,j,k,l;
    NSError* error;
    
    // ----------------------------------- Example of using audioread() --------------------------------- Begin //
    // Memory is allocated to store the samples, free it at the end
    AudioSamples = [AudioAnalyzer audioread:@"18_C4"];
    // ----------------------------------- Example of using audioread() --------------------------------- End //
    
    // ------------------------------------ Output audio samples to text file -------------------------------------- Begin //
    NSString* AudioSamplesFileAtPath = [DocDirectory stringByAppendingPathComponent:@"samples_18C4.txt"];
    NSLog(@"Audio Samples File Path: %@", AudioSamplesFileAtPath);
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:AudioSamplesFileAtPath])
        [[NSFileManager defaultManager] createFileAtPath:AudioSamplesFileAtPath contents:nil attributes:nil];
    
    // AudioSamples._FileSize is in bytes, current audio file is in PCM 16bits (2 bytes)
    for (i=0; i<AudioSamples._FileSize/2; i++)
    {
        NSString* samples = [NSString stringWithFormat: @"%.15f\n", AudioSamples._samples[i]];
        
        if (i==0)
            [samples writeToFile:AudioSamplesFileAtPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
        else
        {
            // append
            NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:AudioSamplesFileAtPath];
            [handle seekToEndOfFile];
            [handle writeData:[samples dataUsingEncoding:NSUTF8StringEncoding]];
            [handle closeFile];
        }
    }
    // ------------------------------------ Output audio samples to text file -------------------------------------- End //
    
    // ----------------------------------- Example of using abs(fft()) and abs(rceps())--------------------------------- Begin //
    UInt32 FFTLength = 4096;
    UInt32 NumOfSamples = AudioSamples._FileSize/2;
    UInt32 NumOfPred = floor((double)NumOfSamples/FFTLength);
    UInt32 first, last;
    
    NSLog(@"NumOfSamples:%u", (unsigned int)NumOfSamples);
    NSLog(@"NumOfPred:%u", (unsigned int)NumOfPred);
    
    Float32 Freq[NumOfPred];
    UInt32 MIDI[NumOfPred];
    for (i=0; i<NumOfPred; i++)
    {
        first = i*FFTLength;
        last = first + FFTLength - 1;
        
        NSLog(@"%d: first:%u last:%u", i, (unsigned int)first, (unsigned int)last);
        
        Float32 inData[FFTLength];
        for (j=0, k=first; k<=last; j++, k++)
            inData[j] = AudioSamples._samples[k];
        
        // Memory is allocated to store the result, free it at the end
        Float32* FFTResult = [AudioAnalyzer abs_fft:inData FFTLength:FFTLength];
        Float32* RCEPSResult = [AudioAnalyzer abs_rcep:inData FFTLength:FFTLength];
        
        Float32 FFT_RCEPS[FFTLength];
        Float32 maxValue = -1;
        int Idx = 9;
        for (l=9; l<=99; l++)
        {
            FFT_RCEPS[l] = FFTResult[l] * RCEPSResult[l];
            if (FFT_RCEPS[l] > maxValue)
            {
                maxValue = FFT_RCEPS[l];
                Idx = l+1;
            }
        }
        
        Freq[i] = (Float32)AudioSamples._samplesRate/(Float32)FFTLength*(Float32)Idx;
        MIDI[i] = floor(12*log2(Freq[i]/440) + 69);
        NSLog(@"%d: %f, %d", i, Freq[i], MIDI[i]);
        
        // ------------------------------------ Output fft result to text file -------------------------------------- Begin //
        NSString* FFTFileAtPath = [DocDirectory stringByAppendingPathComponent:@"fft_18C4.txt"];
        NSLog(@"FFT Result File Path: %@", FFTFileAtPath);
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:FFTFileAtPath])
            [[NSFileManager defaultManager] createFileAtPath:FFTFileAtPath contents:nil attributes:nil];
        
        NSFileHandle *FFTHandle = [NSFileHandle fileHandleForWritingAtPath:FFTFileAtPath];
        
        // One FFT Prediction as One Line
        NSMutableString *outputFFTResult = [NSMutableString stringWithFormat: @"%.15f,", FFTResult[0]];
        for (l=1; l<FFTLength-1; l++)
            [outputFFTResult appendString:[NSString stringWithFormat:@"%.15f,", FFTResult[l]]];
        [outputFFTResult appendString:[NSString stringWithFormat:@"%.15f\n", FFTResult[l]]];
        
        if (i==0)
        {
            if(![outputFFTResult writeToFile:FFTFileAtPath atomically:NO encoding:NSUTF8StringEncoding error:&error])
                NSLog(@"Error Code: %ld", (long)[error code]);
        }
        else
        {
            // append
            [FFTHandle seekToEndOfFile];
            [FFTHandle writeData:[outputFFTResult dataUsingEncoding:NSUTF8StringEncoding]];
        }
        // ------------------------------------ Output fft result to text file -------------------------------------- End //
        
        // ------------------------------------ Output rceps result to text file -------------------------------------- Begin //
        NSString* RCEPSFileAtPath = [DocDirectory stringByAppendingPathComponent:@"rceps_18C4.txt"];
        NSLog(@"RCEPS Result File Path: %@", RCEPSFileAtPath);
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:RCEPSFileAtPath])
            [[NSFileManager defaultManager] createFileAtPath:RCEPSFileAtPath contents:nil attributes:nil];
        
        NSFileHandle *RCEPSHandle = [NSFileHandle fileHandleForWritingAtPath:RCEPSFileAtPath];
        
        // One FFT Prediction as One Line
        NSMutableString *outputRCEPSResult = [NSMutableString stringWithFormat: @"%.15f,", RCEPSResult[0]];
        for (l=1; l<FFTLength-1; l++)
            [outputRCEPSResult appendString:[NSString stringWithFormat:@"%.15f,", RCEPSResult[l]]];
        [outputRCEPSResult appendString:[NSString stringWithFormat:@"%.15f\n", RCEPSResult[l]]];
        
        if (i==0)
        {
            if(![outputRCEPSResult writeToFile:RCEPSFileAtPath atomically:NO encoding:NSUTF8StringEncoding error:&error])
                NSLog(@"Error Code: %ld", (long)[error code]);
        }
        else
        {
            // append
            [RCEPSHandle seekToEndOfFile];
            [RCEPSHandle writeData:[outputRCEPSResult dataUsingEncoding:NSUTF8StringEncoding]];
        }
        // ------------------------------------ Output rceps result to text file -------------------------------------- End //
        
        // Free any allocated memory!
        memset(FFTResult,0,FFTLength*sizeof(Float32));
        free(FFTResult);
        memset(RCEPSResult,0,FFTLength*sizeof(Float32));
        free(RCEPSResult);
    }
    // ----------------------------------- Example of using abs(fft()) and abs(rceps())--------------------------------- End //

    // Free any allocated memory!
    memset(AudioSamples._samples,0,AudioSamples._FileSize);
    free(AudioSamples._samples);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    /* Called when a touch begins */
    /*
    for (UITouch *touch in touches)
    {
        CGPoint location = [touch locationInNode:self];
        
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
        
        sprite.xScale = 0.5;
        sprite.yScale = 0.5;
        sprite.position = location;
        
        SKAction *action = [SKAction rotateByAngle:M_PI duration:1];
        
        [sprite runAction:[SKAction repeatActionForever:action]];
        
        [self addChild:sprite];
    }
    */
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
