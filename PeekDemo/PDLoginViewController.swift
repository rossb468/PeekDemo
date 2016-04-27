//
//  PDLoginViewController.swift
//  PeekDemo
//
//  Created by Ross Bower on 4/25/16.
//  Copyright © 2016 Ross Bower. All rights reserved.
//

import UIKit
import Fabric
import TwitterKit

protocol PDLoginViewDelegate {
    func initializeWithSession(session: TWTRSession?)
}

class PDLoginViewController: UIViewController {

    var delegate:PDLoginViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.view.backgroundColor = UIColor.blackColor()
        
        print(Twitter.sharedInstance().authConfig)
        
        let logInButton = TWTRLogInButton(logInCompletion: { session, error in
            if (session != nil) {
                print("signed in as \(session!.userName)");
                self.delegate?.initializeWithSession(session)
            }
            else {
                print("error: \(error!.localizedDescription)");
            }
        })
        
        logInButton.center = self.view.center
        self.view.addSubview(logInButton)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
