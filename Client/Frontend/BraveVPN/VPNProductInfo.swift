// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import StoreKit
import Shared

class VPNProductInfo: NSObject {
    // Prices are fetched once per launch and kept in memory.
    // If the prices could not be fetched, we retry after user tries to go to buy-vpn screen.
    static var monthlySubProduct: SKProduct?
    static var yearlySubProduct: SKProduct?
    
    /// Whether we have enough product info to present to the user.
    /// If the user has bought the vpn already, it returns `true` since we do not need price details anymore.
    static var isComplete: Bool {
        switch BraveVPN.vpnState {
        case .purchased, .installed:
            return true
        case .notPurchased, .expired:
            return monthlySubProduct != nil && yearlySubProduct != nil
        }
    }
    
    private let productRequest: SKProductsRequest
    
    struct ProductIdentifiers {
        static var monthlySub: String {
            switch AppConstants.buildChannel {
            case .enterprise:
                return "com.brave.ios.browser.dev.vpn.monthly"
            case .release:
                return "bravevpn.monthly"
            case .beta, .developer:
                // return ""
                // FIXME: Remove my personal product id, TESTING ONLY
                return "com.bucci.vpn.monthly"
            }
        }
        
        static var yearlySub: String {
            switch AppConstants.buildChannel {
            case .enterprise:
                return "com.brave.ios.browser.dev.vpn.yearly"
            case .release:
                return "bravevpn.yearly"
            case .beta, .developer:
                // return ""
                // FIXME: Remove my personal product id, TESTING ONLY
                return "com.bucci.vpn.yearly"
            }
        }
        
        static let all = Set<String>(arrayLiteral: monthlySub, yearlySub)
    }
    
    override init() {
        productRequest = SKProductsRequest(productIdentifiers: ProductIdentifiers.all)
        super.init()
        productRequest.delegate = self
    }
    
    func load() {
        productRequest.start()
    }
}

extension VPNProductInfo: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        response.products.forEach {
            switch $0.productIdentifier {
            case ProductIdentifiers.monthlySub:
                VPNProductInfo.monthlySubProduct = $0
            case ProductIdentifiers.yearlySub:
                VPNProductInfo.yearlySubProduct = $0
            default:
                assertionFailure("Found product identifier that doesn't match")
            }
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print(error)
    }
}

