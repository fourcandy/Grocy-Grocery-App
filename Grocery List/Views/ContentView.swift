//
//  ContentView.swift
//  Grocery List
//
//  Created by Moksh Bisht on 07/04/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var item: String = ""
    @State private var notes: String = ""
    @State private var isAddSheetPresented: Bool = false
    @State private var selectedCategory: ItemCategory = .fruitAndVeg
    @State private var expandedCategories: Set<ItemCategory> = Set(ItemCategory.allCases)
    @State private var sortOption: SortOption = .dateAdded
    @State private var isHidingCompleted: Bool = false
    
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    
    
    var body: some View {
        NavigationStack {
            listView
                .navigationTitle("Grocery List")
                .toolbar { toolbarContent }
                .overlay { emptyStateOverlay }
                .sheet(isPresented: $isAddSheetPresented) {
                    AddItemSheetView(
                        item: $item,
                        notes: $notes,
                        category: $selectedCategory,
                        onSave: addItem,
                        onCancel: resetItemInput
                    )
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
        }
    }
    
    private var listView: some View {
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
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Section("Sort") {
                    Button {
                        withAnimation(.snappy) {
                            sortOption = .name
                        }
                    } label: {
                        Label("Name", systemImage: "textformat")
                    }
                    
                    Button {
                        withAnimation(.snappy) {
                            sortOption = .dateAdded
                        }
                    } label: {
                        Label("Date added", systemImage: "calendar")
                    }
                }
                
                Section("Filter") {
                    Button {
                        withAnimation(.snappy) {
                            isHidingCompleted.toggle()
                        }
                    } label: {
                        Label(
                            "Hide completed items",
                            systemImage: isHidingCompleted ? "checkmark.circle.fill" : "circle"
                        )
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        deleteCompletedItems()
                    } label: {
                        Label("Delete completed items", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isAddSheetPresented = true
            } label: {
                Image(systemName: "plus")
            }
        }
        
    }
    
    @ViewBuilder
    private var emptyStateOverlay: some View {
        if items.isEmpty {
            ContentUnavailableView(
                "Empty List",
                systemImage: "cart.circle",
                description: Text("Add whatever you want to buy here!")
            )
        }
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
        .padding(.vertical, 2)
        .listRowBackground(categoryBackgroundColor(for: category))
        .swipeActions {
            Button(role: .destructive) {
                deleteItem(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button(
                item.isCompleted ? "Undo" : "Done",
                systemImage: item.isCompleted ? "xmark.circle" : "checkmark.circle"
            ) {
                toggleItemCompletion(item)
            }
            .tint(item.isCompleted ? .accentColor : .green)
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
    
    private func addItem() {
        guard !item.isEmpty else { return }
        modelContext.insert(
            Item(title: item, notes: notes, isCompleted: false, category: selectedCategory)
        )
        resetItemInput()
        isAddSheetPresented = false
    }
    
    private func resetItemInput() {
        item = ""
        notes = ""
        isFocused = false
        selectedCategory = .fruitAndVeg
    }
    
    private func deleteItem(_ item: Item) {
        withAnimation {
            modelContext.delete(item)
        }
    }
    
    private func toggleItemCompletion(_ item: Item) {
        item.isCompleted.toggle()
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
    
    private func deleteCompletedItems() {
        for item in items where item.isCompleted {
            modelContext.delete(item)
        }
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case name = "Name"
    case dateAdded = "Date Added"
    
    var id: String { rawValue }
}

#Preview("Sample Data") {
    let sampleData: [Item] = [
        Item(title: "Bananas", notes: "Ripe ones for smoothies.", isCompleted: false, category: .fruitAndVeg),
        Item(title: "Baby spinach", notes: "Pre-washed, 2 bags.", isCompleted: false, category: .fruitAndVeg),
        Item(title: "Greek yogurt", notes: "Plain, 5% fat.", isCompleted: false, category: .dairyAndEggs),
        Item(title: "Free-range eggs", notes: "One dozen.", isCompleted: true, category: .dairyAndEggs),
        Item(title: "Chicken thighs", notes: "Bone-in, skin-on.", isCompleted: false, category: .meatAndSeafood),
        Item(title: "Sourdough loaf", notes: "Slice on arrival.", isCompleted: true, category: .bakeryAndBread),
        Item(title: "Pasta", notes: "Rigatoni, 2 packs.", isCompleted: false, category: .pantry),
        Item(title: "Olive oil", notes: "Extra virgin, 1L.", isCompleted: false, category: .pantry),
        Item(title: "Kettle chips", notes: "Sea salt.", isCompleted: false, category: .snacks),
        Item(title: "Dish soap", notes: "Lemon scent.", isCompleted: false, category: .household),
        Item(title: "Aluminum foil", notes: "Heavy duty.", isCompleted: false, category: .household),
        Item(title: "Birthday card", notes: "Any design.", isCompleted: false, category: .other)
    ]
    
    let container = try! ModelContainer(for: Item.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    
    for item in sampleData {
        container.mainContext.insert(item)
    }
    
    return ContentView()
        .modelContainer(container)
}

#Preview("Empty List") {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
