//
//  ImageCropView.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/15.
//

import SwiftUI

struct ImageCropView: View {
    let image: UIImage
    @Binding var croppedImage: UIImage?
    @Binding var isPresented: Bool

    @State private var containerSize: CGSize = .zero
    @State private var cropRect: CGRect = .zero

    // 预设裁切比例
    let aspectRatios = [
        "1:1": CGSize(width: 1, height: 1),
        "4:3": CGSize(width: 4, height: 3),
        "3:4": CGSize(width: 3, height: 4),
        "16:9": CGSize(width: 16, height: 9)
    ]
    @State private var selectedRatio: String = "1:1"

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)

                    // 图片显示区域（图片不缩放；通过调整裁切框大小来控制裁切区域）
                    let availableHeight = geometry.size.height * 0.70
                    let availableSize = CGSize(width: geometry.size.width, height: availableHeight)
                    let imgFrame = imageFrame(in: availableSize)

                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: availableSize.width, height: availableSize.height)
                            // .onAppear {
                            //     containerSize = availableSize
                            //     // 初始化裁切框（位于图片区域中间）
                            //     if cropRect == .zero {
                            //         cropRect = defaultCropRect(in: imgFrame)
                            //     } else {
                            //         cropRect = clampCropRect(cropRect, within: imgFrame)
                            //     }
                            // }

                        // 裁切遮罩 + 可交互裁切框（可拖动 + 拉伸四角，保持比例）
                        InteractiveCropOverlay(
                            cropRect: $cropRect,
                            containerSize: availableSize,
                            imageFrame: imgFrame,
                            aspectRatio: currentAspectRatio
                        )

                        // 关键修改：在布局确定后立即初始化裁切框，且只初始化一次
                        .onAppear {
                            if cropRect == .zero {
                                containerSize = availableSize
                                cropRect = defaultCropRect(in: imgFrame)
                            }
                        }
                        // 新增：监听布局变化，确保旋转等场景下裁切框位置正确
                        .onChange(of: availableSize) { oldValue, newValue in
                            if oldValue != newValue {
                                containerSize = newValue
                                cropRect = clampCropRect(cropRect, within: imageFrame(in: newValue))
                            }
                        }
                        // 提示文案
                        VStack {
                            Text("拖动裁切框移动，拖拽四角调整裁切范围")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.85))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(Color.black.opacity(0.35))
                                .cornerRadius(10)
                                .padding(.top, 12)
                            Spacer()
                        }
                        .frame(width: availableSize.width, height: availableSize.height)
                    }
                    .frame(width: availableSize.width, height: availableSize.height)
                    .position(x: geometry.size.width / 2, y: availableHeight / 2)

                    // 底部控制面板
                    VStack {
                        Spacer()

                        VStack(spacing: 16) {
                            // 比例选择器
                            HStack(spacing: 12) {
                                Text("裁切比例:")
                                    .foregroundColor(.white)
                                    .font(.subheadline)

                                ForEach(aspectRatios.keys.sorted(), id: \.self) { ratio in
                                    Button(action: {
                                        selectedRatio = ratio
                                        // 切换比例时，重置为默认裁切框（在图片区域内居中）
                                        let availableHeight = geometry.size.height * 0.70
                                        let availableSize = CGSize(width: geometry.size.width, height: availableHeight)
                                        let imgFrame = self.imageFrame(in: availableSize)
                                        cropRect = defaultCropRect(in: imgFrame)
                                    }) {
                                        Text(ratio)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedRatio == ratio ? Color.traditional.vermilion : Color.gray.opacity(0.3))
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                }
                            }

                            // 操作按钮
                            HStack(spacing: 20) {
                                Button(action: {
                                    isPresented = false
                                }) {
                                    Text("取消")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 100, height: 44)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(8)
                                }

                                Button(action: {
                                    performCrop()
                                }) {
                                    Text("确定")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 100, height: 44)
                                        .background(Color.traditional.vermilion)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 34)
                        .background(Color.black.opacity(0.8))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("裁切图片")
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Crop Math
    private var currentAspectRatio: CGFloat {
        let ratio = aspectRatios[selectedRatio] ?? CGSize(width: 1, height: 1)
        return ratio.width / ratio.height
    }

    private func aspectFitSize(image: CGSize, in container: CGSize) -> CGSize {
        guard image.width > 0, image.height > 0 else { return .zero }
        let scale = min(container.width / image.width, container.height / image.height)
        return CGSize(width: image.width * scale, height: image.height * scale)
    }

    private func imageFrame(in container: CGSize) -> CGRect {
        let base = aspectFitSize(image: image.size, in: container)
        let x = (container.width - base.width) / 2
        let y = (container.height - base.height) / 2
        return CGRect(x: x, y: y, width: base.width, height: base.height)
    }

    private func defaultCropRect(in imageFrame: CGRect) -> CGRect {
        let padding: CGFloat = 18
        let maxW = max(imageFrame.width - padding * 2, 40)
        let maxH = max(imageFrame.height - padding * 2, 40)

        var w = maxW
        var h = w / currentAspectRatio
        if h > maxH {
            h = maxH
            w = h * currentAspectRatio
        }

        let x = imageFrame.midX - w / 2
        let y = imageFrame.midY - h / 2
        return CGRect(x: x, y: y, width: w, height: h)
    }

    private func clampCropRect(_ rect: CGRect, within bounds: CGRect) -> CGRect {
        var r = rect
        r.size.width = min(max(r.size.width, 40), bounds.width)
        r.size.height = min(max(r.size.height, 40), bounds.height)
        r.origin.x = min(max(r.origin.x, bounds.minX), bounds.maxX - r.size.width)
        r.origin.y = min(max(r.origin.y, bounds.minY), bounds.maxY - r.size.height)
        return r
    }

    private func performCrop() {
        // containerSize 会在 onAppear 时设置；这里做兜底避免为 0
        let container = containerSize == .zero ? CGSize(width: 320, height: 320) : containerSize
        let imgFrame = imageFrame(in: container)
        let crop = clampCropRect(cropRect, within: imgFrame)

        // 将裁切框映射到原图像素坐标
        let scaleX = image.size.width / imgFrame.width
        let scaleY = image.size.height / imgFrame.height

        var cropInImage = CGRect(
            x: (crop.minX - imgFrame.minX) * scaleX,
            y: (crop.minY - imgFrame.minY) * scaleY,
            width: crop.width * scaleX,
            height: crop.height * scaleY
        )

        // 防御性裁剪，避免越界导致 CGImage crop 失败
        cropInImage = cropInImage.integral
        cropInImage.origin.x = max(cropInImage.origin.x, 0)
        cropInImage.origin.y = max(cropInImage.origin.y, 0)
        cropInImage.size.width = min(cropInImage.size.width, image.size.width - cropInImage.origin.x)
        cropInImage.size.height = min(cropInImage.size.height, image.size.height - cropInImage.origin.y)

        guard let cg = image.cgImage,
              let croppedCG = cg.cropping(to: cropInImage) else {
            // 兜底：至少返回原图，避免流程卡死
            self.croppedImage = image
            isPresented = false
            return
        }

        let result = UIImage(cgImage: croppedCG, scale: image.scale, orientation: image.imageOrientation)
        self.croppedImage = result
        isPresented = false
    }
}

