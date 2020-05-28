// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared
import pop

extension BuyVPNViewController {
    class View: UIView {
        
        private let checkmarkViewStrings =
            [Strings.VPN.checkboxBlockAds,
             Strings.VPN.checkboxProtectConnections,
             Strings.VPN.checkboxFast,
             Strings.VPN.checkboxNoSellout,
             Strings.VPN.checkboxNoIPLog,
             Strings.VPN.checkboxEncryption,
             Strings.VPN.checkboxPrivateID,
             Strings.VPN.checkboxWhoAreYou]
        
        private var checkmarksPage = 0 {
            didSet {
                pageControl.currentPage = checkmarksPage
            }
        }
        
        // MARK: - Views
        
        private let mainStackView = UIStackView().then {
            $0.axis = .vertical
            $0.distribution = .equalSpacing
        }
        
        private let contentStackView = UIStackView().then {
            $0.axis = .vertical
            $0.spacing = 4
        }
        
        private let featuresScrollView = UIScrollView().then {
            $0.isPagingEnabled = true
            $0.showsHorizontalScrollIndicator = false
            $0.showsVerticalScrollIndicator = false
            $0.contentInsetAdjustmentBehavior = .never
        }
        
        private lazy var pageControlStackView = UIStackView().then { stackView in
            stackView.axis = .vertical
            
            let poweredByView =
                BraveVPNCommonUI.Views.poweredByView(textColor: .white, fontSize: 15, imageColor: .white)
            [poweredByView, pageControl].forEach(stackView.addArrangedSubview(_:))
        }
        
        private let pageControl = UIPageControl().then {
            $0.currentPage = 0
            $0.numberOfPages = 3
        }
        
        private lazy var vpnPlansStackView = UIStackView().then { stackView in
            let contentStackView = UIStackView()
            contentStackView.axis = .vertical
            contentStackView.spacing = 10
            
            let title = UILabel().then {
                $0.text = Strings.VPN.freeTrial
                $0.textAlignment = .center
                $0.appearanceTextColor = .white
            }
            
            [title, monthlySubButton, yearlySubButton, restorePurchasesButton]
                .forEach(contentStackView.addArrangedSubview(_:))
            
            contentStackView.setCustomSpacing(18, after: yearlySubButton)
            
            [UIView.spacer(.horizontal, amount: 24),
             contentStackView,
             UIView.spacer(.horizontal, amount: 24)]
                .forEach(stackView.addArrangedSubview(_:))
        }
        
        let monthlySubButton = SubscriptionButton(type: .monthly).then {
            $0.snp.makeConstraints { make in
                make.height.lessThanOrEqualTo(80)
            }
            
            $0.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        }
        
        let yearlySubButton = SubscriptionButton(type: .yearly).then {
            $0.snp.makeConstraints { make in
                make.height.lessThanOrEqualTo(80)
            }
            
            $0.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        }
        
        let restorePurchasesButton = UIButton(type: .system).then {
            $0.setTitle(Strings.VPN.restorePurchases, for: .normal)
            $0.appearanceTextColor = .white
            $0.titleLabel?.textAlignment = .center
        }
        
        private let backgroundImage = UIImageView(image: #imageLiteral(resourceName: "buy_vpn_background")).then {
            $0.contentMode = .scaleAspectFill
        }
        
        // MARK: - Init/Lifecycle
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = BraveVPNCommonUI.UX.purpleBackgroundColor
            
            insertSubview(backgroundImage, at: 0)
            addSubview(mainStackView)
            
            let checkmarkSlices = checkmarkViewStrings.splitEvery(CheckmarksView.maxCheckmarksPerView)
            checkmarkSlices.forEach {
                let view = CheckmarksView(checkmarks: $0)
                checkmarksStackView.addArrangedSubview(view)
            }
            
            featuresScrollView.addSubview(checkmarksStackView)
            
            featuresScrollView.snp.makeConstraints {
                $0.height.equalTo(checkmarksStackView).priority(.low)
            }
            
