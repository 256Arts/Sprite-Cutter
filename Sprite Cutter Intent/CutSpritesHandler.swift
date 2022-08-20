//
//  CutSprites.swift
//  Sprite Cutter Intent
//
//  Created by Jayden Irwin on 2021-06-17.
//

import UIKit
import Intents

class CutSpritesHandler: NSObject, CutSpritesIntentHandling {
    
    func resolveImage(for intent: CutSpritesIntent, with completion: @escaping (INFileResolutionResult) -> Void) {
        if let image = intent.image {
            completion(INFileResolutionResult.success(with: image))
        } else {
            completion(INFileResolutionResult.unsupported())
        }
    }
    
    func resolveSpriteWidth(for intent: CutSpritesIntent, with completion: @escaping (CutSpritesSpriteWidthResolutionResult) -> Void) {
        if let number = intent.spriteWidth {
            switch number.intValue {
            case ..<0:
                completion(CutSpritesSpriteWidthResolutionResult.unsupported(forReason: .negativeNumbersNotSupported))
            case 1:
                completion(CutSpritesSpriteWidthResolutionResult.unsupported(forReason: .lessThanMinimumValue))
            default:
                completion(CutSpritesSpriteWidthResolutionResult.success(with: number.intValue))
            }
        } else {
            completion(CutSpritesSpriteWidthResolutionResult.success(with: 16))
        }
    }
    
    func resolveSpriteHeight(for intent: CutSpritesIntent, with completion: @escaping (CutSpritesSpriteHeightResolutionResult) -> Void) {
        if let number = intent.spriteWidth {
            switch number.intValue {
            case ..<0:
                completion(CutSpritesSpriteHeightResolutionResult.unsupported(forReason: .negativeNumbersNotSupported))
            case 1:
                completion(CutSpritesSpriteHeightResolutionResult.unsupported(forReason: .lessThanMinimumValue))
            default:
                completion(CutSpritesSpriteHeightResolutionResult.success(with: number.intValue))
            }
        } else {
            completion(CutSpritesSpriteHeightResolutionResult.success(with: 16))
        }
    }
    
    func handle(intent: CutSpritesIntent, completion: @escaping (CutSpritesIntentResponse) -> Void) {
        guard let data = intent.image?.data, let image = UIImage(data: data) else {
            completion(CutSpritesIntentResponse.failure(error: "Could not load image"))
            return
        }
        let maxImageSize = 512
        guard Int(image.size.width) <= maxImageSize, Int(image.size.height) <= maxImageSize else {
            completion(CutSpritesIntentResponse.failure(error: "Input image too large. (Max: \(maxImageSize) x \(maxImageSize))"))
            return
        }
        guard let width = intent.spriteWidth?.intValue, let height = intent.spriteHeight?.intValue else {
            completion(CutSpritesIntentResponse.failure(error: "Could not read sprite size"))
            return
        }
        var cutter = Cutter()
        cutter.image = image
        cutter.spriteSize = PixelSize(width: width, height: height)
        guard let sprites = try? cutter.cut() else {
            completion(CutSpritesIntentResponse.failure(error: "Failed to cut sprites"))
            return
        }
        var files: [INFile] = []
        for sprite in sprites {
            if let spriteData = sprite.pngData() {
                files.append(INFile(data: spriteData, filename: "Sprite", typeIdentifier: "public.png"))
            }
        }
        let response = CutSpritesIntentResponse(code: .success, userActivity: nil)
        response.result = files
        completion(response)
    }
    
}
