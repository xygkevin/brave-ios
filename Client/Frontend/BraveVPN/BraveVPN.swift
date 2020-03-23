// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared
import NetworkExtension

private let log = Logger.browserLogger

/// A static class to handle all things related to the Brave VPN service.
class BraveVPN {
    
    // MARK: - Initialization
    
    /// This class is supposed to act as a namespace, disabling possibility of creating an instance of it.
    @available(*, unavailable)
    init() {}
    
    /// Initialize the vpn service. It should be called even if the user hasn't bought the vpn yet.
    static func initialize() {
        GRDServerManager.shared().downloadLatestHosts()
        
        // The vpn can live outside of the app.
        // When the app loads we should load it from preferences to track its state.
        NEVPNManager.shared().loadFromPreferences { error in
            if let error = error {
                log.error("Failed to load vpn conection: \(error)")
            }
            
            // We validate the current receipt at the start to know if the service has expirerd.
            BraveVPN.validateReceipt()
        }
    }
    
    // MARK: - STATE
    
    /// How many times we should retry to configure the vpn.
    private static let configMaxRetryCount = 4
    /// Current number of retries.
    private static var configRetryCount = 0
    
    /// Sometimes restoring a purchase is triggered multiple times which leads to calling vpn.configure multiple times.
    /// This flags prevents configuring the vpn more than once.
    private static var configurationPending = false
    
    /// Status of creating vpn credentials on Guardian's servers.
    enum VPNUserCreationStatus {
        case success
        case error(type: VPNUserCreationError)
    }
    
    /// Errors that can happen when a vpn's user credentials are created on Guardian's servers.
    /// Each error has a number associated to it for easier debugging.
    enum VPNUserCreationError: Int {
        case connectionProblems = 501
        case provisioning = 502
        case unknown = 503
    }
    
    enum VPNConfigStatus {
        case success
        case error(type: VPNConfigErrorType)
    }
    
    /// Errors that can happen when trying to estabilish a vpn connection.
    /// Each error has a number associated to it for easier debugging.
    enum VPNConfigErrorType: Int {
        case saveConfigError = 504
        case loadConfigError = 505
        /// User tapped 'Don't allow' when save-vpn-config prompt is shown.
        case permissionDenied = 506
    }
    
    enum VPNPurchaseError: Int {
        /// Returned when the receipt sent to the server is expired. This happens for sandbox users only.
        case receiptExpired = 600
        /// Purchase failed on Apple's side or canceled by user.
        case purchaseFailed = 601
    }
    
    /// A state in which the vpn can be.
    enum State {
        case notPurchased
        /// Purchased but not installed
        case purchased
        /// Purchased and installed
        case installed(enabled: Bool)
        
        case expired(enabled: Bool)
        
        /// What view controller to show once user taps on `Enable VPN` button at one of places in the app.
        var enableVPNDestinationVC: UIViewController? {
            switch self {
            case .notPurchased, .expired: return BuyVPNViewController()
            case .purchased: return InstallVPNViewController()
            // Show nothing, the `Enable` button will now be used to connect and disconnect the vpn.
            case .installed: return nil
            }
        }
    }
    
    /// Current state ot the VPN service.
    static var vpnState: State {
        // User hasn't bought or restored the vpn yet.
        if !Preferences.VPN.purchasedOrRestoredProduct.value { return .notPurchased }
        
        if hasExpired == true {
            return .expired(enabled: NEVPNManager.shared().isEnabled)
        }
        
        // No VPN config set means the user could buy the vpn but hasn't gone through the second screen
        // to install the vpn and connect to a server.
        if !NEVPNManager.shared().isEnabled { return .purchased }
        
        return .installed(enabled: isConnected)
    }
    
    /// Returns true if the user is connected to Brave's vpn at the moment.
    /// This will return true if the user is connected to other VPN.
    static var isConnected: Bool {
        NEVPNManager.shared().connection.status == .connected
    }
    
