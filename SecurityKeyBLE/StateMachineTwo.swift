//
//  StateMachineTwo.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/6/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

class ClientStateMachine {
    var delegate: StateDelegateProtocol
    
    init() {
        delegate = ClientState.Init.newDelegate()
    }
    
    func proceed(to state: ClientState) {
        delegate = state.newDelegate()
    }
}

enum ClientState {
    case Init
    
    func newDelegate() -> StateDelegateProtocol {
        switch self {
        case .Init: return ClientStateInit()
        }
    }
}

protocol StateDelegateProtocol {
    var nextState: ClientState? { get }
}

class ClientStateInit: StateDelegateProtocol {
    let nextState: ClientState? = nil
}