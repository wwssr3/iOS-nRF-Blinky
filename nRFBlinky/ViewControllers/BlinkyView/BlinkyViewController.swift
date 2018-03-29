//
//  BlinkyViewController.swift
//  nRFBlinky
//
//  Created by Mostafa Berg on 01/12/2017.
//  Copyright © 2017 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit
import CoreBluetooth

class BlinkyViewController: UITableViewController, CBCentralManagerDelegate {
    
    //MARK: - Outlets and Actions
    
    @IBOutlet weak var ledStateLabel: UILabel!
    @IBOutlet weak var ledToggleSwitch: UISwitch!
    @IBOutlet weak var buttonStateLabel: UILabel!
    var strNowTime : String = ""
    @IBAction func ledToggleSwitchDidChange(_ sender: Any) {
        handleSwitchValueChange(newValue: ledToggleSwitch.isOn)
    }

    //MARK: - Properties
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private var hapticGenerator : NSObject? //Only available on iOS 10 and above
    private var blinkyPeripheral : BlinkyPeripheral!
    private var centralManager : CBCentralManager!
    
    //MARK: - Implementation
    public func setCentralManager(_ aManager: CBCentralManager) {
        centralManager = aManager
        centralManager.delegate = self
    }
    
    public func setPeripheral(_ aPeripheral: BlinkyPeripheral) {
        let peripheralName = aPeripheral.advertisedName ?? "Unknown Device"
        title = peripheralName
        blinkyPeripheral = aPeripheral
        print("connecting to blinky")
        centralManager.connect(blinkyPeripheral.basePeripheral, options: nil)
    }
    
    private func handleSwitchValueChange(newValue isOn: Bool){
        if isOn {
            blinkyPeripheral.turnOnLED()
            ledStateLabel.text = "ON"
        } else {
            blinkyPeripheral.turnOffLED()
            ledStateLabel.text = "OFF"
        }
    }
    
    private func setupDependencies() {
        //This will run on iOS 10 or above
        //and will generate a tap feedback when the button is tapped on the Dev kit.
        prepareHaptics()
        
        //Set default text to Reading ...
        //As soon as peripheral enables notifications the values will be notified
        buttonStateLabel.text = "Reading ..."
        ledStateLabel.text    = "Reading ..."
        ledToggleSwitch.isEnabled = false
        
        print("adding button notification and led write callback handlers")
        blinkyPeripheral.setButtonCallback { (isPressed) -> (Void) in
            DispatchQueue.main.async {
                if isPressed {
                    self.buttonStateLabel.text = "PRESSED"
                } else {
                    self.buttonStateLabel.text = "RELEASED"
                }
                self.buttonTapHapticFeedback()
            }
        }
        
        blinkyPeripheral.setLEDCallback { (isOn) -> (Void) in
            DispatchQueue.main.async {
                if !self.ledToggleSwitch.isEnabled {
                    self.ledToggleSwitch.isEnabled = true
                }
                
                if isOn {
                    self.ledStateLabel.text = "ON"
                    if self.ledToggleSwitch.isOn == false {
                        self.ledToggleSwitch.setOn(true, animated: true)
                    }
                } else {
                    self.ledStateLabel.text = "OFF"
                    if self.ledToggleSwitch.isOn == true {
                        self.ledToggleSwitch.setOn(false, animated: true)
                    }
                }
            }
        }
    }
    //MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    //MARK: - UIViewController
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard blinkyPeripheral.basePeripheral.state != .connected else {
            //View is coming back from a swipe, everything is already setup
            return
        }
        //This is the first time view appears, setup the subviews and dependencies
        setupDependencies()
        let date = Date()
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyy-MM-dd 'at' HH:mm:ss.SSS"
        strNowTime = timeFormatter.string(from: date)
        
        
    }

    override func viewDidDisappear(_ animated: Bool) {
        print("removing button notification and led write callback handlers")
        blinkyPeripheral.removeLEDCallback()
        blinkyPeripheral.removeButtonCallback()
        
        if blinkyPeripheral.basePeripheral.state == .connected {
            centralManager.cancelPeripheralConnection(blinkyPeripheral.basePeripheral)
        }
        super.viewDidDisappear(animated)
    }

    //MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            dismiss(animated: true, completion: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == blinkyPeripheral.basePeripheral {
            print("connected to blinky. \(strNowTime)")
            
            blinkyPeripheral.discoverBlinkyServices()
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == blinkyPeripheral.basePeripheral {
            let alertController = UIAlertController(title: strNowTime, message: "确定还是取消", preferredStyle: .alert) // 这里因为控件都不存在改变的可能，所以一律使用let类型.UIAlertControllerStyle可以选择.actionSheet或.alert
            
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            let okAction = UIAlertAction(title: "确定", style: .default, handler:{
                (UIAlertAction) -> Void in
                print("点击确定事件")
            })
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)// 当添加的UIAlertAction超过两个的时候，会自动变成纵向分布
            self.present(alertController, animated: true, completion: nil)
            
            print("blinky disconnected.\(strNowTime)")
            navigationController?.popToRootViewController(animated: true)
        }
    }

    private func prepareHaptics() {
        if #available(iOS 10.0, *) {
            hapticGenerator = UIImpactFeedbackGenerator(style: .heavy)
            (hapticGenerator as? UIImpactFeedbackGenerator)?.prepare()
        }
    }
    private func buttonTapHapticFeedback() {
        if #available(iOS 10.0, *) {
            (hapticGenerator as? UIImpactFeedbackGenerator)?.impactOccurred()
        }
    }
}
