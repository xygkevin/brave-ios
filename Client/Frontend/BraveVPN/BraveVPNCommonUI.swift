// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared

struct BraveVPNCommonUI {
    
    struct UX {
        static let purpleBackgroundColor = #colorLiteral(red: 0.1529411765, green: 0.08235294118, blue: 0.368627451, alpha: 1)
    }
    
    struct Views {
        static func poweredByView(textColor: UIColor, fontSize: CGFloat = 13,
                                  imageColor: UIColor) -> UIStackView {
            UIStackView().then { stackView in
                stackView.distribution = .fillEqually
                stackView.spacing = 6

                let label = UILabel().then {
                    $0.text = Strings.VPN.poweredBy
                    $0.textAlignment = .center
                    $0.appearanceTextColor = textColor
                    $0.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                    $0.textAlignment = .right
                    $0.font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
                }

                let image = UIImageView(image: #imageLiteral(resourceName: "vpn_brand").template).then {
                    $0.contentMode = .left
                    $0.tintColor = imageColor
                }

                [label, image].forEach(stackView.addArrangedSubview(_:))
            }
        }
        
        static func checkmarkView(string: String, textColor: UIColor, font: UIFont) -> UIStackView {
            UIStackView().then { stackView in
                stackView.alignment = .top
                stackView.spacing = 4
                
                let image = UIImageView(image: #imageLiteral(resourceName: "vpn_checkmark")).then {
                    $0.contentMode = .scaleAspectFit
                    $0.snp.makeConstraints { make in
                        make.size.equalTo(24)
                    }

                }
                stackView.addArrangedSubview(image)
                
                let verticalStackView = UIStackView().then {
                    $0.axis = .vertical
                    $0.alignment = .leading
                }
                
                verticalStackView.addArrangedSubview(UIView.spacer(.vertical, amount: 2))
                
                let label = ShrinkableLabel().then {
                    $0.text = string
                    $0.font = font
                    $0.appearanceTextColor = textColor
                    $0.numberOfLines = 0
                    $0.lineBreakMode = .byWordWrapping
                }
                verticalStackView.addArrangedSubview(label)
                
                stackView.addArrangedSubview(verticalStackView)
            }
        }
        
        class ShrinkableLabel: UILabel {
            override init(frame: CGRect) {
                super.init(frame: frame)
                
                minimumScaleFactor = 0.5
                adjustsFontSizeToFitWidth = true
            }
            
            @available(*, unavailable)
            required init(coder: NSCoder) { fatalError() }
        }
    }
}
