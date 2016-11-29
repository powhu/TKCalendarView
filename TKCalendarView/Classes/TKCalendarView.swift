//
//  TKCalendar.swift
//  TKCalendar
//
//  Created by PowHu Yang on 2016/11/4.
//  Copyright © 2016年 PowHu Yang. All rights reserved.
//

import UIKit

@objc public protocol TKCalendarViewDelegate {
    @objc optional func calendar(calendar: TKCalendarView , dateChanged date: Date)
}

@IBDesignable
open class TKCalendarView: UIView ,TKDatePageViewDelegate, UIGestureRecognizerDelegate {

    open var delegate : TKCalendarViewDelegate?
    private let pageCount = 4
    
    private var movement = Movement.none
    open var calendar : Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "en")
        return c }() {
        didSet { pages.forEach{ $0.calendar = calendar } }
    }
    open var date : Date {
        set(newValue) {
            selectedDate = newValue
            for (index, v) in pages.enumerated() {
                v.date = newValue.addingTimeInterval(-60*60*24*Double(index))
            }
        }
        get { return selectedDate }
    }
    open var dayFont = UIFont.systemFont(ofSize: 180, weight: UIFontWeightUltraLight) {
        didSet { pages.forEach{ $0.dayFont = dayFont } }
    }
    open var monthFont = UIFont.systemFont(ofSize: 30, weight: UIFontWeightRegular) {
        didSet { pages.forEach{ $0.monthFont = monthFont } }
    }
    open var weekFont = UIFont.systemFont(ofSize: 30, weight: UIFontWeightRegular) {
        didSet { pages.forEach{ $0.weekFont = weekFont } }
    }
    private var selectedDate = Date()
    var gestureMinimalRecognizeInterval : TimeInterval = 0.25
    private(set) var lastGestureReconizedAt = Date()
    private(set) var animatingPagesCount = 0
    private(set) var pages : [TKDatePageView] = []
    @IBInspectable open var color : UIColor = #colorLiteral(red: 0.3403162956, green: 0.572663188, blue: 0.7036480308, alpha: 1) { didSet { pages.forEach{ $0.color = color } } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    open func setup() {
        backgroundColor = .white
        for i in 1...pageCount {
            let v = TKDatePageView(frame: bounds, date: date.addingTimeInterval(-60*60*24*Double(i-1)) , delegate: self)
            v.autoresizingMask = [.flexibleWidth,.flexibleHeight]
            addSubview(v)
            sendSubview(toBack: v)
            pages.append(v)
            
            //Tricky! Move shapeLayer to self so we can use zPostion to reindex it.
            layer.addSublayer(v.shapeLayer)
            v.shapeLayer.zPosition = 10
        }
        let panGes = UIPanGestureRecognizer(target: self, action: #selector(self.pan(ges:)))
        panGes.delegate = self
        addGestureRecognizer(panGes)
    }

    open func pan(ges : UIPanGestureRecognizer) {
        if ges.state == .began {
            if movement != .none &&
               movement != (ges.velocity(in: self).direction == .right ? .backward : .forward) {
                ges.isEnabled = false
                ges.isEnabled = true
                return
            }
            
            lastGestureReconizedAt = Date()
            movement = ges.velocity(in: self).direction == .right ? .backward : .forward

            if movement == .backward {
                let view = pages.last!
                view.date = pages.first!.date.addingTimeInterval(60*60*24)
                view.animator.fractionComplete = 1
                pages.removeLast()
                pages.insert(view, at: 0)
                
                //Using CADisplayLink to update mask path,
                //layer will show before mask update.
                let s = CAShapeLayer()
                s.path = UIBezierPath(rect: CGRect.zero).cgPath
                view.contentView.layer.mask = s
                
                bringSubview(toFront: view)
            }
        }

        guard let view = pages.filter({ !$0.animator.isRunning }).first else { return }
        let animator = view.animator
        animator.isReversed = movement == .backward
        
        switch ges.state {
        case .changed:
            var value = animator.fractionComplete + view.progressStepFor(translation: ges.translation(in: self))
            if movement == .forward {
                if let prePageView = pages.before(item: view) , prePageView.animator.isRunning {
                    value = min(value, prePageView.lastPositionX / (prePageView.bounds.size.width + prePageView.bounds.size.height) / 1.2)
                }
            } else {
                if let prePageView = pages.after(item: view) , prePageView.animator.isRunning {
                    value = max(value, prePageView.lastPositionX / (prePageView.bounds.size.width + prePageView.bounds.size.height) * 1.2)
                }
            }
            view.animator.fractionComplete = value
            ges.setTranslation(.zero, in: self)
        case .ended , .cancelled , .failed:
            if movement == .backward {
                if animator.fractionComplete > 0.88 {
                    animator.isReversed = false
                }
            } else {
                if animator.fractionComplete < 0.12 {
                    animator.isReversed = true
                }
            }
            animator.startAnimation()
            animatingPagesCount += 1
        default: break
        }
    }
    
    public func datePageView(pageView: TKDatePageView, didAnimateToProgress progress: CGFloat) {
        
        if let pre = pages.before(item: pageView) , pre.animator.isRunning {
            pageView.shapeLayer.zPosition = pre.shapeLayer.zPosition + 1
        } else {
            pageView.shapeLayer.zPosition = 10
        }
        
        guard let nextPageView = pages.after(item: pageView)  else { return }
        nextPageView.rotateToProgress(progress: progress ,movement: movement)
    }

    public func datePageView(pageView: TKDatePageView, finishedAnimationAtPosition position: UIViewAnimatingPosition) {

        if movement == .forward && position == .end {
            selectedDate = pageView.date.addingTimeInterval(-60*60*24)
            delegate?.calendar?(calendar: self, dateChanged: selectedDate)
        }

        if movement == .backward && position == .start {
            selectedDate = pageView.date
            delegate?.calendar?(calendar: self, dateChanged: selectedDate)
        }
        
        if  let nextPageView = pages.after(item: pageView) {
            nextPageView.finishRotateAnimation()
        }

        if position == .end {
            let last = pages.last!
            pageView.date = last.date.addingTimeInterval(-60*60*24)
            pages.remove(at: pages.index(of: pageView)!)
            pages.append(pageView)
            sendSubview(toBack: pageView)
        }
        
        animatingPagesCount -= 1
        if animatingPagesCount == 0 {
            movement = .none
        }
    }

    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return Date().timeIntervalSince(lastGestureReconizedAt) > gestureMinimalRecognizeInterval
    }
}

public enum Movement {
    case forward
    case backward
    case none
}

public extension Array where Element: Hashable {
    
    func after(item: Element) -> Element? {
        if let index = self.index(of: item) , index + 1 < self.count {
            return self[index + 1]
        }
        return nil
    }
    
    func before(item: Element) -> Element? {
        if let index = self.index(of: item) , index - 1 >= 0 {
            return self[index - 1]
        }
        return nil
    }
}