// MARK: - Interactive Crop Overlay
struct InteractiveCropOverlay: View {
    @Binding var cropRect: CGRect
    let containerSize: CGSize
    let imageFrame: CGRect
    let aspectRatio: CGFloat

    @State private var lastDragOffset: CGSize = .zero
    @State private var lastRect: CGRect = .zero

    private let minSize: CGFloat = 80
    private let handleSize: CGFloat = 26

    var body: some View {
        ZStack {
            maskOverlay

            // 裁切框（可拖动）
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color.white, lineWidth: 2)
                .frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if lastRect == .zero { lastRect = cropRect }
                            let proposed = CGRect(
                                x: lastRect.minX + value.translation.width,
                                y: lastRect.minY + value.translation.height,
                                width: lastRect.width,
                                height: lastRect.height
                            )
                            cropRect = clampRect(proposed, within: imageFrame)
                        }
                        .onEnded { _ in
                            lastRect = .zero
                        }
                )

            GridLines(cropRect: cropRect)

            // 四角手柄（调整大小，保持比例）
            handle(at: .topLeft)
            handle(at: .topRight)
            handle(at: .bottomLeft)
            handle(at: .bottomRight)
        }
        .frame(width: containerSize.width, height: containerSize.height)
    }

    private var maskOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .frame(width: containerSize.width, height: max(cropRect.minY, 0))
                .position(x: containerSize.width / 2, y: max(cropRect.minY, 0) / 2)

            Color.black.opacity(0.55)
                .frame(width: containerSize.width, height: max(containerSize.height - cropRect.maxY, 0))
                .position(x: containerSize.width / 2, y: cropRect.maxY + max(containerSize.height - cropRect.maxY, 0) / 2)

            Color.black.opacity(0.55)
                .frame(width: max(cropRect.minX, 0), height: cropRect.height)
                .position(x: max(cropRect.minX, 0) / 2, y: cropRect.midY)

            Color.black.opacity(0.55)
                .frame(width: max(containerSize.width - cropRect.maxX, 0), height: cropRect.height)
                .position(x: cropRect.maxX + max(containerSize.width - cropRect.maxX, 0) / 2, y: cropRect.midY)
        }
    }

    private enum Corner { case topLeft, topRight, bottomLeft, bottomRight }

    @ViewBuilder
    private func handle(at corner: Corner) -> some View {
        let pos = cornerPosition(corner)
        Circle()
            .fill(Color.traditional.vermilion)
            .frame(width: handleSize, height: handleSize)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .position(pos)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if lastRect == .zero { lastRect = cropRect }
                        let proposed = resizedRect(from: lastRect, corner: corner, translation: value.translation)
                        cropRect = clampRect(proposed, within: imageFrame)
                    }
                    .onEnded { _ in
                        lastRect = .zero
                    }
            )
    }

    private func cornerPosition(_ corner: Corner) -> CGPoint {
        switch corner {
        case .topLeft: return CGPoint(x: cropRect.minX, y: cropRect.minY)
        case .topRight: return CGPoint(x: cropRect.maxX, y: cropRect.minY)
        case .bottomLeft: return CGPoint(x: cropRect.minX, y: cropRect.maxY)
        case .bottomRight: return CGPoint(x: cropRect.maxX, y: cropRect.maxY)
        }
    }

    private func resizedRect(from rect: CGRect, corner: Corner, translation: CGSize) -> CGRect {
        // 以对角点为锚点，拖动当前角改变宽高；保持比例
        let ar = max(aspectRatio, 0.0001)

        var anchor: CGPoint
        var moving: CGPoint
        switch corner {
        case .topLeft:
            anchor = CGPoint(x: rect.maxX, y: rect.maxY)
            moving = CGPoint(x: rect.minX + translation.width, y: rect.minY + translation.height)
        case .topRight:
            anchor = CGPoint(x: rect.minX, y: rect.maxY)
            moving = CGPoint(x: rect.maxX + translation.width, y: rect.minY + translation.height)
        case .bottomLeft:
            anchor = CGPoint(x: rect.maxX, y: rect.minY)
            moving = CGPoint(x: rect.minX + translation.width, y: rect.maxY + translation.height)
        case .bottomRight:
            anchor = CGPoint(x: rect.minX, y: rect.minY)
            moving = CGPoint(x: rect.maxX + translation.width, y: rect.maxY + translation.height)
        }

        // 先根据 x 方向推导宽，再按比例算高
        var width = abs(moving.x - anchor.x)
        width = max(width, minSize)
        var height = width / ar
        height = max(height, minSize / ar)

        // 如果 y 方向拖动更大，则反过来用 y 推导
        let widthByY = abs(moving.y - anchor.y) * ar
        if widthByY > width {
            width = max(widthByY, minSize)
            height = width / ar
        }

        // 根据锚点位置生成新的 rect
        let minX = min(anchor.x, anchor.x + (corner == .topLeft || corner == .bottomLeft ? -width : width))
        let minY = min(anchor.y, anchor.y + (corner == .topLeft || corner == .topRight ? -height : height))
        return CGRect(x: minX, y: minY, width: width, height: height)
    }

    private func clampRect(_ rect: CGRect, within bounds: CGRect) -> CGRect {
        var r = rect
        r.size.width = min(max(r.size.width, minSize), bounds.width)
        r.size.height = min(max(r.size.height, minSize), bounds.height)
        r.origin.x = min(max(r.origin.x, bounds.minX), bounds.maxX - r.size.width)
        r.origin.y = min(max(r.origin.y, bounds.minY), bounds.maxY - r.size.height)
        return r
    }
}

struct CornerIndicator: View {
    var body: some View {
        Circle()
            .fill(Color.traditional.vermilion)
            .frame(width: 12, height: 12)
    }
}

struct GridLines: View {
    let cropRect: CGRect

    var body: some View {
        ZStack {
            // 垂直线
            ForEach(1..<3) { index in
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 1, height: cropRect.height)
                    .position(x: cropRect.minX + cropRect.width * CGFloat(index) / 3, y: cropRect.midY)
            }

            // 水平线
            ForEach(1..<3) { index in
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: cropRect.width, height: 1)
                    .position(x: cropRect.midX, y: cropRect.minY + cropRect.height * CGFloat(index) / 3)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    if let image = UIImage(systemName: "photo") {
        ImageCropView(image: image, croppedImage: .constant(nil), isPresented: .constant(true))
    } else {
        Text("Preview not available")
    }
}