    /// Returns the last used hostname for the vpn configuration.
    /// Returns nil if the hostname string is empty(due to some error when configuring it for example).
    static var hostname: String? {
        let hostname = GRDVPNHelper.loadApiHostname()
        if hostname.isEmpty { return nil }
        return hostname
    }
    
    /// Whether the vpn subscription has expired.
    /// Returns nil if there has been no subscription yet (user never bought the vpn).
    static var hasExpired: Bool? {
        guard let expirationDate =  Preferences.VPN.expirationDate.value else { return nil }
        return expirationDate < Date()
    }
    
    /// Location of recently used server for the vpn configuration.
    static var serverLocation: String? {
        let hostname = GRDVPNHelper.loadApiHostname()
        return GRDVPNHelper.serverLocation(forHostname: hostname)
    }
    
    /// Name of the purchased vpn plan.
    static var subscriptionName: String {
        guard let productId = Preferences.VPN.lastPurchaseProductId.value else { return "" }
        
        switch productId {
        case VPNProductInfo.ProductIdentifiers.monthlySub:
            return Strings.VPN.vpnSettingsMonthlySubName
        case VPNProductInfo.ProductIdentifiers.yearlySub:
            return Strings.VPN.vpnSettingsYearlySubName
        default:
            assertionFailure("Can't get product id")
            return ""
        }
    }
    
    // MARK: - Actions
    
    /// Reconnects to the vpn.
    /// The vpn must be configured prior to that otherwise it does nothing.
    static func enableVPN() {
        GRDVPNHelper.reconnectVPN()
    }
    
    /// Disconnects the vpn.
    /// The vpn must be configured prior to that otherwise it does nothing.
    static func disableVPN() {
        GRDVPNHelper.disconnectVPN()
    }
    
    /// Connects to Guardian's server to validate the locally stored receipt.
    /// Returns whether the receipt has expired or not.
    /// If the receipt is valid, `expirationDate` and `lastPurchaseProductId` properties are saved with corresponding values.
    static func validateReceipt(receiptHasExpired: ((Bool?) -> Void)? = nil) {
        GRDGatewayAPI.shared()?.validateReceipt(usingSandbox: true) { completion in
            guard let completion = completion, completion.responseStatus == .success else {
                receiptHasExpired?(nil)
                return
            }
            
            guard let expirationDate = completion.receiptExpirationDate,
                let productId = completion.receiptProductID else {
                    // Making expiration date super old to force the expiration logic.
                    // nil is not set here to avoid side effects.
                    // Expiration date is supposed to be nil when the user hasn't bought the app yet
                    // or after app reinstall.
                    Preferences.VPN.expirationDate.value = Date(timeIntervalSince1970: 1)
                    receiptHasExpired?(true)
                    return
            }
            
            Preferences.VPN.expirationDate.value = expirationDate
            Preferences.VPN.lastPurchaseProductId.value = productId
                
            receiptHasExpired?(BraveVPN.hasExpired)
        }
    }
    
    /// Configure the vpn for first time user, or when restoring a purchase on freshly installed app.
    /// Use `resetConfiguration` if you want to reconfigure the vpn for an existing user.
    static func configureFirstTimeUser(completion: ((VPNUserCreationStatus) -> Void)?) {
        if configurationPending { return }
        configurationPending = true
        
        let hostName = GRDVPNHelper.selectRandomProximateHostname()
        
        configureFirstTimeUserInternal(for: hostName) { status in
            configurationPending = false
            completion?(status)
        }
    }
    
