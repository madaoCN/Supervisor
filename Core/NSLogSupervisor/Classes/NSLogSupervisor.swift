//
//  ASLSupervisorProtocol.swift
//  Supervisor
//
//  Created by 梁宪松 on 2020/3/24.
//

import Foundation

//--------------------------------------------------------------------------
// MARK: NSLogSupervisorDelegate
//--------------------------------------------------------------------------
@objc public protocol NSLogSupervisorDelegate : NSObjectProtocol {
    
    func nslogSupervisorDid(with str: String)
}

@objcMembers
//--------------------------------------------------------------------------
// MARK: A tool to hook NSObject and print outputs
//--------------------------------------------------------------------------
open class NSLogSupervisor: NSObject {

    //--------------------------------------------------------------------------
    // MARK: file private property
    //--------------------------------------------------------------------------
    
    private static let _shared: NSLogSupervisor = NSLogSupervisor()

    open class var shared : NSLogSupervisor {
        get {
            return ._shared
        }
    }

    //--------------------------------------------------------------------------
    // MARK: file public property
    //--------------------------------------------------------------------------
        
    // weak delegate tables
    public var delegateTable = NSHashTable<NSLogSupervisorDelegate>(options: .weakMemory)
    
    //--------------------------------------------------------------------------
    // MARK: public func
    //--------------------------------------------------------------------------
    
    /// start to retrive system log
    open func start() {
        
        ASLFishHook.hook { (model) in
            for delegate in self.delegateTable.objectEnumerator() {
                (delegate as? NSLogSupervisorDelegate)?.nslogSupervisorDid(with: model.message)
            }
        }
    }
}


//--------------------------------------------------------------------------
// MARK: Extension for delegate table
//--------------------------------------------------------------------------

extension NSLogSupervisor {
    
    
    open class func add(delegate: NSLogSupervisorDelegate?) {
        
        self.shared.delegateTable.add(delegate)
    }
    
    open class func remove(delegate: NSLogSupervisorDelegate?) {
        
        self.shared.delegateTable.remove(delegate)
    }
    
    open class func removeAllDelegates() {
        
        self.shared.delegateTable.removeAllObjects()
    }
}
