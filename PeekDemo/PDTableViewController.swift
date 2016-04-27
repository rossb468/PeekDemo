//
//  PDTableViewController.swift
//  PeekDemo
//
//  Created by Ross Bower on 4/22/16.
//  Copyright © 2016 Ross Bower. All rights reserved.
//

import UIKit
import TwitterKit
import Fabric

class PDTableViewController: UITableViewController, PDDataSourceDelegate, PDLoginViewDelegate {
    
    var dataSource:PDDataSource?
    var loginViewController:PDLoginViewController?
    var userIcon:UIImage?
    var user:TWTRUser?
    
    func showLoginView() {
        loginViewController = PDLoginViewController()
        loginViewController!.delegate = self
        loginViewController?.modalPresentationStyle = .OverCurrentContext
        presentViewController(loginViewController!, animated: true, completion: nil)
    }
    
    func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }
    
    func downloadUserIcon(url: NSURL){
        print("Download Started")
        print("lastPathComponent: " + (url.lastPathComponent ?? ""))
        getDataFromUrl(url) { (data, response, error)  in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let data = data where error == nil else { return }
                print(response?.suggestedFilename ?? "")
                print("Download Finished")
                self.setTwitterUserIcon(UIImage(data: data)!)
            }
        }
    }
    
    func setTwitterUserIcon(image: UIImage) {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: image.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal), style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        if(Twitter.sharedInstance().sessionStore.existingUserSessions().count == 0) {
            showLoginView()
        }
        else {
            initializeWithSession(Twitter.sharedInstance().sessionStore.existingUserSessions().first as? TWTRSession)
        }
    }
    
    func initializeWithSession(session: TWTRSession?) {
        
        self.dataSource = PDDataSource(session: session, url: "https://api.twitter.com/1.1/search/tweets.json", parameters: ["q":"@peek"])
        self.dataSource?.delegate = self
        
        dataSource?.APIClient.loadUserWithID((session?.userID)!, completion: { (user, error) -> Void in
            if user != nil {
                self.user = user
                self.downloadUserIcon(NSURL(string: (user?.profileImageMiniURL)!)!)
            }
        })
        navigationItem.title = "@" + (session?.userName)!
        
        self.tableView.registerClass(TWTRTweetTableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl!.addTarget(self, action: #selector(PDTableViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        loginViewController?.dismissViewControllerAnimated(true, completion: {})
    }
    
    func refresh(sender:AnyObject) {
        dataSource?.fetchNewTweets()
    }
    
    func newTweetsLoaded(tweetIndecies: [NSIndexPath]) {
        
        tableView.beginUpdates()
        tableView.insertRowsAtIndexPaths(tweetIndecies, withRowAnimation: UITableViewRowAnimation.Automatic)
        tableView.endUpdates()
        
        refreshControl?.endRefreshing()
        
        print("table refresh complete")
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        var point = self.tableView.frame.origin
        point.x += self.tableView.frame.size.width / 2
        point.y += self.tableView.frame.height - 5
        point = self.tableView.convertPoint(point, fromView: self.tableView.superview)
        
        let indexPath = self.tableView?.indexPathForRowAtPoint(point)
        
        if indexPath?.row >= self.tableView.numberOfRowsInSection(0) - 3 && dataSource?.fetchInProgress == false {
            dataSource?.fetchOldTweets()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource == nil ? 0 : dataSource!.tweetCount
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:TWTRTweetTableViewCell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! TWTRTweetTableViewCell

        cell.configureWithTweet((dataSource?.tweetForIndexPath(indexPath))!)

        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let tweet = dataSource?.tweetForIndexPath(indexPath)
        let width = tableView.frame.width
        return TWTRTweetTableViewCell.heightForTweet(tweet!, style: TWTRTweetViewStyle.Compact, width: width, showingActions: false)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
