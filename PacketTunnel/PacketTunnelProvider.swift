//
//  PacketTunnelProvider.swift
//  PacketTunnel
//
//  Created by zly on 2019/4/17.
//  Copyright © 2019 zly. All rights reserved.
//

import NetworkExtension
import NEKit
import CocoaLumberjackSwift
import Yaml

class PacketTunnelProvider: NEPacketTunnelProvider {
    var interface: TUNInterface!
    var enablePacketProcessing = false
    
    var proxyPort: Int!
    
    var proxyServer: ProxyServer!
    
    var lastPath:NWPath?
    
    var started:Bool = false
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        DDLog.removeAllLoggers()
        DDLog.add(DDOSLogger.sharedInstance, with: DDLogLevel.info)
        ObserverFactory.currentFactory = DebugObserverFactory()
        NSLog("-------------")
        
        guard let conf = (protocolConfiguration as! NETunnelProviderProtocol).providerConfiguration else{
            NSLog("[ERROR] No ProtocolConfiguration Found")
            exit(EXIT_FAILURE)
        }
        
        
        let ss_adder = conf["ss_address"] as! String
        NSLog(ss_adder)
        
        let ss_port = conf["ss_port"] as! Int
        let method = conf["ss_method"] as! String
        NSLog(method)
        
        let password = conf["ss_password"] as!String
        
        // Proxy Adapter
        
        
        // SSR Httpsimple
        //        let obfuscater = ShadowsocksAdapter.ProtocolObfuscater.HTTPProtocolObfuscater.Factory(hosts:["intl.aliyun.com","cdn.aliyun.com"], customHeader:nil)
        
        
        // Origin
        let obfuscater = ShadowsocksAdapter.ProtocolObfuscater.OriginProtocolObfuscater.Factory()
        
        
        let algorithm:CryptoAlgorithm
        
        switch method{
        case "AES128CFB":algorithm = .AES128CFB
        case "AES192CFB":algorithm = .AES192CFB
        case "AES256CFB":algorithm = .AES256CFB
        case "CHACHA20":algorithm = .CHACHA20
        case "SALSA20":algorithm = .SALSA20
        case "RC4MD5":algorithm = .RC4MD5
        default:
            fatalError("Undefined algorithm!")
        }
        
        
        let ssAdapterFactory = ShadowsocksAdapterFactory(serverHost: ss_adder, serverPort: ss_port, protocolObfuscaterFactory:obfuscater, cryptorFactory: ShadowsocksAdapter.CryptoStreamProcessor.Factory(password: password, algorithm: algorithm), streamObfuscaterFactory: ShadowsocksAdapter.StreamObfuscater.OriginStreamObfuscater.Factory())
        
        let directAdapterFactory = DirectAdapterFactory()
        
        //Get lists from conf
        let yaml_str = conf["ymal_conf"] as!String
        let value = try! Yaml.load(yaml_str)
        
        var UserRules:[NEKit.Rule] = []
        
        for each in (value["rule"].array! ){
            let adapter:NEKit.AdapterFactory
            if each["adapter"].string! == "direct"{
                adapter = directAdapterFactory
            }else{
                adapter = ssAdapterFactory
            }
            
            let ruleType = each["type"].string!
            switch ruleType {
            case "domainlist":
                var rule_array : [NEKit.DomainListRule.MatchCriterion] = []
                for dom in each["criteria"].array!{
                    let raw_dom = dom.string!
                    let index = raw_dom.index(raw_dom.startIndex, offsetBy: 1)
                    let index2 = raw_dom.index(raw_dom.startIndex, offsetBy: 2)
                    let typeStr = raw_dom[...index]
                    let url = raw_dom[index2...]
                    
                    if typeStr == "s"{
                        rule_array.append(DomainListRule.MatchCriterion.suffix(String(url)))
                    }else if typeStr == "k"{
                        rule_array.append(DomainListRule.MatchCriterion.keyword(String(url)))
                    }else if typeStr == "p"{
                        rule_array.append(DomainListRule.MatchCriterion.prefix(String(url)))
                    }else if typeStr == "r"{
                        // ToDo:
                        // shoud be complete
                    }
                }
                UserRules.append(DomainListRule(adapterFactory: adapter, criteria: rule_array))
                
                
            case "iplist":
                let ipArray = each["criteria"].array!.map{$0.string!}
                UserRules.append(try! IPRangeListRule(adapterFactory: adapter, ranges: ipArray))
            default:
                break
            }
        }
        
        
        // Rules
        
        let chinaRule = CountryRule(countryCode: "CN", match: true, adapterFactory: directAdapterFactory)
        let unKnowLoc = CountryRule(countryCode: "--", match: true, adapterFactory: directAdapterFactory)
        let dnsFailRule = DNSFailRule(adapterFactory: ssAdapterFactory)
        
        let allRule = AllRule(adapterFactory: ssAdapterFactory)
        UserRules.append(contentsOf: [chinaRule,unKnowLoc,dnsFailRule,allRule])
        
