//
//  ServerLink.swift
//  NoteVote
//
//  Created by Dustin Jones on 12/21/15.
//  Copyright © 2015 uiowa. All rights reserved.
//

import Foundation
import Parse

class ServerLink {
	
	//MARK: Variables
    //Needed for HostVC Refresh

    var isHosting:Bool = false
    var songBatch:[(String,String,String)] = []
    private var rooms:[PFObject] = []
    var partyObject:PFObject!
    var songsVoted:[String:[String]] = [:]
    var musicList:[PFObject] = []
    var songsInBatch:[String] = []
	
	
	//MARK: Internal Methods
    
    /**
    * Finds rooms based on a geolocation point of the current device.
    * Will append results to rooms variable -- as a list of PFObjects.
    */
    func findRooms(completion: (result: [PFObject]) -> Void){
        self.rooms = []
        let query = PFQuery(className: "PartyObject")
        
        // NEED TO FIX THIS BEFORE RELEASEING
        // will search within certain distance to phone's location.
        query.whereKey("partyID", notEqualTo: "0")
        query.findObjectsInBackgroundWithBlock{
            (objects: [PFObject]?, error: NSError?) -> Void in
            PFAnalytics.trackEventInBackground("getrooms", block: nil)
            if error == nil {
                // The find succeeded.
                print("Successfully retrieved \(objects!.count) scores.")
                // Do something with the found objects
                if let objects = objects as [PFObject]! {
                    for object in objects {
                        serverLink.rooms.append(object)
                    }
                }
            } else {
                // Log details of the failure
                print("Error: \(error!) \(error!.userInfo)")
            }
            completion(result: serverLink.rooms)
        }
    }
    /**
     * Sets the current room to the room selected by the user.
     * -takes in an Int(objectNum) -> used to locate correct room from rooms variable.
     */
    func partySelect(objectNum:Int){
        partyObject = rooms[objectNum]
    }
    
    func setParty(party:PFObject){
        self.partyObject = party
    }
    
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
     * Adds a party object to the Parse PartyObject class.
     * -takes in a String(partyName) -> used to set the parties name.
     * -takes in a String(partyID) -> used to set the partiesID to the hosts Spotify ID.
     * -takes in a Bool(priv) -> used to set the room as private or not.
     */
    func addParty(partyName:String, partyID:String, priv:Bool) {
        let partyObject = PFObject(className:"PartyObject")
        partyObject["partyName"] = partyName
        partyObject["partyID"] = partyID
        partyObject["partyPrivate"] = priv
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
                // The object has been saved.
                
            } else {
                // There was a problem, check error.description
            }
        }
    }
    
    /**
     * deletes a party object from the Parse PartyObject class.
     * -takes in a String(roomID) -> hosts Spotify ID, used to find correct object for deletion.
     */
    func deleteRoom() {
        self.isHosting = false
        let query = PFQuery(className: "PartyObject")
        userDefaults.setObject("", forKey: "partyPin")
        userDefaults.synchronize()
        query.whereKey("partyID", equalTo: partyObject.objectForKey("partyID") as! String)
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            
            PFAnalytics.trackEventInBackground("deleteroom", block: nil)
            if(error == nil && objects != nil){
                objects![0].deleteInBackground()
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
            }
        }
    }
    
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
            print("syncronise delete failed")
        }
    }

    /**
     * Adds a song to the parties subclass of SongLibrary.
     * -takes in a String(trackTitle) -> title of the song.
     * -takes in a String(trackArtist) -> artist of the song.
     * -takes in a String(uri) -> Spotify track URI of the song.
     * uses these variables to create a song object in Parse.
     */
    func addSongBatch(){
        for song in self.songBatch{
            var alreadyIn:Bool = false
			print(self.musicList.count)
            searchHandler.getURIwithPartial(song.2){
                (result:String) in
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
        self.songBatch = []
    }
    
    func voteURI(uri:String){
        self.songsVoted[self.partyObject.objectForKey("partyID") as! String]?.append(uri)
    }
    
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
            }
        }
        return output
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
        query.whereKey("partyID", equalTo: partyObject.objectForKey("partyID") as! String)
        do{
            let list =  try query.findObjects()
            for object in list {
                self.musicList.append(object)
            }
        }
        catch{ print("synchronise query failed" ) }
    }
    
    /**
     * Asynchronous way to get an updated list of music in the song queue.
     */
    func getQueue(completion: (result: [PFObject]) -> Void){
        self.musicList = []
        let query = PFQuery(className: "SongLibrary")
        query.addAscendingOrder("CreatedAt")
        query.whereKey("partyID", equalTo: partyObject.objectForKey("partyID") as! String)
        query.findObjectsInBackgroundWithBlock {
            (objects:[PFObject]?, error: NSError?) -> Void in
            PFAnalytics.trackEventInBackground("deleteroom", block: nil)
            if(error == nil){
                for object in objects!{
                    self.musicList.append(object)
                }
                completion(result: self.musicList)
            }
        }
    }
    
    /**
     * Sorts musicList in serverLink, based upon votes, highest being the first element of the list.
     */
    func sortMusicList(){
        var temp:[PFObject] = []
        var voteChecker:[String] = []
        if !self.musicList.isEmpty {
			
            for i in 0...self.musicList.count - 1 {
                voteChecker.append(self.musicList[i].objectForKey("uri") as! String)
                if temp.count == 0 {
                    temp.append(self.musicList[i])
                } else {
                    for j in 0...temp.count-1 {
                        
                        //if its larger, insert in temp
                        if self.musicList[i].objectForKey("votes") as! Int > temp[j].objectForKey("votes") as! Int {
                            temp.insert(self.musicList[i], atIndex: j)
                            break
                        }
                        
                        //if its not larger than any element in temp
                        if j == temp.count-1 {
                            temp.append(self.musicList[i])
                        }
                    }
                    
                }
            }
            self.updateSongsVoted(voteChecker)
            self.musicList = temp
        }
    }
    
    func updateSongsVoted(currentSongs:[String]){
        var temp:[String] = []
        for item in self.songsVoted[self.partyObject.objectForKey("partyID") as! String]!{
            if(currentSongs.contains(item)){
               temp.append(item)
            }
        }
        self.songsVoted[self.partyObject.objectForKey("partyID") as! String] = temp
    }
    
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
    
    func addSongToBatch(songTitle:String, trackArtist:String, uri:String){
        let song:(String,String,String) = (songTitle,trackArtist,uri)
        self.songBatch.append(song)
        self.songsInBatch.append(song.2)
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
    
    }