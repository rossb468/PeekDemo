//
//  PDDataSource.swift
//  PeekDemo
//
//  Created by Ross Bower on 4/22/16.
//  Copyright © 2016 Ross Bower. All rights reserved.
//

import UIKit
import TwitterKit
import Fabric

protocol PDDataSourceDelegate {
    func newTweetsLoaded(tweetIndecies: [NSIndexPath])
}

class PDDataSource: NSObject {

    var tweetList:[TWTRTweet] = []
    var APIClient:TWTRAPIClient! // I normally don't like this naming style, but it matches what TwitterKit uses in their data source
    var delegate:PDDataSourceDelegate?
    var tweetCount:Int {
        get {
            return tweetList.count
        }
    }
    var sessionUrlString:String?
    var sessionParameters:[String : String]?
    
    var fetchInProgress:Bool = false
    
    init(session: TWTRSession?, url: String, parameters: [String:String]) {
        super.init()
        if (session != nil) {
            //print("signed in as \(session!.userName)");
            self.APIClient = TWTRAPIClient()
            self.sessionUrlString = url
            self.sessionParameters = parameters
            
            self.fetchNewTweets()
        }
    }
    
    func fetchNewTweets() {
        
        var params = sessionParameters
        if tweetCount > 0 {
            params!["since_id"] = tweetList.first?.tweetID
        }
        
        fetchTweetsWithURL(sessionUrlString!, andParameters: params!, appendToFront: true)
        
    }
    
    func fetchOldTweets() {
        var params = sessionParameters
        if tweetCount > 0 {
            params!["max_id"] = tweetList.last?.tweetID
        }
        
        fetchTweetsWithURL(sessionUrlString!, andParameters: params!, appendToFront: false)
    }
    
    func fetchTweetsWithURL(urlString: String, andParameters parameters: [String : String], appendToFront: Bool) {
        fetchInProgress = true
        var clientError : NSError?
        
        let request = APIClient.URLRequestWithMethod("GET", URL: urlString, parameters: parameters, error: &clientError)
        self.APIClient.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
            if connectionError != nil {
                print("Error: \(connectionError)")
            }
            
            do {
                if data != nil {
                    let json:NSMutableArray = try (NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary)["statuses"] as! NSMutableArray
                    var insertionIndex = appendToFront ? 0 : self.tweetCount
                    if insertionIndex < 0 { insertionIndex = 0 }
                    var newTweets = TWTRTweet.tweetsWithJSONArray(json as [AnyObject]) as! [TWTRTweet]
                
                    // If appending to end, fetch request will include last tweet in list
                    // Remove this duplicate
                    if(appendToFront == false) {
                        newTweets.removeFirst()
                    }
                    self.tweetList.insertContentsOf(newTweets, at: insertionIndex)
                
                    var indexPathSet:[NSIndexPath] = []
                
                    let start = insertionIndex
                    let end = start + newTweets.count - 1
                    if end >= start {
                        for i in insertionIndex...insertionIndex + newTweets.count - 1 {
                            indexPathSet.append(NSIndexPath(forRow: i, inSection: 0))
                        }
                    }
                
                    self.delegate?.newTweetsLoaded(indexPathSet)
                    print("new tweets loaded")
                    self.fetchInProgress = false
                }
                else {
                    print("error loading tweets: no data retrieved")
                    self.fetchInProgress = false
                }
            } catch let jsonError as NSError {
                print("json error: \(jsonError.localizedDescription)")
            }
        }
    }
    
    func tweetForIndexPath(indexPath: NSIndexPath) -> TWTRTweet {
        return tweetList[indexPath.row]
    }
    
}