            [featuresScrollView,
             verticalFlexibleSpace(maxHeight: 48, priority: 100),
             pageControlStackView,
             verticalFlexibleSpace(maxHeight: 48, priority: 80),
             vpnPlansStackView]
                .forEach(contentStackView.addArrangedSubview(_:))
            
            [UIView.spacer(.vertical, amount: 1),
            contentStackView,
            UIView.spacer(.vertical, amount: 1)]
               .forEach(mainStackView.addArrangedSubview(_:))
            
            backgroundImage.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview()
                $0.centerY.equalToSuperview()
            }
            
            mainStackView.snp.makeConstraints {
                $0.leading.trailing.top.equalTo(self.safeAreaLayoutGuide)
                $0.bottom.equalTo(self.safeAreaLayoutGuide).inset(8)
            }
            
            checkmarksStackView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            
            featuresScrollView.delegate = self
            pageControl.addTarget(self, action: #selector(pageControlTapped(_:)), for: .valueChanged)
        }
        
        private func verticalFlexibleSpace(maxHeight: CGFloat, priority: CGFloat) -> UIView {
            UIView().then {
                $0.snp.makeConstraints { make in
                    make.height.lessThanOrEqualTo(maxHeight).priority(.required)
                    make.height.equalTo(maxHeight).priority(priority)
                }
            }
        }
        
        @available(*, unavailable)
        required init(coder: NSCoder) { fatalError() }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            if frame == .zero { return }
            
            checkmarksStackView.subviews
                .filter { $0 is CheckmarksView }
                .forEach {
                    $0.snp.remakeConstraints { make in
                        make.width.equalTo(frame.width)
                    }
            }
            
            checkmarksStackView.setNeedsLayout()
            checkmarksStackView.layoutIfNeeded()
            
            checkmarksStackView.bounds = CGRect(origin: .zero, size: checkmarksStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize))
        }
        
        private let checkmarksStackView = UIStackView().then {
            $0.distribution = .fillEqually
        }
        
        @objc func pageControlTapped(_ sender: UIPageControl) {
            featuresScrollView.setContentOffset(
                CGPoint(x: self.featuresScrollView.frame.width * CGFloat(sender.currentPage), y: 0),
                animated: true)
        }
    }
}

// MARK: - UIScrollViewDelegate
extension BuyVPNViewController.View: UIScrollViewDelegate {
    // Paging implementation.
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if scrollView.frame.width <= 0 {
            checkmarksPage = 0
            return
        }
        
        let pageNumber = targetContentOffset.pointee.x / scrollView.frame.width
        let cappedPageNumber = min(Int(pageNumber), pageControl.numberOfPages)
        
        checkmarksPage = max(0, cappedPageNumber)
    }
}

// MARK: - Checkmarks

private class CheckmarksView: UIView {
    static let maxCheckmarksPerView = 3
    
    private let checkmarks: [String]
    
    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 16
        $0.alignment = .leading
        $0.distribution = .equalSpacing
    }
    
    init(checkmarks: [String]) {
        self.checkmarks = Array(checkmarks.prefix(CheckmarksView.maxCheckmarksPerView))
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        for i in 0...(CheckmarksView.maxCheckmarksPerView - 1) {
            if let checkmark = checkmarks[safe: i] {
                stackView.addArrangedSubview(
                    BraveVPNCommonUI.Views.checkmarkView(string: checkmark,
                                                       textColor: .white,
                                                       font: .systemFont(ofSize: 16, weight: .semibold)))
            } else {
                // Add empty label so the view has the same constaints even if not all checkboxes are filled.
                let emptyLabel = UILabel().then {
                    $0.text = " "
                    $0.isAccessibilityElement = false
                }
                stackView.addArrangedSubview(emptyLabel)
            }
        }
        
        stackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.top.equalToSuperview().inset(8)
            $0.bottom.equalToSuperview()
        }
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError() }
    
    private class CheckmarkInsetLabel: UILabel {
        override func draw(_ rect: CGRect) {
            // Add small top margin to better align with checkmark image.
            let inset = UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 0)
            super.drawText(in: rect.inset(by: inset))
        }
    }
}

