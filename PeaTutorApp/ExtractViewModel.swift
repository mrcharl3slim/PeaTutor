import Foundation
import UniformTypeIdentifiers
import UIKit
import Amplify

@MainActor
final class ExtractViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var progress: Double = 0
    @Published var result: ExtractedWorksheet?
    @Published var mockMode: Bool = false
    @Published var lastSavedWorksheetId: String?
    @Published var duplicateDetected: ExtractionHistory?
    @Published var showingDuplicateAlert = false
    
    // Services
    let awsService = AWSService.shared
    var uploadedS3Keys: [String] = []
    
    // MARK: - Duplicate Detection (Sub-Sprint 3.3.1)
    
    /// Check for duplicates before extraction
    func checkForDuplicatesAndExtract(fileURLs: [URL], capturedImages: [UIImage]) async -> Bool {
        print("🔍 Checking for duplicate files...")
        
        // Calculate hashes for all inputs
        var fileHashes: [String] = []
        
        // Hash file URLs
        for url in fileURLs {
            if let hash = FileHasher.calculateHash(for: url) {
                fileHashes.append(hash)
                print("🔐 File hash: \(url.lastPathComponent) -> \(hash.prefix(16))...")
            } else {
                print("⚠️ Could not calculate hash for: \(url.lastPathComponent)")
            }
        }
        
        // Hash captured images
        for (index, image) in capturedImages.enumerated() {
            if let hash = FileHasher.calculateHash(for: image) {
                fileHashes.append(hash)
                print("🔐 Image hash: Camera Image \(index + 1) -> \(hash.prefix(16))...")
            } else {
                print("⚠️ Could not calculate hash for captured image \(index + 1)")
            }
        }
        
        // If no hashes could be calculated, allow extraction
        guard !fileHashes.isEmpty else {
            print("⚠️ No hashes calculated, proceeding with extraction")
            return false
        }
        
        // Calculate combined hash
        let combinedHash = FileHasher.calculateCombinedHash(from: fileHashes)
        print("🔐 Combined hash: \(combinedHash.prefix(16))...")
        
        // Check for duplicates
        let checkResult = HistoryManager.shared.performDuplicateCheck(
            contentHash: combinedHash,
            fileHashes: fileHashes
        )
        
        switch checkResult {
        case .noDuplicate:
            print("✅ No duplicates found, proceeding with extraction")
            return false
            
        case .exactDuplicate(let extraction):
            print("⛔ Exact duplicate found!")
            duplicateDetected = extraction
            showingDuplicateAlert = true
            return true
            
        case .partialDuplicate(let extractions):
            print("⚠️ Partial duplicates found: \(extractions.count)")
            // For strict mode, treat partial duplicates same as exact
            duplicateDetected = extractions.first
            showingDuplicateAlert = true
            return true
        }
    }
    
    // MARK: - Main Extraction Function
    
    func runExtraction(fileURLs: [URL], capturedImages: [UIImage] = []) async {
        self.isLoading = true
        self.progress = 0
        self.uploadedS3Keys = []
        defer { self.isLoading = false; self.progress = 0 }

        print("🚀 Starting extraction with \(fileURLs.count) files and \(capturedImages.count) camera images")
        print("⏱️ Large files may take 1-2 minutes to process...")

        if mockMode {
            print("📱 Mock mode enabled - loading sample data")
            await loadMock()
            return
        }
        
        guard let client = OpenAIClient() else {
            print("❌ OpenAI client initialization failed - check OPENAI_API_KEY environment variable")
            print("Available environment variables: \(ProcessInfo.processInfo.environment.keys.filter { $0.contains("OPENAI") })")
            await loadMock()
            return
        }
        print("✅ OpenAI client initialized successfully")
        
        // Test API connection first
        do {
            let testResult = try await client.testConnection()
            print("✅ API connection test successful: \(testResult)")
        } catch {
            print("❌ API connection test failed: \(error)")
            self.result = ExtractedWorksheet(questions: [ExtractedQuestion(id: "CONNECTION_ERROR", questionText: "API connection failed: \(error.localizedDescription)", marks: 0, skillsTested: [], subparts: [], hints: "Check your API key and internet connection", stepByStep: "Verify OPENAI_API_KEY is correct", answer: "Contact support")])
            return
        }
        
        var fileIDs: [String] = []
        let totalItems = Double(max(fileURLs.count + capturedImages.count, 1))
        var processedItems = 0
        
        // Process file URLs first
        if !fileURLs.isEmpty {
            print("📂 Processing \(fileURLs.count) file(s)...")
        }
        
        for url in fileURLs {
            do {
                print("📂 Processing file: \(url.lastPathComponent)")
                print("📂 File path: \(url.path)")
                
                // CRITICAL: Must access security-scoped resource before reading file
                var data: Data
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    print("🔐 Security-scoped resource access: granted")
                    
                    // Use NSFileCoordinator to download file if it's not local (iCloud/File Provider)
                    var error: NSError?
                    let coordinator = NSFileCoordinator()
                    var fileData: Data?
                    
                    print("📥 Requesting file download from File Provider...")
                    coordinator.coordinate(readingItemAt: url, options: [.forUploading], error: &error) { newURL in
                        print("📥 File Provider returned local URL: \(newURL.path)")
                        
                        // Now check if the downloaded file exists
                        let localFileExists = FileManager.default.fileExists(atPath: newURL.path)
                        print("📁 Local file exists after coordination: \(localFileExists)")
                        
                        if localFileExists {
                            do {
                                fileData = try Data(contentsOf: newURL)
                                print("✅ Successfully downloaded file: \(fileData?.count ?? 0) bytes")
                            } catch {
                                print("❌ Failed to read downloaded file: \(error)")
                            }
                        } else {
                            print("❌ File still not available after coordination")
                        }
                    }
                    
                    if let e = error {
                        print("❌ File coordination error: \(e)")
                        throw e
                    }
                    
                    guard let downloadedData = fileData else {
                        throw NSError(domain: "ExtractViewModel", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not load file data from File Provider for: \(url.lastPathComponent)"])
                    }
                    
                    data = downloadedData
                    print("✅ Successfully read file data: \(data.count) bytes")
                } else {
                    print("❌ Could not access security-scoped resource")
                    throw NSError(domain: "ExtractViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not access file: \(url.lastPathComponent)"])
                }
                
                let mime = mimeType(for: url)
                print("📄 File data size: \(data.count) bytes")
                print("📄 MIME type: \(mime)")
                
                // Upload to AWS S3 first
                do {
                    let s3Key = try await awsService.uploadWorksheet(
                        data: data,
                        filename: url.lastPathComponent,
                        mimeType: mime
                    )
                    uploadedS3Keys.append(s3Key)
                    print("☁️ Uploaded to S3: \(s3Key)")
                } catch {
                    print("⚠️ S3 upload failed (continuing with OpenAI): \(error)")
                    // Continue even if S3 upload fails - don't block extraction
                }
                
                // Then upload to OpenAI for extraction
                let id = try await client.uploadFile(data: data, filename: url.lastPathComponent, mimetype: mime, purpose: "user_data")
                fileIDs.append(id)
                print("✅ Successfully processed file: \(url.lastPathComponent) -> ID: \(id.prefix(20))...")
            } catch {
                print("❌ Upload error for \(url.lastPathComponent): \(error)")
                print("❌ Error details: \(error.localizedDescription)")
            }
            
            processedItems += 1
            self.progress = Double(processedItems) / totalItems * 0.6 // uploads = 60%
        }
        
        // Process captured images
        if !capturedImages.isEmpty {
            print("📸 Processing \(capturedImages.count) camera image(s)...")
        }
        
        for (index, image) in capturedImages.enumerated() {
            do {
                print("📸 Processing captured image \(index + 1) - Size: \(image.size)")
                
                // Optimize image for better OCR
                let optimizedImage = optimizeImageForOCR(image)
                print("📸 Optimized image size: \(optimizedImage.size)")
                
                // Convert UIImage to JPEG data with high quality for better OCR
                guard let imageData = optimizedImage.jpegData(compressionQuality: 0.85) else {
                    throw NSError(domain: "ExtractViewModel", code: -3, userInfo: [NSLocalizedDescriptionKey: "Could not convert captured image to JPEG data"])
                }
                
                let filename = "captured_image_\(index + 1).jpg"
                print("📸 Image data size: \(imageData.count) bytes")
                
                // Upload to AWS S3 first
                do {
                    let s3Key = try await awsService.uploadWorksheet(
                        data: imageData,
                        filename: filename,
                        mimeType: "image/jpeg"
                    )
                    uploadedS3Keys.append(s3Key)
                    print("☁️ Uploaded image to S3: \(s3Key)")
                } catch {
                    print("⚠️ S3 upload failed (continuing with OpenAI): \(error)")
                    // Continue even if S3 upload fails
                }
                        
                // Then upload to OpenAI for extraction
                let id = try await client.uploadFile(data: imageData, filename: filename, mimetype: "image/jpeg", purpose: "user_data")
                fileIDs.append(id)
                print("✅ Successfully processed camera image \(index + 1) -> ID: \(id.prefix(20))...")
            } catch {
                print("❌ Upload error for captured image \(index + 1): \(error)")
                print("❌ Error details: \(error.localizedDescription)")
            }
            
            processedItems += 1
            self.progress = Double(processedItems) / totalItems * 0.6 // uploads = 60%
        }
        
        if fileIDs.isEmpty {
            print("❌ No files or images were successfully processed")
            self.result = ExtractedWorksheet(questions: [ExtractedQuestion(id: "UPLOAD_ERROR", questionText: "No files or images could be processed. This may be because:\n\n• Files are stored in iCloud and not downloaded\n• File permissions are restricted\n• Network connectivity issues\n• Camera capture failed\n• Image quality is too poor\n\nTry:\n• Opening the file in Files app first to download it\n• Selecting files from 'On My iPhone' instead of iCloud\n• Retaking photos with better lighting and framing\n• Ensuring the worksheet fills most of the camera frame\n• Checking your internet connection", marks: 0, skillsTested: [], subparts: [], hints: "Try downloading files locally first or retake photos with better quality", stepByStep: "1. For files: Open Files app, navigate to file, tap to download locally\n2. For camera: Ensure good lighting, steady hands, full worksheet in frame\n3. Try importing again", answer: "Ensure files are locally available and images are high quality")])
            return
        }
        
        print("🤖 Starting OpenAI extraction with \(fileIDs.count) processed items")
        
        do {
            let parsed = try await client.extractQuestions(fileIDs: fileIDs, model: "gpt-4o")
            print("✅ Extraction successful, got \(parsed.questions.count) questions")
            
            // Log details about extracted questions
            for (index, question) in parsed.questions.enumerated() {
                print("📝 Question \(index + 1): \(question.id) - '\(question.questionText.prefix(50))...' (\(question.marks) marks)")
                if !question.subparts.isEmpty {
                    print("   📎 Has \(question.subparts.count) subparts")
                }
            }
            
            self.result = parsed
            self.progress = 0.8 // 80% - extraction complete

            // 🆕 Sub-Sprint 3.3: Calculate hashes for duplicate detection
            let sourceNames = fileURLs.map { $0.lastPathComponent } +
                              capturedImages.indices.map { "Camera Image \($0 + 1)" }

            // Calculate hashes for saving
            var fileHashes: [String] = []
            fileHashes.append(contentsOf: FileHasher.calculateHashes(for: fileURLs))
            fileHashes.append(contentsOf: FileHasher.calculateHashes(for: capturedImages))
            let combinedHash = FileHasher.calculateCombinedHash(from: fileHashes)

            // 🆕 Sub-Sprint 3.3.2: Save to DataStore (Backend Sync) - DO THIS FIRST!
            let datastoreWorksheetId = await saveToDataStore(
                result: parsed,
                fileURLs: fileURLs,
                capturedImages: capturedImages
            )

            // ✅ FIXED: Handle both success and failure cases
            if let worksheetId = datastoreWorksheetId {
                print("✅ DataStore save successful: \(worksheetId)")
                
                // Save to history WITH DataStore ID
                HistoryManager.shared.saveExtraction(
                    parsed,
                    sourceFiles: sourceNames,
                    contentHash: combinedHash,
                    sourceFileHashes: fileHashes,
                    datastoreWorksheetId: worksheetId  // ✅ Has valid ID
                )
                
                // Update lastSavedWorksheetId (already done in saveToDataStore via MainActor)
                await MainActor.run {
                    self.lastSavedWorksheetId = worksheetId
                }
                
            } else {
                print("⚠️ DataStore save failed - saving to history without sync")
                
                // Save to history WITHOUT DataStore ID
                HistoryManager.shared.saveExtraction(
                    parsed,
                    sourceFiles: sourceNames,
                    contentHash: combinedHash,
                    sourceFileHashes: fileHashes,
                    datastoreWorksheetId: nil  // ⚠️ Not synced to cloud
                )
                
                // Clear lastSavedWorksheetId since save failed
                await MainActor.run {
                    self.lastSavedWorksheetId = nil
                }
            }
            
            print("💾 Saved extraction to history with DataStore ID: \(datastoreWorksheetId ?? "none")")
          

            self.progress = 1.0 // 100% - complete
            
        } catch let error as NSError where error.code == NSURLErrorTimedOut {
            print("❌ Extraction timeout after retries")
            self.result = ExtractedWorksheet(questions: [
                ExtractedQuestion(
                    id: "TIMEOUT_ERROR",
                    questionText: "Request timed out while processing your files.\n\nThis can happen when:\n• Files are very large\n• Multiple images are uploaded\n• Network connection is slow\n• OpenAI API is busy\n\nTry:\n• Upload fewer files at once\n• Use smaller/compressed images\n• Check your internet connection\n• Try again in a moment",
                    marks: 0,
                    skillsTested: ["troubleshooting"],
                    subparts: [],
                    hints: "Try reducing file size or splitting into smaller uploads",
                    stepByStep: "1. Compress images before uploading\n2. Upload 1-2 files at a time\n3. Ensure stable internet connection",
                    answer: "Retry with optimized files"
                )
            ])
        } catch {
            print("❌ Extraction error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            // If extraction fails, show an error message instead of falling back to mock
            self.result = ExtractedWorksheet(questions: [
                ExtractedQuestion(id: "ERROR",
                         questionText: "Failed to extract questions from uploaded files/images. Error: \(error.localizedDescription)\n\nThis might be due to:\n• Poor image quality\n• No recognizable math content\n• API rate limits\n• Network issues\n\nTry:\n• Retaking photos with better lighting\n• Ensuring math problems are clearly visible\n• Waiting a moment and trying again",
                         marks: 0,
                         skillsTested: [],
                         subparts: [],
                         hints: "Check image quality and API configuration",
                         stepByStep: "1. Verify images are clear and well-lit\n2. Ensure math problems are visible\n3. Check OPENAI_API_KEY is set\n4. Try again in a moment",
                         answer: "See troubleshooting steps above")])
        }
    }
    
    // MARK: - DataStore Integration (Sub-Sprint 3.3.2)
    
    /// Save extracted worksheet to DataStore backend
    private func saveToDataStore(
        result: ExtractedWorksheet,
        fileURLs: [URL],
        capturedImages: [UIImage]
    ) async -> String? {
        print("💾 Saving extraction to DataStore...")
        
        // Determine primary source for metadata
        let primaryFileName: String
        let primaryFileType: String?
        var fileSize: Int?
        
        if let firstURL = fileURLs.first {
            primaryFileName = firstURL.lastPathComponent
            primaryFileType = firstURL.pathExtension
            
            // Try to get file size
            if firstURL.startAccessingSecurityScopedResource() {
                defer { firstURL.stopAccessingSecurityScopedResource() }
                fileSize = try? firstURL.resourceValues(forKeys: [.fileSizeKey]).fileSize
            }
        } else if !capturedImages.isEmpty {
            primaryFileName = "Camera Capture \(Date().formatted(date: .abbreviated, time: .omitted))"
            primaryFileType = "jpg"
            // Estimate size from first image
            if let jpegData = capturedImages.first?.jpegData(compressionQuality: 0.85) {
                fileSize = jpegData.count
            }
        } else {
            print("⚠️ No source files or images available for DataStore save")
            return nil
        }
        
        // ✅ NEW: Use placeholder S3 key if upload failed
        let s3Key: String
        if let uploadedKey = uploadedS3Keys.first {
            s3Key = uploadedKey
            print("✅ Using uploaded S3 key: \(s3Key)")
        } else {
            // Generate placeholder key - worksheet still gets saved!
            s3Key = "pending-upload/\(result.id.uuidString)/\(primaryFileName)"
            print("⚠️ S3 upload failed, using placeholder key: \(s3Key)")
        }
        
        do {
            let savedWorksheet = try await DataStoreService.shared.saveWorksheet(
                extractionResult: result,
                s3WorksheetKey: s3Key,
                fileName: primaryFileName,
                fileType: primaryFileType,
                fileSize: fileSize
            )
            
            print("✅ Saved to DataStore with ID: \(savedWorksheet.id)")
            print("📊 Questions: \(savedWorksheet.questionCount ?? 0)")
            print("🎯 Total Marks: \(savedWorksheet.totalMarks ?? 0)")
            
            // ✅ CRITICAL: Set lastSavedWorksheetId to DataStore ID!
            await MainActor.run {
                self.lastSavedWorksheetId = savedWorksheet.id
                print("✅ Set lastSavedWorksheetId to: \(savedWorksheet.id)")
            }
            
            // Update user statistics
            // ✅ FIXED: Fire-and-forget for user stats (non-blocking)
            Task.detached { @MainActor in
                do {
                    try await DataStoreService.shared.updateUserStats()
                    print("✅ User stats updated (background)")
                } catch {
                    print("⚠️ Failed to update user stats (non-critical): \(error)")
                }
            }
            
            // ✅ Return the saved worksheet ID immediately
            return savedWorksheet.id
            
        } catch {
            print("⚠️ DataStore save failed (non-fatal): \(error)")
            print("⚠️ Error details: \(error.localizedDescription)")
            print("⚠️ Extraction result is still available in UI")
            return nil
        }
        
    }
    
    // MARK: - Helper Methods
    
    private func optimizeImageForOCR(_ image: UIImage) -> UIImage {
        // Ensure reasonable size for OCR (not too big, not too small)
        let maxDimension: CGFloat = 2048
        let minDimension: CGFloat = 800
        
        let currentMax = max(image.size.width, image.size.height)
        let currentMin = min(image.size.width, image.size.height)
        
        var targetSize = image.size
        
        // Scale down if too large
        if currentMax > maxDimension {
            let scale = maxDimension / currentMax
            targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        }
        // Scale up if too small
        else if currentMin < minDimension {
            let scale = minDimension / currentMin
            targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        }
        
        // If size is already good, return original
        if targetSize == image.size {
            return image
        }
        
        print("📸 Resizing image from \(image.size) to \(targetSize)")
        
        // Resize image
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        return resizedImage
    }

    private func loadMock() async {
        // Load bundled MockData.json
        guard let url = Bundle.main.url(forResource: "MockData", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let parsed = try? JSONDecoder().decode(ExtractedWorksheet.self, from: data) else {
            self.result = ExtractedWorksheet(questions: [ExtractedQuestion(id: "QX", questionText: "PARSE ERROR – could not extract this question", marks: 0, skillsTested: [], subparts: [], hints: "N/A", stepByStep: "N/A", answer: "N/A")])
            return
        }
        self.result = parsed
        self.progress = 1.0
    }

    private func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "pdf": return "application/pdf"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        default: return "application/octet-stream"
        }
    }
}
