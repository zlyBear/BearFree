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
    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        let str = "IP    ：\(VpnManager.shared.ip_address)\nPort：\(String(VpnManager.shared.port))"
        //通过富文本来设置行间距
        let paraph = NSMutableParagraphStyle()
        //将行间距设置为15
        paraph.lineSpacing = 15
        //样式属性集合
        let attributes = [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 15),
                          NSAttributedString.Key.paragraphStyle: paraph]
        self.ipLabel.attributedText = NSAttributedString(string: str, attributes: attributes)
        
        if VpnManager.shared.vpnStatus == .on {
            self.switchButton.setOn(true, animated: false)
        } else {
            self.switchButton.setOn(false, animated: false)
        }
        
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


