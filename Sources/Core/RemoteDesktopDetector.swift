import Foundation
import Darwin

public final class RemoteDesktopDetector {
    private static var cachedPid: pid_t = 0
    private static var lastLookupTime: TimeInterval = 0
    
    /// Returns the PID of Chrome Remote Desktop host (`remoting_me2me_host`), or 0 if not running.
    /// Caches result for 5 seconds to minimize proc_listpids overhead.
    public static func getChromeRemoteDesktopHostPid() -> pid_t {
        let now = Date().timeIntervalSince1970
        if cachedPid > 0 && (now - lastLookupTime) < 5.0 {
            // Verify process still exists
            if kill(cachedPid, 0) == 0 {
                return cachedPid
            }
        }
        
        lastLookupTime = now
        cachedPid = 0
        
        var pids = [pid_t](repeating: 0, count: 2048)
        let bytes = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, Int32(MemoryLayout<pid_t>.size * pids.count))
        let count = Int(bytes) / MemoryLayout<pid_t>.size
        for i in 0..<count {
            var nameBuffer = [CChar](repeating: 0, count: 1024)
            if proc_name(pids[i], &nameBuffer, UInt32(nameBuffer.count)) > 0 {
                let name = String(cString: nameBuffer)
                if name == "remoting_me2me_host" {
                    cachedPid = pids[i]
                    return cachedPid
                }
            }
        }
        return 0
    }
}
