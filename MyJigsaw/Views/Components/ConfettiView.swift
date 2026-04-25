//
//  ConfettiView.swift
//  MyJigsaw
//

import SwiftUI

struct ConfettiView: View {
    struct Particle {
        let color: Color
        let vx, vy: CGFloat  // px/s（vy 负 = 向上）
        let w, h: CGFloat
        let rot0, rotV: CGFloat  // 初始角 & 旋转速度 (rad/s)
        let delay: CGFloat
    }

    let origin: CGPoint
    private let lifetime: CGFloat = 2.6
    private let gravity:  CGFloat = 480

    // @State 让粒子和起始时间只在首次插入时初始化
    @State private var startDate: Date = Date()
    @State private var particles: [Particle] = ConfettiView.makeParticles()

    static func makeParticles() -> [Particle] {
        let palette: [Color] = [
            Color(red: 0.93, green: 0.22, blue: 0.22),
            Color(red: 0.96, green: 0.68, blue: 0.10),
            Color(red: 0.20, green: 0.72, blue: 0.40),
            Color(red: 0.22, green: 0.50, blue: 0.96),
            Color(red: 0.94, green: 0.38, blue: 0.78),
            Color(red: 0.98, green: 0.88, blue: 0.20),
            Color(red: 0.38, green: 0.82, blue: 0.96),
            Color(red: 0.62, green: 0.28, blue: 0.94),
        ]
        return (0..<90).map { _ in
            let angle = CGFloat.random(in: -.pi ..< .pi)
            let speed = CGFloat.random(in: 160 ... 620)
            return Particle(
                color: palette.randomElement()!,
                vx:    cos(angle) * speed,
                vy:    sin(angle) * speed - CGFloat.random(in: 60 ... 200),
                w:     CGFloat.random(in: 5 ... 11),
                h:     CGFloat.random(in: 12 ... 28),
                rot0:  CGFloat.random(in: 0 ..< 2 * .pi),
                rotV:  CGFloat.random(in: -9 ... 9),
                delay: CGFloat.random(in: 0 ... 0.25)
            )
        }
    }

    var body: some View {
        // TimelineView 保证每帧都调用 content closure，Canvas 每帧重绘
        TimelineView(.animation) { context in
            let t = CGFloat(context.date.timeIntervalSince(startDate))
            Canvas { ctx, _ in
                for p in particles {
                    let dt = max(0, t - p.delay)
                    guard dt > 0 else { continue }
                    let alpha = max(0.0, Double(1.0 - dt / lifetime))
                    guard alpha > 0 else { continue }

                    let x   = origin.x + p.vx * dt
                    let y   = origin.y + p.vy * dt + 0.5 * gravity * dt * dt
                    let rot = Double(p.rot0 + p.rotV * dt)
                    let tf  = CGAffineTransform(translationX: x, y: y).rotated(by: rot)
                    let rect = CGRect(x: -p.w / 2, y: -p.h / 2, width: p.w, height: p.h)
                    ctx.fill(Path(rect).applying(tf), with: .color(p.color.opacity(alpha)))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
}
