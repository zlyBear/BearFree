//
//  ViewController.swift
//  BearSS
//
//  Created by zly on 2019/4/17.
//  Copyright © 2019 zly. All rights reserved.
//

import UIKit
import NetworkExtension
import Eureka

struct userConfig {
    let ip = "ip"
    let port = "port"
    let password = "password"
    let algorithm = "algorithm"
}

class ViewController: FormViewController {
    
    let defaultStand = UserDefaults.standard
    
    let firstSection : Section = Section()
    
    var switchRow : SwitchRow = SwitchRow("switchRowTag"){
        $0.title = "灵魂出窍"
    }

    var status: VPNStatus {
        didSet(o) {
            updateConnectButton()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.status = VpnManager.shared.vpnStatus
        super.init(coder: aDecoder)
        NotificationCenter.default.addObserver(self, selector: #selector(onVPNStatusChanged), name: NSNotification.Name(rawValue: kProxyServiceVPNStatusNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.requestBaidu()
        self.title = "Bear Fly Fly"
        
        form +++ firstSection
            <<< TextRow("IP"){ row in
                row.title = "IP"
                row.placeholder = "Enter server ip here"
                row.value = defaultStand.string(forKey: userConfig().ip)
                }.onChange({ row in
                    VpnManager.shared.ip_address = row.value ?? ""
                    self.defaultStand.set(row.value, forKey: userConfig().ip)
                })
            <<< TextRow("Port"){ row in
                row.title = "Port"
                row.placeholder = "Enter port here"
                row.value = defaultStand.string(forKey: userConfig().port)
                }.onChange({ row in
                    VpnManager.shared.port = Int(row.value ?? "0")!
                    self.defaultStand.set(row.value ?? "0", forKey: userConfig().port)
                })
            <<< PasswordRow("Password"){
                $0.title = "Password"
                $0.placeholder = "Enter password here"
                $0.value = defaultStand.string(forKey: userConfig().password)
                }.onChange({ row in
                    VpnManager.shared.password = row.value ?? ""
                    self.defaultStand.set(row.value, forKey: userConfig().password)
                })
            <<< PushRow<String>("Crypto") {
                $0.title = "Crypto"
                $0.selectorTitle = "Pick crypto algorithm"
                $0.options = ["RC4MD5","SALSA20","CHACHA20","AES128CFB","AES192CFB","AES256CFB"]
                $0.value = defaultStand.string(forKey: userConfig().algorithm)    // initially selected
                }.onChange({ row in
                    VpnManager.shared.algorithm = row.value ?? ""
                    self.defaultStand.set(row.value, forKey: userConfig().algorithm)
                })
            +++ Section("")
            <<< switchRow.onChange({ row in
                    if(VpnManager.shared.vpnStatus == .off && row.value! && !VpnManager.shared.ip_address.isEmpty && VpnManager.shared.port != 0 && !VpnManager.shared.password.isEmpty && !VpnManager.shared.algorithm.isEmpty){
                        VpnManager.shared.connect()
                    }else if(VpnManager.shared.vpnStatus == .on && !row.value!){
                        VpnManager.shared.disconnect()
                    }else {
                        print("no operation")
                }
                })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.status = VpnManager.shared.vpnStatus
    }
    
    @objc func onVPNStatusChanged(){
        self.status = VpnManager.shared.vpnStatus
    }
    
    
    
    func updateConnectButton(){
        let ipRow = form.rowBy(tag: "IP")
        let portRow = form.rowBy(tag: "Port")
        let passwordRow = form.rowBy(tag: "Password")
        let cryptoRow = form.rowBy(tag: "Crypto")
        switch status {
        case .on:
            switchRow.value = true
            firstSection.hidden = true
            ipRow?.disabled = true
            portRow?.disabled = true
            passwordRow?.disabled = true
            cryptoRow?.disabled = true
            break
        case .off:
            switchRow.value = false
            firstSection.hidden = false
            ipRow?.disabled = false
            portRow?.disabled = false
            passwordRow?.disabled = false
            cryptoRow?.disabled = false
            break
        case .connecting:
            break
        case .disconnecting:
            break
        }
        firstSection.evaluateHidden()
        ipRow?.evaluateDisabled()
        portRow?.evaluateDisabled()
        passwordRow?.evaluateDisabled()
        cryptoRow?.evaluateDisabled()
//        switchRow.reload()
        
        VpnManager.shared.ip_address = defaultStand.string(forKey: userConfig().ip) ?? ""
        VpnManager.shared.port = Int(defaultStand.string(forKey: userConfig().port) ?? "0")!
        VpnManager.shared.password = defaultStand.string(forKey: userConfig().password) ?? ""
        VpnManager.shared.algorithm = defaultStand.string(forKey: userConfig().algorithm) ?? ""
    }
    
    func requestBaidu() {
        let url : URL = URL(string:"https://m.baidu.com")!
        let request : URLRequest = URLRequest(url: url)
        let session : URLSession = URLSession.shared
        let task : URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            print(response as Any)
        }
        task.resume()
    }

}

