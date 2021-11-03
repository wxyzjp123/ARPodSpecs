//
//  Memory.swift
//  ARInfoBox
//
//  Created by Victor Wu on 2019/5/8.
//  Copyright © 2019 Victor Wu. All rights reserved.
//

import Foundation

public struct MemoryInfo {
    public var memoryData: [Double]
    public var timeData: [String]
    
    public init() {
        memoryData = []
        timeData = []
    }
    
    public func isEmpty() -> Bool {
        guard memoryData.count == timeData.count else { print("check memoryData no equial to timeData.count"); return true}
        return memoryData.isEmpty
    }
    
    public mutating func resetAll() {
        self.memoryData.removeAll()
        self.timeData.removeAll()
    }
    
}

public struct ApplicationMemoryCurrentUsage {
    
    var usage : Double = 0.0
    var total : Double = 0.0
    var ratio : Double = 0.0
    
    public var description: String {
        return "usage: \(usage) -- total: \(total) -- ratio: \(ratio)"
    }
}

public func report_memory()->ApplicationMemoryCurrentUsage {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_,
                      task_flavor_t(MACH_TASK_BASIC_INFO),
                      $0,
                      &count)
        }
    }
    
    if kerr == KERN_SUCCESS {
        
        print("Memory in use (in bytes): \(info.resident_size)")
        let usage = info.resident_size / (1024 * 1024)
        let total = ProcessInfo.processInfo.physicalMemory / (1024 * 1024)
        let ratio = Double(info.virtual_size) / Double(ProcessInfo.processInfo.physicalMemory)
        return ApplicationMemoryCurrentUsage(usage: Double(usage), total: Double(total), ratio: Double(ratio))
    } else {
        print("Error with task_info(): " +
            (String(cString: mach_error_string(kerr), encoding: String.Encoding.ascii) ?? "unknown error"))
        return ApplicationMemoryCurrentUsage()
    }
}
