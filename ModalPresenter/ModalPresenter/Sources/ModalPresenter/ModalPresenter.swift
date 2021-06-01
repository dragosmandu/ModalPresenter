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

public class ModalPresenter
{
    // MARK: - Initialization
    
    public static let s_SharedInstance: ModalPresenter = .init()
    
    public static var s_LoggerSubsystem: String = Bundle.main.bundleIdentifier!
    public static var s_LoggerCategory: String = "ModalPresenterViewController"
    public static var s_Logger: Logger = .init(subsystem: s_LoggerSubsystem, category: s_LoggerCategory)
    public static var s_AnimationDuration: TimeInterval = 0.55
    public static var s_AnimationDelay: TimeInterval = 0
    public static var s_AnimationSpringDamping: CGFloat = 0.95
    public static var s_AnimationInitialSpringVelocity: CGFloat = 0.25
    public static var s_AnimationOptions: UIView.AnimationOptions = .curveEaseInOut
    
    /// If true, the modal content will be presented/dismissed with opacity transition.
    public var isTransitionWithOpacity: Bool
    
    public private(set) var isPresented: Bool = false
    
    private var m_ContentController: UIViewController? = nil
    private var m_PresenterController: UIViewController? = nil
    private var m_StartEdge: ModalPresenterStartEdge? = nil
    private var m_OrigCenterPoint: CGPoint? = nil
    
    
    /// - Parameter isTransitionWithOpacity: If true, the modal content will be presented/dismissed with opacity transition.
    public init(isTransitionWithOpacity: Bool = false)
    {
        self.isTransitionWithOpacity = isTransitionWithOpacity
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
        guard let contentControllerView = m_ContentController?.view
        else
        {
            ModalPresenter.s_Logger.debug("Invalid nil content controller.")
            
            return nil
        }
        let extraSafeOffset: CGFloat = 5
        let contentControllerFrame = contentControllerView.frame
        var startCenterPoint = contentControllerView.center
        
        switch self.m_StartEdge
        {
            case .k_Leading:
                startCenterPoint.x -= (contentControllerFrame.maxX + extraSafeOffset)
                
            case .k_Trailing:
                startCenterPoint.x += (contentControllerFrame.maxX + extraSafeOffset)
                
            case .k_Top:
                startCenterPoint.y -= (contentControllerFrame.maxY + extraSafeOffset)
                
            default:
                startCenterPoint.y += (UIScreen.main.bounds.height - contentControllerFrame.minY + extraSafeOffset)
        }
        
        return startCenterPoint
    }
    
    func animateWith(_ animations: @escaping () -> Void, completion: @escaping (_ finished: Bool) -> Void)
    {
        UIView.animate(
            withDuration: ModalPresenter.s_AnimationDuration,
            delay: ModalPresenter.s_AnimationDelay,
            usingSpringWithDamping: ModalPresenter.s_AnimationSpringDamping,
            initialSpringVelocity: ModalPresenter.s_AnimationInitialSpringVelocity,
            options: ModalPresenter.s_AnimationOptions
        ) { animations() } completion: { finished in completion(finished) }
    }
}

