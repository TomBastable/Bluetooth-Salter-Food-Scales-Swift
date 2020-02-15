//
//  ViewController.swift
//  BluetoothHeartRate
//
//  Created by Tom Bastable on 09/02/2020.
//  Copyright © 2020 Tom Bastable. All rights reserved.
//

import UIKit
import CoreBluetooth

let salterCBUUID = CBUUID(string: "FFE0")
let weightCharacteristicCBUUID = CBUUID(string: "FFE1")
let zeroCharacteristicCBUUID = CBUUID(string: "FFE3")

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var weightLabel: UILabel!
    var centralManager: CBCentralManager!
    var salterScalePeripheral: CBPeripheral!
    var peripherals:[CBPeripheral] = []
    var zeroCharactisertic:CBCharacteristic?
    @IBOutlet weak var weightMetric: UILabel!
    
    //MARK: - VDL
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //MARK: - Table View Delegate and Datasource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       // create a new cell if needed or reuse an old one
        let cell:PerhiperalTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "peripCell") as! PerhiperalTableViewCell

        // set the text from the data model - Breaking MVC doing it here, but it's only a demo!
        cell.title.text = peripherals[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        salterScalePeripheral = peripherals[indexPath.row]
        centralManager.stopScan()
        centralManager.connect(salterScalePeripheral)
        salterScalePeripheral.delegate = self
    }
    
    //MARK: - Zero Scale Button
    ///This button writes to the salter bluetooth scales and zeroes the scale on-device.
    @IBAction func zeroScale(_ sender: Any) {
        
        //Setup Tare Command !!!!!! Do not change this data otherwise the scale will not zero !!!!!!
        var data: Data = Data(count: 3)
        data[0] = 9
        data[1] = 3
        data[2] = 5
        //Write Value to Peripheral
        salterScalePeripheral.writeValue(data, for: zeroCharactisertic!, type: .withResponse)
        
    }
}

extension ViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state{
            
        case .unknown:
            print("Unknown 1")
        case .resetting:
            print("resetting")
        case .unsupported:
            print("unsupported")
        case .unauthorized:
            print("unauthorised")
        case .poweredOff:
            print("powered off")
        case .poweredOn:
            print("powered on")
            centralManager.scanForPeripherals(withServices: [salterCBUUID])
        @unknown default:
            print("unknown")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
        if !peripherals.contains(peripheral){
            peripherals.append(peripheral)
            tableView.reloadData()
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        salterScalePeripheral.discoverServices(nil)
    }

}

extension ViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }
        
        for service in services {
         print(service)
            
          peripheral.discoverCharacteristics(nil, for: service)
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.properties.contains(.write) {
                peripheral.setNotifyValue(true, for: characteristic)
                if characteristic.uuid == zeroCharacteristicCBUUID{
                    zeroCharactisertic = characteristic
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        
      switch characteristic.uuid {
        
        case weightCharacteristicCBUUID:
            guard let characteristicData = characteristic.value else{return}
            
            if characteristicData.count == 7{
            print("new data")
            //display each byte for the sake of transparency. This is what helped me find the properties of each.
            for value in characteristicData{
                print(value)
            }
            //This date stores the tally of 256bytes. Times this value by 256 and add the current value to retrieve the current weight.
            let tally = characteristicData[4]
            let currentValue = characteristicData[5]
            //this data stores the current metric of weight. See the set current weight function for an exhaustive list.
            let weightMetric = characteristicData[6]
            // set the weight by multiplying the tally by 256 and adding the current value.
            let weight:Int = Int(tally) * 256 + Int(currentValue)
            getCorrectWeight(weight: weight, metric: weightMetric)
                
            }
        
        default:
          print("Unhandled Characteristic UUID: \(characteristic.uuid)")
      }
    }
    
    func getCorrectWeight(weight:Int, metric:UInt8) {
        var weight = weight
        
        let int = Int(metric)
        
        switch int{
        case 0:
            //grams
            self.weightMetric.text = "g"
            weightLabel.text = "\(weight)"
        case 1:
            //ounces - value is in ounces multiplied by 10. Divide by 10 to get weight in ounces.
            weight = weight / 10
            self.weightMetric.text = "oz"
            weightLabel.text = "\(weight)"
        case 2:
            //millilitres
            self.weightMetric.text = "ml"
            weightLabel.text = "\(weight)"
        case 3:
            //fluid ounces
            self.weightMetric.text = "fl oz"
            weight = weight / 10
            weightLabel.text = "\(weight)"
        default:
            //unknown
            
            self.weightMetric.text = ""
        }
        
    }

}
