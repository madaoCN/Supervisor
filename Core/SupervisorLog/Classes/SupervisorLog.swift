//
//  Supervisor.swift
//  iSupervisor
//
//  Created by 梁宪松 on 2020/3/24.
//

import UIKit

//--------------------------------------------------------------------------
// MARK: SupervisorLogDelegate
//--------------------------------------------------------------------------
@objc public protocol SupervisorLogDelegate: NSObjectProtocol {
    
    func supervisorLogDidLog(with logModel: SupervisorLogModel)
}

//--------------------------------------------------------------------------
// MARK: Simple Log Lib
//--------------------------------------------------------------------------
@objcMembers
open class SupervisorLog: NSObject {
        
    //--------------------------------------------------------------------------
    // MARK: file private property
    //--------------------------------------------------------------------------
    
    // shared instance
    fileprivate static let shared: SupervisorLog = SupervisorLog()
    
    // weak delegate tables
    fileprivate var delegateTable = NSHashTable<SupervisorLogDelegate>(options: .weakMemory)
    
    // log queue
    open var logQueue = DispatchQueue.init(label: "SupervisorLog")
    
    // delegate call back queue, default is MainQueue
    open var delegateQueue = DispatchQueue.main;
    

    /// record message
    /// - Parameters:
    ///   - message: message be logged
    ///   - type: log type
    ///   - thread: thread which log the message
    ///   - file: filename with extension
    ///   - line: number of line in source code file
    ///   - function: name of the function which log the message
    fileprivate func record(message: String?,
                           type: SupervisorLogType,
                           thread: Thread,
                           file: String,
                           line: Int,
                           function: String) {
        
        if type == .off {
            return
        }
        
        self.delegateQueue.async {
            
            let logModel = SupervisorLogModel.init(
                type: type,
                thread: thread,
                message: message,
                file: self.name(of: file),
                line: line,
                function: function)
            
            print(logModel.description)
            
            self.delegateQueue.async {
                
                for delegate in self.delegateTable.objectEnumerator() {
                    (delegate as? SupervisorLogDelegate)?.supervisorLogDidLog(with: logModel)
                }
            }
        }
    }
    
    fileprivate func name(of file: String) -> String {
        
        return URL(fileURLWithPath: file).lastPathComponent
    }
}

//--------------------------------------------------------------------------
// MARK: Extension for logging debug messages
//--------------------------------------------------------------------------
extension SupervisorLog {
    
    open class func debug(message: String?,
                         thread: Thread = Thread.current,
                        file: String = #file,
                        line: Int = #line,
                        function: String = #function) {
        
        self.shared.record(message: message,
                           type: SupervisorLogType.debug,
                           thread: thread,
                           file: file,
                           line: line,
                           function: function)
    }
}

//--------------------------------------------------------------------------
// MARK: Extension for logging info messages
//--------------------------------------------------------------------------
extension SupervisorLog {
    
    open class func info(message: String?,
                         thread: Thread = Thread.current,
                        file: String = #file,
                        line: Int = #line,
                        function: String = #function) {
        
        self.shared.record(message: message,
                           type: SupervisorLogType.info,
                           thread: thread,
                           file: file,
                           line: line,
                           function: function)
    }
}

//--------------------------------------------------------------------------
// MARK: Extension for logging warn messages
//--------------------------------------------------------------------------
extension SupervisorLog {
    
    open class func warn(message: String?,
                         thread: Thread = Thread.current,
                        file: String = #file,
                        line: Int = #line,
                        function: String = #function) {
        
        self.shared.record(message: message,
                           type: SupervisorLogType.warn,
                           thread: thread,
                           file: file,
                           line: line,
                           function: function)
    }
}

//--------------------------------------------------------------------------
// MARK: Extension for logging error messages
//--------------------------------------------------------------------------
extension SupervisorLog {
    
    open class func error(message: String?,
                         thread: Thread = Thread.current,
                        file: String = #file,
                        line: Int = #line,
                        function: String = #function) {
        
        self.shared.record(message: message,
                           type: SupervisorLogType.error,
                           thread: thread,
                           file: file,
                           line: line,
                           function: function)
    }
}

//--------------------------------------------------------------------------
// MARK: Extension for delegate table
//--------------------------------------------------------------------------
extension SupervisorLog {
    
    
    open class func add(delegate: SupervisorLogDelegate?) {
        
        self.shared.delegateTable.add(delegate)
    }
    
    open class func remove(delegate: SupervisorLogDelegate?) {
        
        self.shared.delegateTable.remove(delegate)
    }
    
    open class func removeAllDelegates() {
        
        self.shared.delegateTable.removeAllObjects()
    }
}
