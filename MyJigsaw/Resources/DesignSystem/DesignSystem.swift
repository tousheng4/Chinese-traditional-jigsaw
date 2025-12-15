//
//  DesignSystem.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import SwiftUI
import UIKit

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
            .font(.qianTuBiFeng(size: 34)) // 中文字体，对应 largeTitle
            .foregroundColor(.traditional.ink)
    }
}

struct TraditionalHeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.qianTuBiFeng(size: 17)) // 中文字体，对应 headline
            .foregroundColor(.traditional.ink)
    }
}

struct TraditionalSubheadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.qianTuBiFeng(size: 15)) // 中文字体，对应 subheadline
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
            .font(.qianTuBiFeng(size: 17)) // 中文字体
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

// MARK: - Custom Fonts
extension Font {
    /// 千图笔锋手写体字体（中文字体）
    /// 通过查找已注册的字体来获取正确的 PostScript 名称
    static func qianTuBiFeng(size: CGFloat) -> Font {
        // 遍历所有字体家族，查找匹配的字体
        for family in UIFont.familyNames {
            let fontNames = UIFont.fontNames(forFamilyName: family)
            for fontName in fontNames {
                // 检查是否包含关键词（支持中英文）
                let lowercased = fontName.lowercased()
                if fontName.contains("千图") || fontName.contains("笔锋") || 
                   lowercased.contains("qiantu") || lowercased.contains("bifeng") ||
                   lowercased.contains("shouxie") {
                    return .custom(fontName, size: size)
                }
            }
        }
        
        // 如果找不到，尝试直接使用可能的名称
        let possibleNames = [
            "千图笔锋手写体",
            "qiantubifengshouxieti",
            "QianTuBiFengShouXieTi",
            "QianTuBiFeng"
        ]
        
        for name in possibleNames {
            if UIFont(name: name, size: size) != nil {
                return .custom(name, size: size)
            }
        }
        
        // 如果都找不到，回退到系统字体
        return .system(size: size, design: .serif)
    }
    
    /// DancingScript-Regular 字体（英文字体）
    static func dancingScript(size: CGFloat) -> Font {
        // 遍历所有字体家族，查找匹配的字体
        for family in UIFont.familyNames {
            let fontNames = UIFont.fontNames(forFamilyName: family)
            for fontName in fontNames {
                let lowercased = fontName.lowercased()
                if lowercased.contains("dancingscript") {
                    return .custom(fontName, size: size)
                }
            }
        }
        
        // 如果找不到，尝试直接使用可能的名称
        let possibleNames = [
            "DancingScript-Regular",
            "DancingScript",
            "Dancing Script"
        ]
        
        for name in possibleNames {
            if UIFont(name: name, size: size) != nil {
                return .custom(name, size: size)
            }
        }
        
        // 如果都找不到，回退到系统字体
        return .system(size: size, design: .serif)
    }
    
    /// 智能字体：根据文本内容自动选择英文字体或中文字体
    /// - Parameters:
    ///   - text: 文本内容
    ///   - size: 字体大小
    /// - Returns: 合适的字体
    static func smartFont(for text: String, size: CGFloat) -> Font {
        // 检查文本是否包含中文字符
        let containsChinese = text.unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(scalar.value) || // 基本中文
            (0x3400...0x4DBF).contains(scalar.value) || // 扩展A
            (0x20000...0x2A6DF).contains(scalar.value)  // 扩展B
        }
        
        if containsChinese {
            return .qianTuBiFeng(size: size)
        } else {
            return .dancingScript(size: size)
        }
    }
}

