//
//  SupervisorLogModel.swift
//  iSupervisor
//
//  Created by 梁宪松 on 2020/3/24.
//

import Foundation

@objc public enum SupervisorLogType: Int {
    case off
    case debug
    case info
    case warn
    case error
}

extension SupervisorLogType {
    
    public static func description(with type: SupervisorLogType) -> String {
        
        switch type {
        case .off:
            return "OFF"
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warn:
            return "WARN"
        case .error:
            return "ERROR"
        default:
            return ""
        }
    }
}

@objcMembers
open class SupervisorLogModel: NSObject {

    open private(set) var type : SupervisorLogType!
    
    /// date for timestamp
    open private(set) var date: Date!
    
    /// thread which log the message
    open private(set) var thread: Thread?
    
    /// filename with extension
    open private(set) var file: String?
    
    /// number of line in source code file
    open private(set) var line: Int?
    
    /// name of the function which log the message
    open private(set) var function: String?
    
    /// message be logged
    open private(set) var message: String?
    
    init(type:SupervisorLogType,
         thread: Thread,
         message: String?,
         file: String?,
         line: Int?,
         function: String?) {
        super.init()
        self.date = Date()
        self.type = type
        self.thread = thread
        self.file = file
        self.line = line
        self.function = function
        self.message = message
    }
        
    open override var description: String {
        
        get {
            var des = String.init()
            des.append(contentsOf: "[\(SupervisorLogType.description(with: self.type))]")
            
            des.append(contentsOf: " \(self.date.description)")
            
            if let threadStr = thread?.description {
                des.append(contentsOf: " \(threadStr)")
            }
            
            if let fileStr = file {
                des.append(contentsOf: " \(fileStr)")
            }
            
            if let lineInt = line {
                des.append(contentsOf: " \(lineInt)")
            }
            
            if let funcStr = function {
                des.append(contentsOf: " \(funcStr)")
            }
            
            des.append(contentsOf: " \(message ?? "")")

            return des
        }
    }
}
