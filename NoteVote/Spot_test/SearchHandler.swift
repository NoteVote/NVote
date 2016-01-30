//
//  SearchHandler.swift
//  NVBeta
//
//  Created by Dustin Jones on 12/8/15.
//  Copyright © 2015 uiowa. All rights reserved.
//

import Foundation

class SearchHandler {
	
	var playlistData:[(String, NSURL)] = []
	
    func Search(input:String, completion: (result: String) -> Void){
        SPTRequest.performSearchWithQuery(input, queryType: SPTSearchQueryType.QueryTypeTrack, offset: 0, session: nil, callback: { (error:NSError!, result:AnyObject!) -> Void in
            var trackListItems:[SPTPartialTrack] = []
            let trackListPage = result as! SPTListPage
            var trackListPageItems = trackListPage.items
            if(trackListPage.items == nil){
                return
            }
            if(trackListPage.items.count < 20){
                let count = trackListPageItems.count
                while(trackListItems.count < count){
                    trackListItems.append(trackListPageItems.removeFirst() as! SPTPartialTrack)
                }
            }
            else{
                while(trackListItems.count < 20) {
                    trackListItems.append(trackListPageItems.removeFirst() as! SPTPartialTrack)
                }
            }
            spotifyPlayer.searchList = trackListItems
            completion(result: "done")
        })
    }
    
    func getURIwithPartial(uri:String,completion: (result:String) -> Void ){
        
        SPTRequest.requestItemAtURI(NSURL(string: uri), withSession: nil, market: "US", callback: { (error:NSError!, result:AnyObject!) ->Void in
            let track = result as! SPTPartialTrack
            SPTRequest.requestItemFromPartialObject(track, withSession: nil, callback: { (error:NSError!, result:AnyObject!) -> Void in
                    let fullTrack = result as! SPTTrack
                completion(result: String(fullTrack.uri))
                })
        })
    }
	
	
	//TODO: clean up variable names
	func getPlaylists( completion: (result: String) -> Void){
		let sessionHandler = SessionHandler()
		let session = sessionHandler.getSession()
		SPTRequest.playlistsForUserInSession(session, callback: { (error:NSError!, result:AnyObject!) -> Void in
			var playlistList = result as! SPTPlaylistList
			var playlistItems = playlistList.items
			var playlistPartials:[SPTPartialPlaylist] = []
			
			if playlistItems != nil {
				let count = playlistItems.count
				while playlistPartials.count < count {
					playlistPartials.append(playlistItems.removeFirst() as! SPTPartialPlaylist)
				}
			}
			
			for x in playlistPartials {
				self.playlistData.append((x.name, x.uri))
			}
			
			
			completion(result: "Done" )
		})
	}
    
    
    
}