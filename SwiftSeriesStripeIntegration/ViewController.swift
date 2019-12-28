//
//  ViewController.swift
//  SwiftSeriesStripeIntegration
//
//  Created by Chandra Bhushan on 28/12/2019.
//  Copyright © 2019 Chandra Bhushan. All rights reserved.
//

import UIKit
import Stripe
class ViewController: UIViewController {

    var customerContext : STPCustomerContext?
    var paymentContext : STPPaymentContext?
    var isSetShipping = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let config = STPPaymentConfiguration.shared()
        config.additionalPaymentOptions = .applePay
        config.shippingType = .shipping
        config.requiredShippingAddressFields = Set<STPContactField>(arrayLiteral: STPContactField.name,STPContactField.emailAddress,STPContactField.phoneNumber,STPContactField.postalAddress)
        config.companyName = "Testing XYZ"
        customerContext = STPCustomerContext(keyProvider: MyAPIClient())
        paymentContext =  STPPaymentContext(customerContext: customerContext!, configuration: config, theme: .default())
        self.paymentContext?.delegate = self
        self.paymentContext?.hostViewController = self
        self.paymentContext?.paymentAmount = 5000
    }

    
    @IBAction func clickedBtnCreateCustomer(_ sender: Any) {
        MyAPIClient.createCustomer()
    }
    
    
    @IBAction func clickedBtnPayNow(_ sender: Any) {
        self.paymentContext?.presentPaymentOptionsViewController()
    }
    
}

extension ViewController: STPPaymentContextDelegate {
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
       
        if paymentContext.selectedPaymentOption != nil && isSetShipping{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                paymentContext.presentShippingViewController()
            }
        }
        
        if paymentContext.selectedShippingMethod != nil && !isSetShipping {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
             self.paymentContext?.requestPayment()
            }
        }
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didUpdateShippingAddress address: STPAddress, completion: @escaping STPShippingMethodsCompletionBlock) {
        isSetShipping = false
        
        let upsGround = PKShippingMethod()
        upsGround.amount = 0
        upsGround.label = "UPS Ground"
        upsGround.detail = "Arrives in 3-5 days"
        upsGround.identifier = "ups_ground"
        
        let fedEx = PKShippingMethod()
        fedEx.amount = 5.99
        fedEx.label = "FedEx"
        fedEx.detail = "Arrives tomorrow"
        fedEx.identifier = "fedex"
        
        if address.country == "US" {
            completion(.valid, nil, [upsGround, fedEx], upsGround)
        }
        else {
            completion(.invalid, nil, nil, nil)
        }
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPPaymentStatusBlock) {
        
        MyAPIClient.createPaymentIntent(amount: (Double(paymentContext.paymentAmount+Int((paymentContext.selectedShippingMethod?.amount)!))), currency: "usd",customerId: "cus_GRbIU4MmLbqvL5") { (response) in
            switch response {
            case .success(let clientSecret):
                // Assemble the PaymentIntent parameters
                let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                paymentIntentParams.paymentMethodId = paymentResult.paymentMethod?.stripeId
                paymentIntentParams.paymentMethodParams = paymentResult.paymentMethodParams
                
                STPPaymentHandler.shared().confirmPayment(withParams: paymentIntentParams, authenticationContext: paymentContext) { status, paymentIntent, error in
                    switch status {
                    case .succeeded:
                        // Your backend asynchronously fulfills the customer's order, e.g. via webhook
                        completion(.success, nil)
                    case .failed:
                        completion(.error, error) // Report error
                    case .canceled:
                        completion(.userCancellation, nil) // Customer cancelled
                    @unknown default:
                        completion(.error, nil)
                    }
                }
            case .failure(let error):
                completion(.error, error) // Report error from your API
                break
            }
        }
        
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        
    }
}
