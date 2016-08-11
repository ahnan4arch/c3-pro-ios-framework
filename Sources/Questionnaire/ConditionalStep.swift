//
//  ConditionalStep.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 4/27/15.
//  Copyright © 2015 Boston Children's Hospital. All rights reserved.
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
import ResearchKit


/**
A conditional question step, for use with the conditional ordered task.
*/
class ConditionalQuestionStep: ORKQuestionStep {
	
	/// The original "type", specified in the FHIR Questionnaire.
	var fhirType: String?
	
	/// Requirements to fulfil for the step to show up, if any.
	var requirements: [ResultRequirement]?
	
	
	/**
	Designated initializer.
	
	- parameter identifier: The step identifier
	- parameter title: The step's title
	- parameter answer: The step's answer format
	*/
	init(identifier: String, title ttl: String?, answer: ORKAnswerFormat) {
		super.init(identifier: identifier)
		title = ttl
		answerFormat = answer
	}
	
	
	// MARK: - Requirements
	
	func add(requirement: ResultRequirement) {
		if nil == requirements {
			requirements = [ResultRequirement]()
		}
		requirements!.append(requirement)
	}
	
	func add(requirements reqs: [ResultRequirement]) {
		guard !reqs.isEmpty else {
			return
		}
		if nil == requirements {
			requirements = reqs
		}
		else {
			requirements!.append(contentsOf: reqs)
		}
	}
	
	/**
	If the step has requirements, checks if all of them are fulfilled in step results in the given task result.
	
	- parameter result: The result to use for the checks
	- returns: A bool indicating success or failure, nil if there are no requirements
	*/
	func requirementsAreSatisfiedBy(_ result: ORKTaskResult) -> Bool? {
		guard let requirements = requirements else {
			return nil
		}
		
		// check each requirement and drop out early if one fails
		for requirement in requirements {
			if let stepResult = result.result(forIdentifier: requirement.questionIdentifier as String) as? ORKStepResult {
				if let questionResults = stepResult.results as? [ORKQuestionResult] {
					var ok = false
					for questionResult in questionResults {
						//c3_logIfDebug("===>  \(questionResult.identifier) is \(questionResult.answer), needs to be \(requirement.result.answer): \(questionResult.c3_hasSameResponse(requirement.result))")
						if questionResult.c3_hasSameResponse(requirement.result) {
							ok = true
						}
					}
					if !ok {
						return false
					}
				}
				else {
					c3_logIfDebug("Expecting Array<ORKQuestionResult> but got \(stepResult.results)")
				}
			}
			else {
				c3_logIfDebug("Next step \(identifier) has a condition on \(requirement.questionIdentifier), but the latter has no result yet")
			}
		}
		return true
	}
	
	
	// MARK: - NSCopying
	
	override func copy(with zone: NSZone?) -> AnyObject {
		super.copy(with: zone)
		return self
	}
	
	
	// MARK: - NSSecureCoding
	
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		// TODO: how to use [ResultRequirement] as first argument to decodeObject()?
		requirements = aDecoder.decodeObject(of: nil, forKey: "requirements") as? [ResultRequirement]
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		aCoder.encode(requirements, forKey: "requirements")
	}
}


/**
A conditional instruction step, to be used in the conditional ordered task.
*/
class ConditionalInstructionStep: ORKInstructionStep {
	
	/// Requirements to fulfil for the step to show up, if any.
	var requirements: [ResultRequirement]?
	
	/**
	Designated initializer.
	
	- parameter identifier: The step's identifier
	- parameter title: The step's title
	- parameter text: The instruction text
	*/
	init(identifier: String, title ttl: String?, text txt: String?) {
		super.init(identifier: identifier)
		title = ttl
		text = txt
	}
	
	
	// MARK: - Requirements
	
	func add(requirement: ResultRequirement) {
		if nil == requirements {
			requirements = [ResultRequirement]()
		}
		requirements!.append(requirement)
	}
	
	func add(requirements reqs: [ResultRequirement]) {
		if nil == requirements {
			requirements = reqs
		}
		else {
			requirements!.append(contentsOf: reqs)
		}
	}
	
	/**
	If the step has requirements, checks if all of them are fulfilled in step results in the given task result.
	
	- returns: A bool indicating success or failure, nil if there are no requirements
	*/
	func requirementsAreSatisfiedBy(_ result: ORKTaskResult) -> Bool? {
		guard let requirements = requirements else {
			return nil
		}
		
		// check each requirement and drop out early if one fails
		for requirement in requirements {
			if let stepResult = result.result(forIdentifier: requirement.questionIdentifier as String) as? ORKStepResult {
				if let questionResults = stepResult.results as? [ORKQuestionResult] {
					var ok = false
					for questionResult in questionResults {
						//c3_logIfDebug("===>  \(questionResult.identifier) is \(questionResult.answer), needs to be \(requirement.result.answer): \(questionResult.c3_hasSameResponse(requirement.result))")
						if questionResult.c3_hasSameResponse(requirement.result) {
							ok = true
						}
					}
					if !ok {
						return false
					}
				}
				else {
					c3_logIfDebug("Expecting Array<ORKQuestionResult> but got \(stepResult.results)")
				}
			}
			else {
				c3_logIfDebug("Next step \(identifier) has a condition on \(requirement.questionIdentifier), but the latter has no result yet")
			}
		}
		return true
	}
	
	
	// MARK: - NSCopying
	
	override func copy(with zone: NSZone?) -> AnyObject {
		super.copy(with: zone)
		return self
	}
	
	
	// MARK: - NSSecureCoding
	
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		// TODO: how to use [ResultRequirement] as first argument to decodeObject()?
		requirements = aDecoder.decodeObject(of: nil, forKey: "requirements") as? [ResultRequirement]
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		aCoder.encode(requirements, forKey: "requirements")
	}
}

