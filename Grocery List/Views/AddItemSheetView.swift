//
//  AddItemSheetView.swift
//  Grocery List
//
//  Created by Moksh Bisht on 07/04/2025.
//

import SwiftUI

struct AddItemSheetView: View {
    
    @Binding var item: String
    @Binding var notes: String
    @Binding var category: ItemCategory
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            GlassEffectContainer(spacing: 16) {
                VStack(spacing: 12) {
                    TextField("Item name", text: $item)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .padding(.leading, 15)
                        .padding(.trailing, 15)
                        .font(.title.weight(.light))
                        .focused($isFocused)
                        .glassEffect(in: .rect(cornerRadius: 16))
                    
                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases) { category in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 8, height: 8)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(2, reservesSpace: true)
                        .padding(10)
                        .padding(.leading, 15)
                        .padding(.trailing, 15)
                        .font(.body)
                        .glassEffect(in: .rect(cornerRadius: 16))
                    
                    Button {
                        onSave()
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.title2.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(category.color)
                    .disabled(item.isEmpty)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding()
            .navigationTitle("New Item")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}