    private static func configureFirstTimeUserInternal(for hostname: String,
                                                       completion: @escaping ((VPNUserCreationStatus) -> Void)) {
        GRDGatewayAPI.shared()?.apiHostname = hostname
        GRDVPNHelper.saveAll(inOneBoxHostname: hostname)
        
        GRDVPNHelper.createFreshUser { status, error in
            switch status {
            case .success:
                configRetryCount = 0
                completion(.success)
            case .doesNeedMigration:
                log.debug("configure fresh user needs migration")
                if configRetryCount > configMaxRetryCount {
                    completion(.error(type: .connectionProblems))
                    return
                }
                
                configRetryCount += 1
                let newHost = GRDVPNHelper.selectRandomProximateHostname()
                configureFirstTimeUserInternal(for: newHost, completion: completion)
            case .api_ProvisioningError:
                completion(.error(type: .provisioning))
            default:
                completion(.error(type: .unknown))
            }
            
            log.info("configure fresh user status: \(status), error: \(error)")
        }
    }
    
    /// Creates a vpn configuration using Apple's `NEVPN*` api.
    /// This method does not connect to the Guardian's servers unless there is no EAP credentials stored in keychain yet,
    /// in this case it tries to reconfigure the vpn before connecting to it.
    static func createVPNConfiguration(completion: @escaping ((VPNConfigStatus) -> Void)) {
        let eapUser = GRDVPNHelper.loadEapUsername()
        let eapPass = GRDVPNHelper.loadEapPasswordRef()
        
        // This is to be extra safe, in case user creation didn't generate credentials
        // we attempt to try again.
        if eapUser.isEmpty || eapPass.isEmpty {
            BraveVPN.reconfigureVPN() {
                connectInternal { internalCompletion in
                    completion(internalCompletion)
                }
            }
        } else {
            connectInternal { internalCompletion in
                completion(internalCompletion)
            }
        }
    }
    
    private static func connectInternal(completion: @escaping ((VPNConfigStatus) -> Void)) {
        let helper = GRDVPNHelper.self
        let hostName = helper.loadApiHostname()
        
        let eapUser = helper.loadEapUsername()
        let eapPass = helper.loadEapPasswordRef()
        
        let manager = NEVPNManager.shared()
        
        manager.loadFromPreferences { error in
            if error != nil {
                completion(.error(type: .loadConfigError))
                return
            }
            
            manager.isEnabled = true
            manager.protocolConfiguration =
                helper.prepareIKEv2Parameters(forServer: hostName, eapUsername: eapUser,
                                              eapPasswordRef: eapPass, with: .ECDSA256)
            
            manager.localizedDescription = Strings.VPN.vpnName
            
            manager.isOnDemandEnabled = true
            manager.onDemandRules = helper.vpnOnDemandRules() as? [NEOnDemandRule]
            
            // Special case: user explicitly tapped on 'Don't allow'
            // when save-vpn-config prompt was showed, not really an error.
            let permissionDeniedErrorCode = 5
            
            manager.saveToPreferences { saveError in
                if let error = saveError {
                    if error._domain == NEVPNErrorDomain && error._code == permissionDeniedErrorCode {
                        completion(.error(type: .permissionDenied))
                    } else {
                        completion(.error(type: .saveConfigError))
                    }
                    
                    return
                }
                
                manager.loadFromPreferences { loadError in
                    if loadError != nil {
                        completion(.error(type: .loadConfigError))
                        return
                    }
                    
                    GRDGatewayAPI.shared()?.startHealthCheckTimer()
                    completion(.success)
                }
            }
        }
    }
    
    /// Attempts to reconfigure the vpn by migrating to a new server.
    /// The new hostname is chosen randomly.
    /// This method disconnects from the vpn before reconfiguration is happening
    /// and reconnects automatically after reconfiguration is done.
    static func reconfigureVPN(completion: (() -> Void)? = nil) {
        disableVPN()
        GRDVPNHelper.migrateUserToRandomNewNode { status in
            createVPNConfiguration { status in
                log.debug("VPN node migration status: \(status)")
                completion?()
            }
        }
    }

    /// Clears current vpn configuration and removes it from preferences.
    static func clearConfiguration() {
        GRDVPNHelper.clearVpnConfiguration()
        
        NEVPNManager.shared().removeFromPreferences { error in
            if let error = error {
                log.error("Remove vpn error: \(error)")
            }
        }
    }
}
