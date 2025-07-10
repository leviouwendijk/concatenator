import Foundation
import ArgumentParser
import Concatenation

struct Ignore: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ignore",
        abstract: "Manage the .conignore file."
    )

    @Flag(name: .customLong("comments"), help: "Initialize the .conignore file with comments.")
    var comments: Bool = false

    @Flag(name: .customLong("force"), help: "Force re-initialization of the .conignore file.")
    var force: Bool = false

    @Flag(name: .customLong("transfer"), help: "Transfer unique entries from the existing .conignore file during re-initialization.")
    var transfer: Bool = false

    @Flag(name: .customLong("help"), help: "Print a guide on how to use the .conignore file.")
    var showGuide: Bool = false

    func run() throws {
        let initializer = ConignoreInitializer()
        if showGuide {
            initializer.printGuide()
            return
        }
        do {
            try initializer.initialize(
                template: comments ? .comments : .clean,
                force: force,
                transfer: transfer
            )
            let message: String
            if force {
                message = transfer
                    ? ".conignore file has been reinitialized with transferred content."
                    : ".conignore file has been reinitialized without transferring content."
            } else {
                message = ".conignore file has been created."
            }
            print(message)
        } catch ConIgnoreError.alreadyExists {
            print(".conignore file already exists. Use --force to reinitialize.")
        }
    }
}
