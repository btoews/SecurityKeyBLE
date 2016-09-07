//
//  StateMachineTest.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/6/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest


class TestStateMachine: StateMachineProtocol {
    typealias StateType = TestState
    
    var current: TestState?
    var failure: TestState.Type
    var history = [String]()
    
    init(initial: TestState.Type, failure: TestState.Type? = nil) {
        self.failure = failure ?? initial
        proceed(to: initial)
    }
}

class TestState: StateProtocol {
    typealias StateMachineType = TestStateMachine
    
    var machine: TestStateMachine
    var eventHandlers: [String:(error: NSError?) -> Void] = [:]
    
    init(_ m: TestStateMachine) {
        machine = m
    }
}



class StateMachineTest: XCTestCase {
    func testBasicFunctionality() {
        let tsm = TestStateMachine(initial: TestStateOne.self)
        XCTAssertEqual(["sm init", "s1 enter"], tsm.history)
        
        tsm.proceed(to: TestStateTwo.self)
        XCTAssertEqual(["sm init", "s1 enter", "s1 exit", "s2 enter"], tsm.history)
        
        tsm.handle(event: "testEvent")
        XCTAssertEqual(["sm init", "s1 enter", "s1 exit", "s2 enter", "s2 handler", "s2 exit", "s3 enter"], tsm.history)
    }
}
