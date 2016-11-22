# TKCalendar

The page curl animation calendar.  Inspired by 『君の名は｡』

## About

A calendar app used in the movie called 『君の名は｡』
Swipe to change date with page curl animation.

## Preview

![](ScreenShots/sample.gif)

## Installation
### Cocoapods

### Manually
Drag `TKCalendarView.swift` , `TKDatePageView.swift` into your project.

## Usage

### Use Interface Builder
Add a `UIView` and change class to `TKCalendarView`. That's all.

### Or use code

	let calendar = TKCalendarView(frame: CGRect(x: 0, y: 0, width: 320, height: 320))
	calendar.delegate = self
    view.addSubview(calendar)

### Delegate 

When date changed `TKCalendarView` will call this delegate.

	func calendar(calendar: TKCalendarView, dateChanged date: Date) {
        print(date)
    }

## Customization

Here is a list of customizable behaviors:

	var color
	var dayFont
	var monthFont
	var weekFont
	var calendar




## Requirements
iOS 10+
XCode 8.0+
Swift 3.0+

## License
MIT license.
