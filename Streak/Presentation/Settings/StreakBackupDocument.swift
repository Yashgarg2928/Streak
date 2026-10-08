// Presentation/Settings/StreakBackupDocument.swift
// Wraps backup bytes for SwiftUI's file exporter.

import SwiftUI
import UniformTypeIdentifiers

nonisolated struct StreakBackupDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.propertyList]

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
