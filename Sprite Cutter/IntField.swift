//
//  IntField.swift
//  Sprite Cutter
//
//  Created by Jayden Irwin on 2021-04-12.
//

import SwiftUI

struct IntField: View {
    
    @State var title: String
    @Binding var value: Int
    
    var body: some View {
        TextField(title, text: Binding(get: {
            String(value)
        }, set: { (newValue) in
            value = Int(newValue) ?? 1
        }))
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .keyboardType(.numberPad)
        .multilineTextAlignment(.trailing)
        .frame(width: 80)
    }
}

struct IntField_Previews: PreviewProvider {
    static var previews: some View {
        IntField(title: "", value: .constant(0))
    }
}
