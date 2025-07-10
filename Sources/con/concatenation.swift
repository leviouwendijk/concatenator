import Foundation
import ArgumentParser
import plate
import Concatenation

extension DelimiterStyle: @retroactive ExpressibleByArgument { }

struct ConcatenateOptions: ParsableCommand {
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
    
    @Option(name: .shortAndLong, help: "Limit number of lines per file (default: 5000).")
    var lineLimit: Int = 5000
    
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

    var includeStaticIgnores: Bool {
        return !excludeStaticIgnores
    }
}

struct Concatenate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "concat",
        abstract: "Concatenate file contents.",
        subcommands: [Default.self, Select.self],
        defaultSubcommand: Default.self

    )
    
    struct Default: ParsableCommand {
        @OptionGroup var options: ConcatenateOptions
        
        func run() throws {
            let cwd = FileManager.default.currentDirectoryPath

            let parsed = try ConignoreParser.parseFile(at: URL(fileURLWithPath: cwd + "/.conignore"))
            let merged = try IgnoreMap(
                ignoreFiles: parsed.ignoreFiles + options.excludeFiles,
                ignoreDirectories: parsed.ignoreDirectories + options.excludeDirs,
                obscureValues: parsed.obscureValues
            )

            let scanner = try FileScanner(
                concatRoot: cwd,
                maxDepth: options.allSubdirectories ? nil : options.depth,
                includePatterns: options.includeFiles,
                excludeFilePatterns: merged.ignoreFiles,
                excludeDirPatterns: merged.ignoreDirectories,
                includeDotfiles: options.includeDotFiles,
                ignoreMap: merged,
                ignoreStaticDefaults: options.includeStaticIgnores
            )
            let urls = try scanner.scan()

            let outputPath = cwd + "/concatenation.txt"
            let concatenator = FileConcatenator(
                inputFiles: urls,
                outputURL: URL(fileURLWithPath: outputPath),
                delimiterStyle: options.delimiterStyle,
                delimiterClosure: options.delimiterClosure,
                maxLinesPerFile: options.lineLimit,
                trimBlankLines: true,
                relativePaths: options.useRelativePaths,
                rawOutput: options.rawOutput,
                obscureMap: merged.obscureValues,
                copyToClipboard: options.copyToClipboard,
                verbose: options.verboseOutput
            )
            let total = try concatenator.run()
            print("Concatenation completed: \(outputPath)")
            print("\(total) lines concatenated.")
        }
    }

    struct Select: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "select",
            abstract: ".conselect related functions.",
            subcommands: [ConcatenateFromConselect.self, Initialize.self],
            defaultSubcommand: ConcatenateFromConselect.self

        )

        struct Initialize: ParsableCommand {
            static let configuration = CommandConfiguration(
                commandName: "init",
                abstract: "initialize a .conselect file.",
            )

            @Flag(help: "Force overwrite .conselect file")
            var force: Bool = false

            func run() throws {
                let initializer = ConselectInitializer()
                do {
                    try initializer.initialize(force: force)
                    print(".conselect file has been created.")
                } catch ConselectError.alreadyExists {
                    print(".conselect file already exists. Use --force to overwrite.")
                }
            }
        }

        struct ConcatenateFromConselect: ParsableCommand {
            @Option(name: .customLong("select"), help: "Path to .conselect (default: ./.conselect)")
            var selectFile: String?

            @OptionGroup var options: ConcatenateOptions

            @Flag(help: "List matches (debug).")
            var verbose: Bool = false

            func run() throws {
                let cwd = FileManager.default.currentDirectoryPath
                let selPath = selectFile ?? "\(cwd)/.conselect"
                let selection = try ConselectParser.parseFile(at: URL(fileURLWithPath: selPath))

                let parsed = try ConignoreParser.parseFile(at: URL(fileURLWithPath: cwd + "/.conignore"))
                let merged = try IgnoreMap(
                    ignoreFiles: parsed.ignoreFiles + options.excludeFiles,
                    ignoreDirectories: parsed.ignoreDirectories + options.excludeDirs,
                    obscureValues: parsed.obscureValues
                )

                let urls = try selection.resolve(
                    root: cwd,
                    maxDepth: options.allSubdirectories ? nil : options.depth,
                    includeDotfiles: options.includeDotFiles,
                    ignoreMap: merged,
                    verbose: verbose
                )
                guard !urls.isEmpty else {
                    print("No files matched .conselect.")
                    return
                }

                let outputPath = cwd + "/concatenation.txt"
                let concatenator = FileConcatenator(
                    inputFiles: urls,
                    outputURL: URL(fileURLWithPath: outputPath),
                    delimiterStyle: options.delimiterStyle,
                    delimiterClosure: options.delimiterClosure,
                    maxLinesPerFile: options.lineLimit,
                    trimBlankLines: true,
                    relativePaths: options.useRelativePaths,
                    rawOutput: options.rawOutput,
                    obscureMap: merged.obscureValues,
                    copyToClipboard: options.copyToClipboard,
                    verbose: options.verboseOutput
                )
                let total = try concatenator.run()
                print("Concatenation completed: \(outputPath)")
                print("\(total) lines concatenated.")
            }
        }
    }
}
