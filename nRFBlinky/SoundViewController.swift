
import UIKit
import AVFoundation
import IOSThingyLibrary

class SoundViewController: UITableViewController, ThingyManagerDelegate {
    private var thingyManager : ThingyManager?
//    private var targetPeripheral : ThingyPeripheral?
//
    private var discoveredDevices = [ThingyPeripheral]()
//
//    private var engine                      : AVAudioEngine?
//    private var player                      : AVAudioPlayerNode?
//
//    private var records: [(frequency: UInt16, delay: Int)] = []
//    private var lastToneRecordTime: CFAbsoluteTime?

    
    override func viewDidLoad() {
        
        thingyManager = ThingyManager.init(withDelegate: self)

    }
    

    func thingyManager(_ manager: ThingyManager, didChangeStateTo state: ThingyManagerState) {
        
        if state == ThingyManagerState.idle {
        
            
            thingyManager?.discoverDevices()
        }
    }
    
    func thingyManager(_ manager: ThingyManager, didDiscoverPeripheral peripheral: ThingyPeripheral) {
        
    }
    
    func thingyManager(_ manager: ThingyManager, didDiscoverPeripheral peripheral: ThingyPeripheral, withPairingCode: String?) {

        if !discoveredDevices.contains(peripheral) {
            discoveredDevices.append(peripheral)

                self.tableView.reloadData()

        }
    }

//    private func startReceivingMicrophone() {
//        targetPeripheral?.beginMicrophoneUpdates(withCompletionHandler: { success in
//            if success {
//                print("Microphone updates enabled")
//                print("Starting playing...")
//                self.startPlaying()
//            } else {
//                print("Microphone updates failed to start")
//            }
//        }, andNotificationHandler: { (pcm16Data) -> (Void) in
//            self.schedule(pcm16Data: pcm16Data)
//        })
//    }
//    //MARK: - Thingy API
//    func thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState) {
//
//        print("peripheral state \(state)")
//        if state == ThingyPeripheralState.discoveringCharacteristics {
//            targetPeripheral = peripheral
//        }
//
//    }
//
//    func targetPeripheralWillChange(old: ThingyPeripheral, new: ThingyPeripheral?) {
//
//    }
//
    //MARK: - Table View Controller Delegate

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell  = tableView.dequeueReusableCell(withIdentifier: "thingyCell", for: indexPath)
        cell.textLabel?.text = discoveredDevices[indexPath.row].name
        
        cell.detailTextLabel?.text = discoveredDevices[indexPath.row].rssi.decimalValue.description
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredDevices.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if targetPeripheral != nil {
//            startReceivingMicrophone()
//
//
//            return
//        }
//
        tableView.deselectRow(at: indexPath, animated: true)
        
        thingyManager?.connect(toDevice: discoveredDevices[indexPath.row])
        
        thingyManager?.stopScan()
        
        self.performSegue(withIdentifier: "showDFUView", sender: indexPath.row)
//        discoveredPeripherals[indexPath.row].delegate  = self
        
    }

//    private func startPlaying() {
//        // The pcmFormatInt16 format is not supported in AvAudioPlayerNode
//        // Later on we will have to devide all values by Int16.max to get values from -1.0 to 1.0
//        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: true)
//        
//        engine = AVAudioEngine()
//        player = AVAudioPlayerNode()
//        engine!.attach(player!)
//        engine!.connect(player!, to: engine!.mainMixerNode, format: format)
//        engine!.mainMixerNode.volume = 1.0
//        
//        do {
//            engine!.prepare()
//            try engine!.start()
//        } catch {
//            print("AVAudioEngine.start() error: \(error.localizedDescription)")
//        }
//        player!.play()
//    }
//    
//    private func schedule(pcm16Data: [Int16]) {
//        guard let engine = engine, engine.isRunning else {
//            // Streaming has been already stopped
//            return
//        }
//        
//        let buffer = AVAudioPCMBuffer(pcmFormat: engine.mainMixerNode.inputFormat(forBus: 0), frameCapacity: AVAudioFrameCount(pcm16Data.count))
//        buffer.frameLength = buffer.frameCapacity
//        
//        for i in 0 ..< pcm16Data.count {
//            buffer.floatChannelData![0 /* channel 1 */][i] = Float32(pcm16Data[i]) / Float32(Int16.max) // TODO: 32 - increases volume, this should be done on Thingy
//
//        }
//        DispatchQueue.main.async {
//            guard self.engine != nil && self.engine!.isRunning else {
//                return
//            }
//        }
//        
//        player!.scheduleBuffer(buffer, completionHandler: nil)
//    }
//    
//    private func stopPlaying() {
//        player?.stop()
//        engine?.stop()
//        engine?.reset()
//        player = nil
//        engine = nil
//    }
//    
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        switch segue.identifier {
        case "showDFUView":
            let dFUViewController : DFUViewController = segue.destination as! DFUViewController
            dFUViewController.targetPeripheral = discoveredDevices[sender as! Int]
            dFUViewController.thingyManager = thingyManager
            break
        case "showServices":
            let servicesViewController : SoundServiceViewController = segue.destination as! SoundServiceViewController
            servicesViewController.targetPeripheral = discoveredDevices[sender as! Int]
            break
        default:
            break
        }
     }
    

}
