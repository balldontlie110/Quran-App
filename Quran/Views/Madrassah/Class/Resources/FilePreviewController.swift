//
//  FilePreviewController.swift
//  Quran
//
//  Created by Ali Earp on 06/09/2024.
//

import UIKit
import WebKit
import LinkPresentation
import SwiftUI

class FilePreviewController: UIViewController, UIDocumentInteractionControllerDelegate, WKUIDelegate {
    private var activityController: UIActivityViewController?
    private var documentController: UIDocumentInteractionController?
    private var url: URL
    
    private let webView = WKWebView()
    private let navigationBar = UINavigationBar()
    private let navigationBarTitle = UINavigationItem()
    
    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        webView.uiDelegate = self
        webView.scrollView.isScrollEnabled = true
        webView.contentMode = .center

        let request = URLRequest(url: url)
        webView.load(request)

        documentController = UIDocumentInteractionController(url: url)
        documentController?.delegate = self
    }

    private func setupUI() {
        view.backgroundColor = .white
        
        navigationBar.setItems([navigationBarTitle], animated: false)
        navigationBarTitle.title = url.lastPathComponent
        view.addSubview(navigationBar)
        
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(onCloseButtonPressed))
        let moreOptionsButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(onMoreOptionButtonPressed))
        
        navigationBarTitle.leftBarButtonItem = closeButton
        navigationBarTitle.rightBarButtonItem = moreOptionsButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            
        }
    }

    @objc private func onCloseButtonPressed() {
        dismiss(animated: true)
    }
    
    @objc private func onMoreOptionButtonPressed() {
        do {
            let fileShareModel = try FileShareModel(url: url)
            print(url.lastPathComponent)

            let activityController = UIActivityViewController(activityItems: [fileShareModel], applicationActivities: nil)
            
            if let popover = activityController.popoverPresentationController {
                popover.sourceView = self.view
            }
            
            present(activityController, animated: true, completion: nil)
        } catch {
            
        }
    }
}

final class FileShareModel: NSObject, UIActivityItemSource {
    let url: URL
    let data: Data
    let title: String

    init(url: URL) throws {
        self.url = url
        self.title = url.lastPathComponent
        self.data = try Data(contentsOf: url)
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        data
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        data
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.url = url
        metadata.originalURL = url
        metadata.iconProvider = NSItemProvider(contentsOf: url)
        return metadata
    }
}

struct FilePreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> FilePreviewController {
        return FilePreviewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: FilePreviewController, context: Context) {
        
    }
}
