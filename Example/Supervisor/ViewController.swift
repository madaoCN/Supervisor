//
//  ViewController.swift
//  Supervisor
//
//  Created by madaoCN on 03/24/2020.
//  Copyright (c) 2020 madaoCN. All rights reserved.
//

import UIKit
import Supervisor

class ViewController: UIViewController, CrashSupervisorDelegate {
    
    func crashSupervisorDidCatchCrash(_ crashModel: CSCrashModel) {
        SupervisorLogger.debug(message: "test")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        CrashSupervisor.add(self)
        var arr: NSMutableArray = NSArray.init() as! NSMutableArray
        arr.add("test")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

