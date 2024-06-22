//
//  CustomTextBox.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/21/24.
//

import SwiftUI

struct CustomTextBox: View {
    @Binding var textInput: String
    var placeholder: String
    
    var body: some View {
        TextField(
            "",
            text: $textInput,
            prompt: Text(placeholder)
                .font(Font.custom("Menlo", size: 16).weight(.bold))
                .foregroundColor(Color(red: 0, green: 0, blue: 0).opacity(0.60))
        )
        .frame(width: 200, height: 33)
        .font(Font.custom("Menlo", size: 16).weight(.bold))
        .foregroundStyle(Color(.black))
        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .inset(by: -1)
                .stroke(Color.black, lineWidth: 2.5)
        )
    }
}


struct CustomTextBox_Previews: PreviewProvider {
    static var previews: some View {
        CustomTextBox(textInput: .constant(""), placeholder: "Enter text here")
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
