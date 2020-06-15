// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared
import Lottie

class InstallVPNViewController: UIViewController {
    
    private var installVPNView: View {
        return view as! View // swiftlint:disable:this force_cast
    }
    
    override func loadView() {
        view = View()
    }
    
    @objc func dismissView() {
        dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.VPN.installTitle
        installVPNView.installVPNButton.addTarget(self, action: #selector(installVPNAction), for: .touchUpInside)
        navigationItem.setRightBarButton(.init(barButtonSystemItem: .cancel, target: self, action: #selector(dismissView)), animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // For some reason setting `barTintColor` for `formSheet` type of modal doesn't work
        // in `viewDidLoad` method, doing it later to prevent that.
        styleNavigationBar()
    }
    
    private func styleNavigationBar() {
        navigationController?.navigationBar.do {
            $0.tintColor = .white
            $0.barTintColor = BraveVPNCommonUI.UX.purpleBackgroundColor
            $0.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        }
    }
    
    @objc func installVPNAction() {
        installVPNView.installVPNButton.isLoading = true
        
        BraveVPN.connectOrMigrateToNewNode() { [weak self] status in
            DispatchQueue.main.async {
                self?.installVPNView.installVPNButton.isLoading = false
            }
            
            switch status {
            case .success:
                self?.dismiss(animated: true) {
                    self?.showSuccessAlert()
                }
            case .error(let type):
                let alert = { () -> UIAlertController in
                    let okAction = UIAlertAction(title: Strings.OKString, style: .default)
                    
                    switch type {
                    case .permissionDenied:
                        let message = "\(Strings.VPN.vpnConfigPermissionDeniedErrorBody)(\(type.rawValue))"
                        
                        let alert = UIAlertController(title: Strings.VPN.vpnConfigPermissionDeniedErrorTitle,
                                                      message: message, preferredStyle: .alert)
                        alert.addAction(okAction)
                        return alert
                    case .loadConfigError, .saveConfigError:
                        let message = "\(Strings.VPN.vpnConfigGenericErrorBody)(\(type.rawValue))"
                        let alert = UIAlertController(title: Strings.VPN.vpnConfigGenericErrorTitle,
                                                      message: message,
                                                      preferredStyle: .alert)
                        alert.addAction(okAction)
                        return alert
                    }
                }()
                
                DispatchQueue.main.async {
                    self?.present(alert, animated: true)
                }
            }
        }
    }
    
    private func showSuccessAlert() {
        let animation = AnimationView(name: "vpncheckmark").then {
            $0.bounds = CGRect(x: 0, y: 0, width: 300, height: 200)
            $0.contentMode = .scaleAspectFill
            $0.play()
        }
        
        let popup = AlertPopupView(imageView: animation,
                                   title: Strings.VPN.installSuccessPopup, message: "",
                                   titleWeight: .semibold, titleSize: 18,
                                   dismissHandler: { true })
        
        popup.showWithType(showType: .flyUp)
    }
}
