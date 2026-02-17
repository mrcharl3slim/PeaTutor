//
//  AWSSyncTestView.swift
//  PeaTutorApp
//
//  Comprehensive test view for S3 uploads, downloads, and DataStore synchronization
//

import SwiftUI
import Amplify

struct AWSSyncTestView: View {
    @StateObject private var awsService = AWSService.shared
    @StateObject private var dataStoreService = DataStoreService.shared
    
    // Test states
    @State private var testResults: [TestResult] = []
    @State private var isRunningTests = false
    @State private var currentTest = ""
    @State private var overallProgress: Double = 0
    
    // S3 test data
    @State private var uploadedTestKey: String?
    @State private var s3Files: [StorageListResult.Item] = []
    
    // DataStore test data
    @State private var worksheetCount = 0
    @State private var questionCount = 0
    @State private var feedbackCount = 0
    @State private var homeworkCount = 0
    @State private var classroomCount = 0
    
    // Sync status
    @State private var syncStatus = "Unknown"
    @State private var lastSyncTime: Date?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    headerCard
                    
                    // Quick Stats
                    quickStatsGrid
                    
                    // Test Controls
                    testControlsSection
                    
                    // Test Results
                    if !testResults.isEmpty {
                        testResultsSection
                    }
                    
                    // S3 Files List
                    if !s3Files.isEmpty {
                        s3FilesSection
                    }
                    
                    // DataStore Details
                    dataStoreDetailsSection
                    
