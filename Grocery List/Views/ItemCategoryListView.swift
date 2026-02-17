//
//  ItemCategoryListView.swift
//  Grocery List
//
//  Created by Moksh Bisht on 17/02/2026.
//

import SwiftUI

struct ItemCategoryListView: View {

    let items: [Item]
    @Binding var expandedCategories: Set<ItemCategory>
    let sortOption: SortOption
    let isHidingCompleted: Bool
    let onDelete: (Item) -> Void
    let onToggleCompleted: (Item) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        List {
            ForEach(ItemCategory.allCases) { category in
                let categoryItems = sortedItems(for: category)
                if !categoryItems.isEmpty {
                    Section {
                        DisclosureGroup(
                            isExpanded: categoryExpandedBinding(for: category)
                        ) {
                            ForEach(categoryItems) { item in
                                itemRow(for: item, category: category)
                            }
                        } label: {
                            categoryHeader(for: category, count: categoryItems.count)
                        }
                        .listRowBackground(categoryBackgroundColor(for: category))
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                }
            }
        }
        .listSectionSpacing(12)
        .animation(.snappy, value: expandedCategories)
    }

    private func itemRow(for item: Item, category: ItemCategory) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.body)
                .foregroundStyle(item.isCompleted ? .secondary : .primary)
                .strikethrough(item.isCompleted)
                .italic(item.isCompleted)

            if !item.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(item.notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .listRowSeparator(.hidden)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(categoryBackgroundColor(for: category))
        )
        .swipeActions {
            Button(role: .destructive) {
                onDelete(item)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(.red)
                            .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                    )
            }
            .buttonStyle(.plain)
            .tint(.clear)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(
                item.isCompleted ? "Undo" : "Done",
                systemImage: item.isCompleted ? "xmark.circle" : "checkmark.circle"
            ) {
                onToggleCompleted(item)
            }
            .buttonStyle(.plain)
            .tint(.clear)
            .labelStyle(.iconOnly)
            .overlay {
                Circle()
                    .fill(item.isCompleted ? Color.accentColor : .green)
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                    .frame(width: 40, height: 40)
            }
            .frame(width: 40, height: 40)
            .foregroundStyle(.white)
        }
    }

    private func categoryHeader(for category: ItemCategory, count: Int) -> some View {
        HStack(spacing: 10) {
            Text(category.rawValue)
                .font(.title3.weight(.semibold))
            Spacer()
            Text("\(count)")
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }

    private func categoryExpandedBinding(for category: ItemCategory) -> Binding<Bool> {
        Binding(
            get: { expandedCategories.contains(category) },
            set: { isExpanded in
                if isExpanded {
                    expandedCategories.insert(category)
                } else {
                    expandedCategories.remove(category)
                }
            }
        )
    }

    private func categoryBackgroundColor(for category: ItemCategory) -> Color {
        let baseColor = category.color
        return colorScheme == .dark ? baseColor.opacity(0.32) : baseColor.opacity(0.18)
    }

    private func sortedItems(for category: ItemCategory) -> [Item] {
        let baseItems = items.filter { $0.itemCategory == category }
        let visibleItems = isHidingCompleted ? baseItems.filter { !$0.isCompleted } : baseItems

        switch sortOption {
        case .name:
            return visibleItems.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .dateAdded:
            return visibleItems.sorted { $0.dateAdded < $1.dateAdded }
        }
    }
}
