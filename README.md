# HtmlToPdf

HtmlToPdf provides an easy-to-use interface for concurrently printing HTML to PDF on iOS and macOS.

## Features

- Convert HTML strings to PDF documents on both iOS and macOS.
- Lightweight and fast: it can handle thousands of documents quickly.
- Customize margins for PDF documents.
- Swift 6 language mode enabled
- And one more thing: easily print images in your PDFs!

## Examples

Print to a file url:
```swift
try await "<html><body><h1>Hello, World 1!</h1></body></html>".print(to: URL(...))
```
Print to a directory with a file title.
```swift
let directory = URL(...)
let html = "<html><body><h1>Hello, World 1!</h1></body></html>"
try await html.print(title: "file title", to: directory)
```

Print a collection to a directory.
```swift
let directory = URL(...)
try await [
    html,
    html,
    html,
    ....
]
.print(to: directory)
```

## Performance

The package includes a test that prints 1000 HTML strings to PDFs in ~2.6 seconds (using ``UIPrintPageRenderer`` on iOS or Mac Catalyst) or ~12 seconds (using ``NSPrintOperation`` on MacOS).

```swift
@Test func collection() async throws {
    [...]
    let count = 1_000
    try await [String].init(
        repeating: "<html><body><h1>Hello, World 1!</h1></body></html>",
        count: count
    )
    .print(to: URL(...))
    [...]
}
```

### ``AsyncStream<URL>``

Optionally, you can invoke an overload that returns an ``AsyncStream<URL>`` that yields the URL of each printed PDF.
> [!NOTE] 
> You need to include the ``AsyncStream`` type signature in the variable declaration, otherwise the return value will be Void.

```swift
let directory = URL(...)
let urls: AsyncStream = try await [
    html,
    html,
    html,
    ....
]
.print(to: directory)

for await url in urls {
    Swift.print(url)
}
```

## Including Images in PDFs

HtmlToPdf supports base64-encoded images out of the box.

> [!Important]
> You are responsible for encoding your images to base64.

### Example HTML
The example below will correctly render the image in the HTML, assuming the `[...]` is replaced with a valid base64-encoded string.

```swift
"<html><body><h1>Hello, World 1!</h1><img src="data:image/png;charset=utf-8;base64, [...]" alt="imageDescription"></body></html>"
   .print(to: URL(...))
```

> [!Tip]
> You can use swift to load the image from a relative or absolute path and then convert them to base64.
> Here's how you can achieve this using the convenience initializer on Image using [coenttb/swift-html](https://www.github.com/coenttb/swift-html):
> ```
> struct Example: HTML {
>     var body: some HTML {
>         [...]
>         if let image = Image(base64EncodedFromURL: "path/to/your/image.jpg", description: "Description of the image") {
>             image
>         }
>         [...]
>     }
> } 
> ```
> [Click here for the implementation of `Image.init(base64EncodedFromURL:)`](https://github.com/coenttb/swift-html/blob/main/Sources/HTML/Image.swift), which shows how to encode an image to base64.

## Related projects

### The coenttb stack

* [swift-css](https://www.github.com/coenttb/swift-css): A Swift DSL for type-safe CSS.
* [swift-html](https://www.github.com/coenttb/swift-html): A Swift DSL for type-safe HTML & CSS, integrating [swift-css](https://www.github.com/coenttb/swift-css) and [pointfree-html](https://www.github.com/coenttb/pointfree-html).
* [swift-web](https://www.github.com/coenttb/swift-web): Foundational tools for web development in Swift.
* [coenttb-html](https://www.github.com/coenttb/coenttb-html): Builds on [swift-html](https://www.github.com/coenttb/swift-html), and adds functionality for HTML, Markdown, Email, and printing HTML to PDF.
* [coenttb-web](https://www.github.com/coenttb/coenttb-web): Builds on [swift-web](https://www.github.com/coenttb/swift-web), and adds functionality for web development.
* [coenttb-server](https://www.github.com/coenttb/coenttb-server): Build fast, modern, and safe servers that are a joy to write. `coenttb-server` builds on [coenttb-web](https://www.github.com/coenttb/coenttb-web), and adds functionality for server development.
* [coenttb-vapor](https://www.github.com/coenttb/coenttb-server-vapor): `coenttb-server-vapor` builds on [coenttb-server](https://www.github.com/coenttb/coenttb-server), and adds functionality and integrations with Vapor and Fluent.
* [coenttb-com-server](https://www.github.com/coenttb/coenttb-com-server): The backend server for coenttb.com, written entirely in Swift and powered by [coenttb-server-vapor](https://www.github.com/coenttb-server-vapor).

### PointFree foundations
* [coenttb/pointfree-html](https://www.github.com/coenttb/pointfree-html): A Swift DSL for type-safe HTML, forked from [pointfreeco/swift-html](https://www.github.com/pointfreeco/swift-html) and updated to the version on [pointfreeco/pointfreeco](https://github.com/pointfreeco/pointfreeco).
* [coenttb/pointfree-web](https://www.github.com/coenttb/pointfree-html): Foundational tools for web development in Swift, forked from  [pointfreeco/swift-web](https://www.github.com/pointfreeco/swift-web).
* [coenttb/pointfree-server](https://www.github.com/coenttb/pointfree-html): Foundational tools for server development in Swift, forked from  [pointfreeco/swift-web](https://www.github.com/pointfreeco/swift-web).

## Installation

To install the package, add the following line to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/coenttb/swift-html-to-pdf.git", from: "0.1.0")
]
```

You can then make HtmlToPdf available to your Package's target by including HtmlToPdf in your target's dependencies as follows:
```swift
targets: [
    .target(
        name: "TheNameOfYourTarget",
        dependencies: [
            .product(name: "HtmlToPdf", package: "swift-html-to-pdf")
        ]
    )
]
```
