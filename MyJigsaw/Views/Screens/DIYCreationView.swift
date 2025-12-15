//
//  DIYCreationView.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/15.
//

import SwiftUI
import PhotosUI

enum CreationStep {
    case selectImage
    case cropImage
    case configurePuzzle
    case preview
}

struct DIYCreationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var ugcManager = UGCManager.shared

    // 流程状态
    @State private var currentStep: CreationStep = .selectImage
    @State private var selectedImage: UIImage?
    @State private var croppedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?

    // 配置参数
    @State private var puzzleTitle: String = ""
    @State private var gridSize: Int = 4
    @State private var selectedDifficulty: PuzzleDifficulty = .standard

    // UI 状态
    @State private var showCropView = false
    @State private var isCreating = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.traditional.paper.ignoresSafeArea()

                VStack(spacing: 0) {
                    // 步骤指示器
                    StepIndicator(currentStep: currentStep)
                        .padding(.top)

                    // 主要内容区域
                    ScrollView {
                        VStack(spacing: 20) {
                            stepContent
                        }
                        .padding()
                    }

                    // 底部操作按钮
                    bottomButtons
                }
            }
            .navigationTitle("创建拼图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCropView) {
                if let image = selectedImage {
                    ImageCropView(image: image, croppedImage: $croppedImage, isPresented: $showCropView)
                }
            }
            // 裁切完成后：用裁切结果覆盖 selectedImage，确保流程页立即展示裁切后的画面
            .onChange(of: croppedImage) { _, newValue in
                if let newValue {
                    selectedImage = newValue
                }
            }
            // 相册选图：直接用 PhotosPicker，避免“点两次”的多余层
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            selectedImage = uiImage
                            croppedImage = nil
                            // 默认标题（用户可改）
                            if puzzleTitle.isEmpty {
                                puzzleTitle = "我的拼图 \(Date().formatted(.dateTime.year().month().day().hour().minute()))"
                            }
                        }
                    }
                }
            }
            .alert("创建成功", isPresented: $showSuccessAlert) {
                Button("开始游戏") {
                    // TODO: 跳转到游戏
                    dismiss()
                }
                Button("继续创建") {
                    resetFlow()
                }
            } message: {
                Text("你的自制拼图已创建成功！")
            }
            .alert("创建失败", isPresented: $showErrorAlert) {
                Button("知道了", role: .cancel) { }
            } message: {
                Text(errorMessage.isEmpty ? "图片处理或保存失败，请重试。" : errorMessage)
            }
            .overlay {
                if isCreating {
                    ProgressView("正在创建...")
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
        }
    }

    // MARK: - Step Content
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .selectImage:
            SelectImageStep(selectedImage: selectedImage, selectedPhotoItem: $selectedPhotoItem)
        case .cropImage:
            CropImageStep(image: croppedImage ?? selectedImage)
        case .configurePuzzle:
            ConfigurePuzzleStep(
                title: $puzzleTitle,
                gridSize: $gridSize,
                difficulty: $selectedDifficulty
            )
        case .preview:
            PreviewStep(image: croppedImage, config: currentConfig)
        }
    }

    // MARK: - Bottom Buttons
    private var bottomButtons: some View {
        HStack(spacing: 20) {
            if currentStep != .selectImage {
                Button(action: goToPreviousStep) {
                    Text("上一步")
                        .font(.qianTuBiFeng(size: 17))
                        .foregroundColor(.traditional.ink)
                        .frame(width: 100, height: 44)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                }
            }

            Button(action: handleNextAction) {
                Text(buttonTitle)
                    .font(.qianTuBiFeng(size: 17))
                    .foregroundColor(.white)
                    .frame(width: 120, height: 44)
                    .background(Color.traditional.vermilion)
                    .cornerRadius(8)
            }
            .disabled(!canProceedToNextStep)
        }
        .padding(.horizontal)
        .padding(.bottom, 34)
        .background(Color.white.opacity(0.9))
    }

    // MARK: - Helper Properties
    private var buttonTitle: String {
        switch currentStep {
        case .preview: return "创建拼图"
        default: return "下一步"
        }
    }

    private var canProceedToNextStep: Bool {
        switch currentStep {
        case .selectImage: return selectedImage != nil
        case .cropImage: return croppedImage != nil
        case .configurePuzzle: return !puzzleTitle.isEmpty
        case .preview: return true
        }
    }

    private var currentConfig: PuzzleConfig {
        PuzzleConfig(gridSize: gridSize)
    }

    // MARK: - Actions
    private func goToPreviousStep() {
        switch currentStep {
        case .cropImage: currentStep = .selectImage
        case .configurePuzzle: currentStep = .cropImage
        case .preview: currentStep = .configurePuzzle
        default: break
        }
    }

    private func handleNextAction() {
        switch currentStep {
        case .selectImage:
            if selectedImage != nil {
                currentStep = .cropImage
                showCropView = true
            }
        case .cropImage:
            if croppedImage != nil {
                currentStep = .configurePuzzle
            }
        case .configurePuzzle:
            currentStep = .preview
        case .preview:
            createPuzzle()
        }
    }

    private func createPuzzle() {
        guard let image = croppedImage else { return }

        isCreating = true

        Task {
            do {
                let config = PuzzleConfig(gridSize: gridSize)
                let _ = try await ugcManager.createUGCPuzzle(
                    title: puzzleTitle,
                    image: image,
                    config: config
                )

                await MainActor.run {
                    isCreating = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = "\(error)"
                    showErrorAlert = true
                }
            }
        }
    }

    private func resetFlow() {
        currentStep = .selectImage
        selectedImage = nil
        croppedImage = nil
        puzzleTitle = ""
        gridSize = 4
        selectedDifficulty = .standard
    }
}

