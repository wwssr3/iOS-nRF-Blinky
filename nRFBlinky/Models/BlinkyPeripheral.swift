//
//  BlinkyPeripheral.swift
//  nRFBlinky
//
//  Created by Mostafa Berg on 28/11/2017.
//  Copyright © 2017 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit
import AVFoundation
import CoreBluetooth

class BlinkyPeripheral: NSObject, CBPeripheralDelegate {
    //MARK: - Blinky services and charcteristics Identifiers
    //

    public static let SOUND_SERVICE  = CBUUID.init(string: "000018ff-0000-1000-8000-00805f9b34fb")
    public static let SOUND_CHARACTERISTIC = CBUUID.init(string: "00002aff-0000-1000-8000-00805f9b34fb")
    public static let SOUND_CHARACTERISTIC_DESCRIPTOR    = CBUUID.init(string: "00002902-0000-1000-8000-00805f9b34fb")
    
    
    public static let JB_CONFIG_SERVICE_UUID  = CBUUID.init(string: "6e400100-b5a3-f393-e0a9-e50e24dcca9e")
    public static let JB_FIRMWARE_VERSION_CHARACERISTIC_UUID = CBUUID.init(string: "6e400102-b5a3-f393-e0a9-e50e24dcca9e")
    public static let LED_CHARACTERISTIC = CBUUID.init(string: "6e400103-b5a3-f393-e0a9-e50e24dcca9e")
    public static let POWER_CHARACTERISTIC = CBUUID.init(string: "6e400104-b5a3-f393-e0a9-e50e24dcca9e")
    public static let MAGNET_ADJUST_CHARACTERISTIC = CBUUID.init(string: "6e400105-b5a3-f393-e0a9-e50e24dcca9e")
    public static let JB_FEEDBACK_CHARACTERISTIC = CBUUID.init(string: "6e400106-b5a3-f393-e0a9-e50e24dcca9e")
    
    
    
    //MARK: - Properties
    //
    public private(set) var basePeripheral      : CBPeripheral
    public private(set) var advertisedName      : String?
    public private(set) var RSSI                : NSNumber
    public private(set) var advertisedServices  : [CBUUID]?
    
    //MARK: - Callback handlers
    private var ledCallbackHandler : ((Bool) -> (Void))?
    private var buttonPressHandler : ((Bool) -> (Void))?

    //MARK: - Services and Characteristic properties
    //
    private             var blinkyService       : CBService?
    private             var buttonCharacteristic: CBCharacteristic?
    private             var ledCharacteristic   : CBCharacteristic?

    init(withPeripheral aPeripheral: CBPeripheral, advertisementData anAdvertisementDictionary: [String : Any], andRSSI anRSSI: NSNumber) {
        basePeripheral = aPeripheral
        RSSI = anRSSI
        super.init()
        (advertisedName, advertisedServices) = parseAdvertisementData(anAdvertisementDictionary)
        basePeripheral.delegate = self
    }
    
    public func setLEDCallback(aCallbackHandler: @escaping (Bool) -> (Void)){
        ledCallbackHandler = aCallbackHandler
    }

    public func setButtonCallback(aCallbackHandler: @escaping (Bool) -> (Void)) {
        buttonPressHandler = aCallbackHandler
    }
    
    public func removeButtonCallback() {
        buttonPressHandler = nil
    }
    
    public func removeLEDCallback() {
        ledCallbackHandler = nil
    }

    public func discoverBlinkyServices() {
        print("Discovering blinky service")
        basePeripheral.delegate = self
        basePeripheral.discoverServices(nil)
    }
    
    public func discoverCharacteristicsForBlinkyService(_ aService: CBService) {
        basePeripheral.discoverCharacteristics([BlinkyPeripheral.SOUND_CHARACTERISTIC,
                                            BlinkyPeripheral.SOUND_CHARACTERISTIC_DESCRIPTOR],
                                           for: aService)
    }
    
    
    public func enableButtonNotifications(_ buttonCharacteristic: CBCharacteristic) {
        print("Enabling notifications for button characteristic")
        basePeripheral.setNotifyValue(true, for: buttonCharacteristic)
    }
    
    public func readLEDValue() {
        if let ledCharacteristic = ledCharacteristic {
            basePeripheral.readValue(for: ledCharacteristic)
        }
    }
    
    public func readButtonValue() {
        if let buttonCharacteristic = buttonCharacteristic {
            basePeripheral.readValue(for: buttonCharacteristic)
        }
    }

