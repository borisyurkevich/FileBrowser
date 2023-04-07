# FileBrowser

<strong>Plain Text Editor With Document Browser.</strong>

<img src="screenshot.png" width="50%" alt="3 pane Mac application with select folder button list of files and text editor">

This is a sample project I decided to publish together with [the blog post][1] with everything 
I learned so far about working with the file system on macOS. There are not many modern working `AppKit` code examples out there. 
It's fun to develop for the Mac, and I hope this helps someone, it always great to 
see more native applications out there. 

## Requirements

- Mac running macOS 13.1 or newer
- Xcode installed 

## Features

- `SwiftUI`
- Monitors file changes with [`DispatchSource`][2] 
- Basic text editing
- Working example of how to use `NSDocument`
- Pick a root folder and get permanent read/write access to all non-nested files inside without violating the Sandobx
- No need for full disk access or permission dialogues 
- Conflicts resolution
- Potentially compatible with `UIKit`

## Contributions and Disclosure

This project is learning process for me, feel free to suggest changes and raise issues. I am not looking to add any new UI features, but instead interested in improving app, document, and editor models. 

I can't guarantee that the code is written in the best way and bug-free.

## Wants

- Any improvements which utilise more of the `NSDocument` features, and using more higher level APIs, like `NSDocumentController`
- iOS and iPadOS compatibility
- Customisation for conflict resolution, allowing a user to update documents from disk from changes made externally. The app will possibly need a setting to change behaviour
- Possibly this can be turned into a Swift Package for easier integration into larger projects
- Handling a scenario when root folder is moved or renamed

Visit my [website,](https://www.cocoa.productions) subscribe to my [micro blog.](https://micro.cocoaswitch.com)

[1]: https://micro.cocoaswitch.com/2023/04/06/working-with-file.html
[2]: https://developer.apple.com/documentation/dispatch/dispatchsource
