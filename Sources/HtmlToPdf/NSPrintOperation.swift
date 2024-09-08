//
//  swift-html-to-pdf | macOS.swift
//
//
//  Created by Coen ten Thije Boonkkamp on 15/07/2024.
//

#if os(macOS)
import Foundation
import WebKit

extension Document {
    /// Prints a ``Document`` to PDF with the given configuration.
    ///
    /// This function is more convenient when you have a directory and just want to title the PDF and save it to the directory.
    ///
    /// ## Example
    /// ```swift
    /// try await Document.init(...)
    ///     .print(configuration: .a4)
    /// ```
    ///
    /// - Parameters:
    ///   - configuration: The configuration that the PDFs will use.
    ///   - processorCount: In allmost all circumstances you can omit this parameter.
    ///   - createDirectories: If true, the function will call FileManager.default.createDirectory for each document's directory.
    ///
    /// - Throws: `Error` if the function cannot write to the document's fileUrl.
    @MainActor
    public func print(
        configuration: PDFConfiguration,
        processorCount: Int = ProcessInfo.processInfo.activeProcessorCount,
        createDirectories: Bool = true
    ) async throws {
        try await [self].print(
            configuration: configuration,
            processorCount: processorCount,
            createDirectories: createDirectories
        )
    }
}

extension Sequence<Document> {
    /// Prints ``Document``s  to PDFs at the given directory.
    ///
    /// ## Example
    /// ```swift
    /// let htmls = [
    ///     "<html><body><h1>Hello, World 1!</h1></body></html>",
    ///     "<html><body><h1>Hello, World 1!</h1></body></html>",
    ///     ...
    /// ]
    /// try await htmls.print(to: .downloadsDirectory)
    /// ```
    ///
    /// - Parameters:
    ///   - configuration: The configuration that the PDFs will use.
    ///   - processorCount: In allmost all circumstances you can omit this parameter.
    ///   - createDirectories: If true, the function will call FileManager.default.createDirectory for each document's directory.
    ///

    public func print(
        configuration: PDFConfiguration,
        processorCount: Int = ProcessInfo.processInfo.activeProcessorCount,
        createDirectories: Bool = true
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for document in self {
                taskGroup.addTask {
                    let webView = try await WebViewPool.shared.acquireWithRetry()
                    try await document.print(
                        configuration: configuration,
                        createDirectories: createDirectories,
                        using: webView
                    )
                    await WebViewPool.shared.release(webView)
                }
                try await taskGroup.waitForAll()
            }
        }
    }
}

extension Document {
    @MainActor
    fileprivate func print(
        configuration: PDFConfiguration,
        createDirectories: Bool = true,
        using webView: WKWebView = WKWebView(frame: .zero)
    ) async throws {

        let webViewNavigationDelegate = WebViewNavigationDelegate(
            outputURL: self.fileUrl,
            configuration: configuration
        )

        if createDirectories {
            try FileManager.default.createDirectory(at: self.fileUrl.deletingPathExtension().deletingLastPathComponent(), withIntermediateDirectories: true)
        }

        webView.navigationDelegate = webViewNavigationDelegate

        await withCheckedContinuation { continuation in
            let printDelegate = PrintDelegate {
                continuation.resume()
            }
            webViewNavigationDelegate.printDelegate = printDelegate
            webView.loadHTMLString(self.html, baseURL: configuration.baseURL)
        }
    }
}


class WebViewNavigationDelegate: NSObject, WKNavigationDelegate {
    private let outputURL: URL
    var printDelegate: PrintDelegate?

    private let configuration: PDFConfiguration

