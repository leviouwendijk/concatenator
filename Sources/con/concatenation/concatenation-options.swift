import Foundation
import ArgumentParser
import plate
import Concatenation

extension DelimiterStyle: @retroactive ExpressibleByArgument { }

struct ConcatenateOptions: ParsableCommand {
    @Option(name: .shortAndLong, help: "Set output file name.")
    var outputFileName: String? = nil

    @Option(name: .shortAndLong, help: "Specify directories to include (default: current directory).")
    var directories: [String] = [FileManager.default.currentDirectoryPath]
    
    @Option(name: .customLong("de"), help: "Exclude specified directories from processing.")
    var excludeDirs: [String] = []
    
    @Option(name: [.customShort("s"), .customLong("depth")], help: "Set maximum scope / depth level to scan (default: unlimited).")
    var depth: Int? = nil  // Default to unlimited depth.

    @Flag(name: .customLong("all"), help: "Iterate over all subdirectories.")
    var allSubdirectories: Bool = false
    
    @Flag(name: [.customShort("."), .customLong("dot")], help: "Include dotfiles and dot directories (default: false).")
    var includeDotFiles: Bool = false
    
    @Option(name: .shortAndLong, help: "Include specific files for concatenation (supports wildcards, e.g., *.txt).")
    var includeFiles: [String] = ["*"]
    
    @Option(name: .customLong("fe"), help: "Exclude specific files from concatenation (supports wildcards, e.g., *.log).")
    var excludeFiles: [String] = []
    
    @Option(name: .shortAndLong, help: "Limit number of lines per file (default: 10_000).")
    var lineLimit: Int?
    
    @Flag(name: .customLong("verbose-out"), help: "Enable debugging output.")
    var verboseOutput: Bool = false
    
    @Option(name: .customLong("delimiter"), help: "Set delimiter style (none, basic, verbose).")
    var delimiterStyle: DelimiterStyle = .boxed

    @Flag(name: .customLong("closure"), help: "Add a end-of-file delimiter.")
    var delimiterClosure: Bool = false
    
    @Option(name: .customLong("relative"), help: "Use relative paths in headers instead of absolute paths (true/false).")
    var useRelativePaths: Bool = true
    
    @Flag(name: .customLong("raw"), help: "Avoid headers or file tree, preserve syntax.")
    var rawOutput: Bool = false
    
    @Flag(name: .shortAndLong, help: "Copy the concatenation output to clipboard.")
    var copyToClipboard: Bool = false

    @Flag(name: .shortAndLong, help: "Excluding the statically ignored files (may contain sensitive content)")
    var excludeStaticIgnores: Bool = false

    @Flag(name: .shortAndLong, help: "Allow files to be concatenated that are otherwise excluded by protection defaults.")
    var allowSecrets: Bool = false
    
    @Flag(name: .shortAndLong, help: "Turn off deep inspection for file protection of secrets.")
    var noDeepInspect: Bool = false

    var deepInspect: Bool {
        return !noDeepInspect
    }

    var includeStaticIgnores: Bool {
        return !excludeStaticIgnores
    }

    func limit() -> Int? {
        return lineLimit == nil ? 10_000 : lineLimit == 0   ? nil : lineLimit
    }
}
