//
//  BLECentralDelegate.swift
//  BLEService
//
//  Created by Yohai Reshef on 04/08/2021.
//

import Foundation
import CoreBluetooth

class BLECentralDelegate: NSObject, CBCentralManagerDelegate {
    
    // MARK: - Properties | Variables&Constants
    
    static let sharedInstance = BLECentralDelegate()
    private(set) var connectedPeripherals: Set<CBPeripheral> = []
    
    // MARK: - Methods
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            ///Check if transitioning from powered off state
            switch BLEService.sharedInstance?.state {
            case .poweredOff:
                ///Try reconnect to device
                if let defaultsKey = BLEService
                    .sharedInstance?.peripheralDefaultsKey {
                    if let peripheralIDStr = UserDefaults.standard.object(
                        forKey: defaultsKey) as? String,
                       let peripheralID = UUID(uuidString: peripheralIDStr),
                       let previouslyConnected = central.retrievePeripherals(withIdentifiers: [peripheralID]).first
                    {
                        BLEService.sharedInstance?.connect(to: previouslyConnected)
                    }
                }
            ///Check if CB was woken up with a peripheral in 'connecting' state
            case .restoringConnectingPeripheral(let peripheral):
                BLEService.sharedInstance?.connect(to: peripheral)
                
            ///Check if CB was woken up with a 'connected' peripheral,
            ///but had to wait until 'poweredOn' state
            case .restoringConnectedPeripheral(let peripheral):
                
                if peripheral.desiredCharacteristic == nil {
                    BLEService.sharedInstance?.discoverServices(for: peripheral)
                } else {
                    BLEService.sharedInstance?.setConnected(to: peripheral)
                }
            default:
                ///Try to pair to the device connected to the system
                if let desiredServiceID = BLEService.sharedInstance?.desiredServicesID,
                   let systemConnected = central.retrieveConnectedPeripherals(withServices: [desiredServiceID]).first {
                    BLEService.sharedInstance?.connect(to: systemConnected)
                } else {
                    ///Never paired before(or unpaired manually)
                    BLEService.sharedInstance?.state = .disconnected
                }
            }
        } else {
            BLEService.sharedInstance?.state = .poweredOff
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        let peripherals: [CBPeripheral] = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []
        if peripherals.count > 1 {
            //TODO: Handle more than one connection
            print("WARNING! willRestoreState called with more than one connection")
        }
        print("Looking for stored peripherals")
        if let peripheral = peripherals.first {
            switch peripheral.state {
            case .connecting:
                print("Connecting to stored peripheral: \(peripheral)")
                BLEService.sharedInstance?.state =
                    .restoringConnectingPeripheral(peripheral)
                if let defaultsKey = BLEService.sharedInstance?
                    .peripheralDefaultsKey,
                   let _ = UserDefaults.standard
                    .object(forKey: defaultsKey) as? String,
                   let previouslyConnected = central
                    .retrievePeripherals(
                        withIdentifiers: [peripheral.identifier]).first {
                    BLEService.sharedInstance?
                        .centralManager.connect(previouslyConnected)
                }
            case .connected:
                print("Connected to stored peripheral: \(peripheral)")
                BLEService.sharedInstance?.state =
                    .restoringConnectedPeripheral(peripheral)
                if let defaultsKey = BLEService.sharedInstance?
                    .peripheralDefaultsKey,
                   let desiredServiceID = BLEService.sharedInstance?.desiredServicesID,
                   let _ = UserDefaults.standard
                    .object(forKey: defaultsKey) as? String,
                   let previouslyConnected = central
                    .retrieveConnectedPeripherals(
                        withServices: [desiredServiceID]).first{
                    BLEService.sharedInstance?
                        .centralManager.connect(previouslyConnected)
                }
            default:
                print("Could not reconnect to peripheral: \(peripheral)")
                break
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard case .scanning = BLEService.sharedInstance?.state else{ return }
        central.stopScan()
        BLEService.sharedInstance?.connect(to: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Did connect to peripheral: \(peripheral)")
        connectedPeripherals.insert(peripheral)
        if peripheral.desiredCharacteristic == nil {
            BLEService.sharedInstance?.discoverServices(for: peripheral)
        } else {
            BLEService.sharedInstance?.setConnected(to: peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to peripheral.\nState: \(BLEService.sharedInstance?.state)")
        if BLEService.sharedInstance?.state == .outOfRange(peripheral) {
            print("Failed to connect -- starting OOR reconnection proccess")
            BLEService.sharedInstance?.centralManager.connect(peripheral)
            return
        }
        print("Failed to connect to peripheral \(peripheral)")
        BLEService.sharedInstance?.state = .disconnected
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Did disconnect device: \(peripheral.name)")
        if BLEService.sharedInstance?.state.peripheral?.identifier ==
            peripheral.identifier {
            if let error = error,
               (error as NSError).domain == CBErrorDomain,
               let code = CBError.Code(rawValue: (error as NSError).code),
               let outOfRangeError = BLEService.sharedInstance?.outOfRangeErrors,
               outOfRangeError.contains(code){
                print("Error! \(error.localizedDescription),"
                        + " with error code: \(code.rawValue)")
                ///CB will try and reconnect without timing out until the
                ///device is back in range
                print("Peripheral is: \(peripheral.name)")
                BLEService.sharedInstance?.centralManager.connect(peripheral)
                print("Started reconnection process")
                BLEService.sharedInstance?.state = .outOfRange(peripheral)
            } else {
                ///Probably a deliberate unpairing
                connectedPeripherals.remove(peripheral)
                BLEService.sharedInstance?.state = .disconnected
            }
        }
    }
    
}
