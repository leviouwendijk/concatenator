import Foundation
import plate

public func printSuccess(
    outputPath: String,
    totalLines total: Int
) {
    let statusLine = "Status: " + "ok".ansi(.green)

    print("Concatenation completed:")
    print(statusLine.indent())
    print(outputPath.indent())
    print("\(total) lines concatenated.")
    print()
}
