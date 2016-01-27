//
//  Song.swift
//  NoteVote
//
//  Created by Dustin Jones on 1/20/16.
//  Copyright © 2016 uiowa. All rights reserved.
//

import Foundation

class Song {
    
    var Artist:String = ""
    var Title:String = ""
    var URI:String = ""
    
    func setArtist(artist:String){
        Artist = artist
    }
    
    func setTitle(title:String){
        Title = title
    }
    
    func setURI(uri:String){
        URI = uri
    }
}