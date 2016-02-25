//
//  HomeTableCell.swift
//  NoteVote
//
//  Created by Dustin Jones on 2/24/16.
//  Copyright © 2016 uiowa. All rights reserved.
//

import Foundation


class HomeTableCell:UITableViewCell {
    
    @IBOutlet weak var roomName:UILabel!
    
    @IBOutlet weak var roomDistance:UILabel!
    
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // initialization code.
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        //configure the view for the selected state.
    }
    
}