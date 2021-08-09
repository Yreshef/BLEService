//
//  BLEPacket.swift
//  BLEService
//
//  Created by Yohai Reshef on 04/08/2021.
//

import Foundation

public struct BLEPacket: Equatable {
    var data: Data?
    var peripheralID: String
    //NSError because it conforms to equatable
    var error: NSError?
}
