import Foundation
import ArgumentParser

struct ConcatApp: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "con",
        abstract: "A tool to concatenate file contents or generate a file tree.",
        subcommands: [Concatenate.self, Tree.self, Ignore.self],
        defaultSubcommand: Concatenate.self
    )
}

ConcatApp.main()
