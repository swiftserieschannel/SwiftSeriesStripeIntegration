//
//  MyAPIClient.swift
//  SwiftSeriesStripeIntegration
//
//  Created by Chandra Bhushan on 28/12/2019.
//  Copyright © 2019 Chandra Bhushan. All rights reserved.
//

import Foundation
import Alamofire
import Stripe
class MyAPIClient: NSObject,STPCustomerEphemeralKeyProvider {
    
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let parameters = ["api_version":apiVersion]
        Alamofire.request(URL(string: "http://192.168.43.183:80/StripeBackend/empheralkey.php")!, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: [:]).responseJSON { (apiResponse) in
            let data = apiResponse.data
            guard let json = ((try? JSONSerialization.jsonObject(with: data!, options: []) as? [String : Any]) as [String : Any]??) else {
                completion(nil, apiResponse.error)
                return
            }
            completion(json, nil)
            
        }
    }
    
    class func createCustomer(){
        
        var customerDetailParams = [String:String]()
        customerDetailParams["email"] = "tes675t@gmail.com"
        customerDetailParams["phone"] = "8888888888"
        customerDetailParams["name"] = "test"
        
        Alamofire.request(URL(string: "http://192.168.43.183:80/StripeBackend/createcustomer.php")!, method: .post, parameters: customerDetailParams, encoding: URLEncoding.default, headers: nil).responseJSON { (response) in
            
            if response.result.isSuccess {
                debugPrint(response.data!)
            }else{
                debugPrint(response.error)
                debugPrint(response.debugDescription)
            }
        }
    }
    
    
    class func createPaymentIntent(amount:Double,currency:String,customerId:String,completion:@escaping (Result<String>)->Void){
        //        createpaymentintent.php
        Alamofire.request(URL(string: "http://192.168.43.183:80/StripeBackend/createpaymentintent.php")!, method: .post, parameters: ["amount":amount,"currency":currency,"customerId":customerId], encoding: URLEncoding.default, headers: nil).responseJSON { (response) in
            if response.result.isSuccess {
                let data = response.data
                
                guard let json = ((try? JSONSerialization.jsonObject(with: data!, options: []) as? [String : String]) as [String : String]??) else {
                    completion(.failure(response.error!))
                    return
                }
                completion(.success(json!["clientSecret"]!))
            }else{
                completion(.failure(response.result.error!))
            }
        }
    }
}
