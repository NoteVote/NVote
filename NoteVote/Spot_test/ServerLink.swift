//
//  ServerLink.swift
//  NoteVote
//
//  Created by Dustin Jones on 12/21/15.
//  Copyright © 2015 uiowa. All rights reserved.
//

import Foundation
import Parse
import Crashlytics

class ServerLink {
	
	//MARK: Variables
    //Needed for HostVC Refresh

    var isHosting:Bool = false
    var songBatch:[(String,String,String)] = []
    private var rooms:[PFObject] = []
    var cleanUp:Bool = false
    var partyObject:PFObject!
    var songsVoted:[String:[String]] = [:]
    var songCleanup:[String:Int] = [:]
    var musicList:[PFObject] = []
    var songsInBatch:[String] = []
    var currentLocation:PFGeoPoint?
	
	//MARK: Internal Methods
    
    /**
    * Finds rooms based on a geolocation point of the current device.
    * Will append results to rooms variable -- as a list of PFObjects.
    * Finds rooms within 2.0 miles.
    */
    func findRooms(completion: (result: [PFObject]) -> Void){
        if(self.currentLocation != nil){
            self.rooms = []
            let query = PFQuery(className: "PartyObject")
            print(self.currentLocation)
            
            //Change the double withinMiles: to change how far the radius search is.
            query.whereKey("geoLocation", nearGeoPoint: self.currentLocation!, withinMiles: 2.0)
            query.findObjectsInBackgroundWithBlock{
                (objects: [PFObject]?, error: NSError?) -> Void in
                PFAnalytics.trackEventInBackground("getrooms", block: nil)
                if error == nil {
                    
                    if let objects = objects as [PFObject]! {
                        for object in objects {
                            serverLink.rooms.append(object)
                        }
                    }
                } else {
                    Answers.logCustomEventWithName("Parse Error", customAttributes:["Code":error!])
                }
                completion(result: serverLink.rooms)
            }
        }
    }
    /**
     * Sets the current room to the room selected by the user.
     * -takes in an Int(objectNum) -> used to locate correct room from rooms variable.
     */
    func partySelect(objectNum:Int){
        partyObject = rooms[objectNum]
    }
    
    /**
     * Sets the party PFObject to the partyObject for hosting.
     */
    func setParty(party:PFObject){
        self.partyObject = party
    }
    
    /**
     * Gets a list of voted songs from the songsVoted dictionary if the room has been entered before.
     */
    func getSongsVoted() -> [String]{
        let voted = self.songsVoted[self.partyObject.objectForKey("partyID") as! String]
        if(voted != nil){
            return voted!
        }
        else {
            return []
        }
    }
    
    
    /**
     * On party entry it checks to see if the user has voted on any songs in the party
     *      if they have it sets songsVoted to that list of song titles.
     */
    func songsVotedCheck(){
        if(!songsVoted.keys.contains(partyObject.objectForKey("partyID") as! String)){
            songsVoted[(partyObject.objectForKey("partyID") as! String)] = []
        }
    }
    
    /**
     * Adds a party object to the Parse PartyObject class.
     * -takes in a String(partyName) -> used to set the parties name.
     * -takes in a String(partyID) -> used to set the partiesID to the hosts Spotify ID.
     * -takes in a Bool(priv) -> used to set the room as private or not.
     */
    func addParty(partyName:String, partyID:String, priv:Bool, completion:(result: String) -> Void) {
        
        let partyObject = PFObject(className:"PartyObject")
        partyObject["partyName"] = partyName
        partyObject["partyID"] = partyID
        partyObject["partyPrivate"] = priv
        partyObject["geoLocation"] = self.currentLocation!
        if(priv){
            var partyPin = ""
            partyPin += String(Int(arc4random_uniform(10)))
            partyPin += String(Int(arc4random_uniform(10)))
            partyPin += String(Int(arc4random_uniform(10)))
            partyPin += String(Int(arc4random_uniform(10)))
            partyObject["partyPin"] = partyPin
            userDefaults.setObject(partyPin, forKey: "partyPin")
            userDefaults.synchronize()
        }
        partyObject.saveInBackgroundWithBlock {
            (success: Bool, error: NSError?) -> Void in
            
            PFAnalytics.trackEventInBackground("createroom", block: nil)
            if (success) {
                self.partyObject = partyObject
                completion(result: "good")
            } else {
                completion(result: "fail")
				if (error != nil) {
					Answers.logCustomEventWithName("Parse Error", customAttributes:["Code":error!])
				}
            }
        }
    }
    
    /**
     * deletes a party object from the Parse PartyObject class.
     * ASync
     */
    func deleteRoom() {
        self.isHosting = false
        self.songCleanup = [:]
        let query = PFQuery(className: "PartyObject")
        userDefaults.setObject("", forKey: "partyPin")
        userDefaults.synchronize()
        query.whereKey("partyID", equalTo: partyObject.objectForKey("partyID") as! String)
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            
            PFAnalytics.trackEventInBackground("deleteroom", block: nil)
            if(error == nil && objects != nil){
                objects![0].deleteInBackground()
			} else {
				Answers.logCustomEventWithName("Parse Error", customAttributes:["Code":error!])
			}
        }
		
