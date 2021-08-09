//
//  BLEPeripheralDelegate.swift
//  BLEService
//
//  Created by Yohai Reshef on 05/08/2021.
//

import Foundation
import CoreBluetooth
import Combine

//TODO: Add combine implementation

class BLEPeripheralDelegate: NSObject, CBPeripheralDelegate {
    
    // MARK: - Properties | Variables
    
    public static let sharedInstance = BLEPeripheralDelegate()
    
    // MARK: - Methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard case .discoveringServices = BLEService.sharedInstance?.state else {
            return
        }
        print("Did discover services")
        if let error = error {
            print("failed to discover services: \(error.localizedDescription)")
            BLEService.sharedInstance?.disconnect()
            return
        }
        guard peripheral.desiredService != nil else {
            print("Missing desired services")
            return
        }
        BLEService.sharedInstance?.discoverCharacteristics(for: peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard case .discoveringCharacteristics = BLEService.sharedInstance?.state else {
            return
        }
        print("Dis discover characteristics")
        if let error = error {
            print("Failed to discover characteristics: \(error.localizedDescription)")
            BLEService.sharedInstance?.disconnect()
            return
        }
        guard peripheral.desiredCharacteristic != nil else {
            print("Missing characteristics")
            return
        }
        BLEService.sharedInstance?.setConnected(to: peripheral)
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            if characteristic.properties.contains(.notify){
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error! \(error.localizedDescription)")
        }
        guard let data = characteristic.value else {
            print("No data has been recorded")
            return
        }
        switch characteristic.uuid {
        case BLEService.sharedInstance?.desiredCharacteristicsID:
            //TODO: Handle data here using combine
            print("Your data is being sent as we speak!")
        default:
            print("Unhandled characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        //TODO: Implement
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        //TODO: Implement
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        //TODO: Implement
    }

}