        let manager = RuleManager(fromRules: UserRules, appendDirect: true)
        
        RuleManager.currentManager = manager
        proxyPort =  9090
        
        // the `tunnelRemoteAddress` is meaningless because we are not creating a tunnel.
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "8.8.8.8")
        networkSettings.mtu = 1500
        
        let ipv4Settings = NEIPv4Settings(addresses: ["192.0.6.1"], subnetMasks: ["255.255.255.0"])
        if enablePacketProcessing {
            ipv4Settings.includedRoutes = [NEIPv4Route.default()]
            ipv4Settings.excludedRoutes = [
                NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
                NEIPv4Route(destinationAddress: "100.64.0.0", subnetMask: "255.192.0.0"),
                NEIPv4Route(destinationAddress: "127.0.0.0", subnetMask: "255.0.0.0"),
                NEIPv4Route(destinationAddress: "169.254.0.0", subnetMask: "255.255.0.0"),
                NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),
                NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
                NEIPv4Route(destinationAddress: "17.0.0.0", subnetMask: "255.0.0.0"),
            
            ]
        }
        networkSettings.ipv4Settings = ipv4Settings
        
        let proxySettings = NEProxySettings()
        proxySettings.httpEnabled = true
        proxySettings.httpServer = NEProxyServer(address: "127.0.0.1", port: proxyPort)
        proxySettings.httpsEnabled = true
        proxySettings.httpsServer = NEProxyServer(address: "127.0.0.1", port: proxyPort)
        proxySettings.excludeSimpleHostnames = true
        // This will match all domains
        proxySettings.matchDomains = [""]
        proxySettings.exceptionList = ["api.smoot.apple.com","configuration.apple.com","xp.apple.com","smp-device-content.apple.com","guzzoni.apple.com","captive.apple.com","*.ess.apple.com","*.push.apple.com","*.push-apple.com.akadns.net"]
        networkSettings.proxySettings = proxySettings
        
        if enablePacketProcessing {
            let DNSSettings = NEDNSSettings(servers: ["8.8.8.8"])
            DNSSettings.matchDomains = [""]
            DNSSettings.matchDomainsNoSearch = false
            networkSettings.dnsSettings = DNSSettings
        }
        
        setTunnelNetworkSettings(networkSettings) {
            error in
            guard error == nil else {
                DDLogError("Encountered an error setting up the network: \(error.debugDescription)")
                completionHandler(error)
                return
            }
            
            
            if !self.started{
                self.proxyServer = GCDHTTPProxyServer(address: IPAddress(fromString: "127.0.0.1"), port: NEKit.Port(port: UInt16(self.proxyPort)))
                try! self.proxyServer.start()
                self.addObserver(self, forKeyPath: "defaultPath", options: .initial, context: nil)
            }else{
                self.proxyServer.stop()
                try! self.proxyServer.start()
            }
            
            completionHandler(nil)
            
            
            if self.enablePacketProcessing {
                if self.started{
                    self.interface.stop()
                }
                
                self.interface = TUNInterface(packetFlow: self.packetFlow)
                
                
                let fakeIPPool = try! IPPool(range: IPRange(startIP: IPAddress(fromString: "198.168.1.1")!, endIP: IPAddress(fromString: "198.168.255.255")!))
                
                
                let dnsServer = DNSServer(address: IPAddress(fromString: "8.8.8.8")!, port: NEKit.Port(port: 53), fakeIPPool: fakeIPPool)
                let resolver = UDPDNSResolver(address: IPAddress(fromString: "114.114.114.114")!, port: NEKit.Port(port: 53))
                dnsServer.registerResolver(resolver)
                self.interface.register(stack: dnsServer)
                
                DNSServer.currentServer = dnsServer
                
                let udpStack = UDPDirectStack()
                self.interface.register(stack: udpStack)
                let tcpStack = TCPStack.stack
                tcpStack.proxyServer = self.proxyServer
                self.interface.register(stack:tcpStack)
                self.interface.start()
            }
            self.started = true
            
        }
        
    }
    
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        if enablePacketProcessing {
            interface.stop()
            interface = nil
            DNSServer.currentServer = nil
        }
        
        if(proxyServer != nil){
            proxyServer.stop()
            proxyServer = nil
            RawSocketFactory.TunnelProvider = nil
        }
        completionHandler()
        
        exit(EXIT_SUCCESS)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "defaultPath" {
            if self.defaultPath?.status == .satisfied && self.defaultPath != lastPath{
                if(lastPath == nil){
                    lastPath = self.defaultPath
                }else{
                    NSLog("received network change notifcation")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                        // 延迟1s确保系统就绪
                        guard let strongSelf = self else { return }
                        strongSelf.startTunnel(options: nil){ _ in }
                    }
                }
            }else{
                lastPath = defaultPath
            }
        }
    }
}
