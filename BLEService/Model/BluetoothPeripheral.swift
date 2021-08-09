//
//  BluetoothPeripheral.swift
//  BLEService
//
//  Created by Yohai Reshef on 04/08/2021.
//

import Foundation
import CoreBluetooth

struct BluetoothPeripheral: Hashable{
  var value: CBPeripheral
  func hash(into hasher: inout Hasher) {
    hasher.combine(value.identifier)
  }
}
