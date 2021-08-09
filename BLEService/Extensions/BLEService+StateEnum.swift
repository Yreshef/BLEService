//
//  BLEService+StateEnum.swift
//  BLEService
//
//  Created by Yohai Reshef on 04/08/2021.
//

import Foundation
import CoreBluetooth

extension BLEService {
    enum State {
        case poweredOff
        case restoringConnectingPeripheral(CBPeripheral)
        case restoringConnectedPeripheral(CBPeripheral)
        case disconnected
        case scanning(Countdown)
        case connecting(CBPeripheral, Countdown)
        case discoveringServices(CBPeripheral, Countdown)
        case discoveringCharacteristics(CBPeripheral, Countdown)
        case connected(CBPeripheral)
        case outOfRange(CBPeripheral)
        
        internal var peripheral: CBPeripheral? {
          switch self {
          case .poweredOff: return nil
          case .restoringConnectingPeripheral(let p): return p
          case .restoringConnectedPeripheral(let p): return p
          case .disconnected: return nil
          case .scanning: return nil
          case .connecting(let p, _): return p
          case .discoveringServices(let p, _): return p
          case .discoveringCharacteristics(let p, _): return p
          case .connected(let p): return p
          case .outOfRange(let p): return p
          }
        }
    }
}

extension BLEService.State: Equatable {
    static func == (lhs: BLEService.State, rhs: BLEService.State) -> Bool {
      switch (lhs, rhs) {
      case (.outOfRange(_), .outOfRange(_)): return true
      default: return false
      }
    }
}

