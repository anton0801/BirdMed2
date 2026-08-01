import SwiftUI

struct NotesView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAddNote = false
    @State private var selected: BirdNote? = nil
    @State private var filterGroupId: UUID? = nil

    var displayed: [BirdNote] {
        guard let gid = filterGroupId else { return store.notes }
        return store.notes.filter { $0.groupId == gid }
    }

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Group filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        NotesFilterChip(label: "All", isSelected: filterGroupId == nil) {
                            withAnimation(.appSpring) { filterGroupId = nil }
                        }
                        ForEach(store.birdGroups) { g in
                            NotesFilterChip(label: "\(g.type.emoji) \(g.name)",
                                           isSelected: filterGroupId == g.id) {
                                withAnimation(.appSpring) {
                                    filterGroupId = filterGroupId == g.id ? nil : g.id
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                if displayed.isEmpty {
                    EmptyStateView(icon: "note.text", title: "No notes yet",
                                   message: "Record observations, symptoms, and photos for your flock.")
                        .padding(.top, 40)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(displayed) { note in
                            NoteCard(note: note)
                                .onTapGesture { selected = note }
                        }
                    }
                    .padding(.horizontal, 16)
                }

            }
            .padding(.top, 16)
            .padding(.bottom, 16)
            .tabBarBottomPadding()
        }
        .background(LinearGradient.appBg.ignoresSafeArea())
        .navigationTitle("Notes & Photos")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddNote = true } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(.primaryGreen)
                }
            }
        }
        .sheet(isPresented: $showAddNote) { AddNoteView(isPresented: $showAddNote) }
        .sheet(item: $selected) { n in NoteDetailView(note: n) }
    }
}

private struct NotesFilterChip: View {
    let label: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(isSelected ? Color.accentCyan : Color.freshBg)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? Color.accentCyan : Color.dividerGreen, lineWidth: 1))
        }
    }
}

// MARK: - Note Card (grid cell)
private struct NoteCard: View {
    @EnvironmentObject var store: DataStore
    let note: BirdNote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imgData = note.imageData, let uiImg = UIImage(data: imgData) {
                Image(uiImage: uiImg)
                    .resizable().scaledToFill()
                    .frame(height: 100)
                    .clipped()
                    .cornerRadius(10)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentCyan.opacity(0.1))
                        .frame(height: 60)
                    Image(systemName: "note.text")
                        .font(.system(size: 24)).foregroundColor(.accentCyan.opacity(0.6))
                }
            }

            Text(note.content)
                .font(.system(size: 13))
                .foregroundColor(.textPrimary)
                .lineLimit(3)

            HStack {
                if let gid = note.groupId {
                    Text(store.groupName(gid))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.primaryGreen)
                        .lineLimit(1)
                }
                Spacer()
                Text(note.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 10)).foregroundColor(.textInactive)
            }
        }
        .padding(12)
        .background(Color.cardBg)
        .cornerRadius(14)
        .appShadow()
    }
}

// MARK: - Image Picker (iOS 14+ compatible)
struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePickerView
        init(_ parent: ImagePickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.imageData = image.jpegData(compressionQuality: 0.75)
            }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Add Note
struct AddNoteView: View {
    @EnvironmentObject var store: DataStore
    @Binding var isPresented: Bool

    @State private var content = ""
    @State private var selectedGroupId: UUID?
    @State private var imageData: Data? = nil
    @State private var showImagePicker = false
    @State private var showValidation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo
                    VStack(spacing: 10) {
                        Text("Photo").font(.system(size: 13, weight: .semibold)).foregroundColor(.textSecondary).frame(maxWidth: .infinity, alignment: .leading)
                        Button { showImagePicker = true } label: {
                            if let imgData = imageData, let uiImg = UIImage(data: imgData) {
                                Image(uiImage: uiImg)
                                    .resizable().scaledToFill()
                                    .frame(height: 160).clipped().cornerRadius(14)
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.freshBg)
                                        .frame(height: 120)
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.dividerGreen, lineWidth: 1.5))
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo.badge.plus").font(.system(size: 32)).foregroundColor(.textInactive)
                                        Text("Add Photo").font(.system(size: 14)).foregroundColor(.textInactive)
                                    }
                                }
                            }
                        }
                        if imageData != nil {
                            Button("Remove Photo") { imageData = nil }
                                .font(.system(size: 12)).foregroundColor(.statusDanger)
                        }
                    }
                    .sheet(isPresented: $showImagePicker) {
                        ImagePickerView(imageData: $imageData)
                    }

                    FormRow("Note") {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $content)
                                .frame(minHeight: 120)
                                .padding(10)
                                .background(Color.freshBg)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dividerGreen, lineWidth: 1))
                            if content.isEmpty {
                                Text("Write your observation, symptoms, or notes here...")
                                    .foregroundColor(.textInactive)
                                    .padding(.horizontal, 14).padding(.top, 18)
                                    .allowsHitTesting(false)
                            }
                        }
                        if showValidation && content.isEmpty { Text("Note cannot be empty").font(.system(size: 12)).foregroundColor(.statusDanger) }
                    }

                    FormRow("Attach to Group (optional)") {
                        Picker("Group", selection: $selectedGroupId) {
                            Text("No specific group").tag(UUID?.none)
                            ForEach(store.birdGroups) { g in Text("\(g.type.emoji) \(g.name)").tag(UUID?.some(g.id)) }
                        }.pickerStyle(.menu).appFieldBox()
                    }

                    Button("Save Note") {
                        guard !content.isEmpty else { showValidation = true; return }
                        store.addNote(BirdNote(groupId: selectedGroupId, content: content, date: Date(), imageData: imageData))
                        isPresented = false
                    }.buttonStyle(PrimaryButtonStyle())
                }
                .padding(20)
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }.foregroundColor(.primaryGreen)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Note Detail
struct NoteDetailView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    let note: BirdNote

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let imgData = note.imageData, let uiImg = UIImage(data: imgData) {
                        Image(uiImage: uiImg)
                            .resizable().scaledToFit()
                            .cornerRadius(16)
                            .padding(.horizontal, 16)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            if let gid = note.groupId {
                                StatusBadge(text: store.groupName(gid), color: .accentCyan)
                            }
                            Spacer()
                            Text(note.date.formatted(.dateTime.month(.wide).day().year().hour().minute()))
                                .font(.system(size: 12)).foregroundColor(.textInactive)
                        }
                        Text(note.content)
                            .font(.system(size: 16))
                            .foregroundColor(.textPrimary)
                    }
                    .appCard()
                    .padding(.horizontal, 16)

                    Button("Delete Note") { store.deleteNote(note); dismiss() }
                        .buttonStyle(DestructiveButtonStyle())
                        .padding(.horizontal, 16)

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationTitle("Note Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }.foregroundColor(.primaryGreen)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
