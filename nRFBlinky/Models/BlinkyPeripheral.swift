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
    public var basePeripheral      : CBPeripheral
    public private(set) var advertisedName      : String?
    public private(set) var RSSI                : NSNumber
    public private(set) var advertisedServices  : [CBUUID]?
    
    // PMC Audio
    private var engine                      : AVAudioEngine?
    private var player                      : AVAudioPlayerNode?
    
    //MARK: - Callback handlers
    private var ledCallbackHandler : ((Bool) -> (Void))?
    private var buttonPressHandler : ((Bool) -> (Void))?

    //MARK: - Services and Characteristic properties
    //
    private             var blinkyService       : CBService?
    private             var soundCharacteristic: CBCharacteristic?
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
    
    public func didReceiveButtonNotificationWithValue(_ aValue: Data) {
        
        
//        print(aValue.count)
        // The pcmFormatInt16 format is not supported in AvAudioPlayerNode
        // Later on we will have to devide all values by Int16.max to get values from -1.0 to 1.0
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: true)
        
        engine = AVAudioEngine()
        player = AVAudioPlayerNode()
        engine!.attach(player!)
        engine!.connect(player!, to: engine!.mainMixerNode, format: format)
        engine!.mainMixerNode.volume = 1.0
        
        do {
            engine!.prepare()
            try engine!.start()
        } catch {
            print("AVAudioEngine.start() error: \(error.localizedDescription)")
        }
        player!.play()
        
        
        guard let engine = engine, engine.isRunning else {
            // Streaming has been already stopped
            return
        }
        
//        let buffer = AVAudioPCMBuffer(pcmFormat: engine.mainMixerNode.inputFormat(forBus: 0), frameCapacity: AVAudioFrameCount(pcm16Data.count))!
//        buffer.frameLength = buffer.frameCapacity
//
//        var graphData = [Double]()
//        for i in 0 ..< pcm16Data.count {
//            buffer.floatChannelData![0 /* channel 1 */][i] = Float32(pcm16Data[i]) / Float32(Int16.max) // TODO: 32 - increases volume, this should be done on Thingy
//            // print("Value \(i): \(pcm16Data[i]) => \(buffer.floatChannelData![0][i])")
//
//            // Unfortunatelly we can't show all samples on the graph, it would be too slow.
//            // We show only every n-th sample from whole 800 samples in the buffer keeping the same precission as when sending sound.
//            if i % (800 / self.soundGraphHandler.maximumVisiblePoints) == 0 {
//                graphData.append((Double((buffer.floatChannelData![0][i]))))
//            }
//        }
//        DispatchQueue.main.async {
//            guard self.engine != nil && self.engine!.isRunning else {
//                return
//            }
//            self.soundGraphHandler.addPoints(withValues: graphData)
//        }
//
//        player!.scheduleBuffer(buffer, completionHandler: nil)
        


        
        
        
        
        
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
        
        if characteristic == BlinkyPeripheral.SOUND_CHARACTERISTIC {
            print("didUpdateValueFor SOUND_CHARACTERISTIC")
        }
        if characteristic == soundCharacteristic {
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
        if characteristic.uuid == soundCharacteristic?.uuid {
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
                print("Discovered service! \(aService) )")
                if aService.uuid == BlinkyPeripheral.SOUND_SERVICE {
                    print("Discovered SOUND_SERVICE service )")
                    //Capture and discover all characteristics for the blinky service
                    blinkyService = aService
                    
                    discoverCharacteristicsForBlinkyService(blinkyService!)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if service == blinkyService {
            print("didDiscoverCharacteristicsFor \(service.characteristics?.count)")
            if let characteristics = service.characteristics {
                for aCharacteristic in characteristics {
                    
                    print("Discovered Blinky characteristics! \(aCharacteristic.uuid) \(String(describing: aCharacteristic.descriptors))")
                    if aCharacteristic.uuid == BlinkyPeripheral.SOUND_CHARACTERISTIC {
                        print("SOUND_CHARACTERISTIC")
                        soundCharacteristic = aCharacteristic
                        enableButtonNotifications(soundCharacteristic!)
//                        peripheral.discoverDescriptors(for: aCharacteristic)
                    }
                }
            }
        } else {
            print("Discovered characteristics for an unnknown service with UUID: \(service.uuid.uuidString)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("didDiscoverDescriptorsFor \(characteristic)")
        if let descriptors = characteristic.descriptors {
            for descriptor in descriptors {
                if descriptor.uuid == BlinkyPeripheral.SOUND_CHARACTERISTIC_DESCRIPTOR {
                    
                    
//                    peripheral.writeValue(Data.init(bytes: [0x01, 0x00]), for: descriptor)
//                    peripheral.readValue(for: descriptor)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print("didUpdateValueFor \(descriptor)")
        
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
