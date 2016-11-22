//
//  ViewController.swift
//  TKCalendarView
//
//  Created by PowHu Yang on 11/22/2016.
//  Copyright (c) 2016 PowHu Yang. All rights reserved.
//

import UIKit
import TKCalendarView

class ViewController: UIViewController ,TKCalendarViewDelegate{

    @IBOutlet var calendarView : TKCalendarView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        calendarView.delegate = self
        
        /*
        //Change calendar you can get localize support 
        //Something like 11月 22　火曜日
        var c = Calendar(identifier: .japanese)
        c.locale = Locale(identifier: "ja")
        calendarView.calendar = c
         */
    }

    func calendar(calendar: TKCalendarView, dateChanged date: Date) {
        print(date)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(calendarView.date)
    }
}

