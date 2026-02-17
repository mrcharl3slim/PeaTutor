import SwiftUI
import SwiftData

@main
struct PeaTutorApp: App {
    @StateObject private var awsService = AWSService.shared
    
    // SwiftData container for extraction history
    let modelContainer: ModelContainer
    
    init() {
        // 🔥 CRITICAL: Delete corrupted SwiftData store
        Self.deleteSwiftDataStore()
        
        do {
            modelContainer = try ModelContainer(for: ExtractionHistory.self)
            print("✅ SwiftData ModelContainer initialized")
            
            Task {
                await Self.clearDataStoreIfNeeded()
                await Self.seedCurriculumIfNeeded()
            }
        } catch {
            fatalError("❌ Failed to initialize ModelContainer: \(error)")
        }
    }
    
    private static func deleteSwiftDataStore() {
        let hasDeletedKey = "HasDeletedSwiftDataStoreV3" // V3 to force re-deletion
        let hasDeleted = UserDefaults.standard.bool(forKey: hasDeletedKey)
        
        // Only delete once per version
        if !hasDeleted {
            print("🔍 Detecting and removing corrupted SwiftData store...")
            
            do {
                // Get the application support directory where SwiftData stores files
                guard let appSupportURL = FileManager.default.urls(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask
                ).first else {
                    print("⚠️ Could not find application support directory")
                    return
                }
                
                print("📁 Scanning directory: \(appSupportURL.path)")
                
                // Get all files in the directory
                let contents = try FileManager.default.contentsOfDirectory(
                    at: appSupportURL,
                    includingPropertiesForKeys: nil,
                    options: .skipsHiddenFiles
                )
                
                var deletedFiles: [String] = []
                
                // Delete all SwiftData/CoreData store files
                for fileURL in contents {
                    let ext = fileURL.pathExtension.lowercased()
                    
                    // CoreData/SwiftData creates .store, .store-wal, .store-shm files
                    if ext == "store" || ext == "wal" || ext == "shm" {
                        do {
                            try FileManager.default.removeItem(at: fileURL)
                            deletedFiles.append(fileURL.lastPathComponent)
                            print("🗑️ Deleted: \(fileURL.lastPathComponent)")
                        } catch {
                            print("⚠️ Could not delete \(fileURL.lastPathComponent): \(error.localizedDescription)")
                        }
                    }
                }
                
                if deletedFiles.isEmpty {
                    print("✅ No corrupted store files found")
                } else {
                    print("✅ Successfully deleted \(deletedFiles.count) corrupted file(s):")
                    deletedFiles.forEach { print("   - \($0)") }
                }
                
                // Mark as deleted so we don't do this every launch
                UserDefaults.standard.set(true, forKey: hasDeletedKey)
                print("✅ SwiftData store cleanup complete")
                
            } catch {
                print("❌ Error during store deletion: \(error.localizedDescription)")
                // Don't set the flag if we failed, so we try again next launch
            }
        } else {
            print("✅ SwiftData store already cleaned (skipping)")
        }
    }
    
    @MainActor
    private static func clearDataStoreIfNeeded() async {
        let hasClearedKey = "HasClearedDataStoreV1"
        let hasCleared = UserDefaults.standard.bool(forKey: hasClearedKey)
        
        if !hasCleared {
            do {
                print("🔄 Clearing DataStore cache...")
                try await DataStoreService.shared.clearLocalDataStore()
                UserDefaults.standard.set(true, forKey: hasClearedKey)
                print("✅ DataStore cleared")
            } catch {
                print("⚠️ Failed to clear DataStore: \(error)")
            }
        }
    }
    
    @MainActor
    private static func seedCurriculumIfNeeded() async {
        do {
            let isSeeded = await CurriculumService.shared.isCurriculumSeeded()
            
            if !isSeeded {
                print("🌱 Auto-seeding curriculum data...")
                try await CurriculumService.shared.seedFromBundledJSON()
                print("✅ Curriculum seeding complete")
            } else {
                print("✅ Curriculum data already exists in DataStore")
            }
        } catch {
            print("⚠️ Failed to seed curriculum: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AuthenticationView()
                .environmentObject(awsService)
                .modelContainer(modelContainer)
                .onAppear {
                    configureHistoryManager()
                }
                .onChange(of: awsService.currentUser?.userId) { oldUserId, newUserId in
                    handleUserChange(oldUserId: oldUserId, newUserId: newUserId)
                }
        }
    }
    
    // ✅ NEW: Configure history manager with current user
    private func configureHistoryManager() {
        guard let userId = awsService.currentUser?.userId else {
            print("⚠️ No user logged in, HistoryManager not configured")
            return
        }
        
        let context = modelContainer.mainContext
        HistoryManager.shared.configure(with: context, userId: userId)
        print("✅ App: HistoryManager configured for user: \(userId)")
    }
    
    // ✅ NEW: Handle user changes (logout/login/switch)
    private func handleUserChange(oldUserId: String?, newUserId: String?) {
        // Only handle if user actually changed
        guard oldUserId != newUserId else {
            return
        }
        
        print("👤 User change detected")
        print("   Old: \(oldUserId ?? "none")")
        print("   New: \(newUserId ?? "none")")
        
        if let newUserId = newUserId {
            // New user logged in - reconfigure HistoryManager
            print("👋 New user logged in: \(newUserId)")
            configureHistoryManager()
            
            // Restart DataStore for new user
            Task {
                do {
                    try await DataStoreService.shared.startDataStore()
                    print("✅ DataStore restarted for user: \(newUserId)")
                } catch {
                    print("⚠️ DataStore restart failed: \(error)")
                }
            }
        } else {
            // User logged out - reset HistoryManager state (but keep data)
            print("🚪 User logged out - HistoryManager reset")
            HistoryManager.shared.resetForLogout()
        }
    }
}
