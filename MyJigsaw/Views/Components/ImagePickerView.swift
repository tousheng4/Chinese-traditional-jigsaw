//
//  ImagePickerView.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/15.
//

import SwiftUI
import PhotosUI

struct ImagePickerView: View {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("选择图片")
                    .font(.title2)
                    .padding(.top)

                Text("从相册中选择一张图片来创建拼图")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.traditional.vermilion)

                        Text("从相册选择")
                            .font(.headline)
                            .foregroundColor(.traditional.ink)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color.traditional.lightGray)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
            .onChange(of: selectedItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ImagePickerView(selectedImage: .constant(nil), isPresented: .constant(true))
}
