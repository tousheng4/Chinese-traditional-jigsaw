//
//  DesignSystem.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import SwiftUI

// MARK: - Traditional Colors
extension Color {
    static let traditional = TraditionalColorTheme()
}

struct TraditionalColorTheme {
    /// 宣纸白 - 背景基调
    let paper = Color(red: 0.98, green: 0.97, blue: 0.95)
    
    /// 墨色 - 主要文字
    let ink = Color(red: 0.20, green: 0.20, blue: 0.20)
    
    /// 朱红 - 强调、选中、印章
    let vermilion = Color(red: 0.82, green: 0.25, blue: 0.20)
    
    /// 靛蓝 - 次要强调、链接
    let indigo = Color(red: 0.16, green: 0.38, blue: 0.55)
    
    /// 赭石 - 边框、分割线
    let ocher = Color(red: 0.65, green: 0.45, blue: 0.30)
    
    /// 淡灰 - 辅助背景
    let lightGray = Color(red: 0.92, green: 0.92, blue: 0.90)
}

// MARK: - Typography Modifiers
struct TraditionalTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.largeTitle, design: .serif))
            .fontWeight(.bold)
            .foregroundColor(.traditional.ink)
    }
}

struct TraditionalHeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.headline, design: .serif))
            .fontWeight(.medium)
            .foregroundColor(.traditional.ink)
    }
}

struct TraditionalSubheadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.subheadline, design: .serif))
            .foregroundColor(.traditional.ink.opacity(0.7))
    }
}

extension View {
    func traditionalTitle() -> some View {
        modifier(TraditionalTitleStyle())
    }
    
    func traditionalHeadline() -> some View {
        modifier(TraditionalHeadlineStyle())
    }
    
    func traditionalSubheadline() -> some View {
        modifier(TraditionalSubheadlineStyle())
    }
}

// MARK: - Component Styles
struct TraditionalCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white.opacity(0.8)) // 稍微透出一点背景
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.traditional.ocher.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.traditional.ink.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct TraditionalButtonStyle: ButtonStyle {
    var isPrimary: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .serif))
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                isPrimary ? Color.traditional.vermilion : Color.clear
            )
            .foregroundColor(isPrimary ? .white : .traditional.vermilion)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.traditional.vermilion, lineWidth: isPrimary ? 0 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension View {
    func traditionalCard() -> some View {
        modifier(TraditionalCardStyle())
    }
}

