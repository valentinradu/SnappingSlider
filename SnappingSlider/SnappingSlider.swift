//
//  Created by Rehat Kathuria
//  www.kthr.co
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

public protocol SnappingSliderDelegate: class {
    func snappingSliderDidIncrementValue(_ slider:SnappingSlider)
    func snappingSliderDidDecrementValue(_ slider:SnappingSlider)
}

open class SnappingSlider: UIView {

    final public weak var delegate:SnappingSliderDelegate? {
        didSet {
            plusButton.addTarget(self, action: #selector(inc), for: .touchUpInside)
            minusButton.addTarget(self, action: #selector(dec), for: .touchUpInside)
        }
    }
    @objc dynamic public var shouldContinueAlteringValueUntilGestureCancels:Bool = true
    @objc dynamic public var incrementAndDecrementLabelFont:UIFont = UIFont(name: "TrebuchetMS-Bold", size: 18.0)! { didSet { setNeedsLayout() } }
    @objc dynamic public var incrementAndDecrementLabelTextColor:UIColor = UIColor.white { didSet { setNeedsLayout() } }
    @objc dynamic public var incrementAndDecrementBackgroundColor:UIColor = UIColor(red:0.36, green:0.65, blue:0.65, alpha:1) { didSet { setNeedsLayout() } }
    @objc dynamic public var sliderColor:UIColor = UIColor(red:0.42, green:0.76, blue:0.74, alpha:1) { didSet { setNeedsLayout() } }
    @objc dynamic public var sliderWidthRatio:CGFloat = 0.5 { didSet { setNeedsLayout() } }
    @objc dynamic public var sliderTitleFont:UIFont = UIFont(name: "TrebuchetMS-Bold", size: 15.0)! { didSet { setNeedsLayout() } }
    @objc dynamic public var sliderTitleColor:UIColor = UIColor.white { didSet { setNeedsLayout() } }
    @objc dynamic public var sliderTitleColorAtop:UIColor = UIColor(red:0.36, green:0.65, blue:0.65, alpha:1)
    @objc dynamic public var sliderTitleText:String = "Slide Me" { didSet { updateText() } }
    @objc dynamic public var sliderTitleAttributedText:NSAttributedString? { didSet { updateText() } }
    @objc dynamic public var sliderCornerRadius:CGFloat = 3.0 { didSet { setNeedsLayout() } }
    @objc dynamic public var shouldKeepTitleAtop:Bool = true

    final fileprivate let sliderContainer = UIView(frame: CGRect.zero)
    final fileprivate let minusButton = UIButton(frame: CGRect.zero)
    final fileprivate let plusButton = UIButton(frame: CGRect.zero)
    final fileprivate let sliderView = UIView(frame: CGRect.zero)
    final fileprivate let sliderViewLabel = UILabel(frame: CGRect.zero)
    
    final fileprivate var isCurrentDraggingSlider = false
    final fileprivate var lastDelegateFireOffset = CGFloat(0)
    final fileprivate var touchesBeganPoint = CGPoint.zero
    final fileprivate var valueChangingTimer:Timer?
    
    final fileprivate let sliderPanGestureRecogniser = UIPanGestureRecognizer()
    final fileprivate let dynamicButtonAnimator = UIDynamicAnimator()
    final fileprivate var snappingSliderBehavior:SliderSnappingBehavior?
    final fileprivate var snappingLabelBehavior:SliderSnappingBehavior?

    public init(frame:CGRect, title:String) {

        super.init(frame: frame)

        sliderTitleText = title
        setup()
        setNeedsLayout()
    }
    
    required public init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
        setup()
        setNeedsLayout()
    }
    
    fileprivate func setup() {
        
        sliderContainer.backgroundColor = backgroundColor
        
        minusButton.setTitle("-", for: .normal)
        minusButton.titleLabel?.textAlignment = NSTextAlignment.center
        sliderContainer.addSubview(minusButton)
        
        plusButton.setTitle("+", for: .normal)
        plusButton.titleLabel?.textAlignment = NSTextAlignment.center
        sliderContainer.addSubview(plusButton)
        
        sliderContainer.addSubview(sliderView)
        
        sliderViewLabel.isUserInteractionEnabled = false
        sliderViewLabel.textAlignment = NSTextAlignment.center
        sliderViewLabel.textColor = sliderTitleColor
        
        sliderPanGestureRecogniser.addTarget(self, action: #selector(type(of: self).handleGesture(_:)))
        sliderView.addGestureRecognizer(sliderPanGestureRecogniser)
        
        sliderContainer.center = CGPoint(x: bounds.size.width * 0.5, y: bounds.size.height * 0.5)
        sliderContainer.clipsToBounds = true
        addSubview(sliderContainer)
        
        if shouldKeepTitleAtop {
            addSubview(sliderViewLabel)
        }
        else {
            sliderView.addSubview(sliderViewLabel)
        }
    }
    
    override open func layoutSubviews() {
        
        super.layoutSubviews()
        
        if snappingSliderBehavior?.snappingPoint.x != center.x {
            snappingSliderBehavior = SliderSnappingBehavior(item: sliderView,
                                                            snapToPoint: CGPoint(x: bounds.size.width * 0.5, y: bounds.size.height * 0.5),
                                                            damping:0.25)
            lastDelegateFireOffset = sliderView.center.x
        }
        
        sliderContainer.frame = frame
        sliderContainer.center = CGPoint(x: bounds.size.width * 0.5, y: bounds.size.height * 0.5)
        sliderContainer.backgroundColor = incrementAndDecrementBackgroundColor

        minusButton.frame = CGRect(x: 0.0, y: 0.0, width: bounds.size.width * sliderWidthRatio * 0.5, height: bounds.size.height)
        minusButton.center = CGPoint(x: minusButton.bounds.size.width * 0.5, y: bounds.size.height * 0.5)
        minusButton.backgroundColor = incrementAndDecrementBackgroundColor
        minusButton.titleLabel?.font = incrementAndDecrementLabelFont
        minusButton.titleLabel?.textColor = incrementAndDecrementLabelTextColor
        
        plusButton.frame = CGRect(x: 0.0, y: 0.0, width: bounds.size.width * sliderWidthRatio * 0.5, height: bounds.size.height)
        plusButton.center = CGPoint(x: bounds.size.width - plusButton.bounds.size.width * 0.5, y: bounds.size.height * 0.5)
        plusButton.backgroundColor = incrementAndDecrementBackgroundColor
        plusButton.titleLabel?.font = incrementAndDecrementLabelFont
        plusButton.titleLabel?.textColor = incrementAndDecrementLabelTextColor
        
        sliderView.frame = CGRect(x: 0.0, y: 0.0, width: bounds.size.width * sliderWidthRatio, height: bounds.size.height)
        sliderView.center = CGPoint(x: bounds.size.width * 0.5, y: bounds.size.height * 0.5)
        sliderView.backgroundColor = sliderColor
        
        sliderViewLabel.frame.size = sliderView.frame.size
        sliderViewLabel.center = sliderViewLabel.superview!.convert(sliderView.center, from: sliderView.superview)
        sliderViewLabel.font = sliderTitleFont
        
        sliderContainer.layer.cornerRadius = sliderCornerRadius
        sliderView.layer.cornerRadius = sliderCornerRadius
        
        if snappingLabelBehavior == nil && shouldKeepTitleAtop {
            let point = CGPoint(x: bounds.size.width * 0.5,
                                y: bounds.size.height * 0.5)
            snappingLabelBehavior = SliderSnappingBehavior(item: sliderViewLabel,
                                                           snapToPoint: point,
                                                           damping:0.8)
            dynamicButtonAnimator.addBehavior(snappingLabelBehavior!)
        }
        
        updateText()
    }
    
    // MARK: Gesture & Timer Handling
    
    @objc final func handleGesture(_ sender: UIGestureRecognizer) {

        guard let snapSliderBehavior = snappingSliderBehavior else { return }

        if sender as NSObject == sliderPanGestureRecogniser {
        
            switch sender.state {
             
            case .began:
                
                isCurrentDraggingSlider = true
                touchesBeganPoint = sliderPanGestureRecogniser.translation(in: sliderView)
                dynamicButtonAnimator.removeBehavior(snapSliderBehavior)
                lastDelegateFireOffset = (bounds.size.width * 0.5) + ((touchesBeganPoint.x + touchesBeganPoint.x) * 0.40)
                
                if shouldKeepTitleAtop {
                    UIView.transition(with: self.sliderViewLabel,
                                      duration: 0.3,
                                      options: .transitionCrossDissolve,
                                      animations: {
                                        self.sliderViewLabel.textColor = self.sliderTitleColorAtop
                    }, completion: nil)
                    if let s = snappingLabelBehavior {
                        let point = CGPoint(x: bounds.size.width * 0.5,
                                            y: -bounds.size.height * 0.5)
                        s.snappingPoint = point
                    }
                }
                
            case .changed:
                
                valueChangingTimer?.invalidate()
                
                let translationInView = sliderPanGestureRecogniser.translation(in: sliderView)
                let translatedCenterX:CGFloat = (bounds.size.width * 0.5) + ((touchesBeganPoint.x + translationInView.x) * 0.40)
                sliderView.center = CGPoint(x: translatedCenterX, y: sliderView.center.y);
                
                if (translatedCenterX < lastDelegateFireOffset) {
                    
                    if (fabs(lastDelegateFireOffset - translatedCenterX) >= (sliderView.bounds.size.width * 0.15)) {
                        
                        delegate?.snappingSliderDidDecrementValue(self)
                        lastDelegateFireOffset = translatedCenterX
                    }
                }
                else {
                    
                    if (fabs(lastDelegateFireOffset - translatedCenterX) >= (sliderView.bounds.size.width * 0.15)) {
                        
                        delegate?.snappingSliderDidIncrementValue(self)
                        lastDelegateFireOffset = translatedCenterX
                    }
                }
                
                if shouldContinueAlteringValueUntilGestureCancels {
                    let ratio = abs(sliderView.center.x - bounds.width / 2) / ((bounds.width - sliderView.bounds.width) / 2)
                    let time = 0.05 + 0.5 * (1.0 - ratio)
                    valueChangingTimer = Timer.scheduledTimer(timeInterval: Double(time),
                                                              target: self,
                                                              selector: #selector(handleTimer),
                                                              userInfo: nil,
                                                              repeats: true)
                }
                
                if shouldKeepTitleAtop {
                    if let s = snappingLabelBehavior {
                        let point = CGPoint(x: translatedCenterX,
                                            y: -bounds.size.height * 0.5)
                        s.snappingPoint = point
                    }
                }
                
            case .ended:

                fallthrough
                
            case .failed:

                fallthrough

            case .cancelled:
                
                dynamicButtonAnimator.addBehavior(snapSliderBehavior)
                isCurrentDraggingSlider = false
                lastDelegateFireOffset = center.x
                valueChangingTimer?.invalidate()
                
                if shouldKeepTitleAtop {
                    UIView.transition(with: self.sliderViewLabel,
                                      duration: 0.3,
                                      options: .transitionCrossDissolve,
                                      animations: {
                        self.sliderViewLabel.textColor = self.sliderTitleColor
                    }, completion: nil)
                    if let s = snappingLabelBehavior {
                        let point = CGPoint(x: bounds.size.width * 0.5,
                                            y: bounds.size.height * 0.5)
                        s.snappingPoint = point
                    }
                }
                
            case .possible:

                // Swift requires at least one statement per case
                _ = 0
            }
        }
    }
    
    @objc final func handleTimer(_ sender: Timer) {
        if sliderView.frame.midX > self.bounds.midX {
            delegate?.snappingSliderDidIncrementValue(self)
        }
        else {
            delegate?.snappingSliderDidDecrementValue(self)
        }
    }

    //MARK: - Text update
    private func updateText() {
        if let attributedText = sliderTitleAttributedText {
            sliderViewLabel.attributedText = attributedText
        }
        else {
            sliderViewLabel.text = sliderTitleText
        }
    }
    
    //MARK: - Inc and dec forwarders
    @objc private func inc() {
        delegate?.snappingSliderDidIncrementValue(self)
    }
    @objc private func dec() {
        delegate?.snappingSliderDidDecrementValue(self)
    }
}

final class SliderSnappingBehavior: UIDynamicBehavior {
    var snappingPoint:CGPoint {
        didSet {
            snapBehavior.snapPoint = snappingPoint
        }
    }
    let dynamicItemBehavior:UIDynamicItemBehavior
    let snapBehavior:UISnapBehavior
    init(item: UIDynamicItem, snapToPoint point: CGPoint, damping: CGFloat) {
    
        dynamicItemBehavior = UIDynamicItemBehavior(items: [item])
        dynamicItemBehavior.allowsRotation = false
        
        snapBehavior = UISnapBehavior(item: item, snapTo: point)
        snapBehavior.damping = damping
        
        snappingPoint = point
        
        super.init()
        
        addChildBehavior(dynamicItemBehavior)
        addChildBehavior(snapBehavior)
    }
}
