// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import StoreKit
import Shared
import BraveShared

class IAPObserver: NSObject, SKPaymentTransactionObserver {
    
    /// Pass transaction argument here if the transaction must be set as finished at later point,
    /// for example after we get a callback from some api call.
    /// At the moment this is used for Brave VPN, we wait with finalizing the transaction after we receive correct vpn credentials.
    var purchasedOrRestoredProductCallback: (() -> Void)?
    var purchaseFailedCallback: ((SKError?) -> Void)?

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
            transactions.forEach { transaction in
                switch transaction.transactionState {
                case .purchased, .restored:
                    print("bxx purchased or restored")
                    BraveVPN.validateReceipt() { [weak self] expired in
                        guard let self = self else { return }
                        // This should be always called, no matter if transaction is successful or not.
                        SKPaymentQueue.default().finishTransaction(transaction)
                        
                        if expired == false {
                            self.purchasedOrRestoredProductCallback?()
                        } else {
                            // Receipt either expired or receipt validation returned some error.
                            self.purchaseFailedCallback?(nil)
                        }
                    }
                case .purchasing, .deferred:
                    print("bxx purchasing")
                case .failed:
                    purchaseFailedCallback?(transaction.error as? SKError)
                    SKPaymentQueue.default().finishTransaction(transaction)
                @unknown default:
                    assertionFailure("Unknown transactionState")
                }
            }
        }
                
}
