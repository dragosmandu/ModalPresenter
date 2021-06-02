//
//
//  Workspace: ModalPresenter
//  MacOS Version: 11.4
//			
//  File Name: ModalPresenter.swift
//  Creation: 6/1/21 4:05 PM
//
//  Author: Dragos-Costin Mandu
//
//


import UIKit
import os

public class ModalPresenter: NSObject
{
    // MARK: - Initialization
    
    public static let s_SharedInstance: ModalPresenter = .init()
    
    public static var s_LoggerSubsystem: String = Bundle.main.bundleIdentifier!
    public static var s_LoggerCategory: String = "ModalPresenterViewController"
    public static var s_Logger: Logger = .init(subsystem: s_LoggerSubsystem, category: s_LoggerCategory)
    public static var s_AnimationDuration: TimeInterval = 0.3
    public static var s_AnimationDelay: TimeInterval = 0
    public static var s_AnimationOptions: UIView.AnimationOptions = .curveEaseOut
    public static var s_DismissGestureName: String = "DismissGestureName"
    
    /// If true, the modal content will be presented/dismissed with opacity transition.
    public var isTransitionWithOpacity: Bool
    public var isGestureDismissable: Bool
    
    public private(set) var isPresented: Bool = false
    
    private var m_ContentController: UIViewController? = nil
    private var m_PresenterController: UIViewController? = nil
    private var m_StartEdge: ModalPresenterStartEdge? = nil
    private var m_OrigCenterPoint: CGPoint? = nil
    
    /// The center point of the content controller when a dismiss gesture was recognized.
    private var m_DismissCenterStart: CGPoint? = nil
    
    /// The maximum drag for a dismiss gesture on the oposite side of the corect dismiss drag.
    private var m_DismissMaxOpositeDrag: CGFloat
    {
        guard let presenterController = m_PresenterController, let dismissCenterStart = m_DismissCenterStart else { return 0 }
        let ratio: CGFloat = 0.05
        
        switch m_StartEdge
        {
            case .k_Leading, .k_Trailing:
                let maxOpositeDrag = presenterController.view.frame.width * ratio
                
                if m_StartEdge == .k_Leading
                {
                    return dismissCenterStart.x + maxOpositeDrag
                }
                else
                {
                    return dismissCenterStart.x - maxOpositeDrag
                }
                
            default:
                let maxOpositeDrag = presenterController.view.frame.height * ratio
                
                if m_StartEdge == .k_Top
                {
                    return dismissCenterStart.y + maxOpositeDrag
                }
                else
                {
                    return dismissCenterStart.y - maxOpositeDrag
                }
        }
    }
    
    /// The minimum translation in the correct dismiss direction in order to dismiss the modal.
    private var m_MinTranslationToDismiss: CGFloat
    {
        guard let contentController = m_ContentController else { return 0 }
        let ratio: CGFloat = 0.33
        
        switch m_StartEdge
        {
            case .k_Leading:
                return -contentController.view.frame.size.width * ratio
                
            case .k_Trailing:
                return contentController.view.frame.size.width * ratio
                
            case .k_Top:
                return -contentController.view.frame.size.height * ratio
                
            default:
                return contentController.view.frame.size.height * ratio
        }
    }
    
    
    /// - Parameter isTransitionWithOpacity: If true, the modal content will be presented/dismissed with opacity transition.
    public init(isTransitionWithOpacity: Bool = false, isGestureDismissable: Bool = true)
    {
        self.isTransitionWithOpacity = isTransitionWithOpacity
        self.isGestureDismissable = isGestureDismissable
    }
}

public extension ModalPresenter
{
    
