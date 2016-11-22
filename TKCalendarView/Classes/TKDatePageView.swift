//
//  TKDatePageView.swift
//  TKCalendar
//
//  Created by PowHu Yang on 2016/11/5.
//  Copyright © 2016年 PowHu Yang. All rights reserved.
//

import UIKit

public protocol TKDatePageViewDelegate {
    func datePageView(pageView : TKDatePageView, finishedAnimationAtPosition position : UIViewAnimatingPosition)
    func datePageView(pageView : TKDatePageView, didAnimateToProgress progress: CGFloat)
}

open class TKDatePageView: UIView {
    
    open var progress : CGFloat = 0

    open var contentView = UIView()
    open var rotateView = UIView()
    open var monthLabel = UILabel()
    open var dayLabel = UILabel()
    open var weekdayLabel = UILabel()
    open var dayFont = UIFont.systemFont(ofSize: 180, weight: UIFontWeightUltraLight) {
        didSet {
            dayLabel.font = dayFont
            setNeedsLayout()
        }
    }
    open var monthFont = UIFont.systemFont(ofSize: 30, weight: UIFontWeightRegular) {
        didSet {
            monthLabel.font = monthFont
            setNeedsLayout()
        }
    }
    open var weekFont = UIFont.systemFont(ofSize: 30, weight: UIFontWeightRegular) {
        didSet {
            weekdayLabel.font = weekFont
            setNeedsLayout()
        }
    }
    open let shapeLayer = CAShapeLayer()
    open var maskLayer = CAShapeLayer()
    private let dummyAnimatorView = UIView()
    public var delegate : TKDatePageViewDelegate
    var animationDuration = 1.2
    private(set) var isAnimatorFinished = false
    open var animator : UIViewPropertyAnimator {
        if let a = runningAnimator , isAnimatorFinished == false {
            return a
        } else {
            let a = UIViewPropertyAnimator(duration: animationDuration, curve: .easeInOut, animations: {
                self.dummyAnimatorView.center = CGPoint(x: self.bounds.size.width + self.bounds.size.height, y: 0)
            })
            a.addCompletion { position in
                self.delegate.datePageView(pageView: self, finishedAnimationAtPosition: position)
                self.dummyAnimatorView.center = .zero
                self.isAnimatorFinished = true
            }
            isAnimatorFinished = false
            runningAnimator = a
            return a
        }
    }
    private var runningAnimator : UIViewPropertyAnimator?
    private(set) var lastPositionX : CGFloat = 0.0
    open var date : Date { didSet { refreshDate() } }
    open var labels : [UILabel] { return [monthLabel,dayLabel,weekdayLabel] }
    open var color = #colorLiteral(red: 0.3403162956, green: 0.572663188, blue: 0.7036480308, alpha: 1) {
        didSet {
            labels.forEach{ $0.textColor = color }
            shapeLayer.fillColor = color.cgColor
        }
    }
    open var calendar : Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "en")
        return c }() {
        didSet { refreshDate() }
    }

    public init(frame: CGRect ,date aDate : Date , delegate : TKDatePageViewDelegate) {
        self.date = aDate
        self.delegate = delegate
        super.init(frame: frame)

        addSubview(dummyAnimatorView)

        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleHeight,.flexibleWidth]
        contentView.backgroundColor = .white
        var t = contentView.layer.sublayerTransform
        t.m34 = -1 / 400
        contentView.layer.sublayerTransform = t
        addSubview(contentView)

        rotateView.frame = bounds
        rotateView.autoresizingMask = [.flexibleHeight,.flexibleWidth]
        contentView.addSubview(rotateView)

        contentView.layer.mask = maskLayer

        for l in labels {
            l.textColor = color
            l.textAlignment = .center
            rotateView.addSubview(l)
        }

        dayLabel.font = dayFont
        monthLabel.font = monthFont
        weekdayLabel.font = weekFont
        refreshDate()

        shapeLayer.fillColor = color.cgColor
        shapeLayer.shadowColor = UIColor.black.cgColor
        shapeLayer.shadowOffset = CGSize(width: -1, height: 1)
        shapeLayer.shadowRadius = 2.5
        shapeLayer.shadowOpacity = 0.5
        layer.addSublayer(shapeLayer)

        let displayLink = CADisplayLink(target: self, selector: #selector(self.update(displayLink:)))
        displayLink.preferredFramesPerSecond = 60
        displayLink.add(to: .current, forMode: .commonModes)
    }
    
    open func refreshDate() {
        dayLabel.text = "\(calendar.component(.day, from: date))"
        monthLabel.text = calendar.standaloneMonthSymbols[calendar.component(.month, from: date) - 1]
        weekdayLabel.text = calendar.standaloneWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
        setNeedsLayout()
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        maskLayer.path = UIBezierPath(rect: bounds).cgPath
        
        let spacing : CGFloat = 5
        dayLabel.sizeToFit()
        monthLabel.sizeToFit()
        weekdayLabel.sizeToFit()
        
        let maxHeight = bounds.size.height - weekdayLabel.bounds.size.height - monthLabel.bounds.size.height - spacing * 2
        if dayLabel.bounds.size.height > maxHeight {
            dayLabel.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: maxHeight)
        }
        dayLabel.center = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
        monthLabel.center = CGPoint(x: dayLabel.center.x, y: dayLabel.frame.origin.y - monthLabel.bounds.size.height / 2 - spacing)
        weekdayLabel.center = CGPoint(x: dayLabel.center.x, y: dayLabel.frame.origin.y + dayLabel.bounds.size.height + weekdayLabel.bounds.size.height / 2 + spacing)
    }

    open func progressStepFor(translation: CGPoint) -> CGFloat {
        return (-translation.x + translation.y) * 1.5 / (bounds.size.height + bounds.size.width)
    }

    open func update(displayLink: CADisplayLink?) {
        guard let aniLayer = dummyAnimatorView.layer.presentation() else { return }
        guard lastPositionX != aniLayer.position.x else {return}
        lastPositionX = aniLayer.position.x

        let h = frame.size.height
        let w = frame.size.width
        let l = lastPositionX
        let o : CGFloat = 10
        let ratioR = (w + h) - l < o * 2 ? ((w + h) - l) / (o * 2) : min(l > h ? l - h : l, o * 2) / (o * 2)
        let ratioL = (w + h) - l < o * 2 ? ((w + h) - l) / (o * 2) : min(l > w ? l - w : l, o * 2) / (o * 2)

        delegate.datePageView(pageView: self, didAnimateToProgress: l / (h + w))

        let p = UIBezierPath()
        
        let lp = CGPoint(x: l <= w ? w - l : -o * ratioL, y: max(l - w, 0))
        let rp = CGPoint(x: min(w , w - (l - h)), y: l <= h ? l : h + o * ratioR)
        let rp2 = CGPoint(x: rp.x, y: l)
        let lp2 = CGPoint(x: w - l, y: lp.y)

        let cp = CGPoint(x: lp2.x + o * (w + h - l < o * 2 ? ratioL : 1), y: rp2.y - o * (w + h - l < o * 2 ? ratioR : 1))
        
        p.move(to: lp)
        p.addLine(to: rp)
        if rp != rp2 {
            // rp > rp2
            p.addQuadCurve(to: CGPoint(x: rp2.x - o * ratioR,y: rp2.y), controlPoint: CGPoint(x: rp.x + o * ratioR, y: rp.y + o * ratioR))
        }

        if rp != rp2 {
            // rp2 > cp
            p.addLine(to: cp)
        } else {
            // rp > cp
            let t = min(1,(h - l) / (o * 2))
            p.addQuadCurve(to: cp, controlPoint: CGPoint(x: rp.x - o * t, y: rp.y - o * t))
        }

        if lp == lp2 {
            //cp > lp
            let t = min(1,(w - l) / (o * 2))
            p.addQuadCurve(to: lp, controlPoint: CGPoint(x: lp.x + o * t, y: lp.y + o * t))
        } else {
            // cp > lp2
            p.addLine(to: CGPoint(x: lp2.x,y: lp2.y + o * ratioL))
            // lp2 > lp
            p.addQuadCurve(to: lp, controlPoint: CGPoint(x: lp.x - o * ratioL, y: lp.y - o * ratioL))
        }
        p.close()
        shapeLayer.path = l <= o * 2 ? nil : p.cgPath
        shapeLayer.shadowPath = shapeLayer.path

        //Mask
        let mrp = CGPoint(x: w - max(l - h , 0), y: h)
        let mlp = CGPoint(x: 0, y: max(l - w , 0))
        let maskP = UIBezierPath()
        maskP.move(to: lp)
        maskP.addLine(to: rp)
        maskP.addLine(to: mrp)
        maskP.addLine(to: CGPoint(x: 0, y: h))
        maskP.addLine(to: mlp)
        maskP.close()
        maskLayer.path = maskP.cgPath
        contentView.layer.mask = maskLayer
    }
    
    open func rotateToProgress( progress : CGFloat) {
        if progress == 0 {
            rotateView.layer.transform = CATransform3DIdentity
            rotateView.center = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
        } else {
            let v = 1.0 - progress
            rotateView.layer.transform = CATransform3DScale(CATransform3DMakeRotation(CGFloat.pi * v, 0, 1, 0), 1 + 0.6 * v, 1 + 0.6 * v, 1 + 0.6 * v)
            rotateView.center = CGPoint(x: bounds.size.width / 2 + bounds.width * 0.5 * max(0, v - 0.5), y: bounds.size.height / 2 - bounds.height * 0.5 * max(0, v - 0.5))
        }
    }

    private(set) var isBounceAnimationPlaying = false
    open func startBounceAnimation() {
        isBounceAnimationPlaying = true
        let a = UIViewPropertyAnimator(duration: 0.7, dampingRatio: 0.25) {
            self.rotateView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        a.addCompletion{ p in
            self.isBounceAnimationPlaying = false 
        }
        a.startAnimation()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension CGPoint {
    enum Direction {
        case topLeft
        case topRight
        case bottomRight
        case bottomLeft
        case none
    }
    
    var direction : Direction {
        if x == 0 && y == 0 {
            return .none
        } else if x <= 0 && y <= 0 {
            return .topLeft
        } else if x >= 0 && y <= 0 {
            return .topRight
        } else if x >= 0 && y >= 0 {
            return .bottomRight
        } else {
            return .bottomLeft
        }
    }
}
