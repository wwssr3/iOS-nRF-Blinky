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
import IOSThingyLibrary

class BlinkyPeripheral: NSObject, CBPeripheralDelegate {
    //MARK: - Blinky services and charcteristics Identifiers
    //

    public static let SOUND_SERVICE  = CBUUID.init(string: "000018ff-0000-1000-8000-00805f9b34fb")//
    public static let SOUND_CHARACTERISTIC = CBUUID.init(string: "00002aff-0000-1000-8000-00805f9b34fb")
    public static let SOUND_CHARACTERISTIC_DESCRIPTOR    = CBUUID.init(string: "00002902-0000-1000-8000-00805f9b34fb")
    
    
    public static let Nordic_UART_Service_UUID  = CBUUID.init(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    public static let Nordic_UART_RX_Characteristic  = CBUUID.init(string: "6e400002-B5A3-F393-E0A9-E50E24DCCA9E")
    public static let Nordic_UART_TX_Characteristic  = CBUUID.init(string: "6e400003-B5A3-F393-E0A9-E50E24DCCA9E")
    public static let JB_FIRMWARE_VERSION_CHARACERISTIC_UUID = CBUUID.init(string: "6e400102-b5a3-f393-e0a9-e50e24dcca9e")
    public static let LED_CHARACTERISTIC = CBUUID.init(string: "6e400103-b5a3-f393-e0a9-e50e24dcca9e")
    public static let POWER_CHARACTERISTIC = CBUUID.init(string: "6e400104-b5a3-f393-e0a9-e50e24dcca9e")
    public static let MAGNET_ADJUST_CHARACTERISTIC = CBUUID.init(string: "6e400105-b5a3-f393-e0a9-e50e24dcca9e")
    public static let JB_FEEDBACK_CHARACTERISTIC = CBUUID.init(string: "6e400106-b5a3-f393-e0a9-e50e24dcca9e")
    
    public static let  SENSOR_SERVICE = CBUUID.init(string:"000018fe-0000-1000-8000-00805f9b34fb")//
    public static let  SENSOR_CHARACTERISTIC = CBUUID.init(string:"00002afd-0000-1000-8000-00805f9b34fb")
    public static let  SENSOR_CHARACTERISTIC_DESCRIPTOR = CBUUID.init(string:"00002902-0000-1000-8000-00805f9b34fb")
    
    
    
    public static let  SENSOR_SERVICE1 = CBUUID.init(string:"00001800-0000-1000-8000-00805f9b34fb")
    public static let  SENSOR_SERVICE2 = CBUUID.init(string:"00001801-0000-1000-8000-00805f9b34fb")
    public static let  SENSOR_SERVICE3 = CBUUID.init(string:"000018f0-0000-1000-8000-00805f9b34fb")
    public static let  SENSOR_SERVICE4 = CBUUID.init(string:"0000180f-0000-1000-8000-00805f9b34fb")
    public static let  SENSOR_SERVICE5 = CBUUID.init(string:"0000180a-0000-1000-8000-00805f9b34fb")
    public static let  SECURE_DFU_SERVICE = CBUUID.init(string:"0000FE59-0000-1000-8000-00805F9B34FB")

    //MARK: - Properties
    //
    public var basePeripheral      : CBPeripheral
    public private(set) var advertisedName      : String?
    public private(set) var RSSI                : NSNumber
    public private(set) var advertisedServices  : [CBUUID]?
    
    //MARK: - Callback handlers
    private var ledCallbackHandler : ((Bool) -> (Void))?
    private var buttonPressHandler : ((String) -> (Void))?

    //MARK: - Services and Characteristic properties
    //
    private             var blinkyService       : CBService?
    private             var soundCharacteristic: CBCharacteristic?
    private             var ledCharacteristic   : CBCharacteristic?
    private             var rxCharacteristic   : CBCharacteristic?
    private             var txCharacteristic   : CBCharacteristic?

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

    public func setButtonCallback(aCallbackHandler: @escaping (String) -> (Void)) {
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
        if let buttonCharacteristic = soundCharacteristic {
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
    
    public func didReceiveSoundCharacteristicUpdateWithValue(_ aValue: Data) {

            buttonPressHandler?("Button value changed to: \(aValue[0])")

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
        
        print(characteristic.value!)
        if characteristic == BlinkyPeripheral.SOUND_CHARACTERISTIC {
            print("didUpdateValueFor SOUND_CHARACTERISTIC")
        }
        else if characteristic == soundCharacteristic {
            if let aValue = characteristic.value {
                didReceiveSoundCharacteristicUpdateWithValue(aValue)
            }
        } else if characteristic == ledCharacteristic {
            if let aValue = characteristic.value {
                didWriteValueToLED(aValue)
            }
        } else if characteristic == txCharacteristic {
            print(characteristic.value! as Data)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == soundCharacteristic?.uuid {
            print("Notification state is now \(characteristic.isNotifying) for Button characteristic")
//            readButtonValue()
//            readLEDValue()
        } else if characteristic.uuid == BlinkyPeripheral.Nordic_UART_TX_Characteristic {
            writeBabyPhoneThreshold()
//            writeSystemTime()
        } else {
            print("Notification state is now \(characteristic.isNotifying) for an unknown characteristic with UUID: \(characteristic.uuid.uuidString)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for aService in services {
                print("Discovered service! \(aService) )")
                
                switch aService.uuid {
                case BlinkyPeripheral.SOUND_SERVICE:
                    print("Discovered SOUND_SERVICE service )")
//                    blinkyService = aService
//                    basePeripheral.discoverCharacteristics(nil, for: blinkyService!)
                    //Capture and discover all characteristics for the blinky service
                    
                    break
                case BlinkyPeripheral.SENSOR_SERVICE:
                    print("Discovered SENSOR_SERVICE service )")
//                    blinkyService = aService
//                    basePeripheral.discoverCharacteristics(nil, for: blinkyService!)
                    break
                case BlinkyPeripheral.Nordic_UART_Service_UUID:
                    blinkyService = aService
                    basePeripheral.discoverCharacteristics(nil, for: blinkyService!)
                default:
                    break

                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {

        print("Discovered characteristics for an service with UUID: \(service.uuid.uuidString)")
        if let characteristics = service.characteristics {
            for aCharacteristic in characteristics {
                
                print("Discovered Blinky characteristics! \(aCharacteristic.uuid) \(String(describing: aCharacteristic.descriptors))")
                switch aCharacteristic.uuid {
                case BlinkyPeripheral.SOUND_CHARACTERISTIC:
                    print("SOUND_CHARACTERISTIC")
//                    soundCharacteristic = aCharacteristic
//                    enableButtonNotifications(soundCharacteristic!)
                    break
                case BlinkyPeripheral.Nordic_UART_RX_Characteristic:

                    
                    rxCharacteristic = aCharacteristic
                    
                    break
                case BlinkyPeripheral.Nordic_UART_TX_Characteristic:
                    txCharacteristic = aCharacteristic
                    peripheral.setNotifyValue(true, for: txCharacteristic!)

                default:
                    break
                }
                
            }
        }
        
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("didDiscoverDescriptorsFor \(characteristic)")
        if let descriptors = characteristic.descriptors {
            for descriptor in descriptors {
                if descriptor.uuid == BlinkyPeripheral.SOUND_CHARACTERISTIC_DESCRIPTOR {

                }
            }
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print("didUpdateValueFor \(descriptor)")
        
    }
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == BlinkyPeripheral.Nordic_UART_TX_Characteristic {
            print(characteristic.value! as Data)
        }
    }
    
    func writeSystemTime () {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yy MM dd HH mm ss"
        let stringDate = dateFormatter.string(from: currentDate)
        
        var dataArray : [UInt8] = Array.init(repeating: 0, count: 5)
        dataArray[0] = 0xaa
        dataArray[1] = 0x55
        dataArray[2] = 0x10
        dataArray[3] = 0x07
        dataArray[4] = 20
        
        for str in stringDate.components(separatedBy: " ") {
            print(str)
            dataArray.append(UInt8((str as NSString).intValue))
        }
        
        for byte in dataArray {
            print(String(byte,radix:16))
        }
        
        self.basePeripheral.writeValue(Data.init(bytes: dataArray), for: rxCharacteristic!, type: CBCharacteristicWriteType.withResponse)
    }
    
    func writeBabyPhoneThreshold () {
        var dataArray : [UInt8] = Array.init(repeating: 0, count: 6)
        dataArray[0] = 0xaa
        dataArray[1] = 0x55
        dataArray[2] = 0x11
        dataArray[3] = 0x02
        dataArray[4] = 0x01
        dataArray[5] = 0x04
        self.basePeripheral.writeValue(Data.init(bytes: dataArray), for: rxCharacteristic!, type: CBCharacteristicWriteType.withResponse)
    }
}

