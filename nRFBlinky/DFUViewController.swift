//
//  DFUViewController.swift
//  nRFBlinky
//
//  Created by Sirui Wang on 04/05/2018.
//  Copyright © 2018 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit

import IOSThingyLibrary
import iOSDFULibrary

class DFUViewController: UIViewController ,ThingyDFUDelegate, NORFileSelectionDelegate{
    
    private var dfuController    : ThingyDFUController!
    var thingyManager    : ThingyManager?
    var targetPeripheral : ThingyPeripheral?
    var selectedFirmware : DFUFirmware?
    private var selectedFileURL  : URL?
    
//    {
//        willSet {
//            if targetPeripheral != nil && targetPeripheral != newValue {
//                targetPeripheralWillChange(old: targetPeripheral!, new: newValue)
//            }
//        }
//    }
    override func viewDidLoad() {
        super.viewDidLoad()

        

    }

    @IBAction func selectFile(_ sender: Any) {
        performSegue(withIdentifier: "selectFile", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectFile" {
            let aNavigationController = segue.destination as? UINavigationController
            
            let appFilecsVC = aNavigationController?.viewControllers.first as? NORAppFilesViewController
            appFilecsVC?.fileDelegate = self

            if selectedFileURL != nil {
                appFilecsVC?.selectedPath = selectedFileURL
            }
        }
    }

    func dfuDidStart() {
        print("start")
    }
    
    func dfuDidJumpToBootloaderMode(newPeripheral: ThingyPeripheral) {
        
    }
    
    func dfuDidStartUploading() {
        print("dfuDidStartUploading")
    }
    
    func dfuDidFinishUploading() {
        
    }
    
    func dfuDidComplete(thingy: ThingyPeripheral?) {
        
    }
    
    func dfuDidAbort() {
        
    }
    
    func dfuDidFail(withError anError: Error, andMessage aMessage: String) {
        
    }
    
    func dfuDidProgress(withCompletion aCompletion: Int, forPart aPart: Int, outOf totalParts: Int, andAverageSpeed aSpeed: Double) {
        print("dfuDidProgress")
    }
    
    func onFileSelected(withURL aFileURL: URL) {
        
        selectedFileURL = aFileURL
        selectedFirmware = DFUFirmware(urlToZipFile: aFileURL)
        
        let centralManager = thingyManager!.centralManager!
        dfuController = ThingyDFUController(withPeripheral: targetPeripheral!, centralManager: centralManager, firmware: selectedFirmware!, andDelegate: self)
        dfuController.startDFUProcess()
    }
    
    

    
}
