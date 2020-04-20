本文主要介绍iOS中NetworkExtension在ss开发中的应用，使用了第三方库NEKit提供路由规则支持。

> Demo代码已适配swift5，点击[GitHub链接](https://github.com/zlyBear/BearFree/tree/master)查看。
>
> Demo运行需要有开发者账号，修改bundle id，在自己的开发者账号进行注册。

在创建应用之前我们需要安装**NEProviderTargetTemplates.pkg**，在xcode10.12之后苹果在xcode中删除了这个文件，为什么？可能和中国区被下架的那些VXN一样的原因吧。好在我们还可以从老版本的xcode中提取这个文件，链接在此[点击下载](https://pan.baidu.com/s/1p-HxTtJr64RbzSuE33tyYw) ，提取码：**18ek**，要低调，安装好后重启xcode。

### 创建工程

接下来我们开始创建工程，首先和创建普通App一样创建一个Project

![创建Project](http://lyz0818.5166.info//20190422152501_ChhUeh_Screenshot.jpeg)

创建好后我们在当前Project中创建一个Target

![](http://lyz0818.5166.info//20190422153925_NI6i8o_Screenshot.jpeg)

选择Network Extension，Next

![](http://lyz0818.5166.info//20190422154532_PgKs21_Screenshot.jpeg)

语言选择swift，因为NEKit是swift写的，并且对oc支持不是很好，所以这里就用swift来写了。

![](http://lyz0818.5166.info//20190422154651_9JICcO_Screenshot.jpeg)

创建好后，目录下会出现一个新的文件夹

![](http://lyz0818.5166.info//20190422160544_sZl27o_Screenshot.jpeg)

有关代理的代码在PacketTunnelProvider.swift中编写。

在工程创建完毕后，需要在Target的Capabilities中开启Network Extensions和Personal VXN功能，注意项目本身主Target及PacketTunnel都需要开启这两项功能。

![](http://lyz0818.5166.info//20190422161751_mpCKDy_Screenshot.jpeg)

好了，到此工程就创建好了。

### NEKit集成

由于项目中使用的NEKit这个第三方库只支持Carthage进行集成管理，所以demo使用的集成工具也是Carthage，没有用过的可以自行Google，安装使用难度不高，一看即会。

但是**注意**在第三方库编译的时候需要使用NEKit提供的编译方式，直接carthage update项目无法运行。

> **carthage update --no-use-binaries --platform mac,ios**

第三方库编译好后会在Carthage目录下Build/iOS中生成.framework文件，我们需要把这些framework添加到项目中去，下图的两个位置都要需要添加，与Net无关的包在packetTunnel中可以不需要添加。

![](http://lyz0818.5166.info//20190422171252_Y994p5_Screenshot.jpeg)

![](http://lyz0818.5166.info//img/20190422171706_L5Mzuo_Screenshot.png?markdown)

至此相关环境配置就已经搞定了，下面开始看代码如何建立VXN链接

### 创建VXN Manager

首先需要创建一个NETunnelProviderManager

```swift
fileprivate func createProviderManager() -> NETunnelProviderManager {
    let manager = NETunnelProviderManager()
    let conf = NETunnelProviderProtocol()
    conf.serverAddress = "BearFree"
    manager.protocolConfiguration = conf
    manager.localizedDescription = "BearFree"
    return manager
}
```

将manager保存至系统中

```swift
manager.saveToPreferences{
    error in
        if error != nil{print(error);return;}
        //Todo
}
```

执行save方法后会跳转系统VXN菜单，添加我们创建的VPN

![](http://lyz0818.5166.info//20190422201004_mlgeUD_Screenshot.jpeg)

此时如果save方法调用多次，会出现VPN 1 VPN 2等多个描述文件 ，因此，苹果也要求，在创建前应读取当前的managers

```swift
NETunnelProviderManager.loadAllFromPreferencesWithCompletionHandler{ 
    (managers, error) in
    guard let managers = managers else{return}
    let manager: NETunnelProviderManager
    if managers.count > 0 {
        manager = managers[0]
    }else{
        manager = self.createProviderManager()
    }
    // Todo
    // manager.saveToPreferences.......
}
```

### 配置Network Extension

打开extension中的模板文件，对应Swift版本与父类修改语法。主要需要以下两个函数控制VPN状态

```swift
//启动VPN时调用
func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void)

//停止VPN时调用
func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void)
```

此时我们仅仅需要测试VPN连接是否能正常建立。因此我们只需要在startTunnelWithOptions中调用setTunnelNetworkSettings 方法即可。当completionHandler()执行后VPN连接就会显示在手机上了。

```swift
override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
    let ipv4Settings = NEIPv4Settings(addresses: ["192.169.89.1"], subnetMasks: ["255.255.255.0"])
    let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "8.8.8.8")
    networkSettings.mtu = 1500
    networkSettings.iPv4Settings = ipv4Settings
    setTunnelNetworkSettings(networkSettings) {
        error in
        guard error == nil else {
            completionHandler(error)
            return
        }
            completionHandler(nil)
    }
}
```

### 开启VXN

对刚刚创建的manager调用startVPNTunnel方法即可

```swift
try manager.connection.startVPNTunnel(options: [:])
```

如果在创建VXN saveToPreferences后立刻执行startVPNTunnel，此时可能会出现Domin="null"，说明系统并未准备好，所以启动代码放至loadAndCreatePrividerManager方法的返回block中

```swift
func connect(){
    self.loadAndCreatePrividerManager { (manager) in
        guard let manager = manager else{return}
        do{
            try manager.connection.startVPNTunnel(options: [:])
        }catch let err{
            print(err)
        }
    }
}
```

具体的实现逻辑可以查看demo中vpnManager.swift文件。

连接成功后manager.connection.status会发生改变，所以我们需要监听status值，从而得知目前的vpn连接状态，用于更新UI显示。

```swift
func addVPNStatusObserver() {
    guard !observerAdded else{
        return
    }
    loadProviderManager { [unowned self] (manager) -> Void in
        if let manager = manager {
            self.observerAdded = true
            NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: manager.connection, queue: OperationQueue.main, using: { [unowned self] (notification) -> Void in
                self.updateVPNStatus(manager)
                })
            }
        }
}
```

### VXN配置(IP、端口等)

manager通过protocolConfiguration的属性向Network Extension传递配置信息，在vpnManager中实现如下配置方法，并在启动vpn前调用即可

```swift
fileprivate func setRulerConfig(_ manager:NETunnelProviderManager){
    var conf = [String:AnyObject]()
    conf["ss_address"] = ip_address as AnyObject?
    conf["ss_port"] = port as AnyObject?
    conf["ss_method"] = algorithm as AnyObject? // 大写 没有横杠 看Extension中的枚举类设定 否则引发fatal error
    conf["ss_password"] = password as AnyObject?
    conf["ymal_conf"] = getRuleConf() as AnyObject?
    let orignConf = manager.protocolConfiguration as! NETunnelProviderProtocol
    orignConf.providerConfiguration = conf
    manager.protocolConfiguration = orignConf
    print(ip_address,port,algorithm,password)
}
```

在Extension中

```swift
public var protocolConfiguration: NEVPNProtocol { get }    
```

存入了上面写入的配置信息，我们可以直接读取。

### 关于网络状态的改变 

4G与wifi切换，这里确实有点坑，在里面绕了很久，一开始调试发现vxn是通的，但是过段时间就不能用了，删了重装也不行，无意中改了一个extension中的ip又好用了，换了网络环境又不能用了，百思不得其解，debug了半天也没找到问题，下面先说下怎么如何监听网络环境变化：

NEProvider 中存在属性`public var defaultPath: NWPath? { get }` 表明当前系统的网络请求路径。我们可以通过KVO监听`defaultPath`的改变。当`defaultPath`与之前状态发生改变，且`defaultPath.status == .Satisfied`时，我们可以认定系统网络进行了切换。此时我们需要重启VPN及重启代理服务器。

重连VPN方法非常简单，只需要再次调用StartVPN函数即可。

```swift
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
```

那如何在这个Network Extension中debug呢？我们用正常的debug方式，尝试在当前文件中加入断点，发现毫无反应，所以Tunnel的调试有着单独的调试方式，首先我们需要将主程序在设备上运行，然后通过Xcode->Debug->Attach To Process （有个列表加载过程，需要稍等一下）选择你的Tunnel名进行debug，**debug过程中如果不手动关闭tunnel的调试模式，会出现vxn链接后秒断的情况，需要注意一下。**下面再来说我是如何解决上面所说的切换网络时出现的问题，在系统设置中找到我们的App，将**网络访问权限调整为WLAN与蜂窝移动网**，至此再切换网络就没有之前的问题了，为了App在刚启动时就可以获取网络权限，我加了一个无用的网络请求，你也可以用自己的方式来获取权限。

![](http://lyz0818.5166.info//20190423121036_XaOOXa_Screenshot.jpeg)

### DemoUI

UI层我直接使用了Eureka这个第三方框架，它是XLForm的swift版本，也是通过carthage集成，想了解的也可以看下demo。



### The End

好了，我碰到的问题应该都讲清楚了，有问题可以和我交流，如果有不对的地方希望指正，3Q！
