//
//  StateMachine.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/6/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

enum StateError: ErrorType {
    case UnhandledEvent
}

protocol StateMachineProtocol: class {
    associatedtype StateType: StateProtocol

    var current: StateType?      { get set }
    var failure: StateType.Type  { get set }
}

extension StateMachineProtocol {
    // Helper for proceeding to the failure state.
    func fail() {
        proceed(to: failure)
    }
    
    // Proceed to the specified state.
    func proceed(to next: StateType) {
        let nextStateStateMachine = self as! StateType.StateMachineType
        
        do {
            current?.beforeExit()
            try current?.exit()
            current = next.init(nextStateStateMachine)
            current!.beforeEnter()
            try current!.enter()
        } catch {
            return fail()
        }
    }
    
    // Tell the current state about an event.
    func handle(event name: String, withError error: NSError? = nil) {
        do {
            try current!.handle(event: name, withError: error)
        } catch StateError.UnhandledEvent {
            print("Unexpected '\(name)' event while in \(current.self)")
            fail()
        } catch {
            print("Unkown error while handling \(name) event in \(current.self)")
        }
    }
}

protocol StateProtocol {
    associatedtype StateMachineType

    var machine: StateMachineType                         { get set }
    var eventHandlers: [String:(error: NSError?) -> Void] { get set }
}

extension StateProtocol {
    // Debugging callback
    func beforeEnter() {
        print("Entering \(self)")
    }
    
    // Callback when entering state
    func enter() throws {
    }
    
    // Debugging callback
    func beforeExit() {
        print("Exiting \(self)")
    }
    
    // Callback when leaving state
    func exit() throws {
    }
    
    // Register an event handler
    mutating func handle(event: String, with handler: (error: NSError?) -> Void) {
        eventHandlers[event] = handler
    }
    
    // Fire an event handler, optionally with an error
    func handle(event name: String, withError error: NSError?) throws {
        guard let handler = eventHandlers[name] else {
            throw StateError.UnhandledEvent
        }
        
        handler(error: error)
    }
}