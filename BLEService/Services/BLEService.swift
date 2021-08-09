//
//  BLEService.swift
//  BLEService
//
//  Created by Yohai Reshef on 04/08/2021.
//


//TODO: Transition to model based implementation
//TODO: Re-implement using combine
//TODO: Add my logger

import Foundation
import CoreBluetooth
import Combine

// MARK: - Protocol

protocol BLEServiceable {
    func initializeConnection()
    func scan()
    func connect(to peripheral: CBPeripheral)
    func disconnect(forgetPeripheral: Bool)
    func setConnected(to peripheral: CBPeripheral)
    func discoverServices(for peripheral: CBPeripheral)
    func discoverCharacteristics(for peripheral: CBPeripheral)
    
}

// MARK: - BLEService

public class BLEService: BLEServiceable {
    
    // MARK: - Properties | Variables
    
    public static var sharedInstance: BLEService?
    let centralManager: CBCentralManager
    
    internal var state = State.poweredOff
    var restoreIDKey: String
    var peripheralDefaultsKey: String?
    internal var desiredServicesID: CBUUID
    var desiredCharacteristicsID: CBUUID
    let outOfRangeErrors: Set<CBError.Code> =
        [
            .unknown,
            .connectionTimeout,
            .peripheralDisconnected,
            .connectionFailed
        ]
    let actionTimer = 10.0 ///Timer for countdown closure
    
    // MARK: - Life Cycle

    init(restoreIDKey: String,
         peripheralDefaultsKey: String,
         serviceID: CBUUID,
         characteristicsID: CBUUID) {
        
        self.restoreIDKey = restoreIDKey
        self.peripheralDefaultsKey = peripheralDefaultsKey
        self.desiredServicesID = serviceID
        self.desiredCharacteristicsID = characteristicsID
        
        self.centralManager = CBCentralManager(
            delegate: BLECentralDelegate.sharedInstance,
            queue: nil,
            options: [CBCentralManagerOptionRestoreIdentifierKey: peripheralDefaultsKey])
        
        BLEService.sharedInstance = self
    }
    
    // MARK: - Methods
    
    public func initializeConnection() {
        
        /*
         If device been connected to before - discover services
         Forgoes the need to re-scan for devices
        */
        if let connectedPeripheral = BLEService
            .sharedInstance?
            .centralManager
            .retrieveConnectedPeripherals(
                withServices: [desiredServicesID]).first {
            print("Device already connected before, discovering services")
            BLEService
                .sharedInstance?
                .discoverCharacteristics(for: connectedPeripheral)
        } else {
            print("Scanning for new devices")
            BLEService.sharedInstance?.scan()
        }
    }
    
    internal func scan() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth is powered off -- cannot scan for devices")
            return
        }
        print("Scanning for new devices")
        centralManager.scanForPeripherals(withServices: [desiredServicesID])
        state = .scanning(Countdown(seconds: actionTimer, closure: {
            self.centralManager.stopScan()
            self.state = .disconnected
            print("Scan timed out")
        }))
    }
    
    internal func connect(to peripheral: CBPeripheral) {
        print("Connecting to device: \(peripheral)")
        
        ///Retaining peripheral in peripheral enum to facilitate reconnection
        /// without the need for a new scan
        centralManager.connect(peripheral)
        state = .connecting(peripheral, Countdown(seconds: actionTimer, closure: {
            self.centralManager.cancelPeripheralConnection(peripheral)
            self.state = .disconnected
            print("Device connection timed out")
        }))
    }
    
    internal func disconnect(forgetPeripheral: Bool = false) {
        if let peripheral = state.peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        if forgetPeripheral {
            if let defaultsKey = peripheralDefaultsKey {
                print("Forgetting device")
                UserDefaults.standard.removeObject(forKey: defaultsKey)
                UserDefaults.standard.synchronize()
            }
        }
        print("Disconnected from peripheral")
        state = .disconnected
    }
    
    
    internal func setConnected(to peripheral: CBPeripheral) {
        guard let desiredCharacteristics = peripheral.desiredCharacteristic else {
            print("Missing characteristics")
            disconnect()
            return
        }
        
        ///Save device id for future reconnection
        if let defaultsKey = peripheralDefaultsKey {
            UserDefaults.standard.setValue(
                peripheral.identifier.uuidString,
                forKey: defaultsKey)
            UserDefaults.standard.synchronize()
        }
        
        state = .connected(peripheral)
    }
    
    internal func discoverServices(for peripheral: CBPeripheral) {
        print("Discovering services")
        peripheral.delegate = BLEPeripheralDelegate.sharedInstance
        peripheral.discoverServices([desiredServicesID])
        state = .discoveringServices(
            peripheral,
            Countdown(seconds: actionTimer, closure: {
                self.disconnect()
                print("Could not discover services for \(peripheral)")
            }))
    }
    
    internal func discoverCharacteristics(for peripheral: CBPeripheral) {
        guard let desiredServices = peripheral.desiredService else {
            self.disconnect()
            return
        }
        print("Discovering chars. for \(peripheral)")
        peripheral.delegate = BLEPeripheralDelegate.sharedInstance
        peripheral.discoverCharacteristics(
            [desiredCharacteristicsID],
            for: desiredServices)
        state = .discoveringCharacteristics(
            peripheral,
            Countdown(seconds: actionTimer, closure: {
                self.disconnect()
                print("Could not discover characteristics for: \(peripheral)")
            }))
    }   
}
