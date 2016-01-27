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
    
    //Needed for HostVC Refresh
    var albumArt:UIImage?
    var trackTitle:String?
    var artistName:String?
    var currentURI:String?
    
    var songBatch:[(String,String,String)] = []
    private var rooms:[PFObject] = []
    private var partyObject:PFObject!
    var songsVoted:[String:[String]] = [:]
    var musicOptions:[Song] = []
    var musicList:[PFObject] = []
    var searchList:[SPTPartialTrack] = []
    
    
    //- - - - - Internal Methods - - - - -
    
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
        let query = PFQuery(className: "PartyObject")
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
    
    /**
     * Adds a song to the parties subclass of SongLibrary.
     * -takes in a String(trackTitle) -> title of the song.
     * -takes in a String(trackArtist) -> artist of the song.
     * -takes in a String(uri) -> Spotify track URI of the song.
     * uses these variables to create a song object in Parse.
     */
    func addSongBatch(){
        for song in self.songBatch{
            let trackObject = PFObject(className: "SongLibrary")
            trackObject["trackTitle"] = song.0
            trackObject["trackArtist"] = song.1
            trackObject["uri"] = song.2
            trackObject["votes"] = 1
            trackObject["partyID"] = self.partyObject.objectForKey("partyID") as! String
            voteURI(song.2)
            trackObject.saveInBackground()
            serverLink.musicList.append(trackObject)
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
    func increment(songURI:String){
        let query = PFQuery(className: "SongLibrary")
        query.whereKey("partyID", equalTo: partyObject.objectForKey("partyID") as! String)
        query.whereKey("uri", equalTo: songURI)
        query.findObjectsInBackgroundWithBlock {
                (objects: [PFObject]?, error: NSError?) -> Void in
                if(error == nil && objects != nil){
                    objects![0].incrementKey("votes")
                    objects![0].saveInBackground()
                }
        }
    }
    
    /**
     * decrements the vote on a specific song by 1.
     * -takes in a String(songURI) -> the Spotify track URI for the song voted on.
     * uses that to find the correct song.
     */
    func decrement(songURI:String){
        let query = PFQuery(className: "SongLibrary")
        query.whereKey("partyID", equalTo: partyObject.objectForKey("partyID") as! String)
        query.whereKey("uri", equalTo: songURI)
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            if(error == nil && objects != nil){
                objects![0].incrementKey("votes", byAmount: -1)
                objects![0].saveInBackground()
            }
        }
    }

    /**
     * pops the top item off of musicList, Which should be the highest voted song.
     * then calls removeSong passing along the top song. while removing it form itself.
     * then returns the removed song's URI.
     */
    func pop()->String{
        sortMusicList()
        let uri:String = musicList.first!.objectForKey("uri") as! String
        serverLink.removeSong(uri)
        musicList.removeFirst()
        PFAnalytics.trackEventInBackground("savequeue", dimensions: ["where":"host"], block: nil)
        return uri
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
            PFAnalytics.trackEventInBackground("deleteroom", block: nil)
            if(error == nil && objects != nil){
                objects![0].deleteInBackground()
            }
        }
    }
    
    /**
     * Synchronise way to get an updated list of music in the song queue.
     */
    func syncGetQueue(){
        let query = PFQuery(className: "SongLibrary")
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
     * Asynchronise way to get an updated list of music in the song queue.
     */
    func getQueue(completion: (result: [PFObject]) -> Void){
        self.musicList = []
        let query = PFQuery(className: "SongLibrary")
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
        for object in musicList {
            if(temp.isEmpty){
                temp.append(object)
            }
            else{
                var index = 0
                for obj in temp {
                    let num1 = object.objectForKey("votes") as! Int
                    let num2 = obj.objectForKey("votes") as! Int
                    if(num1 > num2){
                        temp.insert(object, atIndex: index)
                        break
                    }
                    index+=1
                }
            }
        }
        musicList = temp
    }
    
    func removeSongFromBatch(songTitle:String, trackArtist:String){
        if(!self.songBatch.isEmpty){
            for i in 0...songBatch.count-1 {
                if(songBatch[i].0 == songTitle && songBatch[i].1 == trackArtist){
                    songBatch.removeAtIndex(i)
                    return
                }
            }
        }
    }
    
    func addSongToBatch(songTitle:String, trackArtist:String, uri:String){
        let song:(String,String,String) = (songTitle,trackArtist,uri)
        self.songBatch.append(song)
    }
    
    
    /**
     * On party entry it checks to see if the user has voted on any songs in the party
     *      if they have it sets songsVoted to that list of song titles.
     */
    func songsVotedCheck(){
        if(!songsVoted.keys.contains(userDefaults.objectForKey("roomID") as! String)){
            songsVoted[(userDefaults.objectForKey("roomID") as! String)] = []
        }
    }
    
    /**
     * Changes songs from Spotify objects into Song objects.
     * saves all the Song objects in serverLink.musicOptions.
     */
    func setMusicOptions(){
        self.musicOptions = []
        for track in self.searchList {
            let song:Song = Song()
            song.setURI(String(track.uri))
            song.setTitle(track.name)
            let str = String(track.artists.first)
            
            //Building artist name with parsing.
            let strList = str.componentsSeparatedByString(" ")
            var artistName:String = strList[2]
            if(strList.count-1 > 3){
                for i in 3...strList.count-2{
                    artistName += " " + strList[i]
                }
            }
            song.setArtist(artistName)
            self.musicOptions.append(song)
        }
    }
}