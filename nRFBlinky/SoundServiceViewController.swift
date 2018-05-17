//
//  SoundServiceViewController.swift
//  nRFBlinky
//
//  Created by Sirui Wang on 23/04/2018.
//  Copyright © 2018 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit

import AVFoundation
import IOSThingyLibrary
import CoreBluetooth

class SoundServiceViewController: UIViewController, ThingyPeripheralDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var targetPeripheral : ThingyPeripheral?
    
    private var discoveredServices = [CBService]()
    
    private var engine                      : AVAudioEngine?
    private var player                      : AVAudioPlayerNode?
    
    private var records: [(frequency: UInt16, delay: Int)] = []
    private var lastToneRecordTime: CFAbsoluteTime?
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.targetPeripheral?.delegate = self
    }
    
    
    //MARK: - Thingy API
    func thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState) {
        
        print("peripheral state \(state)")
        switch state {
        case .connected:

            break
        case .discoveringCharacteristics:
            
            discoveredServices = peripheral.basePeripheral.services!
            tableView.reloadData()

            startReceivingMicrophone()
            
            break
        default:
            break
        }
    }
    
    func targetPeripheralWillChange(old: ThingyPeripheral, new: ThingyPeripheral?) {
        
    }
    private func startPlaying() {
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
    }
    
    private func schedule(pcm16Data: [Int16]) {
        guard let engine = engine, engine.isRunning else {
            // Streaming has been already stopped
            return
        }
        
        let buffer = AVAudioPCMBuffer(pcmFormat: engine.mainMixerNode.inputFormat(forBus: 0), frameCapacity: AVAudioFrameCount(pcm16Data.count))
        buffer.frameLength = buffer.frameCapacity
        
        for i in 0 ..< pcm16Data.count {
            buffer.floatChannelData![0 /* channel 1 */][i] = Float32(pcm16Data[i]) / Float32(Int16.max) // TODO: 32 - increases volume, this should be done on Thingy
            
        }
        DispatchQueue.main.async {
            guard self.engine != nil && self.engine!.isRunning else {
                return
            }
        }
        
        player!.scheduleBuffer(buffer, completionHandler: nil)
    }
    
    private func stopPlaying() {
        player?.stop()
        engine?.stop()
        engine?.reset()
        player = nil
        engine = nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell  = tableView.dequeueReusableCell(withIdentifier: "serviceCell", for: indexPath)
        cell.textLabel?.text = discoveredServices[indexPath.row].uuid.description

        cell.detailTextLabel?.text = discoveredServices[indexPath.row].uuid.uuidString
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredServices.count
    }

    @IBAction func btnClicked(_ sender: Any) {
        
        startReceivingMicrophone()
    }
    
    @IBAction func babyPhoneThreadValueChanged(_ sender: Any) {
        targetPeripheral?.setBabyPhoneThread()
    }
    private func startReceivingMicrophone() {
        targetPeripheral?.beginMicrophoneUpdates(withCompletionHandler: { success in
            if success {
                print("Microphone updates enabled")
                print("Starting playing...")
                self.startPlaying()
            } else {
                print("Microphone updates failed to start")
            }
        }, andNotificationHandler: { (pcm16Data) -> (Void) in
            self.schedule(pcm16Data: pcm16Data)
        })
    }
    
    @IBAction func stop(_ sender: Any) {
        targetPeripheral?.stopMicrophoneUpdates(withCompletionHandler: { (scuess) -> (Void) in
            if scuess {
                
            }
        })
    }
}
