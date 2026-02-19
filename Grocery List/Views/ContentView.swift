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
    @State private var expandedCategories: Set<ItemCategory> = Set(
        ItemCategory.allCases
    )
    @State private var sortOption: SortOption = .dateAdded
    @State private var isHidingCompleted: Bool = false
    @State private var pendingHideItems: Set<ObjectIdentifier> = []
    @State private var isConfirmingDeleteCompleted: Bool = false
    @State private var editingItem: Item? = nil
    
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    private var hasCompletedItems: Bool {
        items.contains(where: { $0.isCompleted })
    }
    
    var body: some View {
        NavigationStack {
            listView
                .navigationTitle("Grocery List")
                .toolbar { toolbarContent }
                .overlay { emptyStateOverlay }
                .sheet(isPresented: $isAddSheetPresented) {
                    NavigationStack {
                        AddItemSheetView(
                            item: $item,
                            notes: $notes,
                            category: $selectedCategory,
                            onSave: addItem,
                            onCancel: resetItemInput,
                            title: "New Item"
                        )
                        .navigationTitle("New Item")
                        .navigationBarTitleDisplayMode(.inline)
                    }
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
                .alert("Delete compleated items?", isPresented: $isConfirmingDeleteCompleted, actions: {
                    Button("Delete", role: .destructive) {
                        deleteCompletedItems()
                    }
                    Button("Cancel", role: .cancel) { }
                }, message: {
                    Text("This will permanently delete all completed items.")
                }
                )
                .sheet(item: $editingItem, onDismiss: {
                    resetItemInput()
                }) { itemToEdit in
                    NavigationStack {
                        AddItemSheetView(
                            item: Binding(
                                get: { item },
                                set: { item = $0 }
                            ),
                            notes: Binding(
                                get: { notes },
                                set: { notes = $0 }
                            ),
                            category: Binding(
                                get: { selectedCategory },
                                set: { selectedCategory = $0 }
                            ),
                            onSave: {
                                updateEditingItem()
                            },
                            onCancel: {
                                resetItemInput()
                                editingItem = nil
                            },
                            title: "Edit Item"
                        )
                        .onAppear {
                            // Prefill the editing buffers with the item's existing values
                            item = itemToEdit.title
                            notes = itemToEdit.notes
                            selectedCategory = itemToEdit.itemCategory
                        }
                        .navigationTitle("Edit Item")
                        .navigationBarTitleDisplayMode(.inline)
                    }
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
                            categoryHeader(
                                for: category,
                                count: categoryItems.count
                            )
                        }
                        .listRowBackground(
                            categoryBackgroundColor(for: category)
                        )
                    }
                    .listRowInsets(
                        EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
                    )
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
                        isConfirmingDeleteCompleted = true
                    } label: {
                        Label("Delete completed items", systemImage: "trash")
                    }
                    .disabled(!hasCompletedItems)
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                resetItemInput()
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

    private var squeezeOutTransition: AnyTransition {
        .asymmetric(
            insertion: .identity,
            removal: .modifier(
                active: SqueezeOutModifier(scaleY: 0.01, opacity: 0.0),
                identity: SqueezeOutModifier(scaleY: 1.0, opacity: 1.0)
            )
        )
    }

    private func itemRow(for item: Item, category: ItemCategory) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.body)
                .foregroundStyle(item.isCompleted ? .secondary : .primary)
                .strikethrough(item.isCompleted)
                .italic(item.isCompleted)

            if !item.notes
                .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(item.notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
        .listRowBackground(categoryBackgroundColor(for: category))
        .transition(squeezeOutTransition)
        .swipeActions {
            Button(role: .destructive) {
                deleteItem(item)
            } label: {
                Label("", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button(
                "",
                systemImage: item.isCompleted ? "xmark.circle" : "checkmark.circle"
            ) {
                toggleItemCompletion(item)
            }
            .tint(item.isCompleted ? .accentColor : .green)
            
            
            Button {
                beginEditing(item)
            } label: {
                Label("", systemImage: "pencil")
            }
            .tint(.blue)
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
        return colorScheme == .dark ? baseColor
            .opacity(0.32) : baseColor
            .opacity(0.18)
    }
    
    private func addItem() {
        guard !item.isEmpty else { return }
        modelContext.insert(
            Item(
                title: item,
                notes: notes,
                isCompleted: false,
                category: selectedCategory
            )
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
    
    private func beginEditing(_ item: Item) {
        editingItem = item
        // Prefill occurs in the sheet's onAppear
    }

    private func updateEditingItem() {
        guard let editingItem else { return }
        // Apply edits to the model object
        editingItem.title = item
        editingItem.notes = notes
        editingItem.itemCategory = selectedCategory
        // Reset edit state
        resetItemInput()
        self.editingItem = nil
    }
    
    private func toggleItemCompletion(_ item: Item) {
        if item.isCompleted {
            pendingHideItems.remove(ObjectIdentifier(item))
            item.isCompleted.toggle()
            return
        }

        item.isCompleted.toggle()

        if isHidingCompleted {
            let itemIdentifier = ObjectIdentifier(item)
            pendingHideItems.insert(itemIdentifier)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if pendingHideItems.contains(itemIdentifier) {
                    withAnimation(.snappy) {
                        pendingHideItems.remove(itemIdentifier)
                    }
                }
            }
        }
    }
    
    private func sortedItems(for category: ItemCategory) -> [Item] {
        let baseItems = items.filter { $0.itemCategory == category }
        let visibleItems = isHidingCompleted
        ? baseItems
            .filter {
                !$0.isCompleted || pendingHideItems
                    .contains(ObjectIdentifier($0))
            }
        : baseItems

        switch sortOption {
        case .name:
            return visibleItems
                .sorted {
                    $0.title
                        .localizedCaseInsensitiveCompare(
                            $1.title
                        ) == .orderedAscending
                }
        case .dateAdded:
            return visibleItems.sorted { $0.dateAdded < $1.dateAdded }
        }
    }
    
    private struct SqueezeOutModifier: ViewModifier {
        let scaleY: CGFloat
        let opacity: Double

        func body(content: Content) -> some View {
            content
                .scaleEffect(x: 1.0, y: scaleY, anchor: .center)
                .opacity(opacity)
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
        Item(
            title: "Bananas",
            notes: "Ripe ones for smoothies.",
            isCompleted: false,
            category: .fruitAndVeg
        ),
        Item(
            title: "Baby spinach",
            notes: "Pre-washed, 2 bags.",
            isCompleted: false,
            category: .fruitAndVeg
        ),
        Item(
            title: "Greek yogurt",
            notes: "Plain, 5% fat.",
            isCompleted: false,
            category: .dairyAndEggs
        ),
        Item(
            title: "Free-range eggs",
            notes: "One dozen.",
            isCompleted: true,
            category: .dairyAndEggs
        ),
        Item(
            title: "Chicken thighs",
            notes: "Bone-in, skin-on.",
            isCompleted: false,
            category: .meatAndSeafood
        ),
        Item(
            title: "Sourdough loaf",
            notes: "Slice on arrival.",
            isCompleted: true,
            category: .bakeryAndBread
        ),
        Item(
            title: "Pasta",
            notes: "Rigatoni, 2 packs.",
            isCompleted: false,
            category: .pantry
        ),
        Item(
            title: "Olive oil",
            notes: "Extra virgin, 1L.",
            isCompleted: false,
            category: .pantry
        ),
        Item(
            title: "Kettle chips",
            notes: "Sea salt.",
            isCompleted: false,
            category: .snacks
        ),
        Item(
            title: "Dish soap",
            notes: "Lemon scent.",
            isCompleted: false,
            category: .household
        ),
        Item(
            title: "Aluminum foil",
            notes: "Heavy duty.",
            isCompleted: false,
            category: .household
        ),
        Item(
            title: "Birthday card",
            notes: "Any design.",
            isCompleted: false,
            category: .other
        )
    ]
    
    let container = try! ModelContainer(
        for: Item.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
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

