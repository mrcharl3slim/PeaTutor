//
//  FileHasher.swift
//  PeaTutorApp
//
//  Sub-Sprint 3.3.1: Hash calculation utility for duplicate detection
//

import Foundation
import UIKit
import CryptoKit

struct FileHasher {
    
    // MARK: - Hash Calculation
    
    /// Calculate SHA256 hash for file data
    static func calculateHash(for data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Calculate hash for a file URL
    static func calculateHash(for url: URL) -> String? {
        guard url.startAccessingSecurityScopedResource() else {
            print("❌ FileHasher: Could not access security-scoped resource")
            return nil
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        var data: Data?
        let coordinator = NSFileCoordinator()
        var error: NSError?
        
        coordinator.coordinate(readingItemAt: url, options: [.forUploading], error: &error) { newURL in
            do {
                data = try Data(contentsOf: newURL)
            } catch {
                print("❌ FileHasher: Failed to read file: \(error)")
            }
        }
        
        if let error = error {
            print("❌ FileHasher: Coordination error: \(error)")
            return nil
        }
        
        guard let fileData = data else {
            print("❌ FileHasher: No data available")
            return nil
        }
        
        return calculateHash(for: fileData)
    }
    
    /// Calculate hash for a UIImage (as JPEG data)
    static func calculateHash(for image: UIImage) -> String? {
        // Use same quality as extraction to ensure consistent hash
        guard let imageData = image.jpegData(compressionQuality: 0.95) else {
            print("❌ FileHasher: Could not convert image to JPEG")
            return nil
        }
        
        return calculateHash(for: imageData)
    }
    
    /// Calculate combined hash for multiple sources
    static func calculateCombinedHash(from hashes: [String]) -> String {
        // Sort hashes to ensure consistent ordering
        let sortedHashes = hashes.sorted()
        let combined = sortedHashes.joined(separator: "|")
        
        guard let data = combined.data(using: .utf8) else {
            return ""
        }
        
        return calculateHash(for: data)
    }
    
    // MARK: - Batch Processing
    
    /// Calculate hashes for multiple files
    static func calculateHashes(for urls: [URL]) -> [String] {
        return urls.compactMap { calculateHash(for: $0) }
    }
    
    /// Calculate hashes for multiple images
    static func calculateHashes(for images: [UIImage]) -> [String] {
        return images.compactMap { calculateHash(for: $0) }
    }
    
    // MARK: - Validation
    
    /// Check if a hash string is valid (64 hex characters)
    static func isValidHash(_ hash: String) -> Bool {
        let hexPattern = "^[a-fA-F0-9]{64}$"
        let regex = try? NSRegularExpression(pattern: hexPattern)
        let range = NSRange(location: 0, length: hash.utf16.count)
        return regex?.firstMatch(in: hash, range: range) != nil
    }
}

// MARK: - Hash Result Model
struct HashCalculationResult {
    let individualHashes: [String]
    let combinedHash: String
    let sourceNames: [String]
    
    var allHashes: [String] {
        return individualHashes + [combinedHash]
    }
}
