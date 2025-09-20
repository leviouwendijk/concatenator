import Foundation
import ArgumentParser
import plate
import Concatenation

extension Concatenate {
    struct Default: ParsableCommand {
        @OptionGroup var options: ConcatenateOptions
        
        func run() throws {
            let cwd = FileManager.default.currentDirectoryPath

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

            let scanner = try FileScanner(
                concatRoot: cwd,
                maxDepth: options.allSubdirectories ? nil : options.depth,
                includePatterns: options.includeFiles,
                excludeFilePatterns: finalMap.ignoreFiles,
                excludeDirPatterns: finalMap.ignoreDirectories,
                includeDotfiles: options.includeDotFiles,
                ignoreMap: finalMap,
                ignoreStaticDefaults: options.includeStaticIgnores
            )
            let urls = try scanner.scan()

            let outputPath = cwd + "/" + (options.outputFileName ?? "concatenation.txt")
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

            printSuccess(
                outputPath: outputPath,
                totalLines: total
            )
            // print("Concatenation completed:")
            // let statusLine = "Status: " + "ok".ansi(.green)
            // print(statusLine.indent())
            // print(outputPath.indent())
            // print("\(total) lines concatenated.")
        }
    }
}
