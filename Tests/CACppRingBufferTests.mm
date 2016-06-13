//
//  CARingBufferTests.m
//  CARingBuffer
//
//  Created by Vlad Gorlov on 12.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AVFoundation/AVFoundation.h>
#import "CARingBuffer.h"

void generateSampleChannelData(AVAudioPCMBuffer* buffer, UInt32 numberOfFrames, UInt32 biasValue = 1) {
	AudioBufferList *anABL = buffer.mutableAudioBufferList;
	for (UInt32 numberOfBuffer = 0; numberOfBuffer < anABL->mNumberBuffers; ++numberOfBuffer) {
		for (UInt32 numberOfFrame = 0; numberOfFrame < numberOfFrames; ++numberOfFrame) {
			float *floatData = (float *)anABL->mBuffers[numberOfBuffer].mData;
			floatData[numberOfFrame] = biasValue + 0.1 * numberOfBuffer + 0.01 * numberOfFrame;
		}
	}
	buffer.frameLength = numberOfFrames;
}

void printChannelData(const char * title, AVAudioPCMBuffer *buffer) {
	puts(title);
	AudioBufferList *anABL = buffer.mutableAudioBufferList;
	for (UInt32 numberOfFrame = 0; numberOfFrame < buffer.frameLength; ++numberOfFrame) {
		for (UInt32 numberOfBuffer = 0; numberOfBuffer < anABL->mNumberBuffers; ++numberOfBuffer) {
			float *floatData = (float *)anABL->mBuffers[numberOfBuffer].mData;
			float sampleValue = floatData[numberOfFrame];
			printf("%6.3f ", sampleValue);
		}
		printf("\n");
	}
}

BOOL compareBuffersContents(AVAudioPCMBuffer *writeBuffer, UInt32 writeBufferOffset,
									 AVAudioPCMBuffer* readBuffer, UInt32 readBufferOffset, UInt32 numberOfFrames) {
	assert(writeBuffer.frameLength >= writeBufferOffset + numberOfFrames);
	assert(readBuffer.frameLength >= readBufferOffset + numberOfFrames);
	assert(writeBuffer.format.channelCount == readBuffer.format.channelCount);
	AudioBufferList *writeABL = writeBuffer.mutableAudioBufferList;
	AudioBufferList *readABL = readBuffer.mutableAudioBufferList;
	for (UInt32 numberOfBuffer = 0; numberOfBuffer < writeABL->mNumberBuffers; ++numberOfBuffer) {
		for (UInt32 numberOfFrame = 0; numberOfFrame < numberOfFrames; ++numberOfFrame) {
			float *floatDataWrite = (float *)writeABL->mBuffers[numberOfBuffer].mData;
			float *floatDataRead = (float *)readABL->mBuffers[numberOfBuffer].mData;
			float sampleValueWrite = floatDataWrite[numberOfFrame + writeBufferOffset];
			float sampleValueRead = floatDataRead[numberOfFrame + readBufferOffset];
			if (sampleValueWrite != sampleValueRead) {
				return false;
			}
		}
	}
	return true;
}

BOOL checkBuffersContentsIsZero(AVAudioPCMBuffer *buffer, UInt32 bufferOffset, UInt32 numberOfFrames) {
	assert(buffer.frameLength >= bufferOffset + numberOfFrames);
	AudioBufferList *abl = buffer.mutableAudioBufferList;
	for (UInt32 numberOfBuffer = 0; numberOfBuffer < abl->mNumberBuffers; ++numberOfBuffer) {
		for (UInt32 numberOfFrame = 0; numberOfFrame < numberOfFrames; ++numberOfFrame) {
			float *floatData = (float *)abl->mBuffers[numberOfBuffer].mData;
			float sampleValue = floatData[numberOfFrame + bufferOffset];
			if (sampleValue != 0) {
				return false;
			}
		}
	}
	return true;
}

@interface CACppRingBufferTests : XCTestCase {
	CARingBuffer *ringBuffer;
	AVAudioPCMBuffer *writeBuffer;
	AVAudioPCMBuffer *secondaryWriteBuffer;
	AVAudioPCMBuffer *readBuffer;
}
@end

@implementation CACppRingBufferTests

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
	generateSampleChannelData(writeBuffer, 4);
	printChannelData("Write buffer:", writeBuffer);
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
	printChannelData("Read buffer (1 part):", readBuffer);
	XCTAssertTrue(compareBuffersContents(writeBuffer, 0, readBuffer, 0, 2));
	status = ringBuffer->GetTimeBounds(startTime, endTime);
	XCTAssertTrue(status == kCARingBufferError_OK);
	XCTAssertTrue(startTime == 0 && endTime == 4);

	status = ringBuffer->Fetch(readBuffer.mutableAudioBufferList, 2, 2);
	XCTAssertTrue(status == kCARingBufferError_OK);
	printChannelData("Read buffer (2 part):", readBuffer);
	XCTAssertTrue(compareBuffersContents(writeBuffer, 2, readBuffer, 0, 2));
	status = ringBuffer->GetTimeBounds(startTime, endTime);
	XCTAssertTrue(status == kCARingBufferError_OK);
	XCTAssertTrue(startTime == 0 && endTime == 4);
}

