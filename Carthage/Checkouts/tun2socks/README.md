tun2socks
=========
[![Build Status](https://travis-ci.org/zhuhaow/tun2socks.svg?branch=master)](https://travis-ci.org/zhuhaow/tun2socks) [![GitHub release](https://img.shields.io/github/release/zhuhaow/tun2socks.svg?maxAge=2592000)](https://github.com/zhuhaow/tun2socks/releases) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![GitHub license](https://img.shields.io/badge/license-BSD_3--Clause-blue.svg)](https://raw.githubusercontent.com/zhuhaow/NEKit/master/LICENSE.md)

tun2socks is designed to work with the NetworkExtension framework. It is based on the latest stable lwip with minimal modification.

Feature
-----
The whole stack is based on GCD which is efficient and fast.

Only TCP protocol is supported.

All other protocols (UDP, ICMP, IGMP, ...) will not be supported since they are stateless or can not be supported in NetworkExtension.

Usage
-----
The overall structure of tun2socks:

```
╔═══════════════════════╗                                                       
║sourceAddress: X.X.X.X ║                                                       
║    sourcePort: XX     ║                    writeData(_:)                      
╚═══════════════════════╝                          │                            
                                                   │            ┌──────────────┐
┌─────────────┐  ┌───────┐  ┌────────────┐  ┌──────▼──────┐     │TSTCPSocketDel│
│    Local    ◀──▶  TUN  ◀──▶ TSIPStack  ◀──▶ TSTCPSocket ├─────▶egate.didReadD│
└─────────────┘  └───────┘  └────────────┘  └─────────────┘     │    ata()     │
                                                                └──────────────┘
```

Fully documented API reference can be found [here](https://zhuhaow.github.io/tun2socks/).

[Carthage](https://github.com/Carthage/Carthage) is recommended to integrate tun2socks by adding

```
github "zhuhaow/tun2socks"
```

to the `Cartfile`.

Another alternative may be [NEKit](https://github.com/zhuhaow/NEKit) which uses tun2socks and provides many features to build a proxy app.

IPv6 support
------------
As of now, IPv6 is not supported since lwip 1.4 does not support dual stack.
IPv6 will be supported in the next major version of lwip.