    init(
        outputURL: URL,
        onFinished: (@Sendable () -> Void)? = nil,
        configuration: PDFConfiguration
    ) {
        self.outputURL = outputURL
        self.configuration = configuration
        self.printDelegate = onFinished.map(PrintDelegate.init)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor [configuration, outputURL, printDelegate] in

            webView.frame = .init(origin: .zero, size: configuration.paperSize)

            let printOperation = webView.printOperation(with: .pdf(jobSavingURL: outputURL, configuration: configuration))
            printOperation.showsPrintPanel = false
            printOperation.showsProgressPanel = false
            printOperation.canSpawnSeparateThread = true

            printOperation.runModal(
                for: webView.window ?? NSWindow(),
                delegate: printDelegate,
                didRun: #selector(PrintDelegate.printOperationDidRun(_:success:contextInfo:)),
                contextInfo: nil
            )
        }
    }
}

extension NSPrintInfo.PaperOrientation {
    init(orientation: PDFConfiguration.Orientation) {
        self = switch orientation {
        case .landscape: .landscape
        case .portrait: .portrait
        }
    }
}

class PrintDelegate: @unchecked Sendable {

    var onFinished: @Sendable () -> Void

    init(onFinished: @Sendable @escaping () -> Void) {
        self.onFinished = onFinished
    }

    @objc func printOperationDidRun(_ printOperation: NSPrintOperation, success: Bool, contextInfo: UnsafeMutableRawPointer?) {
        self.onFinished()
    }
}

extension PDFConfiguration {
    public static func a4(margins: EdgeInsets = .a4, baseURL: URL? = nil) -> PDFConfiguration {
        return .init(
            margins: margins,
            paperSize: .paperSize(),
            baseURL: baseURL
        )
    }
}

extension NSEdgeInsets {
    init(
        edgeInsets: EdgeInsets
    ) {
        self = .init(
            top: edgeInsets.top,
            left: edgeInsets.left,
            bottom: edgeInsets.bottom,
            right: edgeInsets.right
        )
    }
}

extension CGSize {
    public static func paperSize() -> CGSize {
        CGSize(width: NSPrintInfo.shared.paperSize.width, height: NSPrintInfo.shared.paperSize.height)
    }
}

extension NSPrintInfo {
    static func pdf(jobSavingURL: URL, configuration: PDFConfiguration) -> NSPrintInfo {
        return NSPrintInfo(
            dictionary: [
                .jobDisposition: NSPrintInfo.JobDisposition.save,
                .jobSavingURL: jobSavingURL,
                .allPages: true,
                .topMargin: configuration.margins.top,
                .bottomMargin: configuration.margins.bottom,
                .leftMargin: configuration.margins.left,
                .rightMargin: configuration.margins.right,
                .paperSize: configuration.paperSize,
                .verticalPagination: NSNumber(value: NSPrintInfo.PaginationMode.automatic.rawValue)
            ]
        )
    }
}

// public extension NSPrintInfo {
//    static func pdf(
//        jobSavingURL: URL,
//        configuration: PDFConfiguration
//    ) -> NSPrintInfo {
//        .pdf(
//            url: jobSavingURL,
//            paperSize: configuration.paperSize,
//            topMargin: configuration.margins.top,
//            bottomMargin: configuration.margins.bottom,
//            leftMargin: configuration.margins.left,
//            rightMargin: configuration.margins.right
//        )
//    }
//    
//    static func pdf(
//        url: URL,
//        paperSize: CGSize = NSPrintInfo.shared.paperSize,
//        topMargin: CGFloat = 36,
//        bottomMargin: CGFloat = 36,
//        leftMargin: CGFloat = 36,
//        rightMargin: CGFloat = 36
//    ) -> NSPrintInfo {
//        NSPrintInfo(
//            dictionary: [
//                .jobDisposition: NSPrintInfo.JobDisposition.save,
//                .jobSavingURL: url,
//                .allPages: true,
//                .topMargin: topMargin,
//                .bottomMargin: bottomMargin,
//                .leftMargin: leftMargin,
//                .rightMargin: rightMargin,
//                .paperSize: paperSize
//            ]
//        )
//    }
// }

#endif
