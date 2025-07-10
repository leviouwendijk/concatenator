import Foundation
import ArgumentParser
import plate
import Concatenation

struct Tree: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tree",
        abstract: "Generate a hierarchical file tree."
    )
    
    @Option(name: .shortAndLong, help: "Specify directories to include (default: current directory).")
    var directories: [String] = [FileManager.default.currentDirectoryPath]
    
    @Option(name: .customLong("de"), help: "Exclude specified directories from processing.")
    var excludeDirs: [String] = []
    
    @Option(name: [.customShort("s"), .customLong("depth")], help: "Set maximum scope / depth level to scan (default: unlimited).")
    var depth: Int? = nil
    
    @Flag(name: .customLong("all"), help: "Iterate over all subdirectories.")
    var allSubdirectories: Bool = false
    
    @Flag(name: [.customShort("."), .customLong("dot")], help: "Include dotfiles and dot directories (default: false).")
    var includeDotFiles: Bool = false
    
    @Option(name: .shortAndLong, help: "Include specific files (supports wildcards, e.g., *.txt).")
    var includeFiles: [String] = ["*"]
    
    @Option(name: .customLong("fe"), help: "Exclude specific files (supports wildcards, e.g., *.log).")
    var excludeFiles: [String] = []

    @Flag(name: .customLong("verbose"), help: "Enable debugging output.")
    var verboseOutput: Bool = false

    @Flag(name: .customLong("no-trailing-slash"), help: "Enable debugging output.")
    var removeTrailingSlash: Bool = false

    @Flag(name: [.customShort("e"), .customLong("include-empty")], help: "Include empty files and directories in the file tree.")
    var includeEmpty: Bool = false

    @Flag(name: .shortAndLong, help: "Copy the concatenation output to clipboard.")
    var copyToClipboard: Bool = false

    @Flag(name: .shortAndLong, help: "Don't write output to a file.")
    var clean: Bool = false

    @Flag(name: .shortAndLong, help: "Excluding the statically ignored files (may contain sensitive content)")
    var excludeStaticIgnores: Bool = false

    private var includeStaticIgnores: Bool {
        return !excludeStaticIgnores
    }
    
    func run() throws {
        let parsed = try ConignoreParser.parseFile(
            at: URL(fileURLWithPath: directories[0] + "/.conignore")
        )
        let merged = try IgnoreMap(
            ignoreFiles: parsed.ignoreFiles + excludeFiles,
            ignoreDirectories: parsed.ignoreDirectories + excludeDirs,
            obscureValues: parsed.obscureValues
        )
        let scanner = try FileScanner(
            treeRoot: directories[0],
            maxDepth: allSubdirectories ? nil : depth,
            includePatterns: includeFiles,
            excludeFilePatterns: merged.ignoreFiles,
            excludeDirPatterns: merged.ignoreDirectories,
            includeDotfiles: includeDotFiles,
            includeEmpty: includeEmpty,
            ignoreMap: merged,
            ignoreStaticDefaults: includeStaticIgnores
        )
        let urls = try scanner.scan()
        if urls.isEmpty {
            print("No files found in the specified directories.")
            return
        }
        let copyPolicy = clean || copyToClipboard
        let maker = FileTreeMaker(
            files: urls,
            rootPath: directories[0],
            removeTrailingSlash: removeTrailingSlash,
            copyToClipboard: copyPolicy
        )
        let tree = maker.generate()
        if !clean {
            let path = FileManager.default.currentDirectoryPath + "/tree"
            try tree.write(toFile: path, atomically: true, encoding: .utf8)
            print("File tree generated: \(path)")
        } else {
            print("Tree copied.")
            print("-c (copy) flag auto-set to true.")
            print("No file was written.")
        }
    }
}
