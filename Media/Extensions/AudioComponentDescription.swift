//
//  AudioComponentDescription.swift
//  WLMedia
//
//  Created by Vlad Gorlov on 23.03.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import AVFoundation

public extension AudioComponentDescription {
	public init(type: OSType, subType: OSType, manufacturer: OSType = kAudioUnitManufacturer_Apple,
	            flags: UInt32 = 0, flagsMask: UInt32 = 0) {
		self.init(componentType: type, componentSubType: subType, componentManufacturer: manufacturer,
		                                 componentFlags: flags, componentFlagsMask: flagsMask)
	}
}
