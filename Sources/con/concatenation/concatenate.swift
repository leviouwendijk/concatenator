import Foundation
import ArgumentParser
import plate
import Concatenation

struct Concatenate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "concat",
        abstract: "Concatenate file contents.",
        subcommands: [Default.self, Select.self, Figure.self, `Any`.self],
        defaultSubcommand: Default.self
    )
}
