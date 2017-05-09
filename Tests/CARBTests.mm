//
//  CARBTests.mm
//  WaveLabs
//
//  Created by Vlad Gorlov on 12.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AVFoundation/AVFoundation.h>
#import "CARBTestsCpp-Swift.h"
#import "CARingBuffer.h"

@interface CARBCppTests : XCTestCase {
   CARingBuffer *ringBuffer;
   AVAudioPCMBuffer *writeBuffer;
   AVAudioPCMBuffer *secondaryWriteBuffer;
   AVAudioPCMBuffer *readBuffer;
}
@end

@implementation CARBCppTests

- (void)setUp {
   [super setUp];
   AVAudioFormat *audioFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:2];
   writeBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:16];
   secondaryWriteBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:16];
   readBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:16];

   ringBuffer = new CARingBuffer();
   ringBuffer->Allocate(2, sizeof(float), 5);
}

- (void)tearDown {
   delete ringBuffer;
   ringBuffer = nullptr;
   writeBuffer = nil;
   readBuffer = nil;
   [super tearDown];
}

- (void)testIOInRange {
   [CARBTestsUtility generateSampleChannelData:writeBuffer numberOfFrames:4 biasValue:1];
   [CARBTestsUtility printChannelDataWithTitle:@"Write buffer:" buffer:writeBuffer];
   CARingBufferError status = kCARingBufferError_OK;

   status = ringBuffer->Store(writeBuffer.audioBufferList, 4, 0);
   XCTAssertTrue(status == kCARingBufferError_OK);

   CARingBuffer::SampleTime startTime = 0;
   CARingBuffer::SampleTime endTime = 0;
   status = ringBuffer->GetTimeBounds(startTime, endTime);
   XCTAssertTrue(status == kCARingBufferError_OK);
   XCTAssertTrue(startTime == 0 && endTime == 4);

   readBuffer.frameLength = 2;
   status = ringBuffer->Fetch(readBuffer.mutableAudioBufferList, 2, 0);
   XCTAssertTrue(status == kCARingBufferError_OK);
   [CARBTestsUtility printChannelDataWithTitle:@"Read buffer (1 part):" buffer:readBuffer];
   XCTAssertTrue([CARBTestsUtility compareBuffersContents:writeBuffer writeBufferOffset:0
                                                       readBuffer:readBuffer readBufferOffset:0 numberOfFrames:2]);
   status = ringBuffer->GetTimeBounds(startTime, endTime);
   XCTAssertTrue(status == kCARingBufferError_OK);
   XCTAssertTrue(startTime == 0 && endTime == 4);

   status = ringBuffer->Fetch(readBuffer.mutableAudioBufferList, 2, 2);
   XCTAssertTrue(status == kCARingBufferError_OK);
   [CARBTestsUtility printChannelDataWithTitle:@"Read buffer (2 part):" buffer:readBuffer];
   XCTAssertTrue([CARBTestsUtility compareBuffersContents:writeBuffer writeBufferOffset:2
                                                       readBuffer:readBuffer readBufferOffset:0 numberOfFrames:2]);
   status = ringBuffer->GetTimeBounds(startTime, endTime);
   XCTAssertTrue(status == kCARingBufferError_OK);
   XCTAssertTrue(startTime == 0 && endTime == 4);
}

- (void)testReadBehindAndAhead {
   [CARBTestsUtility generateSampleChannelData:writeBuffer numberOfFrames:4 biasValue:1];
   [CARBTestsUtility printChannelDataWithTitle:@"Write buffer:" buffer:writeBuffer];
   CARingBufferError status = kCARingBufferError_OK;

   status = ringBuffer->Store(writeBuffer.audioBufferList, 4, 2);
   XCTAssertTrue(status == kCARingBufferError_OK);

   CARingBuffer::SampleTime startTime = 0;
   CARingBuffer::SampleTime endTime = 0;
   status = ringBuffer->GetTimeBounds(startTime, endTime);
   XCTAssertTrue(status == kCARingBufferError_OK);
   XCTAssertTrue(startTime == 0 && endTime == 6);

   readBuffer.frameLength = 4;
   status = ringBuffer->Fetch(readBuffer.mutableAudioBufferList, 4, 0);
   XCTAssertTrue(status == kCARingBufferError_OK);
   [CARBTestsUtility printChannelDataWithTitle:@"Read buffer (1 part):" buffer:readBuffer];
   XCTAssertTrue([CARBTestsUtility compareBuffersContents:writeBuffer writeBufferOffset:0
                                                       readBuffer:readBuffer readBufferOffset:2 numberOfFrames:2]);
   XCTAssertTrue([CARBTestsUtility checkBuffersContentsIsZero:readBuffer bufferOffset:0 numberOfFrames:2]);

   status = ringBuffer->Fetch(readBuffer.mutableAudioBufferList, 4, 4);
   XCTAssertTrue(status == kCARingBufferError_OK);
   [CARBTestsUtility printChannelDataWithTitle:@"Read buffer (2 part):" buffer:readBuffer];
   XCTAssertTrue([CARBTestsUtility compareBuffersContents:writeBuffer writeBufferOffset:2
                                                       readBuffer:readBuffer readBufferOffset:0 numberOfFrames:2]);
   XCTAssertTrue([CARBTestsUtility checkBuffersContentsIsZero:readBuffer bufferOffset:2 numberOfFrames:2]);
}

