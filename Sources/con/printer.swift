import Foundation
import plate

public func printSuccess(
    outputPath: String,
    totalLines total: Int
) {
    // let statusLine = "Status: " + "ok".ansi(.green)
    let pathLine = "source: \(outputPath)".ansi(.brightBlack)

    let headerLine = "Concatenation " + "ok".ansi(.green, .bold)
    let totalsLine = "\(total) ".ansi(.cyan) + "lines concatenated"

    // print("Concatenation completed:")
    print(headerLine)
    // print(statusLine.indent())
    print(pathLine.indent())
    // print("\(total) lines concatenated.".indent())
    print(totalsLine.indent())
    print()
}
