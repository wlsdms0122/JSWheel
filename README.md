# JSWheel
`JSWheel` is an easy and intuitive wheel picker component for [SwiftUI](https://developer.apple.com/kr/xcode/swiftui/).

- [Requirements](#requirements)
- [Installation](#installation)
  - [Swift Package Manager](#swift-package-manager)
- [Getting Started](#getting-started)
  - [Basic Usage](#basic-usage)
  - [Additional Options](#additional-options)
- [Contribution](#contribution)
- [License](#license)

# Requirements

- iOS 14.0+

# Installation
## Swift Package Manager
```swift
dependencies: [
    .package(url: "https://github.com/wlsdms0122/JSWheel.git", from: "1.0.0")
]
```

# Getting Started
## Basic Usage
To use `JSWheel`, you can place the wheel picker within a view. Here's a simple example:

```swift
struct ContentView: View {
    var body: some View {
        JSWheel(selection: $selectedItem, data: items) { [selectedItem] item in
            Text(item).padding()
        }
    }

    @State
    private var selectedItem: String?
    private let items = ["Option 1", "Option 2", "Option 3", "Option 4", "Option 5"]
}
```

In this example, a wheel picker is created with a list of string options. The selected item is bound to the `selectedItem` state variable.

The full initializer parameters for JSWheel are as follows:

```swift
JSWheel(
    selection: Binding<Data.Element?>,
    data: Data,
    id: KeyPath<Data.Element, ID>,
    @ViewBuilder content: @escaping (Data.Element) -> Content
)
```

## Additional Options
You can configure additional options for the wheel using [Stylish](https://github.com/wlsdms0122/Stylish).

```swift
@Stylish
public struct JSWheelOption {
    /// The height of each item in the wheel.
    public var itemHeight: CGFloat = 32
    /// The spacing between items in the wheel.
    public var spacing: CGFloat = 0
}
```

For more detailed information, check out the sample preview in the source code.

# Contribution

Any ideas, issues, opinions are welcome.

# License

`JSWheel` is available under the MIT license. See the LICENSE file for more info.
