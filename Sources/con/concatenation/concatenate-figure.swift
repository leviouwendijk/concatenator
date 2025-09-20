import Foundation
import ArgumentParser
import plate
import Concatenation

extension Concatenate {
    struct Figure: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "figure",
            abstract: "Manage the .configure file.",
            subcommands: [Init.self, ConcatenateFromConfigure.self],
            defaultSubcommand: ConcatenateFromConfigure.self
        )

        struct Init: ParsableCommand {
            @Flag(help: "Force overwrite existing .configure")
            var force: Bool = false

            func run() throws {
                let initializer = ConfigureInitializer()
                do {
                    try initializer.initialize(force: force)
                    print(".configure created.")
                } catch ConfigureError.alreadyExists {
                    print(".configure already exists, use --force to overwrite.")
                }
            }
        }

        struct ConcatenateFromConfigure: ParsableCommand {
            @Option(name: .customLong("figure"), help: "Path to .configure (default: ./.configure)")
            var figureFile: String?

            @OptionGroup var options: ConcatenateOptions

            @Flag(help: "List matches (debug).")
            var verbose: Bool = false

            func run() throws {
                let cwd = FileManager.default.currentDirectoryPath
                let figPath = figureFile ?? "\(cwd)/.configure"
                let filters = try ConfigureParser.parseFile(at: URL(fileURLWithPath: figPath))

                let finalMap: IgnoreMap
                if let parsed = try? ConignoreParser.parseFile(at: URL(fileURLWithPath: cwd + "/.conignore")) {
                    let merged = try IgnoreMap(
                        ignoreFiles: parsed.ignoreFiles + options.excludeFiles,
                        ignoreDirectories: parsed.ignoreDirectories + options.excludeDirs,
                        obscureValues: parsed.obscureValues
                    )
                    finalMap = merged
                } else {
                    let argMap = try IgnoreMap(
                        ignoreFiles: options.excludeFiles,
                        ignoreDirectories: options.excludeDirs,
                        obscureValues: [:]
                    )
                    finalMap = argMap
                }

                let resolver = ConfigureResolver(
                    root: cwd,
                    maxDepth: options.allSubdirectories ? nil : options.depth,
                    includeDotfiles: options.includeDotFiles,
                    ignoreMap: finalMap
                )
                let snippets = try resolver.resolve(filters: filters)

                guard !snippets.isEmpty else {
                    print("No snippets matched .configure.")
                    return
                }

                let outputPath = cwd + "/" + (options.outputFileName ?? "configure.txt")
                let snippetConcatenator = SnippetConcatenator(
                    snippets: snippets,
                    outputURL: URL(fileURLWithPath: outputPath),
                    delimiterStyle: options.delimiterStyle,
                    delimiterClosure: options.delimiterClosure,
                    copyToClipboard: options.copyToClipboard,
                    verbose: verbose
                )
                let total = try snippetConcatenator.run()
                // print("Concatenation completed: \(outputPath)")
                // print("\(total) lines concatenated.")
                printSuccess(
                    outputPath: outputPath,
                    totalLines: total
                )
            }
        }
    }
}
