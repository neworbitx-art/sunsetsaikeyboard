import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {

    private var hostingController: UIHostingController<KeyboardRootView>?
    private var heightConstraint: NSLayoutConstraint?
    private var reloadCount: Int = 0

    private static let keyboardHeight: CGFloat = 320

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadCount += 1
        updateRootView()
    }

    private func makeRootView() -> KeyboardRootView {
        KeyboardRootView(
            onInsertText: { [weak self] text in
                self?.textDocumentProxy.insertText(text)
            },
            onAdvanceToNextKeyboard: { [weak self] in
                self?.advanceToNextInputMode()
            },
            needsInputModeSwitchKey: needsInputModeSwitchKey,
            reloadTrigger: reloadCount
        )
    }

    private func updateRootView() {
        hostingController?.rootView = makeRootView()
    }

    private func setupKeyboardUI() {
        let hc = UIHostingController(rootView: makeRootView())
        addChild(hc)

        hc.view.translatesAutoresizingMaskIntoConstraints = false
        hc.view.backgroundColor = .clear
        view.addSubview(hc.view)

        let height = NSLayoutConstraint(
            item: hc.view!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: Self.keyboardHeight
        )
        height.priority = .required
        hc.view.addConstraint(height)
        heightConstraint = height

        NSLayoutConstraint.activate([
            hc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hc.view.topAnchor.constraint(equalTo: view.topAnchor),
            hc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        hc.didMove(toParent: self)
        hostingController = hc
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Update needsInputModeSwitchKey without incrementing reloadCount
        updateRootView()
    }

    override func textWillChange(_ textInput: UITextInput?) {}
    override func textDidChange(_ textInput: UITextInput?) {}
}
