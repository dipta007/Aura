import CoreGraphics
import Foundation

private func debugLog(_ msg: String) {
    let line = "\(Date()): \(msg)\n"
    if let data = line.data(using: .utf8) {
        if let handle = FileHandle(forWritingAtPath: "/tmp/lumenx.log") {
            handle.seekToEndOfFile()
            handle.write(data)
            handle.closeFile()
        } else {
            FileManager.default.createFile(atPath: "/tmp/lumenx.log", contents: data)
        }
    }
}

class BrightnessController {
    private let coreDisplay = CoreDisplayControl()
    private let m1ddcPath: String?

    /// Cache of display UUID by CGDirectDisplayID
    private var displayUUIDs: [CGDirectDisplayID: String] = [:]

    init() {
        // Find m1ddc binary: bundled first, then system
        let bundledPath = Bundle.main.path(forResource: "m1ddc", ofType: nil)
        let paths = [bundledPath, "/opt/homebrew/bin/m1ddc", "/usr/local/bin/m1ddc"].compactMap { $0 }
        m1ddcPath = paths.first { FileManager.default.fileExists(atPath: $0) }

        if let path = m1ddcPath {
            debugLog("[Brightness] Found m1ddc at \(path)")
            loadDisplayUUIDs()
        } else {
            debugLog("[Brightness] m1ddc not found!")
        }
    }

    func setBrightness(for display: DisplayInfo, to value: Float, manual: Bool = false) {
        let clamped: Float
        if manual {
            clamped = max(0.0, min(1.0, value))
        } else {
            clamped = max(display.minBrightness, min(display.maxBrightness, value))
        }
        let ddcValue = Int(round(clamped * 100))

        if display.isBuiltIn {
            coreDisplay.set(display.id, brightness: clamped)
            debugLog("[Brightness] \(display.name): CoreDisplay set to \(clamped)")
        } else if let uuid = uuidForDisplay(display), let path = m1ddcPath {
            let result = runM1DDC(path: path, args: ["display", uuid, "set", "luminance", "\(ddcValue)"])
            debugLog("[Brightness] \(display.name): DDC set to \(ddcValue) result=\(result ?? "nil")")
        } else {
            debugLog("[Brightness] \(display.name): no control method available (id=\(display.id))")
        }
    }

    private func loadDisplayUUIDs() {
        guard let path = m1ddcPath else { return }
        guard let output = runM1DDC(path: path, args: ["display", "list"]) else { return }

        // Parse lines like: [1] BenQ RD320U (77814E39-2D4F-49C3-B762-3ABCA71A173C)
        for line in output.split(separator: "\n") {
            guard let uuidStart = line.lastIndex(of: "("),
                  let uuidEnd = line.lastIndex(of: ")") else { continue }
            let uuid = String(line[line.index(after: uuidStart)..<uuidEnd])

            // Get display number from [N]
            guard let bracketStart = line.firstIndex(of: "["),
                  let bracketEnd = line.firstIndex(of: "]") else { continue }
            let numStr = String(line[line.index(after: bracketStart)..<bracketEnd])
            guard let displayNum = Int(numStr) else { continue }

            // Get the display ID via m1ddc detailed output
            if let detailed = runM1DDC(path: path, args: ["display", "\(displayNum)", "display", "list", "detailed"]) {
                // Look for "Display ID:" line
                for detailLine in detailed.split(separator: "\n") {
                    if detailLine.contains("Display ID:") {
                        let parts = detailLine.split(separator: ":")
                        if let idStr = parts.last?.trimmingCharacters(in: .whitespaces),
                           let displayID = UInt32(idStr) {
                            displayUUIDs[displayID] = uuid
                            debugLog("[Brightness] Mapped display ID \(displayID) -> UUID \(uuid)")
                        }
                    }
                }
            }
        }

        // If detailed parsing didn't work, fall back to matching by name
        if displayUUIDs.isEmpty {
            debugLog("[Brightness] Falling back to index-based UUID mapping")
            // Parse just the UUIDs in order and we'll match by display index
            var uuids: [String] = []
            for line in output.split(separator: "\n") {
                guard let uuidStart = line.lastIndex(of: "("),
                      let uuidEnd = line.lastIndex(of: ")") else { continue }
                uuids.append(String(line[line.index(after: uuidStart)..<uuidEnd]))
            }
            // Store with a simple key - we'll match by m1ddc display number instead
            for (i, uuid) in uuids.enumerated() {
                // Use m1ddc display number (1-based) as a fallback
                debugLog("[Brightness] m1ddc display \(i+1) -> UUID \(uuid)")
            }
            // Store UUIDs indexed by m1ddc number for name-based matching later
            self.m1ddcUUIDs = uuids
        }
    }

    private var m1ddcUUIDs: [String] = []

    /// Find UUID for a display, matching by name if needed
    func uuidForDisplay(_ display: DisplayInfo) -> String? {
        if let uuid = displayUUIDs[display.id] {
            return uuid
        }
        // If we have m1ddc UUIDs but couldn't map by ID, match by name
        guard let path = m1ddcPath,
              let output = runM1DDC(path: path, args: ["display", "list"]) else { return nil }
        for line in output.split(separator: "\n") {
            if line.contains(display.name) {
                guard let uuidStart = line.lastIndex(of: "("),
                      let uuidEnd = line.lastIndex(of: ")") else { continue }
                let uuid = String(line[line.index(after: uuidStart)..<uuidEnd])
                displayUUIDs[display.id] = uuid
                return uuid
            }
        }
        return nil
    }

    private func runM1DDC(path: String, args: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            debugLog("[Brightness] m1ddc error: \(error)")
            return nil
        }
    }
}
