//
//  ViewController.swift
//  TKCalendarView
//
//  Created by Yang on 11/22/2016.
//  Copyright (c) 2016 Yang. All rights reserved.
//

import UIKit
import TKCalendarView

class ViewController: UIViewController ,TKCalendarViewDelegate{

    @IBOutlet var calendarView : TKCalendarView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        calendarView.delegate = self
    }

    func calendar(calendar: TKCalendarView, dateChanged date: Date) {
        print(date)
    }
}

