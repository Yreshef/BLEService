//
//  BLEService+ErrorEnum.swift
//  BLEService
//
//  Created by Yohai Reshef on 04/08/2021.
//

import Foundation
import CoreBluetooth

extension BLEService {
    private enum BLEError: LocalizedError {
        case notConnected
        case missingCharacteristic
        
        var errorDescription: String? {
            switch self {
            case .notConnected:
                return "Error: BLE peripheral is not connected"
            case .missingCharacteristic:
                return "Error: Missing characteristic"
            }
        }
    }
}
