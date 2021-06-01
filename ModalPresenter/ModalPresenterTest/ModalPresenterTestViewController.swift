//
//
//  Workspace: ModalPresenter
//  MacOS Version: 11.4
//			
//  File Name: ModalPresenterTestViewController.swift
//  Creation: 6/1/21 4:04 PM
//
//  Author: Dragos-Costin Mandu
//
//


import UIKit
import ModalPresenter

class ModalPresenterTestViewController: UIViewController
{
    private let m_ModalPresenter: ModalPresenter = .init(isTransitionWithOpacity: false)
    private let m_ModalContent: UIViewController = .init()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        addPresentingButtons()
        
        m_ModalContent.view.backgroundColor = .red
        m_ModalContent.view.frame.size = CGSize(width: 300, height: 200)
        m_ModalContent.view.center.x = UIScreen.main.bounds.midX
        m_ModalContent.view.center.y = 200
        m_ModalContent.view.layer.cornerRadius = 16
        m_ModalContent.view.layer.cornerCurve = .continuous
    }
    
    private func addPresentingButtons()
    {
        let presentLeadingBtn = UIButton()
        
        presentLeadingBtn.setTitle("Present Leading", for: .normal)
        presentLeadingBtn.setTitleColor(.blue, for: .normal)
        presentLeadingBtn.addTarget(self, action: #selector(didPresentLeading), for: .touchUpInside)
        presentLeadingBtn.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(presentLeadingBtn)
        
        NSLayoutConstraint.activate(
            [
                presentLeadingBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                presentLeadingBtn.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ]
        )
        
        let presentTrailingBtn = UIButton()
        
        presentTrailingBtn.setTitle("Present Trailing", for: .normal)
        presentTrailingBtn.setTitleColor(.blue, for: .normal)
        presentTrailingBtn.addTarget(self, action: #selector(didPresentTrailing), for: .touchUpInside)
        presentTrailingBtn.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(presentTrailingBtn)
        
        NSLayoutConstraint.activate(
            [
                presentTrailingBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                presentTrailingBtn.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 120)
            ]
        )
        
        let presentTopBtn = UIButton()
        
        presentTopBtn.setTitle("Present Top", for: .normal)
        presentTopBtn.setTitleColor(.blue, for: .normal)
        presentTopBtn.addTarget(self, action: #selector(didPresentTop), for: .touchUpInside)
        presentTopBtn.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(presentTopBtn)
        
        NSLayoutConstraint.activate(
            [
                presentTopBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                presentTopBtn.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 240)
            ]
        )
        
        let prsentBottomBtn = UIButton()
        
        prsentBottomBtn.setTitle("Present Bottom", for: .normal)
        prsentBottomBtn.setTitleColor(.blue, for: .normal)
        prsentBottomBtn.addTarget(self, action: #selector(didPresentBottom), for: .touchUpInside)
        prsentBottomBtn.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(prsentBottomBtn)
        
        NSLayoutConstraint.activate(
            [
                prsentBottomBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                prsentBottomBtn.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 360)
            ]
        )
    }
    
    @objc private func didPresentLeading()
    {
        if !m_ModalPresenter.isPresented
        {
            m_ModalPresenter.present(contentController: m_ModalContent, presenterController: self, startEdge: .k_Leading)
            {
                print("Presented")
            }
        }
        else
        {
            m_ModalPresenter.dismiss
            {
                print("Dismissed")
            }
        }
    }
    
    @objc private func didPresentTrailing()
    {
        if !m_ModalPresenter.isPresented
        {
            m_ModalPresenter.present(contentController: m_ModalContent, presenterController: self, startEdge: .k_Trailing)
            {
                print("Presented")
            }
        }
        else
        {
            m_ModalPresenter.dismiss
            {
                print("Dismissed")
            }
        }
    }
    
    @objc private func didPresentTop()
    {
        if !m_ModalPresenter.isPresented
        {
            m_ModalPresenter.present(contentController: m_ModalContent, presenterController: self, startEdge: .k_Top)
            {
                print("Presented")
            }
        }
        else
        {
            m_ModalPresenter.dismiss
            {
                print("Dismissed")
            }
        }
    }
    
    @objc private func didPresentBottom()
    {
        if !m_ModalPresenter.isPresented
        {
            m_ModalPresenter.present(contentController: m_ModalContent, presenterController: self, startEdge: .k_Bottom)
            {
                print("Presented")
            }
        }
        else
        {
            m_ModalPresenter.dismiss
            {
                print("Dismissed")
            }
        }
    }
}