- (void)testWriteBehindAndAhead {
   [CARBTestsUtility generateSampleChannelData:secondaryWriteBuffer numberOfFrames:8 biasValue:2];
   [CARBTestsUtility printChannelDataWithTitle:@"Secondary write buffer:" buffer:secondaryWriteBuffer];
   CARingBufferError status = kCARingBufferError_OK;

   status = ringBuffer->Store(secondaryWriteBuffer.audioBufferList, 8, 0);
   XCTAssertTrue(status == kCARingBufferError_OK);

   CARingBuffer::SampleTime startTime = 0;
   CARingBuffer::SampleTime endTime = 0;
   status = ringBuffer->GetTimeBounds(startTime, endTime);
   XCTAssertTrue(status == kCARingBufferError_OK);
   XCTAssertTrue(startTime == 0 && endTime == 8);

   [CARBTestsUtility generateSampleChannelData:writeBuffer numberOfFrames:4 biasValue:1];
   [CARBTestsUtility printChannelDataWithTitle:@"Write buffer:" buffer:writeBuffer];
   status = ringBuffer->Store(writeBuffer.audioBufferList, 4, 2);
   XCTAssertTrue(status == kCARingBufferError_OK);
   status = ringBuffer->GetTimeBounds(startTime, endTime);
   XCTAssertTrue(status == kCARingBufferError_OK);
   XCTAssertTrue(startTime == 2 && endTime == 6);

   readBuffer.frameLength = 8;
   status = ringBuffer->Fetch(readBuffer.mutableAudioBufferList, 8, 0);
   XCTAssertTrue(status == kCARingBufferError_OK);
   [CARBTestsUtility printChannelDataWithTitle:@"Read buffer:" buffer:readBuffer];
   XCTAssertTrue([CARBTestsUtility compareBuffersContents:writeBuffer writeBufferOffset:0
                                                       readBuffer:readBuffer readBufferOffset:2 numberOfFrames:4]);
   XCTAssertTrue([CARBTestsUtility checkBuffersContentsIsZero:readBuffer bufferOffset:0 numberOfFrames:2]);
   XCTAssertTrue([CARBTestsUtility checkBuffersContentsIsZero:readBuffer bufferOffset:6 numberOfFrames:2]);
}

- (void)testReadFromEmptyBuffer {
   CARingBufferError status = kCARingBufferError_OK;

   CARingBuffer::SampleTime startTime = 0;
   CARingBuffer::SampleTime endTime = 0;
   status = ringBuffer->GetTimeBounds(startTime, endTime);
   XCTAssertTrue(status == kCARingBufferError_OK);
   XCTAssertTrue(startTime == 0 && endTime == 0);

   readBuffer.frameLength = 4;
   status = ringBuffer->Fetch(readBuffer.mutableAudioBufferList, 4, 0);
   XCTAssertTrue(status == kCARingBufferError_OK);
   [CARBTestsUtility printChannelDataWithTitle:@"Read buffer:" buffer:readBuffer];
   XCTAssertTrue([CARBTestsUtility checkBuffersContentsIsZero:readBuffer bufferOffset:0 numberOfFrames:4]);
}

- (void)testIOWithWrapping {
   [CARBTestsUtility generateSampleChannelData:secondaryWriteBuffer numberOfFrames:4 biasValue:2];
   [CARBTestsUtility printChannelDataWithTitle:@"Secondary write buffer:" buffer:secondaryWriteBuffer];
   CARingBufferError status = kCARingBufferError_OK;

   status = ringBuffer->Store(secondaryWriteBuffer.audioBufferList, 4, 0);
   XCTAssertTrue(status == kCARingBufferError_OK);

   [CARBTestsUtility generateSampleChannelData:writeBuffer numberOfFrames:6 biasValue:1];
   [CARBTestsUtility printChannelDataWithTitle:@"Write buffer:" buffer:writeBuffer];

   status = ringBuffer->Store(writeBuffer.audioBufferList, 6, 4);
   XCTAssertTrue(status == kCARingBufferError_OK);

   CARingBuffer::SampleTime startTime = 0;
   CARingBuffer::SampleTime endTime = 0;
   status = ringBuffer->GetTimeBounds(startTime, endTime);
   XCTAssertTrue(status == kCARingBufferError_OK);
   XCTAssertTrue(startTime == 2 && endTime == 10);

   readBuffer.frameLength = 10;
   status = ringBuffer->Fetch(readBuffer.mutableAudioBufferList, 10, 0);
   XCTAssertTrue(status == kCARingBufferError_OK);
   [CARBTestsUtility printChannelDataWithTitle:@"Read buffer:" buffer:readBuffer];
   XCTAssertTrue([CARBTestsUtility checkBuffersContentsIsZero:readBuffer bufferOffset:0 numberOfFrames:2]);
   XCTAssertTrue([CARBTestsUtility compareBuffersContents:secondaryWriteBuffer writeBufferOffset:2
                                                       readBuffer:readBuffer readBufferOffset:2 numberOfFrames:2]);
   XCTAssertTrue([CARBTestsUtility compareBuffersContents:writeBuffer writeBufferOffset:0
                                                       readBuffer:readBuffer readBufferOffset:4 numberOfFrames:6]);
}

- (void)testIOEdgeCases {
   CARingBufferError status = kCARingBufferError_OK;

   status = ringBuffer->Store(writeBuffer.audioBufferList, 0, 0);
   XCTAssertTrue(status == kCARingBufferError_OK);

   status = ringBuffer->Store(writeBuffer.audioBufferList, 512, 0);
   XCTAssertTrue(status == kCARingBufferError_TooMuch);

   status = ringBuffer->Fetch(readBuffer.mutableAudioBufferList, 0, 0);
   XCTAssertTrue(status == kCARingBufferError_OK);
}

@end
