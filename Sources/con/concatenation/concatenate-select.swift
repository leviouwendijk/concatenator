import Foundation
import ArgumentParser
import plate
import Concatenation

extension Concatenate {
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

                let urls = try selection.resolve(
                    root: cwd,
                    maxDepth: options.allSubdirectories ? nil : options.depth,
                    includeDotfiles: options.includeDotFiles,
                    ignoreMap: finalMap,
                    verbose: verbose
                )
                guard !urls.isEmpty else {
                    print("No files matched .conselect.")
                    return
                }

                let outputPath = cwd + "/" + (options.outputFileName ?? "conselection.txt")
                let concatenator = FileConcatenator(
                    inputFiles: urls,
                    outputURL: URL(fileURLWithPath: outputPath),
                    delimiterStyle: options.delimiterStyle,
                    delimiterClosure: options.delimiterClosure,
                    maxLinesPerFile: options.limit(),
                    trimBlankLines: true,
                    relativePaths: options.useRelativePaths,
                    rawOutput: options.rawOutput,
                    obscureMap: finalMap.obscureValues,
                    copyToClipboard: options.copyToClipboard,
                    verbose: options.verboseOutput,
                    allowSecrets: options.allowSecrets,
                    deepSecretInspection: options.deepInspect
                )
                let total = try concatenator.run()
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
