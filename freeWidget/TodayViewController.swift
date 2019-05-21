//
//  TodayViewController.swift
//  freeWidget
//
//  Created by zly on 2019/5/21.
//  Copyright © 2019 zly. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    @IBOutlet weak var switchButton: UISwitch!
    @IBOutlet weak var ipLabel: UILabel!
    let defaultStand = UserDefaults.init(suiteName: "group.com.zly.BearSS")
    override func viewDidLoad() {
        super.viewDidLoad()
        VpnManager.shared.ip_address = defaultStand!.string(forKey: userConfig().ip) ?? ""
        VpnManager.shared.port = Int(defaultStand!.string(forKey: userConfig().port) ?? "0")!
        VpnManager.shared.password = defaultStand!.string(forKey: userConfig().password) ?? ""
        VpnManager.shared.algorithm = defaultStand!.string(forKey: userConfig().algorithm) ?? ""
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            self.ipLabel.text = "\(VpnManager.shared.ip_address) : \(String(VpnManager.shared.port))"
            if VpnManager.shared.vpnStatus == .on {
                self.switchButton.setOn(true, animated: false)
            } else {
                self.switchButton.setOn(false, animated: false)
            }
        }
        
        
        // Do any additional setup after loading the view.
    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    @IBAction func switchAction(_ sender: UISwitch) {
        if (sender.isOn) {
            VpnManager.shared.connect()
        } else {
            VpnManager.shared.disconnect()
        }
    }
}