                    // Danger Zone
                    dangerZoneSection
                }
                .padding()
            }
            .navigationTitle("AWS Sync Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await refreshAll() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await refreshAll()
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "cloud.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AWS Cloud Services")
                        .font(.headline)
                    Text("S3 Storage & DataStore Sync")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Connection status
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(awsService.isSignedIn ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(awsService.isSignedIn ? "Connected" : "Disconnected")
                            .font(.caption)
                    }
                    
                    if let userId = awsService.currentUserId {
                        Text(userId.prefix(8) + "...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            // Sync status
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.orange)
                Text("Sync: \(syncStatus)")
                    .font(.subheadline)
                
                Spacer()
                
                if let lastSync = lastSyncTime {
                    Text("Last: \(formatTime(lastSync))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Quick Stats Grid
    private var quickStatsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard2(title: "Worksheets", value: "\(worksheetCount)", icon: "doc.text", color: .blue)
            StatCard2(title: "Questions", value: "\(questionCount)", icon: "questionmark.circle", color: .green)
            StatCard2(title: "Feedback", value: "\(feedbackCount)", icon: "bubble.left.and.bubble.right", color: .purple)
            StatCard2(title: "Homework", value: "\(homeworkCount)", icon: "book", color: .orange)
            StatCard2(title: "Classrooms", value: "\(classroomCount)", icon: "person.3", color: .pink)
            StatCard2(title: "S3 Files", value: "\(s3Files.count)", icon: "folder.fill", color: .indigo)
        }
    }
    
    // MARK: - Test Controls Section
    private var testControlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Test Suite")
                .font(.headline)
            
            if isRunningTests {
                VStack(spacing: 12) {
                    ProgressView(value: overallProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(currentTest)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    // Run All Tests
                    Button(action: { Task { await runAllTests() } }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Run All Tests")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    // Individual test buttons
                    HStack(spacing: 12) {
                        Button(action: { Task { await testS3Upload() } }) {
                            VStack {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.title2)
                                Text("S3 Upload")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Button(action: { Task { await testS3Download() } }) {
                            VStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.title2)
                                Text("S3 Download")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Button(action: { Task { await testDataStoreSync() } }) {
                            VStack {
                                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                    .font(.title2)
                                Text("DataStore")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Test Results Section
    private var testResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Test Results")
                    .font(.headline)
                
                Spacer()
                
                let passed = testResults.filter { $0.passed }.count
                let total = testResults.count
                Text("\(passed)/\(total) Passed")
                    .font(.caption)
                    .foregroundColor(passed == total ? .green : .orange)
            }
            
            ForEach(testResults) { result in
                TestResultRow(result: result)
            }
            
            Button(action: { testResults.removeAll() }) {
                Text("Clear Results")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - S3 Files Section
    private var s3FilesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("S3 Files")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { Task { await listS3Files() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
            }
            
            if s3Files.isEmpty {
                Text("No files found")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(s3Files.prefix(10), id: \.key) { file in
                    S3FileRow(file: file)
                }
                
                if s3Files.count > 10 {
                    Text("+ \(s3Files.count - 10) more files...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - DataStore Details Section
    private var dataStoreDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DataStore Details")
                .font(.headline)
            
            VStack(spacing: 8) {
                DataStoreRow(label: "Worksheets", count: worksheetCount, icon: "doc.text.fill")
                DataStoreRow(label: "Questions", count: questionCount, icon: "questionmark.circle.fill")
                DataStoreRow(label: "Solution Feedback", count: feedbackCount, icon: "bubble.left.fill")
                DataStoreRow(label: "Homework Assignments", count: homeworkCount, icon: "book.fill")
                DataStoreRow(label: "Classrooms", count: classroomCount, icon: "person.3.fill")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Danger Zone Section
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Danger Zone")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            
            Text("These actions are destructive and cannot be undone.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Button(action: { Task { await clearLocalDataStore() } }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear Local Cache")
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button(action: { Task { await forceResync() } }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Force Resync")
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Test Methods
    
    private func runAllTests() async {
        isRunningTests = true
        testResults.removeAll()
        overallProgress = 0
        
        let tests: [(String, () async -> TestResult)] = [
            ("Authentication Check", testAuthentication),
            ("S3 Upload Test", testS3Upload),
            ("S3 List Files", testS3List),
            ("S3 Download Test", testS3Download),
            ("DataStore Query - Worksheets", testDataStoreWorksheets),
            ("DataStore Query - Questions", testDataStoreQuestions),
            ("DataStore Query - Feedback", testDataStoreFeedback),
            ("DataStore Query - Homework", testDataStoreHomework),
            ("DataStore Query - Classrooms", testDataStoreClassrooms),
            ("DataStore Sync Status", testDataStoreSync)
        ]
        
        for (index, (name, test)) in tests.enumerated() {
            currentTest = name
            let result = await test()
            testResults.append(result)
            overallProgress = Double(index + 1) / Double(tests.count)
            
            // Small delay for visual feedback
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
        
        currentTest = "Complete!"
        isRunningTests = false
        lastSyncTime = Date()
        syncStatus = testResults.allSatisfy { $0.passed } ? "All Tests Passed" : "Some Tests Failed"
    }
    
    private func testAuthentication() async -> TestResult {
        let start = Date()
        
        guard awsService.isSignedIn else {
            return TestResult(
                name: "Authentication Check",
                passed: false,
                message: "User not signed in",
                duration: Date().timeIntervalSince(start)
            )
        }
        
        guard let userId = awsService.currentUserId else {
            return TestResult(
                name: "Authentication Check",
                passed: false,
                message: "No user ID available",
                duration: Date().timeIntervalSince(start)
            )
        }
        
        return TestResult(
            name: "Authentication Check",
            passed: true,
            message: "User ID: \(userId.prefix(20))...",
            duration: Date().timeIntervalSince(start)
        )
    }
    
    private func testS3Upload() async -> TestResult {
        let start = Date()
        
        // Create test data
        let testData = "PeaTutor Test Upload - \(Date())".data(using: .utf8)!
        let filename = "test_upload_\(Int(Date().timeIntervalSince1970)).txt"
        
        do {
            let key = try await awsService.uploadWorksheet(
                data: testData,
                filename: filename,
                mimeType: "text/plain"
            )
            
            uploadedTestKey = key
            
            return TestResult(
                name: "S3 Upload Test",
                passed: true,
                message: "Uploaded: \(key.suffix(30))...",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "S3 Upload Test",
                passed: false,
                message: "Error: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testS3List() async -> TestResult {
        let start = Date()
        
        do {
            let files = try await awsService.listSolutions()
            await MainActor.run {
                s3Files = files
            }
            
            return TestResult(
                name: "S3 List Files",
                passed: true,
                message: "Found \(files.count) files",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "S3 List Files",
                passed: false,
                message: "Error: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testS3Download() async -> TestResult {
        let start = Date()
        
        guard let key = uploadedTestKey ?? s3Files.first?.key else {
            return TestResult(
                name: "S3 Download Test",
                passed: false,
                message: "No file available for download test",
                duration: Date().timeIntervalSince(start)
            )
        }
        
        do {
            let data = try await awsService.downloadFile(key: key)
            
            return TestResult(
                name: "S3 Download Test",
                passed: true,
                message: "Downloaded \(data.count) bytes",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "S3 Download Test",
                passed: false,
                message: "Error: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testDataStoreWorksheets() async -> TestResult {
        let start = Date()
        
        do {
            let worksheets = try await Amplify.DataStore.query(Worksheet.self)
            await MainActor.run {
                worksheetCount = worksheets.count
            }
            
            return TestResult(
                name: "DataStore Query - Worksheets",
                passed: true,
                message: "Found \(worksheets.count) worksheets",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "DataStore Query - Worksheets",
                passed: false,
                message: "Error: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testDataStoreQuestions() async -> TestResult {
        let start = Date()
        
        do {
            let questions = try await Amplify.DataStore.query(Question.self)
            await MainActor.run {
                questionCount = questions.count
            }
            
            return TestResult(
                name: "DataStore Query - Questions",
                passed: true,
                message: "Found \(questions.count) questions",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "DataStore Query - Questions",
                passed: false,
                message: "Error: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testDataStoreFeedback() async -> TestResult {
        let start = Date()
        
        do {
            let feedback = try await Amplify.DataStore.query(SolutionFeedback.self)
            let fullWorksheetFeedback = try await Amplify.DataStore.query(FullWorksheetSolution.self)
            
            await MainActor.run {
                feedbackCount = feedback.count + fullWorksheetFeedback.count
            }
            
            return TestResult(
                name: "DataStore Query - Feedback",
                passed: true,
                message: "Found \(feedback.count) single + \(fullWorksheetFeedback.count) full worksheet",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "DataStore Query - Feedback",
                passed: false,
                message: "Error: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testDataStoreHomework() async -> TestResult {
        let start = Date()
        
        do {
            let homework = try await Amplify.DataStore.query(Homework.self)
            await MainActor.run {
                homeworkCount = homework.count
            }
            
            return TestResult(
                name: "DataStore Query - Homework",
                passed: true,
                message: "Found \(homework.count) homework assignments",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "DataStore Query - Homework",
                passed: false,
                message: "Error: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testDataStoreClassrooms() async -> TestResult {
        let start = Date()
        
        do {
            let classrooms = try await Amplify.DataStore.query(Classroom.self)
            await MainActor.run {
                classroomCount = classrooms.count
            }
            
            return TestResult(
                name: "DataStore Query - Classrooms",
                passed: true,
                message: "Found \(classrooms.count) classrooms",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "DataStore Query - Classrooms",
                passed: false,
                message: "Error: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testDataStoreSync() async -> TestResult {
        let start = Date()
        
        // Try to start DataStore and check sync
        do {
            try await dataStoreService.startDataStore()
            
            await MainActor.run {
                syncStatus = "Synced"
                lastSyncTime = Date()
            }
            
            return TestResult(
                name: "DataStore Sync Status",
                passed: true,
                message: "DataStore is syncing properly",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            return TestResult(
                name: "DataStore Sync Status",
                passed: false,
                message: "Error: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func refreshAll() async {
        await listS3Files()
        _ = await testDataStoreWorksheets()
        _ = await testDataStoreQuestions()
        _ = await testDataStoreFeedback()
        _ = await testDataStoreHomework()
        _ = await testDataStoreClassrooms()
        syncStatus = "Ready"
    }
    
    private func listS3Files() async {
        do {
            let files = try await awsService.listSolutions()
            await MainActor.run {
                s3Files = files
            }
        } catch {
            print("Failed to list S3 files: \(error)")
        }
    }
    
    private func clearLocalDataStore() async {
        do {
            try await dataStoreService.clearLocalDataStore()
            await refreshAll()
            syncStatus = "Cache Cleared"
        } catch {
            syncStatus = "Clear Failed"
        }
    }
    
    private func forceResync() async {
        do {
            try await dataStoreService.stopDataStore()
            try await dataStoreService.startDataStore()
            await refreshAll()
            syncStatus = "Resynced"
            lastSyncTime = Date()
        } catch {
            syncStatus = "Resync Failed"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct TestResult: Identifiable {
    let id = UUID()
    let name: String
    let passed: Bool
    let message: String
    let duration: TimeInterval
}

struct TestResultRow: View {
    let result: TestResult
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.passed ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result.name)
                    .font(.subheadline)
                Text(result.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "%.2fs", result.duration))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct StatCard2: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct S3FileRow: View {
    let file: StorageListResult.Item
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForFile(file.key))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.key.components(separatedBy: "/").last ?? file.key)
                    .font(.caption)
                    .lineLimit(1)
                
                Text(file.key)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func iconForFile(_ key: String) -> String {
        if key.hasSuffix(".jpg") || key.hasSuffix(".jpeg") || key.hasSuffix(".png") {
            return "photo"
        } else if key.hasSuffix(".pdf") {
            return "doc.text"
        } else {
            return "doc"
        }
    }
}

struct DataStoreRow: View {
    let label: String
    let count: Int
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(count)")
                .font(.subheadline.bold())
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct AWSSyncTestView_Previews: PreviewProvider {
    static var previews: some View {
        AWSSyncTestView()
    }
}