    /// Presents the given contentController modally from current controller.
    /// - Parameters:
    ///   - contentController: Modal to present.
    ///   - presenterController: The controller that presents the modal content.
    ///   - startEdge: The edge the modal will be presented from.
    ///   - completion: Called when the modal has been presented.
    func present(contentController: UIViewController, presenterController: UIViewController, startEdge: ModalPresenterStartEdge, _ completion: (() -> Void)? = nil)
    {
        if !isPresented
        {
            ModalPresenter.s_Logger.debug("Presenting modal controller.")
            
            DispatchQueue.main.async
            { [weak self] in
                guard let `self` = self
                else
                {
                    ModalPresenter.s_Logger.error("Invalid nil object. Modal presenter has been released.")
                    completion?()
                    
                    return
                }
                
                self.m_ContentController = contentController
                self.m_PresenterController = presenterController
                self.m_StartEdge = startEdge
                self.m_OrigCenterPoint = contentController.view.center
                
                if self.isGestureDismissable
                {
                    self.addDismissGesture() // Enabled modals to be dismissed with drag gesture.
                }
                
                guard let startCenterPoint = self.getStartCenterPoint()
                else
                {
                    ModalPresenter.s_Logger.error("Failed to get the start center point.")
                    completion?()
                    
                    return
                }
                
                self.m_ContentController!.view.center = startCenterPoint
                self.m_ContentController!.view.layer.opacity = self.isTransitionWithOpacity ? 0 : 1
                self.m_ContentController!.willMove(toParent: self.m_PresenterController!)
                self.m_PresenterController!.addChild(self.m_ContentController!)
                self.m_PresenterController!.view.addSubview(self.m_ContentController!.view)
                
                self.animateWith
                {
                    self.m_ContentController!.view.center = self.m_OrigCenterPoint!
                    self.m_ContentController!.view.layer.opacity = 1
                } completion:
                { finished in
                    if !finished
                    {
                        self.m_ContentController!.view.center = self.m_OrigCenterPoint!
                        self.m_ContentController!.view.layer.opacity = 1
                    }
                    
                    self.isPresented = true
                    completion?()
                }
            }
        }
        else
        {
            dismiss
            { [weak self] in
                self?.present(contentController: contentController, presenterController: presenterController, startEdge: startEdge, completion)
            }
        }
    }
    
    /// Dismisses the latest presented modal controller, if any.
    /// - Parameters:
    ///   - completion: Called when the modal has been dismissed.
    func dismiss(_ completion: (() -> Void)? = nil)
    {
        if isPresented
        {
            ModalPresenter.s_Logger.debug("Dismissing modal controller.")
            
            DispatchQueue.main.async
            { [weak self] in
                guard let `self` = self
                else
                {
                    ModalPresenter.s_Logger.error("Invalid nil object. Modal presenter has been released.")
                    completion?()
                    
                    return
                }
                
                guard let contentController = self.m_ContentController, let origCenterPoint = self.m_OrigCenterPoint, let startCenterPoint = self.getStartCenterPoint()
                else
                {
                    ModalPresenter.s_Logger.error("Invalid nil objects.")
                    completion?()
                    
                    return
                }
                
                self.animateWith
                {
                    contentController.view.center = startCenterPoint
                    contentController.view.layer.opacity = self.isTransitionWithOpacity ? 0 : 1
                } completion:
                { finished in
                    if !finished
                    {
                        contentController.view.center = startCenterPoint
                        contentController.view.layer.opacity = 0
                    }
                    
                    // Resets the center as the original.
                    contentController.view.center = origCenterPoint
                    contentController.willMove(toParent: nil)
                    contentController.view.removeFromSuperview()
                    contentController.removeFromParent()
                    
                    self.reset()
                    completion?()
                }
            }
        }
        else
        {
            ModalPresenter.s_Logger.debug("Modal controller is already dismissed.")
            completion?()
        }
    }
}

