//
//  ActivityReporter.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 15/07/16.
//  Copyright © 2016 University Hospital Zurich. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import SMART


/**
Protocol to which activity reporters/collectors should adhere.

See [HealthKit/README.md](https://github.com/C3-PRO/c3-pro-ios-framework/tree/master/Sources/HealthKit#activity-reporter) for detailed instructions.
*/
public protocol ActivityReporter {
	
	/**
	Retrieve activities performed between two given dates.
	
	- parameter startingAt: The start date
	- parameter until:      The end date
	- parameter callback:   The callback to call when all activities have been retrieved
	*/
	func reportForActivityPeriod(startingAt start: NSDate, until: NSDate, callback: ((period: ActivityReportPeriod?, error: ErrorType?) -> Void))
	
	/**
	Retrieve activity data with progressively increasing time intervals (1 day -> 1 month) up until today.
	
	- parameter callback: The callback to call when all activities have been retrieved
	*/
	func progressivelyCollatedActivityData(callback: ((report: ActivityReport, error: ErrorType?) -> Void))
}


extension ActivityReporter {
	
	/**
	Will retrieve activity data with progressively increasing time intervals (1 day -> 1 month).
	*/
	public func progressivelyCollatedActivityData(callback: ((report: ActivityReport, error: ErrorType?) -> Void)) {
		let queue = dispatch_queue_create("org.chip.c3-pro.activity-reporter-queue", DISPATCH_QUEUE_SERIAL)
		dispatch_async(queue) {
			let calendar = NSCalendar.currentCalendar()
			calendar.timeZone = NSTimeZone(abbreviation: "UTC")!    // use UTC
			let intervals = calendar.reverseProgressiveDateComponentsSinceToday()
			var errors = [ErrorType]()
			
			// sample all intervals
			var periods = [ActivityReportPeriod]()
			for (from, to, numDays, name) in intervals {
				let start = calendar.dateFromComponents(from) ?? NSDate()
				let end = calendar.dateFromComponents(to) ?? NSDate()
				let semaphore = dispatch_semaphore_create(0)
				self.reportForActivityPeriod(startingAt: start, until: end) { period, error in
					if let period = period {
						period.humanPeriod = name
						period.numberOfDays = numDays
						periods.append(period)
					}
					if let error = error {
						errors.append(error)
					}
					dispatch_semaphore_signal(semaphore)
				}
				dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
			}
			
			// all intervals collected, order and return
			let report = ActivityReport(periods: periods)
			c3_performOnMainQueue() {
				callback(report: report, error: (errors.count > 0) ? C3Error.MultipleErrors(errors) : nil)
			}
		}
	}
}

