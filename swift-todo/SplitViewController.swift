//
//  SplitViewController.swift
//  swift-todo
//
//  Created by Joey on 8/18/16.
//  Copyright © 2016 Oursky Ltd. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController {
    override func viewDidAppear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if !appDelegate.loggedin {
            let loginView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController")
            self.present(loginView, animated: true, completion: nil)
        }
    }
}
