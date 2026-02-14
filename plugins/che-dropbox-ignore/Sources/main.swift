// dropbox-ignore — Detect and exclude build artifacts from Dropbox sync
// Uses com.dropbox.ignored xattr via Darwin C functions (zero process fork)

import Foundation
import Darwin

// MARK: - Configuration

let kDropboxIgnoredAttr = "com.dropbox.ignored"
let kMaxDepth = Int.max

let dropboxPrefixes: [String] = {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    return [
        home + "/Library/CloudStorage/Dropbox",
        home + "/Dropbox"
    ]
}()

/// Directories to always exclude by exact name
let alwaysExclude: Set<String> = [
    ".git", ".build", ".swiftpm",
    "node_modules", ".next", ".nuxt", "dist",
    ".cache", "__pycache__", ".venv", "venv", ".tox",
    "target", "Pods", ".gradle", ".dart_tool", ".pub-cache",
    "xcuserdata"
]

/// Directory bundles to exclude by file extension (Xcode artifacts)
let alwaysExcludeSuffixes: [String] = [
    ".xcodeproj", ".xcworkspace", ".dSYM"
]

/// Files to exclude by file extension
let alwaysExcludeFileSuffixes: [String] = [
    ".profraw", ".profdata"
]

/// "build" is conditional — only exclude when parent has package.json or CMakeLists.txt
let conditionalBuild = "build"

// MARK: - xattr helpers (direct C calls, zero fork)

func isIgnored(at path: String) -> Bool {
    var buf = [CChar](repeating: 0, count: 8)
    let size = getxattr(path, kDropboxIgnoredAttr, &buf, buf.count, 0, 0)
    guard size > 0 else { return false }
    return String(cString: buf) == "1"
}

func setIgnored(at path: String) -> Bool {
    let value = "1"
    let result = setxattr(path, kDropboxIgnoredAttr, value, value.count, 0, 0)
    return result == 0
}

// MARK: - Path helpers

func isUnderDropbox(_ path: String) -> Bool {
    for prefix in dropboxPrefixes {
        if path == prefix || path.hasPrefix(prefix + "/") {
            return true
        }
    }
    return false
}

func resolvePath(_ raw: String) -> String? {
    let url = URL(fileURLWithPath: raw).standardized
    // Verify it exists
    var isDir: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
        return nil
    }
    return url.path
}

// MARK: - Main scan

func scan(root: String) {
    let fm = FileManager.default
    guard let enumerator = fm.enumerator(
        at: URL(fileURLWithPath: root),
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.producesRelativePathURLs]
    ) else {
        fputs("Error: cannot enumerate \(root)\n", stderr)
        return
    }

    var newCount = 0
    var skipCount = 0

    while let url = enumerator.nextObject() as? URL {
        // Depth control
        if enumerator.level > kMaxDepth {
            enumerator.skipDescendants()
            continue
        }

        let fullPath: String
        if url.relativePath.hasPrefix("/") {
            fullPath = url.path
        } else {
            fullPath = root + "/" + url.relativePath
        }
        let name = url.lastPathComponent

        let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
        let isDir = values?.isDirectory == true

        // --- File exclusion (by suffix) ---
        if !isDir {
            if alwaysExcludeFileSuffixes.contains(where: { name.hasSuffix($0) }) {
                if isIgnored(at: fullPath) {
                    skipCount += 1
                } else if setIgnored(at: fullPath) {
                    newCount += 1
                }
            }
            continue
        }

        // --- Directory exclusion: exact name ---
        if alwaysExclude.contains(name) {
            enumerator.skipDescendants()
            if isIgnored(at: fullPath) {
                skipCount += 1
            } else if setIgnored(at: fullPath) {
                newCount += 1
            }
            continue
        }

        // --- Directory exclusion: suffix match (Xcode bundles) ---
        if alwaysExcludeSuffixes.contains(where: { name.hasSuffix($0) }) {
            enumerator.skipDescendants()
            if isIgnored(at: fullPath) {
                skipCount += 1
            } else if setIgnored(at: fullPath) {
                newCount += 1
            }
            continue
        }

        // --- Conditional: "build" directory ---
        if name == conditionalBuild {
            let parentPath = URL(fileURLWithPath: fullPath).deletingLastPathComponent().path
            let hasPackageJson = fm.fileExists(atPath: parentPath + "/package.json")
            let hasCMake = fm.fileExists(atPath: parentPath + "/CMakeLists.txt")
            if hasPackageJson || hasCMake {
                enumerator.skipDescendants()
                if isIgnored(at: fullPath) {
                    skipCount += 1
                } else if setIgnored(at: fullPath) {
                    newCount += 1
                }
            }
            continue
        }
    }

    // Output summary (only if something happened)
    if newCount > 0 || skipCount > 0 {
        print("Dropbox Ignore: \(newCount) newly excluded, \(skipCount) already excluded")
    }
}

// MARK: - Entry point

let scanPath: String
if CommandLine.arguments.count > 1 {
    guard let resolved = resolvePath(CommandLine.arguments[1]) else {
        fputs("Error: path does not exist or is not a directory: \(CommandLine.arguments[1])\n", stderr)
        exit(1)
    }
    scanPath = resolved
} else {
    guard let resolved = resolvePath(FileManager.default.currentDirectoryPath) else {
        exit(0)
    }
    scanPath = resolved
}

// Not under Dropbox — exit silently
guard isUnderDropbox(scanPath) else { exit(0) }

scan(root: scanPath)