        let query2 = PFQuery(className: "SongLibrary")
        query2.whereKey("partyID", equalTo: partyObject.objectForKey("partyID") as! String)
        query2.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            if(error == nil && objects != nil){
                for object in objects!{
                    object.deleteInBackground()
                }
			} else {
				Answers.logCustomEventWithName("Parse Error", customAttributes:["Code":error!])
			}
        }
    }
    
    
    /**
     * Delets a party object from the Parse PartyObject class.
     * Sync
     */
    func deleteRoomNow(){
        userDefaults.setObject("", forKey: "partyPin")
        userDefaults.synchronize()
        self.isHosting = false
        
        let query = PFQuery(className: "SongLibrary")
        query.whereKey("partyID", equalTo: partyObject.objectForKey("partyID") as! String)
        do{
            try serverLink.partyObject.delete()
            let objects = try query.findObjects()
            for object in objects{
                try object.delete()
            }
        }
        catch{
            Answers.logCustomEventWithName("Parse Error", customAttributes:["Type":"Syncronous Delete"])
        }
    }
    
    /**
     * First Creates a song object from given input.
     * Then adds that song object to songBatch.
     * Used when poeple are clicking on songs in Search
     */
    func addSongToBatch(songTitle:String, trackArtist:String, uri:String){
        let song:(String,String,String) = (songTitle,trackArtist,uri)
        self.songBatch.append(song)
        self.songsInBatch.append(song.2)
    }
    
    /**
     * Removes a song from songBatch
     * Used when people are unclicking songs on Search
     */
    func removeSongFromBatch(songTitle:String, trackArtist:String){
        if(!self.songBatch.isEmpty){
            for i in 0...songBatch.count-1 {
                if(songBatch[i].0 == songTitle && songBatch[i].1 == trackArtist){
                    songBatch.removeAtIndex(i)
                    songsInBatch.removeAtIndex(i)
                    return
                }
            }
        }
    }

    /**
     * Adds songs to the parties subclass of SongLibrary.
     * uses songBatch and adds its songs SongLibrary on Parse.
     * ASync
     */
    func addSongBatch(completion:(result:String)->Void){
        let reachability: Reachability
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            Answers.logCustomEventWithName("Reachability Error", customAttributes: nil)
            completion(result: "fail")
            return
        }
        if reachability.isReachable(){
            for song in self.songBatch{
                var alreadyIn:Bool = false
                print(self.musicList.count)
                searchHandler.getURIwithPartial(song.2){
                    (result:String) in
                    if(result == "fail"){
                        self.songBatch = []
                        self.songsInBatch = []
                        completion(result: "fail")
                        return
                    }
                    else{
                        for track in self.musicList{
                            if(track.objectForKey("uri") as! String == result){
                                if(!self.songsVoted[self.partyObject.objectForKey("partyID") as! String]!.contains(result)){
                                    self.increment(result)
                                    self.voteURI(result)
                                    alreadyIn = true
                                    break
                                }
                            }
                        }
                        if(!alreadyIn){
                            let trackObject = PFObject(className: "SongLibrary")
                            trackObject["trackTitle"] = song.0
                            trackObject["trackArtist"] = song.1
                            trackObject["uri"] = result
                            trackObject["votes"] = 1
                            trackObject["partyID"] = self.partyObject.objectForKey("partyID") as! String
                            self.voteURI(result)
                            trackObject.saveInBackground()
                            serverLink.musicList.append(trackObject)
                        }
                    }
                }
            }
            self.songBatch = []
            self.songsInBatch = []
            completion(result: "Done")
            return
        }
        else{
            self.songBatch = []
            self.songsInBatch = []
            completion(result: "connect_fail")
            return
        }
    }
    
    /**
     * Adds a uri of a song voted on into songsVoted.
     * Used to know which songs are voted on in a party already by a user.
     */
    func voteURI(uri:String){
        self.songsVoted[self.partyObject.objectForKey("partyID") as! String]?.append(uri)
    }
    
    /**
     * Removes a uri of a song voted on into songsVoted.
     * Used to know which songs are voted on in a party already by a user.
     */
    func unvoteURI(uri:String){
        let index = self.songsVoted[self.partyObject.objectForKey("partyID") as! String]?.indexOf(uri)
        self.songsVoted[self.partyObject.objectForKey("partyID") as! String]?.removeAtIndex(index!)
    }
    
    /**
     * increments the vote on a specific song by 1.
     * -takes in a String(songURI) -> the Spotify track URI for the song voted on.
     * uses that to find the correct song.
     */
    func increment(songURI:String) -> Bool{
        var output = true
        let query = PFQuery(className: "SongLibrary")
        query.whereKey("partyID", equalTo: partyObject.objectForKey("partyID") as! String)
        query.whereKey("uri", equalTo: songURI)
        query.findObjectsInBackgroundWithBlock {
                (objects: [PFObject]?, error: NSError?) -> Void in
                if(error == nil && objects != nil){
                    objects![0].incrementKey("votes")
                    objects![0].saveInBackground()
                }
                else{
                    output = false
					Answers.logCustomEventWithName("Parse Error", customAttributes:["Code":error!])
            }
        }
        return output
    }
    
    /**
     * decrements the vote on a specific song by 1.
     * -takes in a String(songURI) -> the Spotify track URI for the song voted on.
     * uses that to find the correct song.
     */
    func decrement(songURI:String) -> Bool{
        var output = true
        let query = PFQuery(className: "SongLibrary")
        query.whereKey("partyID", equalTo: partyObject.objectForKey("partyID") as! String)
        query.whereKey("uri", equalTo: songURI)
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            if(error == nil && objects != nil){
                objects![0].incrementKey("votes", byAmount: -1)
                objects![0].saveInBackground()
            }
            else{
                output = false
				Answers.logCustomEventWithName("Parse Error", customAttributes:["Code":error!])
            }
        }
        return output
    }
    
    /**
     * This is a function that can be activated by the user in createRoom
     * This will remove songs from songLibrary on Parse if
     * the song has note been voted above 1 vote for 5 consecutive songs played.
     */
    func songClean(){
        if(self.cleanUp){
            for song in musicList {
                
                let songuri = song.objectForKey("uri") as! String
            
                //if song votes are less than 2
                if (song.objectForKey("votes") as! Int) <= 1 {
                    
                    //if song uri is already in songCleanup
                    if(  songCleanup.keys.contains(songuri) ){
                        
                        //if song uri has been through cleanup more than 4 times.
                        //remove song from server and from songCleanup.
                        if(songCleanup[songuri]! >= 4){
                            removeSong(songuri)
                            songCleanup.removeValueForKey(songuri)
                        }
                        else{
                            songCleanup[songuri]! += 1
                        }
                    }
                        
                    //if song not in songCleanup add it with a counter of 1.
                    else{
                        songCleanup[songuri] = 1
                    }
                }
                    //if song vote higher than 2 and still in songcleanup. remove from cleanup.
                else{
                    if(songCleanup.keys.contains(songuri)){
                        songCleanup.removeValueForKey(songuri)
                    }
                }
            }
        }
    }
    
    
    /**
     * removes the song with the URI given that matches the partyID the host has.
     * -Paramaters:
     *      uri:String -> used to find the song to remove.
     */
    func removeSong(uri:String){
        let query = PFQuery(className: "SongLibrary")
        query.whereKey("partyID", equalTo: partyObject.objectForKey("partyID") as! String)
        query.whereKey("uri", equalTo: uri)
        query.findObjectsInBackgroundWithBlock {
            (objects:[PFObject]?, error: NSError?) -> Void in
            if(error == nil && objects != nil){
                objects![0].deleteInBackground()
			} else {
				if (error != nil) {
					Answers.logCustomEventWithName("Parse Error", customAttributes:["Code":error!])
				}
			}
        }
    }
    
    /**
     * Synchronous way to get an updated list of music in the song queue.
     */
    func syncGetQueue(){
		self.musicList = []
        let query = PFQuery(className: "SongLibrary")
        query.addAscendingOrder("CreatedAt")
        query.addDescendingOrder("votes")
        query.whereKey("partyID", equalTo: partyObject.objectForKey("partyID") as! String)
        do{
            let list =  try query.findObjects()
            for object in list {
                self.musicList.append(object)
            }
        } catch {
			Answers.logCustomEventWithName("Parse Error", customAttributes:["Type":"Synchronous getQueue"])
		}
    }
    
    /**
     * Asynchronous way to get an updated list of music in the song queue.
     */
    func getQueue(completion: (result: [PFObject]) -> Void){
        let reachability: Reachability
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            completion(result: [])
            Answers.logCustomEventWithName("Reachability Error", customAttributes: nil)
            return
        }
        if reachability.isReachable(){
            self.musicList = []
            let query = PFQuery(className: "SongLibrary")
            query.addAscendingOrder("CreatedAt")
            query.addDescendingOrder("votes")
            query.whereKey("partyID", equalTo: partyObject.objectForKey("partyID") as! String)
            query.findObjectsInBackgroundWithBlock {
                (objects:[PFObject]?, error: NSError?) -> Void in
                
                PFAnalytics.trackEventInBackground("deleteroom", block: nil)
                
                if(error == nil){
                    for object in objects!{
                        print(object.objectForKey("trackTitle") as! String)
                        self.musicList.append(object)
                    }
                    completion(result: self.musicList)
                    
                } else {
                    Answers.logCustomEventWithName("Parse Error", customAttributes:["Code":error!])
                }
            }
        }
        else{
            completion(result: [])
            return
        }
    }

}