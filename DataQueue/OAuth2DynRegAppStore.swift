//
//  OAuth2DynRegAppStore.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 6/2/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import SMART
import StoreKit


public class OAuth2DynRegAppStore: OAuth2DynReg
{
	deinit {
		if let delegate = refreshDelegate {
			refreshRequest?.cancel()
			delegate.callback(error: OAuth2Error.Generic("App Store Receipt refresh cancelled [deinit]"))
		}
	}
	
	/// Whether the sandbox environment should be used.
	public var sandbox = false
	
	/// The App Receipt, read from file.
	var appReceipt: String?
	
	var refreshRequest: SKReceiptRefreshRequest?
	
	var refreshDelegate: AppStoreRequestDelegate?
	
	
	override public func register(callback: ((json: OAuth2JSON?, error: ErrorType?) -> Void)) {
		if ensureHasAppReceipt() {
			super.register(callback)
		}
		else {
			refreshAppReceipt() { error in
				if let error = error {
					if SKErrorDomain == error._domain && SKErrorUnknown == error._code {
						callback(json: nil, error: chip_genErrorDataQueue("App receipt refresh failed. Are you running on device?"))
					}
					else {
						callback(json: nil, error: error)
					}
				}
				else {
					super.register(callback)
				}
			}
		}
	}
	
	override public func registrationBody() -> OAuth2JSON {
		var dict = super.registrationBody()
		dict["sandbox"] = sandbox
		dict["receipt-data"] = appReceipt
		return dict
	}
	
	
	// MARK: - App Store Receipt
	
	func ensureHasAppReceipt() -> Bool {
		if nil == appReceipt, let receiptURL = NSBundle.mainBundle().appStoreReceiptURL {
			if let receipt = NSData(contentsOfURL: receiptURL) {
				appReceipt = receipt.base64EncodedStringWithOptions([])
			}
		}
		return (nil != appReceipt)
	}
	
	func refreshAppReceipt(callback: ((error: ErrorType?) -> Void)) {
		if let delegate = refreshDelegate {
			refreshRequest?.cancel()
			delegate.callback(error: OAuth2Error.Generic("App Store Receipt refresh timeout"))
		}
		refreshDelegate = AppStoreRequestDelegate(callback: { error in
			callback(error: error)
			self.refreshRequest = nil
			self.refreshDelegate = nil
		})
		
		let refresh = SKReceiptRefreshRequest(receiptProperties: nil)
		refresh.delegate = refreshDelegate
		refreshRequest = refresh
		refresh.start()
	}
}


/**
    Simple object used by `OAuth2DynRegAppStore` to use block-based callbacks on an SKRequest.
 */
class AppStoreRequestDelegate: NSObject, SKRequestDelegate
{
	let callback: ((error: ErrorType?) -> Void)
	
	init(callback: ((error: ErrorType?) -> Void)) {
		self.callback = callback
	}
	
	func requestDidFinish(request: SKRequest) {
		callback(error: nil)
	}
	
	func request(request: SKRequest, didFailWithError error: NSError) {
		callback(error: error)
	}
}

