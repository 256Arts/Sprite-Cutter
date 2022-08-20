//
//  IntentHandler.swift
//  Sprite Cutter Intent
//
//  Created by Jayden Irwin on 2021-06-16.
//

import Intents

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        guard intent is CutSpritesIntent else {
            fatalError("Unknown intent")
        }
        return CutSpritesHandler()
    }
    
}