// MARK: - Subscription buttons

extension BuyVPNViewController {
    class SubscriptionButton: UIControl {
        
        private struct UX {
            static let disclaimerColor = #colorLiteral(red: 0.07058823529, green: 0.6392156863, blue: 0.4705882353, alpha: 1)
            static let primaryTextColor = #colorLiteral(red: 1, green: 1, blue: 0.9411764706, alpha: 1)
            static let secondaryTextColor = primaryTextColor.withAlphaComponent(0.7)
            static let discountTextColor = primaryTextColor.withAlphaComponent(0.6)
            
            static var gradientOverlay: CAGradientLayer {
                CAGradientLayer().then {
                    $0.colors = [#colorLiteral(red: 0.2196078431, green: 0.1176470588, blue: 0.5215686275, alpha: 1).cgColor, #colorLiteral(red: 0.4078431373, green: 0.2705882353, blue: 0.8196078431, alpha: 1).cgColor]
                    $0.locations = [0, 1]
                    
                    // Make it horizontal
                    $0.startPoint = CGPoint(x: 0, y: 0)
                    $0.endPoint = CGPoint(x: 1, y: 0)
                }
            }
        }
        
        private let gradientView = GradientView(colors: [#colorLiteral(red: 0.2196078431, green: 0.1176470588, blue: 0.5215686275, alpha: 1), #colorLiteral(red: 0.4078431373, green: 0.2705882353, blue: 0.8196078431, alpha: 1)],
                                                positions: [0, 1],
                                                startPoint: CGPoint(x: 0, y: 0),
                                                endPoint: CGPoint(x: 1, y: 0))
        
        enum SubscriptionType { case monthly, yearly }
        
        private let title: String
        private var disclaimer: String?
        private var detail: String = ""
        private var price: String = ""
        private var priceDiscount: String?
        
        init(type: SubscriptionType) {
            switch type {
            case .monthly:
                title = Strings.VPN.monthlySubTitle
                detail = Strings.VPN.monthlySubDetail
                
                guard let product = VPNProductInfo.monthlySubProduct,
                    let formattedPrice = product.price
                        .frontSymbolCurrencyFormatted(with: product.priceLocale) else {
                        break
                }
                  
                price = "\(formattedPrice) / \(Strings.monthAbbreviation)"
            case .yearly:
                title = Strings.VPN.yearlySubTitle
                disclaimer = Strings.VPN.yearlySubDisclaimer
                
                guard let monthlyProduct = VPNProductInfo.monthlySubProduct,
                    let discountFormattedPrice = monthlyProduct.price.multiplying(by: 12)
                        .frontSymbolCurrencyFormatted(with: monthlyProduct.priceLocale),
                    let yearlyProduct = VPNProductInfo.yearlySubProduct,
                    let formattedYearlyPrice =
                    yearlyProduct.price.frontSymbolCurrencyFormatted(with: yearlyProduct.priceLocale) else {
                        break
                }
                
                // Calculating savings of the annual plan.
                // Since different countries have different price brackets in App Store
                // we have to calculate it manually.
                let yearlyDouble = yearlyProduct.price.doubleValue
                let discountDouble = monthlyProduct.price.multiplying(by: 12).doubleValue
                let discountSavingPercentage = 100 - Int((yearlyDouble * 100) / discountDouble)
                
                detail =  String(format: Strings.VPN.yearlySubDetail, "\(discountSavingPercentage)%")
                price = "\(formattedYearlyPrice) / \(Strings.yearAbbreviation)"
                priceDiscount = discountFormattedPrice
            }
            
            super.init(frame: .zero)
            
            layer.cornerRadius = 12
            layer.masksToBounds = true
            
            let mainStackView = UIStackView().then {
                $0.distribution = .equalSpacing
                $0.alignment = .center
                $0.spacing = 4
                $0.isUserInteractionEnabled = false
            }
            
            let titleStackView = UIStackView().then { stackView in
                stackView.axis = .vertical
                
                let titleLabel = BraveVPNCommonUI.Views.ShrinkableLabel().then {
                    $0.text = title
                    $0.appearanceTextColor = UX.primaryTextColor
                    $0.font = .systemFont(ofSize: 15, weight: .semibold)
                }
                
                let titleStackView = UIStackView(arrangedSubviews: [titleLabel]).then {
                    $0.spacing = 4
                }
                
                if let disclaimer = disclaimer {
                    let disclaimerLabel = DisclaimerLabel().then {
                        $0.text = disclaimer
                        $0.setContentHuggingPriority(UILayoutPriority(rawValue: 100), for: .horizontal)
                        $0.appearanceTextColor = UX.primaryTextColor
                        $0.font = .systemFont(ofSize: 12, weight: .bold)
                        $0.backgroundColor = UX.disclaimerColor
                        $0.layer.cornerRadius = 4
                        $0.layer.masksToBounds = true
                    }
                    
                    titleStackView.addArrangedSubview(disclaimerLabel)
                    
                    let spacer = UIView().then {
                        $0.setContentHuggingPriority(UILayoutPriority(100), for: .horizontal)
                    }
                    
                    titleStackView.addArrangedSubview(spacer)
                }
                
                let detailLabel = BraveVPNCommonUI.Views.ShrinkableLabel().then {
                    $0.text = detail
                    $0.appearanceTextColor = UX.secondaryTextColor
                    $0.font = .systemFont(ofSize: 15, weight: .regular)
                }
                
                [titleStackView, detailLabel].forEach(stackView.addArrangedSubview(_:))
            }
            
            let priceStackView = UIStackView().then { stackView in
                stackView.axis = .vertical
                
                let priceLabel = BraveVPNCommonUI.Views.ShrinkableLabel().then {
                    $0.text = price
                    $0.appearanceTextColor = UX.primaryTextColor
                    $0.font = .systemFont(ofSize: 15, weight: .bold)
                }
                
                var views: [UIView] = [priceLabel]
                
                if let priceDiscount = priceDiscount {
                    let discountLabel = BraveVPNCommonUI.Views.ShrinkableLabel().then {
                        let strikeThroughText = NSMutableAttributedString(string: priceDiscount).then {
                            $0.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2,
                                            range: NSRange(location: 0, length: $0.length))
                        }
                        
                        $0.attributedText = strikeThroughText
                        $0.appearanceTextColor = #colorLiteral(red: 1, green: 1, blue: 0.9411764706, alpha: 1).withAlphaComponent(0.6)
                        $0.font = .systemFont(ofSize: 13, weight: .regular)
                        $0.textAlignment = .right
                    }
                    
                    views.append(discountLabel)
                }
                
                views.forEach(stackView.addArrangedSubview(_:))
            }
            
            [titleStackView, priceStackView].forEach(mainStackView.addArrangedSubview(_:))
            
            addSubview(mainStackView)
            mainStackView.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
            
            insertSubview(gradientView, at: 0)
            gradientView.isUserInteractionEnabled = false
            gradientView.snp.makeConstraints { $0.edges.equalToSuperview() }
        }
        
        @available(*, unavailable)
        required init(coder: NSCoder) { fatalError() }
        
        override var isHighlighted: Bool {
            didSet {
                basicAnimate(property: kPOPViewAlpha, key: "alpha") { animation, _ in
                    animation.toValue = self.isHighlighted ? 0.5 : 1.0
                    animation.duration = 0.1
                }
            }
        }
    }
}

private class DisclaimerLabel: BraveVPNCommonUI.Views.ShrinkableLabel {
    private let insetAmount: CGFloat = 5
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 0, left: insetAmount, bottom: 0, right: insetAmount)
        super.drawText(in: rect.inset(by: insets))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insetAmount * 2,
                      height: size.height)
    }
}