    public func didWriteValueToLED(_ aValue: Data) {
        print("LED value written \(aValue[0])")
        if aValue[0] == 1 {
            ledCallbackHandler?(true)
        } else {
            ledCallbackHandler?(false)
        }
    }
    
    public func didReceiveButtonNotificationWithValue(_ aValue: Data) {
        var player:AVAudioPlayer?
        do {
            player = try AVAudioPlayer.init(data: aValue)
            
            
            player?.play()
        } catch let error {
            print(error.localizedDescription)
        }
        
        
        
        
        
//        print("Button value changed to: \(aValue[0])")
//        if aValue[0] == 1 {
//            buttonPressHandler?(true)
//        } else {
//            buttonPressHandler?(false)
//        }
    }
    
    public func turnOnLED() {
        writeLEDCharcateristicValue(Data([0x1]))
    }
    
    public func turnOffLED() {
        writeLEDCharcateristicValue(Data([0x0]))
    }
    
    private func writeLEDCharcateristicValue(_ aValue: Data) {
        guard let ledCharacteristic = ledCharacteristic else {
            print("LED characteristic is not present, nothing to be done")
            return
        }
        basePeripheral.writeValue(aValue, for: ledCharacteristic, type: .withResponse)
    }

    private func parseAdvertisementData(_ anAdvertisementDictionary: [String : Any]) -> (String?, [CBUUID]?) {
        var advertisedName: String
        var advertisedServices: [CBUUID]

        if let name = anAdvertisementDictionary[CBAdvertisementDataLocalNameKey] as? String{
            advertisedName = name
        } else {
            advertisedName = "N/A"
        }
        if let services = anAdvertisementDictionary[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            advertisedServices = services
        } else {
            advertisedServices = [CBUUID]()
        }
        
        return (advertisedName, advertisedServices)
    }
    
    //MARK: - NSObject protocols
    override func isEqual(_ object: Any?) -> Bool {
        if object is BlinkyPeripheral {
            let peripheralObject = object as! BlinkyPeripheral
            return peripheralObject.basePeripheral.identifier == basePeripheral.identifier
        } else if object is CBPeripheral {
            let peripheralObject = object as! CBPeripheral
            return peripheralObject.identifier == basePeripheral.identifier
        } else {
            return false
        }
    }
    
    //MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == buttonCharacteristic {
            if let aValue = characteristic.value {
                didReceiveButtonNotificationWithValue(aValue)
            }
        } else if characteristic == ledCharacteristic {
            if let aValue = characteristic.value {
                didWriteValueToLED(aValue)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == buttonCharacteristic?.uuid {
            print("Notification state is now \(characteristic.isNotifying) for Button characteristic")
//            readButtonValue()
//            readLEDValue()
        } else {
            print("Notification state is now \(characteristic.isNotifying) for an unknown characteristic with UUID: \(characteristic.uuid.uuidString)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for aService in services {
                print("Discovered Blinky service! \(aService) )")
                if aService.uuid == BlinkyPeripheral.SOUND_SERVICE {
                    
                    //Capture and discover all characteristics for the blinky service
                    blinkyService = aService
                    discoverCharacteristicsForBlinkyService(blinkyService!)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if service == blinkyService {
            print("Discovered characteristics for blinky service")
            if let characteristics = service.characteristics {
                for aCharacteristic in characteristics {
                    
                    print("Discovered Blinky characteristics! \(aCharacteristic.uuid) \(String(describing: aCharacteristic.descriptors))")
                    if aCharacteristic.uuid == BlinkyPeripheral.SOUND_CHARACTERISTIC {
                        print("Discovered Blinky Sound characteristic")
                        buttonCharacteristic = aCharacteristic
                        
                        peripheral.discoverDescriptors(for: aCharacteristic)
                    }
                }
            }
        } else {
            print("Discovered characteristics for an unnknown service with UUID: \(service.uuid.uuidString)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if let descriptors = characteristic.descriptors {
            for descriptor in descriptors {
                if descriptor.uuid == BlinkyPeripheral.SOUND_CHARACTERISTIC_DESCRIPTOR {
//                    enableButtonNotifications(buttonCharacteristic!)
                    
                    peripheral.readValue(for: descriptor)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        
        
//        let aValue = descriptor.value as! Data
//        var player:AVAudioPlayer?
//        do {
//            player = try AVAudioPlayer.init(data: aValue)
//            
//            
//            player?.play()
//        } catch let error {
//            print(error.localizedDescription)
//        }
    }
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == ledCharacteristic {
            peripheral.readValue(for: ledCharacteristic!)
        }
    }
}