- (void)testReadBehindAndAhead {
	generateSampleChannelData(writeBuffer, 4);
	printChannelData("Write buffer:", writeBuffer);
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
	printChannelData("Read buffer (1 part):", readBuffer);
	XCTAssertTrue(compareBuffersContents(writeBuffer, 0, readBuffer, 2, 2));
	XCTAssertTrue(checkBuffersContentsIsZero(readBuffer, 0, 2));

	status = ringBuffer->Fetch(readBuffer.mutableAudioBufferList, 4, 4);
	XCTAssertTrue(status == kCARingBufferError_OK);
	printChannelData("Read buffer (2 part):", readBuffer);
	XCTAssertTrue(compareBuffersContents(writeBuffer, 2, readBuffer, 0, 2));
	XCTAssertTrue(checkBuffersContentsIsZero(readBuffer, 2, 2));
}

- (void)testWriteBehindAndAhead {
	generateSampleChannelData(secondaryWriteBuffer, 8, 2);
	printChannelData("Secondary write buffer:", secondaryWriteBuffer);
	CARingBufferError status = kCARingBufferError_OK;

	status = ringBuffer->Store(secondaryWriteBuffer.audioBufferList, 8, 0);
	XCTAssertTrue(status == kCARingBufferError_OK);

	CARingBuffer::SampleTime startTime = 0;
	CARingBuffer::SampleTime endTime = 0;
	status = ringBuffer->GetTimeBounds(startTime, endTime);
	XCTAssertTrue(status == kCARingBufferError_OK);
	XCTAssertTrue(startTime == 0 && endTime == 8);

	generateSampleChannelData(writeBuffer, 4);
	printChannelData("Write buffer:", writeBuffer);
	status = ringBuffer->Store(writeBuffer.audioBufferList, 4, 2);
	XCTAssertTrue(status == kCARingBufferError_OK);
	status = ringBuffer->GetTimeBounds(startTime, endTime);
	XCTAssertTrue(status == kCARingBufferError_OK);
	XCTAssertTrue(startTime == 2 && endTime == 6);

	readBuffer.frameLength = 8;
	status = ringBuffer->Fetch(readBuffer.mutableAudioBufferList, 8, 0);
	XCTAssertTrue(status == kCARingBufferError_OK);
	printChannelData("Read buffer:", readBuffer);
	XCTAssertTrue(compareBuffersContents(writeBuffer, 0, readBuffer, 2, 4));
	XCTAssertTrue(checkBuffersContentsIsZero(readBuffer, 0, 2));
	XCTAssertTrue(checkBuffersContentsIsZero(readBuffer, 6, 2));
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
	printChannelData("Read buffer:", readBuffer);
	XCTAssertTrue(checkBuffersContentsIsZero(readBuffer, 0, 4));
}

- (void)testIOWithWrapping {
	generateSampleChannelData(secondaryWriteBuffer, 4, 2);
	printChannelData("Secondary write buffer:", secondaryWriteBuffer);
	CARingBufferError status = kCARingBufferError_OK;

	status = ringBuffer->Store(secondaryWriteBuffer.audioBufferList, 4, 0);
	XCTAssertTrue(status == kCARingBufferError_OK);

	generateSampleChannelData(writeBuffer, 6);
	printChannelData("Write buffer:", writeBuffer);

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
	printChannelData("Read buffer:", readBuffer);
	XCTAssertTrue(checkBuffersContentsIsZero(readBuffer, 0, 2));
	XCTAssertTrue(compareBuffersContents(secondaryWriteBuffer, 2, readBuffer, 2, 2));
	XCTAssertTrue(compareBuffersContents(writeBuffer, 0, readBuffer, 4, 6));
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

@interface CACppRingBufferPerformanceTests : XCTestCase
@end

@implementation CACppRingBufferPerformanceTests

- (void)testPerformanceExample {
	UInt32 numberOfChannels = 2;
	UInt32 IOCapacity = 512;
	AVAudioFormat *audioFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:numberOfChannels];
	AVAudioPCMBuffer *writeBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:IOCapacity];
	AVAudioPCMBuffer *readBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:IOCapacity];
	CARingBuffer *ringBuffer = new CARingBuffer();
	ringBuffer->Allocate(numberOfChannels, sizeof(float), 4096);
	generateSampleChannelData(writeBuffer, IOCapacity);
	[self measureBlock:^{
		CARingBufferError status;
		for (UInt32 iteration = 0; iteration < 1000000; ++iteration) {
			status = ringBuffer->Store(writeBuffer.audioBufferList, IOCapacity, IOCapacity * iteration);
			XCTAssertTrue(status == kCARingBufferError_OK);

			status = ringBuffer->Fetch(readBuffer.mutableAudioBufferList, IOCapacity, IOCapacity * iteration);
			XCTAssertTrue(status == kCARingBufferError_OK);
		}
	}];
}

@end
