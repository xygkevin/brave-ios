// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared

class InstallVPNViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        installVPNView.installVPNButton.addTarget(self, action: #selector(installVPNAction), for: .touchUpInside)
        navigationItem.setRightBarButton(.init(barButtonSystemItem: .cancel, target: self, action: #selector(dismissView)), animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // For some reason setting `barTintColor` for `formSheet` type of modal doesn't work
        // in `viewDidLoad` method, doing it later to prevent that.
        styleNavigationBar()
    }
    
    private var installVPNView: View {
        return view as! View // swiftlint:disable:this force_cast
    }
    
    override func loadView() {
        view = View()
    }
    
    @objc func dismissView() {
        dismiss(animated: true)
    }

    private func styleNavigationBar() {
        title = Strings.VPN.installTitle
                        
        navigationController?.navigationBar.do {
            $0.tintColor = .white
            $0.barTintColor = View.UX.backgroundColor
            $0.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        }
    }
    
    @objc func installVPNAction() {
        installVPNView.installVPNButton.isLoading = true
        
        BraveVPN.createVPNConfiguration() { [weak self] status in
            DispatchQueue.main.async {
                self?.installVPNView.installVPNButton.isLoading = false
            }
            
            switch status {
            case .success:
                self?.dismiss(animated: true)
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
}