// MARK: - Step Indicator
struct StepIndicator: View {
    let currentStep: CreationStep

    var steps: [CreationStep] = [.selectImage, .cropImage, .configurePuzzle, .preview]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                let step = steps[index]
                let isCompleted = stepIndex(step) < stepIndex(currentStep)
                let isCurrent = step == currentStep

                Circle()
                    .fill(circleColor(isCompleted: isCompleted, isCurrent: isCurrent))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("\(index + 1)")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                    )

                if index < steps.count - 1 {
                    Rectangle()
                        .fill(lineColor(for: index))
                        .frame(height: 2)
                        .frame(maxWidth: 40)
                }
            }
        }
        .padding(.horizontal)
    }

    private func stepIndex(_ step: CreationStep) -> Int {
        steps.firstIndex(of: step) ?? 0
    }

    private func circleColor(isCompleted: Bool, isCurrent: Bool) -> Color {
        if isCompleted {
            return .traditional.vermilion
        } else if isCurrent {
            return .traditional.ocher
        } else {
            return .gray.opacity(0.3)
        }
    }

    private func lineColor(for index: Int) -> Color {
        if index < stepIndex(currentStep) - 1 {
            return .traditional.vermilion
        } else {
            return .gray.opacity(0.3)
        }
    }
}

// MARK: - Step Content Views
struct SelectImageStep: View {
    let selectedImage: UIImage?
    @Binding var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 20) {
            Text("选择图片")
                .font(.qianTuBiFeng(size: 22))
                .foregroundColor(.traditional.ink)

            Text("从相册中选择一张你喜欢的图片")
                .font(.qianTuBiFeng(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 16) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("未选择图片")
                                .font(.qianTuBiFeng(size: 15))
                                .foregroundColor(.gray)
                        }
                    )
            }

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.headline)
                    Text("从相册选择")
                        .font(.qianTuBiFeng(size: 17))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.traditional.vermilion)
                .cornerRadius(12)
            }
        }
    }
}

struct CropImageStep: View {
    let image: UIImage?

    var body: some View {
        VStack(spacing: 20) {
            Text("裁切图片")
                .font(.qianTuBiFeng(size: 22))
                .foregroundColor(.traditional.ink)

            Text("调整图片构图，确定拼图区域")
                .font(.qianTuBiFeng(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            }
        }
    }
}

struct ConfigurePuzzleStep: View {
    @Binding var title: String
    @Binding var gridSize: Int
    @Binding var difficulty: PuzzleDifficulty

    var body: some View {
        VStack(spacing: 20) {
            Text("配置拼图")
                .font(.qianTuBiFeng(size: 22))
                .foregroundColor(.traditional.ink)

            VStack(spacing: 16) {
                // 标题输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("拼图标题")
                        .font(.qianTuBiFeng(size: 17))
                        .foregroundColor(.traditional.ink)

                    TextField("输入拼图标题", text: $title)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 2)
                }

                // 难度选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("拼图难度")
                        .font(.qianTuBiFeng(size: 17))
                        .foregroundColor(.traditional.ink)

                    Picker("难度", selection: $difficulty) {
                        Text("简单 (3×3)").tag(PuzzleDifficulty.easy)
                        Text("标准 (4×4)").tag(PuzzleDifficulty.standard)
                        Text("困难 (6×6)").tag(PuzzleDifficulty.hard)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: difficulty) { _, newValue in
                        gridSize = newValue.gridSize
                    }
                }

                // 预览信息
                VStack(alignment: .leading, spacing: 8) {
                    Text("预览信息")
                        .font(.qianTuBiFeng(size: 17))
                        .foregroundColor(.traditional.ink)

                    HStack {
                        Text("网格大小:")
                        Spacer()
                        Text("\(gridSize)×\(gridSize)")
                            .foregroundColor(.traditional.vermilion)
                    }

                    HStack {
                        Text("拼图块数:")
                        Spacer()
                        Text("\(gridSize * gridSize)")
                            .foregroundColor(.traditional.vermilion)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(8)
            }
        }
    }
}

struct PreviewStep: View {
    let image: UIImage?
    let config: PuzzleConfig

    var body: some View {
        VStack(spacing: 20) {
            Text("预览拼图")
                .font(.qianTuBiFeng(size: 22))
                .foregroundColor(.traditional.ink)

            Text("确认拼图配置，准备创建")
                .font(.qianTuBiFeng(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            }

            // 配置摘要
            VStack(alignment: .leading, spacing: 12) {
                Text("配置摘要")
                    .font(.qianTuBiFeng(size: 17))
                    .foregroundColor(.traditional.ink)

                HStack {
                    Text("网格大小:")
                    Spacer()
                    Text("\(config.gridSize)×\(config.gridSize)")
                        .foregroundColor(.traditional.vermilion)
                }

                HStack {
                    Text("拼图块数:")
                    Spacer()
                    Text("\(config.gridSize * config.gridSize)")
                        .foregroundColor(.traditional.vermilion)
                }

                HStack {
                    Text("允许旋转:")
                    Spacer()
                    Text(config.allowRotation ? "是" : "否")
                        .foregroundColor(config.allowRotation ? .green : .gray)
                }

                HStack {
                    Text("打乱模式:")
                    Spacer()
                    Text(config.shuffleMode.rawValue)
                        .foregroundColor(.traditional.ocher)
                }
            }
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview
#Preview {
    DIYCreationView()
}
