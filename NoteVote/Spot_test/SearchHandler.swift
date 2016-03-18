//
//  SearchHandler.swift
//
//  Created by Dustin Jones on 12/8/15.
//  Copyright © 2015 uiowa. All rights reserved.
//

import Foundation

class SearchHandler {
	
	var playlistData:[(String, NSURL)] = []
	
    func Search(input:String, completion: (result: String) -> Void){
        SPTSearch.performSearchWithQuery(input, queryType: SPTSearchQueryType.QueryTypeTrack, offset: 0, accessToken: nil, market: "US", callback: { (error:NSError!, result:AnyObject!) -> Void in
            if(error != nil){
                completion(result: "fail")
                return
            }
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
            if(error != nil){
                completion(result: "fail")
                return
            }
            let track = result as! SPTPartialTrack
            SPTRequest.requestItemFromPartialObject(track, withSession: nil, callback: { (error:NSError!, result:AnyObject!) -> Void in
                if(error != nil){
                    completion(result: "fail")
                    return
                }
                let fullTrack = result as! SPTTrack
                completion(result: String(fullTrack.playableUri))
            })
        })
    }
	
	
	func getPlaylists( completion: (result: String) -> Void){
		let sessionHandler = SessionHandler()
		let session = sessionHandler.getSession()
		
		SPTPlaylistList.playlistsForUserWithSession(session, callback: { (error:NSError!, result:AnyObject!) -> Void in
			let playlistList = result as! SPTPlaylistList
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