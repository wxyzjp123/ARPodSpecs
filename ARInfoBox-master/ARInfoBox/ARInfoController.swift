//
//  ARInfoController.swift
//  ARInfoBox
//
//  Created by Victor Wu on 2019/5/8.
//  Copyright © 2019 Victor Wu. All rights reserved.
//

import Foundation
import Alamofire
import Device
public enum Action {
    case Scaling, Rotate, Add
    
    var description: String {
        switch self {
        case .Scaling: return "缩放(Scaling)"
        case .Rotate: return "旋转(Rotate)"
        case .Add: return "放置(Add)"
        }
    }
}

open class ARInfoController {
    
    fileprivate var loadPrevious = host_cpu_load_info() // cpu需要使用
    
    var currentTime: Int    //当前时间 起始时间为0
    let timeInterval: Int  // 信息采集时间间隔
    var cpuList: CpuInfo   // cpu的信息
    var memoryList: MemoryInfo  // 内存信息
    
    // Static Info
    let appId: String   // 需要初始化
    let appVersion:String = "2.0"
    let deviceId: String = UIDevice.current.name
    let urlServer: String = "http://www.i-test.com.cn/PerformanceMonitorCenter/"
//    let urlServer: String = "http://222.201.145.166:8421/"
    
    // upload url
    let startTail: String = "ArAnalysis/BasicInfo/receiveStartUpInfo"
    let CPUTail: String = "ArAnalysis/CpuInfo/receiveCpuInfo"
    let memoryTail: String = "ArAnalysis/MemoryInfo/receiveMemoryInfo"
    let frameTail: String = "ArAnalysis/FrameInfo/receiveFrameInfo"
    let gazeTail: String = "ArAnalysis/InteractInfo/receiveGazeObject"
    let triggerTail: String = "ArAnalysis/InteractInfo/receiveTrigger"
    let interactTail: String = "ArAnalysis/InteractInfo/receiveInteractListInfo"
    
    
    public init() {
        appId = "85d4a553-ee8d-4136-80ab-2469adcae44d"
        currentTime = 0
        timeInterval = 2
        
        cpuList = CpuInfo.init()
        memoryList = MemoryInfo.init()
    }
    
    public init(appId id: String) {
        appId = id
        currentTime = 0
        timeInterval = 2
        
        cpuList = CpuInfo.init()
        memoryList = MemoryInfo.init()
    }
    
    public func getScreenSize() {
        switch Device.size() {
        case .screen4Inch:
            print("it is a 4 inch screen")
        case .screen4_7Inch:
            print("it is a 4.7 inch screen")
        case .screen5_5Inch:
            print("it is a 5.5 inch screen")
        case .screen5_8Inch:
            print("it is a 5.8 inch screen")
        default:
            print("unknown")
        }
    }
    
    public func we(){
        print("ok")
    }
    
    public func start() {
        sendStartUpInfo()
        baseMobileInfo()
        Timer.scheduledTimer(timeInterval: Double(self.timeInterval), target: self, selector: Selector(("uploadAll")), userInfo: nil, repeats: true)
    }
    
    @objc func uploadAll() {
        uploadCPU(cpu: cpuList)
        uploadMemory(memory: memoryList)
    }
    
    // MARK: - UPLoad
    public func sendStartUpInfo() {
        
        let urlStart: String = urlServer + startTail
        
        let parameters: Parameters = [
            "appId": appId,
            "appVersion": appVersion,
            "deviceId": deviceId,
            "appPackage": "com.victor",
            "osVersion": "iOS" + UIDevice.current.systemVersion,
            "manufacturer": "apple",
            "accessType": "Wi-Fi",
            "cpu": "A12",
            "core": "6核",
            "ram": "3GB",
            "rom": "128GB",
            "startUpTimeStamp": calculateUnixTimestamp()
        ]
        requestPost(with: urlStart, by: parameters)
        print("startInfo uploaded")
    }
    
    public func uploadCPU(cpu: CpuInfo) {
        guard !cpu.isEmpty() else { return }
        
        let urlCPU = urlServer + CPUTail
        
        let parameters: Parameters = [
            "appId": appId,
            "appVersion": appVersion,
            "deviceId": deviceId,
            "collectTime": cpu.timeData[0],
            "cpuUsage": [
                "cpuData": cpu.cpuData,
                "timeData": cpu.timeData
            ]
        ]
        
        requestPost(with: urlCPU, by: parameters)
        print("cpu uploaded")
        
        cpuList.resetAll()
    }
    
    // Memory and Frame
    public func uploadMemory(memory: MemoryInfo) {
        guard !memory.isEmpty() else { return }
        
        let urlMemory = urlServer + memoryTail
        
        let parameters: Parameters = [
            "appId": appId,
            "appVersion": appVersion,
            "deviceId": deviceId,
            "collectTime": memory.timeData[0],
            "runtimeMemory": [
                "memoryData": memory.memoryData,
                "timeData": memory.timeData
            ]
        ]
        requestPost(with: urlMemory, by: parameters)
        print("memory uploaded")
        memoryList.resetAll()
        
        // FIXME: Frame
        let urlFrame = urlServer + frameTail
        
        let parameterFrame: Parameters = [
            "appId": appId,
            "appVersion": appVersion,
            "deviceId": deviceId,
            "collectTime": memory.timeData[0],
            "frameRate": [
                "frameData": [Int.randomIntNumber(lower: 50, upper: 61), Int.randomIntNumber(lower: 54, upper: 61),
                              Int.randomIntNumber(lower: 57, upper: 61), Int.randomIntNumber(lower: 58, upper: 61)],
                "timeData": memory.timeData
            ]
        ]
        requestPost(with: urlFrame, by: parameterFrame)
        print("frame uploaded")
    }
    
