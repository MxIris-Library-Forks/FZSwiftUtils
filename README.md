# FZSwiftUtils

Swift Foundation extensions and useful classes & utilities.

**For a full documentation take a look at the included documentation located at */Documentation*. Opening the file launches Xcode's documentation browser.**

## Notable Extensions & Classes

### DataSize
A data size abstraction 
```swift
let dataSize = DataSize(gigabytes: 1.5)
dataSize.countStyle = .file // Specifies display of file or storage byte counts
dataSize.megabyte // 1500 megabytes
dataSize.terabyte += 1
dataSize.string(includesUnit: true) // 1tb, 1gb, 500mb
dataSize.string(for: .terabyte, includesUnit: false) // 1,15
```

### TimeDuration
A duration/time interval abstraction 
```swift
let duration = TimeDuration(seconds: 1)
duration.minutes += 2
duration.string(style: .full) // 2 minutes, 1 seconds
duration.string(for: .seconds) =  121 seconds
```

### KeyValueObserver
Observes multiple properties of an object.
```swift
let textField = NSTextField()
let observer = KeyValueObserver(textField)
observer.add(\.stringValue) { oldStringValue, stringValue in
guard oldStringValue != stringValue else { return }
/// Process stringValue
}  
```
 
### NSObject extensions
- `associatedValue`: Getting and setting associated values of an object.
```swift
// Set
button.associatedValue["myAssociatedValue"] = "SomeValue"

// get
if let string: String = button.associatedValue["myAssociatedValue"] {

}
```
- `observeChanges<Value>(for: for keyPath: KeyPath<Self, Value>)`: Observes changes for a property.
```swift
textField.observeChanges(for \.stringValue) { oldStringValue, stringValue in
guard oldStringValue != stringValue else { return }
/// Process stringValue
}  
```

### Progress extensions
- `updateEstimatedTimeRemaining()`: Updates the estimted time remaining and throughput.
- `addFileProgress(url: URL, kind: FileOperationKind = .downloading)`: Shows the file progress in Finder.
```swift
progress.addFileProgress(url: fileURL, kind: .downloading)
```
- `MutableProgress`: A progress that allows to add and remove children progresses.

### Iterate directories & files

Addition `URL` methods for iterating the content of file system directories.

```swift
let downloadsDirectory = URL.downloadsDirectory

// Iterates all files
for fileURL in downloadsDirectory.iterateFiles() {

}

// Iterates all files including hidden files and files in subdirectories.
for fileURL in downloadsDirectory.iterateFiles(.includeHiddenFiles, .includeSubdirectoryDescendants) {

}

// Iterates all subdirectories
for subDirectory in downloadsDirectory.iterateDirectories() {

}
```

### MeasureTime
Meassures the time executing a block.

```swift
let timeElapsed = MeasureTime.timeElapsed() {
/// The block to measure
}
```

### OSHash
An implementation of the OpenSuptitle hash.
```swift
let hash = try? OSHash(url: fileURL)
hash?.Value /// The hash value
```
 
### More…
- `AsyncOperation`: An asynchronous, pausable operation.
- `PausableOperationQueue`: A pausable operation queue.
- `SynchronizedArray`/`SynchronizedDictionary`: A synchronized array/dictioanry.
- `Equatable.isEqual(_ other: any Equatable) -> Bool`: Returns a Boolean value indicating whether the value is equatable to another value.
- `Comparable.isLessThan(_ other: any Comparable) -> Bool`: Returns a Boolean value indicating whether the value is less than another value.