private extension ModalPresenter
{
    func addDismissGesture()
    {
        let dismissGesture = UIPanGestureRecognizer(target: self, action: #selector(didDismiss))
        
        dismissGesture.maximumNumberOfTouches = 1
        dismissGesture.minimumNumberOfTouches = 1
        dismissGesture.name = ModalPresenter.s_DismissGestureName
        
        m_ContentController?.view.addGestureRecognizer(dismissGesture)
    }
    
    func reset()
    {
        self.m_ContentController = nil
        self.m_PresenterController = nil
        self.m_StartEdge = nil
        self.m_OrigCenterPoint = nil
        self.isPresented = false
    }
    
    /// Calculates the center point where the modal content is offscreen.
    func getStartCenterPoint() -> CGPoint?
    {
        guard let contentControllerView = m_ContentController?.view , let presenterController = m_PresenterController
        else
        {
            ModalPresenter.s_Logger.debug("Invalid nil content/presenter controller.")
            
            return nil
        }
        let extraSafeOffset: CGFloat = 5
        let contentControllerFrame = contentControllerView.frame
        var startCenterPoint = contentControllerView.center
        
        switch m_StartEdge
        {
            case .k_Leading:
                startCenterPoint.x -= (contentControllerFrame.maxX + extraSafeOffset)
                
            case .k_Trailing:
                startCenterPoint.x += (presenterController.view.frame.width - contentControllerFrame.minX + extraSafeOffset)
                
            case .k_Top:
                startCenterPoint.y -= (contentControllerFrame.maxY + extraSafeOffset)
                
            default:
                startCenterPoint.y += (presenterController.view.frame.height - contentControllerFrame.minY + extraSafeOffset)
        }
        
        return startCenterPoint
    }
    
    func animateWith(_ animations: @escaping () -> Void, completion: @escaping (_ finished: Bool) -> Void)
    {
        UIView.animate(
            withDuration: ModalPresenter.s_AnimationDuration,
            delay: ModalPresenter.s_AnimationDelay,
            options: ModalPresenter.s_AnimationOptions
        ) { animations() } completion: { finished in completion(finished) }
    }
    
    func moveModalWith(translation: CGPoint)
    {
        guard let contentController = m_ContentController, let dismissCenterStart = m_DismissCenterStart else { return }
        
        switch m_StartEdge
        {
            case .k_Leading, .k_Trailing:
                let newCenterX = dismissCenterStart.x + translation.x
                
                if m_StartEdge == .k_Leading && newCenterX <= m_DismissMaxOpositeDrag
                {
                    contentController.view.center.x = newCenterX
                }
                else if m_StartEdge == .k_Trailing && newCenterX >= m_DismissMaxOpositeDrag
                {
                    contentController.view.center.x = newCenterX
                }
                
            default:
                let newCenterY = dismissCenterStart.y + translation.y
                
                if m_StartEdge == .k_Top && newCenterY <= m_DismissMaxOpositeDrag
                {
                    contentController.view.center.y = newCenterY
                }
                else if m_StartEdge == .k_Bottom && newCenterY >= m_DismissMaxOpositeDrag
                {
                    contentController.view.center.y = newCenterY
                }
        }
    }
    
    func onDismissGestureEndedWith(translation: CGPoint)
    {
        guard let contentController = m_ContentController, let dismissCenterStart = m_DismissCenterStart else { return }
        
        switch m_StartEdge
        {
            case .k_Leading:
                if translation.x > m_MinTranslationToDismiss
                {
                    animateWith
                    {
                        contentController.view.center = dismissCenterStart
                    } completion:
                    { finished in
                        if !finished
                        {
                            contentController.view.center = dismissCenterStart
                        }
                    }
                }
                else
                {
                    dismiss()
                }
                
            case .k_Trailing:
                if translation.x < m_MinTranslationToDismiss
                {
                    animateWith
                    {
                        contentController.view.center = dismissCenterStart
                    } completion:
                    { finished in
                        if !finished
                        {
                            contentController.view.center = dismissCenterStart
                        }
                    }
                }
                else
                {
                    dismiss()
                }
                
            case .k_Top:
                if translation.y > m_MinTranslationToDismiss
                {
                    animateWith
                    {
                        contentController.view.center = dismissCenterStart
                    } completion:
                    { finished in
                        if !finished
                        {
                            contentController.view.center = dismissCenterStart
                        }
                    }
                }
                else
                {
                    dismiss()
                }
                
            default:
                if translation.y < m_MinTranslationToDismiss
                {
                    animateWith
                    {
                        contentController.view.center = dismissCenterStart
                    } completion:
                    { finished in
                        if !finished
                        {
                            contentController.view.center = dismissCenterStart
                        }
                    }
                }
                else
                {
                    dismiss()
                }
        }
    }
    
    @objc func didDismiss(_ gesture: UIPanGestureRecognizer)
    {
        guard let contentController = m_ContentController, let presenterController = m_PresenterController else { return }
        
        if gesture.state == .began
        {
            let translation = gesture.translation(in: presenterController.view)
            m_DismissCenterStart = contentController.view.center
            moveModalWith(translation: translation)
        }
        else if gesture.state == .changed
        {
            let translation = gesture.translation(in: presenterController.view)
            moveModalWith(translation: translation)
        }
        else if gesture.state == .ended
        {
            let translation = gesture.translation(in: presenterController.view)
            onDismissGestureEndedWith(translation: translation)
        }
    }
}