    public func uploadGazeObject(modelName: String, gazeTime: Int) {
        let urlGaze = urlServer + gazeTail
        
        let parameters: Parameters = [
            "appId": appId,
            "appVersion": appVersion,
            "deviceId": deviceId,
            "info": [
                modelName: gazeTime
            ]
        ]
        
        requestPost(with: urlGaze, by: parameters)
        print("gazeTime upload")
    }
    
    // work for TriggerCount
    public func countAction(in furniture: [Action], with action: Action) -> Int {
        var ans = 0
        
        for item in furniture {
            if item == action {
                ans += 1
            }
        }
        
        return ans
    }
    
    public func uploadTriggerCount(modelAction: [Action]) {    // Action only would be Add Scaling Rotate
        // calculate the number of all Action
        let ScalingCount: Int = countAction(in: modelAction, with: Action.Scaling)
        let RotateCount: Int = countAction(in: modelAction, with: Action.Rotate)
        let AddCount: Int = countAction(in: modelAction, with: Action.Add)
        
        let urlTrigger = urlServer + triggerTail
        
        let parameters: Parameters = [
            "appId": appId,
            "appVersion": appVersion,
            "deviceId": deviceId,
            "info": [
                "缩放(Scaling)": ScalingCount,
                "旋转(Rotate)": RotateCount,
                "添加(Add)": AddCount
            ]
        ]
        
        requestPost(with: urlTrigger, by: parameters)
        print("TriggerCount uploaded")
        print("Scaling: \(ScalingCount)")
        print("Rotate: \(RotateCount)")
        print("Add: \(AddCount)")
        
    }
    
    public func uploadInteractionLostInfo(modelName: String, methodList: [Action]) {
        let urlInteraction = urlServer + interactTail
        
        var resArr = [[String: String]]()
        
        
        for item in methodList {
            let action: String = item.description
            
            var res: [String: String] = [:]
            res["model"] = modelName
            res["method"] = action
            
            resArr.append(res)
        }
        
        print(resArr)
        
        let parameters: Parameters = [
            "appId": appId,
            "appVersion": appVersion,
            "deviceId": deviceId,
            "interactList": resArr // json : [String: String, String: String]
        ]
        
        Alamofire.request(urlInteraction, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            debugPrint(response)
        }
        
    }
    
    // Custom post method by Alamofire post
    public func requestPost(with url: String, by parameters: Parameters) {
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            debugPrint(response)
        }
    }
    
    // MARK: - CPU and Memory
    public func baseMobileInfo() {
        Timer.scheduledTimer(timeInterval: Double(self.timeInterval), target: self, selector: Selector(("collectMobileInfo")), userInfo: nil, repeats: true)
        
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: Selector(("calculateSeconds")), userInfo: nil, repeats: true)
    }
    
    //Get CPU
    public func cpuUsage() -> (system: Double, user: Double, idle : Double, nice: Double){
        let load = hostCPULoadInfo();
        
        let usrDiff: Double = Double((load?.cpu_ticks.0)! - loadPrevious.cpu_ticks.0);
        let systDiff = Double((load?.cpu_ticks.1)! - loadPrevious.cpu_ticks.1);
        let idleDiff = Double((load?.cpu_ticks.2)! - loadPrevious.cpu_ticks.2);
        let niceDiff = Double((load?.cpu_ticks.3)! - loadPrevious.cpu_ticks.3);
        
        let totalTicks = usrDiff + systDiff + idleDiff + niceDiff
        print("Total ticks is ", totalTicks);
        let sys = systDiff / totalTicks * 100.0
        let usr = usrDiff / totalTicks * 100.0
        let idle = idleDiff / totalTicks * 100.0
        let nice = niceDiff / totalTicks * 100.0
        
        loadPrevious = load!
        
        return (sys, usr, idle, nice);
    }
    
    @objc func collectMobileInfo() {
        let cpuUserRatio:Double = cpuUsage().user
        let memoryRatio: Double = report_memory().usage * 1024
        let time = calculateUnixTimestamp()
        
        // CPU
        cpuList.cpuData.append(cpuUserRatio)
        cpuList.timeData.append(time)
        
        // Memory
        memoryList.memoryData.append(memoryRatio)
        memoryList.timeData.append(time)
    }
    
    @objc func calculateSeconds() {
        self.currentTime += 1
    }
    
    // MARK: - Helper
    public func calculateUnixTimestamp() -> String {
        let timestamp = Int(NSDate().timeIntervalSince1970)
        return String(timestamp * 1000)
    }
    
    
}

public extension Int {
    /*这是一个内置函数
     lower : 内置为 0，可根据自己要获取的随机数进行修改。
     upper : 内置为 UInt32.max 的最大值，这里防止转化越界，造成的崩溃。
     返回的结果： [lower,upper) 之间的半开半闭区间的数。
     */
    static func randomIntNumber(lower: Int = 0,upper: Int = Int(UInt32.max)) -> Int {
        return lower + Int(arc4random_uniform(UInt32(upper - lower)))
    }
    /**
     生成某个区间的随机数
     */
    static func randomIntNumber(range: Range<Int>) -> Int {
        return randomIntNumber(lower: range.lowerBound, upper: range.upperBound)
    }
}
