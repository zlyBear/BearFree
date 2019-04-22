import Foundation
import lwip

/// The delegate that the developer should implement to handle what to do when a new TCP socket is connected.
public protocol TSIPStackDelegate: class {
    /**
     A new TCP socket is accepted. This means we received a new TCP packet containing SYN signal.
     
     - parameter sock: the socket object.
     */
    func didAcceptTCPSocket(_ sock: TSTCPSocket)
}

func tcpAcceptFn(_ arg: UnsafeMutableRawPointer?, pcb: UnsafeMutablePointer<tcp_pcb>?, error: err_t) -> err_t {
    return TSIPStack.stack.didAcceptTCPSocket(pcb!, error: error)
}

func outputPCB(_ interface: UnsafeMutablePointer<netif>?, buf: UnsafeMutablePointer<pbuf>?, ipaddr: UnsafeMutablePointer<ip_addr_t>?) -> err_t {
    TSIPStack.stack.writeOut(pbuf: buf!)
    return err_t(ERR_OK)
}

/**
 This is the IP stack that receives and outputs IP packets.
 
 `outputBlock` and `delegate` should be set before any input.
 Then call `receivedPacket(_:)` when a new IP packet is read from the TUN interface.
 
 There is a timer running internally. When the device is going to sleep (which means the timer will not fire for some time), then the timer must be paused by calling `suspendTimer()` and resumed by `resumeTimer()` when the deivce wakes up.
 
 - note: This class is NOT thread-safe.
 */
public final class TSIPStack {
    /// The singleton stack instance that developer should use. The `init()` method is a private method, which means there will never be more than one IP stack running at the same time.
    public static var stack = TSIPStack()
    
    // The whole stack is running in this dispatch queue.
    public var processQueue = DispatchQueue(label: "tun2socks.IPStackQueue", attributes: [])
    
    var timer: DispatchSourceTimer?
    let listenPCB: UnsafeMutablePointer<tcp_pcb>
    
    /// When the IP stack decides to output some IP packets, this block is called.
    ///
    /// - warning: This should be set before any input.
    public var outputBlock: (([Data], [NSNumber]) -> ())!
    
    /// The delegate instance.
    ///
    /// - warning: Setting this variable is not protected in the GCD queue, so this shoule be set before any input and shoule never change afterwards.
    public weak var delegate: TSIPStackDelegate?
    
    // Since all we need is a mock interface, we just use the loopback interface provided by lwip.
    // No need to add any interface.
    var interface: UnsafeMutablePointer<netif> {
        return netif_list
    }
    
    private init() {
        lwip_init()
        
        // add a listening pcb
        var pcb = tcp_new()
        var addr = ip_addr_any
        tcp_bind(pcb, &addr, 0)
        pcb = tcp_listen_with_backlog(pcb, UInt8(TCP_DEFAULT_LISTEN_BACKLOG))
        listenPCB = pcb!
        tcp_accept(pcb, tcpAcceptFn)
        
        netif_list.pointee.output = outputPCB
    }
    
    private func checkTimeout() {
        sys_check_timeouts()
    }
    
    func dispatch_call(_ block: @escaping () -> ()) {
        processQueue.async(execute: block)
    }
    
    /**
     Suspend the timer. The timer should be suspended when the device is going to sleep.
     */
    public func suspendTimer() {
        timer = nil
    }
    
    /**
     Resume the timer when the device is awoke.
     
     - warning: Do not call this unless the stack is not resumed or you suspend the timer.
     */
    public func resumeTimer() {
        timer = DispatchSource.makeTimerSource(queue: processQueue)
        // note the default tcp_tmr interval is 250 ms.
        // I don't know the best way to set leeway.
        timer!.schedule(deadline: DispatchTime.distantFuture , repeating: DispatchTimeInterval.microseconds(250), leeway: DispatchTimeInterval.microseconds(250))
        timer!.setEventHandler {
            [weak self] in
            self?.checkTimeout()
        }
        sys_restart_timeouts()
        timer!.resume()
    }
    
    /**
     Input an IP packet.
     
     - parameter packet: the data containing the whole IP packet.
     */
    public func received(packet: Data) {
        // Due to the limitation of swift, if we want a zero-copy implemention, we have to change the definition of `pbuf.payload` to `const`, which is not possible.
        // So we have to copy the data anyway.
        let buf = pbuf_alloc(PBUF_RAW, UInt16(packet.count), PBUF_RAM)!
        packet.copyBytes(to: buf.pointee.payload.bindMemory(to: UInt8.self, capacity: packet.count), count: packet.count)
        
        // The `netif->input()` should be ip_input(). According to the docs of lwip, we do not pass packets into the `ip_input()` function directly.
        _ = netif_list.pointee.input(buf, interface)
    }
    
    func writeOut(pbuf: UnsafeMutablePointer<pbuf>) {
        var data = Data(count: Int(pbuf.pointee.tot_len))
        _ = data.withUnsafeMutableBytes { p in
            pbuf_copy_partial(pbuf, p.baseAddress, pbuf.pointee.tot_len, 0)
        }
        // Only support IPv4 as of now.
        outputBlock([data], [NSNumber(value: AF_INET)])
    }
    
    func didAcceptTCPSocket(_ pcb: UnsafeMutablePointer<tcp_pcb>, error: err_t) -> err_t {
        tcp_accepted_c(listenPCB)
        delegate?.didAcceptTCPSocket(TSTCPSocket(pcb: pcb, queue: processQueue))
        return err_t(ERR_OK)
    }
}
