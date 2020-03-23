// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Static
import Shared
import BraveShared

class BraveVPNSettingsViewController: TableViewController {
    
    var faqLinkTapped: (() -> Void)?
    
    init() {
        super.init(style: .grouped)
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError() }
    
    private let manageSubcriptionURL = URL(string: "https://apps.apple.com/account/subscriptions")
    
    private let serverSectionId = "server"
    private let hostCellId = "host"
    private let locationCellId = "location"
    private let resetCellId = "reset"
    
    private let vpnStatusSectionCellId = "vpnStatus"
    
    private var switchView: SwitchAccessoryView?
    
    private var vpnReconfigurationPending = false {
        didSet {
            DispatchQueue.main.async {
                self.switchView?.isEnabled = !self.vpnReconfigurationPending
            }
        }
    }
    
    /// This is local variable only to prevents users from spamming the reset configuration button.
    private var lastTimeVPNWasResetted: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.VPN.vpnName
        NotificationCenter.default.addObserver(self, selector: #selector(vpnConfigChanged),
                                               name: .NEVPNStatusDidChange, object: nil)
        
        let isConnected = BraveVPN.isConnected
        let switchView = SwitchAccessoryView(initialValue: BraveVPN.isConnected, valueChange: { vpnOn in
            if vpnOn {
                BraveVPN.enableVPN()
            } else {
                BraveVPN.disableVPN()
            }
        })
        
        self.switchView = switchView
        
        // section uuid
        
        switchView.isEnabled = isConnected
        
        let vpnStatusSection = Section(rows: [
            Row(text: Strings.VPN.settingsVPNEnabled,
                accessory: .view(switchView), uuid: vpnStatusSectionCellId)
        ], uuid: vpnStatusSectionCellId)

        let subscriptionStatus = BraveVPN.hasExpired == true ?
            Strings.VPN.subscriptionStatusExpired : BraveVPN.subscriptionName
        
        let expirationDate = BraveVPN.hasExpired == true ? "-" : getExpirationDate
        
        let subscriptionSection =
            Section(header: .title(Strings.VPN.settingsSubscriptionSection),
                    rows: [Row(text: Strings.VPN.settingsSubscriptionStatus,
                               detailText: subscriptionStatus),
                           Row(text: Strings.VPN.settingsSubscriptionExpiration, detailText: expirationDate),
                           Row(text: Strings.VPN.settingsManageSubscription,
                               selection: { [unowned self] in
                                guard let url = self.manageSubcriptionURL else { return }
                                if UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url, options: [:])
                                }
                            }, cellClass: ButtonCell.self)])
        
        let location = BraveVPN.serverLocation ?? "-"
        
        let serverSection =
            Section(header: .title(Strings.VPN.settingsServerSection),
                    rows: [Row(text: Strings.VPN.settingsServerHost, detailText: getHostname, uuid: hostCellId),
                           Row(text: Strings.VPN.settingsServerLocation, detailText: location,
                               uuid: locationCellId),
                           Row(text: Strings.VPN.settingsResetConfiguration,
                               selection: resetConfigurationTapped,
                               cellClass: ButtonCell.self, uuid: resetCellId)],
                    uuid: serverSectionId)
        
        let techSupportSection = Section(rows:
            [Row(text: Strings.VPN.settingsContactSupport,
                 selection: { [unowned self] in
                    self.sendContactSupportEmail()
            }, accessory: .disclosureIndicator,
                 cellClass: ButtonCell.self)])
        
        let termsSection = Section(rows:
            [Row(text: Strings.VPN.settingsFAQ, selection: { [weak self] in
                self?.faqLinkTapped?()
                }, accessory: .disclosureIndicator,
                 cellClass: ButtonCell.self)])

        dataSource.sections = [vpnStatusSection,
                               subscriptionSection,
                               serverSection,
                               techSupportSection,
                               termsSection]
    }
    
    private var getHostname: String {
        BraveVPN.hostname?.components(separatedBy: ".").first ?? "-"
    }
    
    private var getExpirationDate: String {
        guard let expirationDate = Preferences.VPN.expirationDate.value else {
            return ""
        }
        
        let dateFormatter = DateFormatter().then {
            $0.locale = Locale.current
            $0.dateStyle = .short
        }
        
        return dateFormatter.string(from: expirationDate)
    }
    
    private func updateServerInfo() {
        guard let hostIndexPath = dataSource
            .indexPath(rowUUID: hostCellId, sectionUUID: serverSectionId) else { return }
        
        guard let locationIndexPath = dataSource
            .indexPath(rowUUID: locationCellId, sectionUUID: serverSectionId) else { return }
        
        dataSource.sections[hostIndexPath.section].rows[hostIndexPath.row]
            .detailText = getHostname
        dataSource.sections[locationIndexPath.section].rows[locationIndexPath.row]
            .detailText = BraveVPN.serverLocation ?? "-"
    }
    
    private func sendContactSupportEmail() {
        navigationController?.pushViewController(BraveVPNContactFormViewController(), animated: true)
    }
    
    private func resetConfigurationTapped() {
        if BraveVPN.hasExpired == true { return }
        
        if let lastResetTime = lastTimeVPNWasResetted {
            let timeBetweenLastReset = Date().timeIntervalSince(lastResetTime)
            if timeBetweenLastReset < 60 { return }
        }
        
        let alert = UIAlertController(title: Strings.VPN.vpnResetAlertTitle,
                                      message: Strings.VPN.vpnResetAlertBody,
                                      preferredStyle: .actionSheet)
        
        let cancel = UIAlertAction(title: Strings.cancelButtonTitle, style: .cancel)
        let reset = UIAlertAction(title: Strings.VPN.vpnResetButton, style: .destructive,
                                  handler: { [weak self] _ in
            self?.vpnReconfigurationPending = true
            self?.lastTimeVPNWasResetted = Date()
            BraveVPN.reconfigureVPN() {
                self?.vpnReconfigurationPending = false
                self?.updateServerInfo()
            }
        })
        
        alert.addAction(cancel)
        alert.addAction(reset)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            alert.popoverPresentationController?.permittedArrowDirections = [.down, .up]
            
            if let resetCellIndexPath = dataSource
                .indexPath(rowUUID: resetCellId, sectionUUID: serverSectionId) {
                let cell = tableView.cellForRow(at: resetCellIndexPath)
                
                alert.popoverPresentationController?.sourceView = cell
                alert.popoverPresentationController?.sourceRect = cell?.bounds ?? .zero
            } else {
                alert.popoverPresentationController?.sourceView = self.view
                alert.popoverPresentationController?.sourceRect = self.view.bounds
            }
        }
        
        present(alert, animated: true)
    }
    
    @objc func vpnConfigChanged() {
        switchView?.isOn = BraveVPN.isConnected
    }
}
