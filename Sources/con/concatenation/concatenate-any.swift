import Foundation
import ArgumentParser
import plate
import Concatenation

extension Concatenate {
    struct `Any`: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "any",
            abstract: "Concatenate arbitrary absolute/relative files via .conany.",
            subcommands: [Init.self, Run.self],
            defaultSubcommand: Run.self
        )

        struct Init: ParsableCommand {
            @Flag(help: "Force overwrite existing .conany")
            var force: Bool = false

            func run() throws {
                let initr = ConAnyInitializer()
                do { try initr.initialize(force: force); print(".conany created.") }
                catch ConAnyInitError.alreadyExists { print(".conany already exists. Use --force to overwrite.") }
            }
        }

        struct Run: ParsableCommand {
            @Option(name: .customLong("config"), help: "Path to .conany (default: ./.conany)")
            var configPath: String?

            @OptionGroup var options: ConcatenateOptions
            @Flag(help: "Verbose resolution")
            var verbose: Bool = false

            func run() throws {
                let cwd = FileManager.default.currentDirectoryPath
                let cfgURL = URL(fileURLWithPath: configPath ?? "\(cwd)/.conany").standardizedFileURL
                let cfg = try ConAnyParser.parseFile(at: cfgURL)

                // optional .conignore merge (reuse your existing logic)
                let finalMap: IgnoreMap
                if let parsed = try? ConignoreParser.parseFile(at: URL(fileURLWithPath: cwd + "/.conignore")) {
                    finalMap = try IgnoreMap(
                        ignoreFiles: parsed.ignoreFiles + options.excludeFiles,
                        ignoreDirectories: parsed.ignoreDirectories + options.excludeDirs,
                        obscureValues: parsed.obscureValues
                    )
                } else {
                    finalMap = try IgnoreMap(
                        ignoreFiles: options.excludeFiles,
                        ignoreDirectories: options.excludeDirs,
                        obscureValues: [:]
                    )
                }

                let resolver = ConAnyResolver(baseDir: cfgURL.deletingLastPathComponent().path)

                var totalLinesAll = 0
                for r in cfg.renderables {
                    let urls = try resolver.resolve(r,
                        maxDepth: options.allSubdirectories ? nil : options.depth,
                        includeDotfiles: options.includeDotFiles,
                        ignoreMap: finalMap,
                        verbose: verbose
                    )

                    guard !urls.isEmpty else {
                        print("No files matched block → \(r.output ?? "any.txt")")
                        continue
                    }

                    let outURL = resolver.outputURL(for: r)
                    // let context = "con any block '\(r.output ?? "nil")' → \(outURL.path)"
                    let location = "con any block '\(r.output ?? "nil")' → \(outURL.path)"
                    let concat = FileConcatenator(
                        inputFiles: urls,
                        outputURL: outURL,
                        context: r.context,

                        delimiterStyle: options.delimiterStyle,
                        delimiterClosure: options.delimiterClosure,
                        maxLinesPerFile: options.limit(),
                        trimBlankLines: true,
                        relativePaths: false,
                        rawOutput: options.rawOutput,
                        obscureMap: finalMap.obscureValues,

                        copyToClipboard: options.copyToClipboard,
                        verbose: options.verboseOutput,

                        // context: context,
                        location: location,
                        allowSecrets: options.allowSecrets,
                        deepSecretInspection: options.deepInspect
                    )
                    let total = try concat.run()
                    totalLinesAll += total
                    // print("Concatenation completed: \(outURL.path)")
                    // print("  \(total) lines.")
                    printSuccess(
                        outputPath: outURL.path,
                        totalLines: total
                    )
                }

                if cfg.renderables.count > 1 {
                    print("Done. Blocks: \(cfg.renderables.count), total lines: \(totalLinesAll).")
                }
            }
        }
    }
}
