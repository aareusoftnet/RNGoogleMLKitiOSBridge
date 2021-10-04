//
//  RTPosDetectorManager.swift
//  BridgingDemo
//

import Foundation

@objc(NativeMLKitManager)
class NativeMLKitManager: RCTViewManager {

    override static func requiresMainQueueSetup() -> Bool {
        return true
    }

    override func view() -> UIView! {
        return RTPosDetectorView()
    }
}
