//
//  BLEService+CBPeripheral.swift
//  BLEService
//
//  Created by Yohai Reshef on 05/08/2021.
//

import Foundation
import CoreBluetooth

// MARK: - Extension CBPeripheral
//===============================

extension CBPeripheral{
  /// Helper to find the service we're interested in.
  var desiredService: CBService? {
    guard let services = services else { return nil }
    return services.first { $0.uuid == BLEService.sharedInstance?.desiredServicesID }
  }
  
  /// Helper to find the characteristic we're interested in.
  var desiredCharacteristic: CBCharacteristic? {
    guard let characteristics = desiredService?.characteristics else {
      return nil
    }
    return characteristics.first { $0.uuid == BLEService.sharedInstance?.desiredCharacteristicsID }
  }
}
