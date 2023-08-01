//
//  Progress+.swift
//
//
//  Created by Florian Zand on 01.03.23.
//

import Foundation

public extension Progress {
    /// The identifier of the progress.
    var identifier: Any? {
        get { getAssociatedValue(key: "Progress_identifier", object: self, initialValue: nil) }
        set {
            set(associatedValue: newValue, key: "Progress_identifier", object: self)
        }
    }
    
    /// Updates the estimate time remaining.
    func updateEstimatedTimeRemaining() {
        self.setupEstimatedTimeProgressObserver()
        self.updateEstimatedTimeRemaining(dateStarted: estimatedTimeStartDate)
    }
    
    /**
     Updates the estimate time remaining by providing the start date of the progress.
     
     - Parameters:
     - date: The start date of the progress.
     - completedUnits: The units completed since start.
     */
    func updateEstimatedTimeRemaining(dateStarted date: Date, completedUnits: Int64? = nil) {
        let elapsedTime = Date().timeIntervalSince(date)
        updateEstimatedTimeRemaining(timeElapsed: elapsedTime, completedUnits: completedUnits)
    }
    
    /**
     Updates the estimate time remaining by providing the time elapsed since the start of the progress.
     
     - Parameters:
     - elapsedTime: The time elapsed since the start of the progress.
     - completedUnits: The units completed since start.
     */
    func updateEstimatedTimeRemaining(timeElapsed elapsedTime: TimeInterval, completedUnits: Int64? = nil) {
        guard Int64(elapsedTime) > 1 else {
            self.throughput = 0
            self.estimatedTimeRemaining = TimeInterval.infinity
            return
        }
        
        guard self.completedUnitCount != self.totalUnitCount else {
            self.throughput = 0
            self.estimatedTimeRemaining = 0.0
            return
        }
        self.estimatedTimeCompletedUnits = completedUnits ?? self.estimatedTimeCompletedUnits
        var completedUnitCount = completedUnitCount - self.estimatedTimeCompletedUnits
        var totalUnitCount = totalUnitCount - (completedUnits ?? 0)
        
        if completedUnitCount < 0 {
            completedUnitCount = 0
        }
        if totalUnitCount < 0 {
            totalUnitCount = 0
        }
        
        let unitsPerSecond = Double(completedUnitCount) / elapsedTime
        let throughput = Int(unitsPerSecond)
        let unitsRemaining = totalUnitCount - completedUnitCount
        
        guard unitsPerSecond > 0 else {
            self.throughput = throughput
            self.estimatedTimeRemaining = TimeInterval.infinity
            return
        }
        
        let secondsRemaining = Double(unitsRemaining) / unitsPerSecond
        
        self.throughput = throughput
        self.estimatedTimeRemaining = secondsRemaining
    }
    
    /// A boolean value indicating whether the progress should auomatically update the estimated time remaining.
    var autoUpdateEstimatedTimeRemaining: Bool {
        get { getAssociatedValue(key: "Progress_autoUpdateEstimatedTimeRemaining", object: self, initialValue: false) }
        set {
            guard newValue != autoUpdateEstimatedTimeRemaining else { return }
            set(associatedValue: newValue, key: "Progress_autoUpdateEstimatedTimeRemaining", object: self)
            self.setupEstimatedTimeProgressObserver(includingFraction: newValue)
        }
    }
#if os(macOS)
    /**
     The progress will be shown as a progress bar in the Finder for the given url.
     
     - Parameters:
     - url: The URL of the file.
     - kind: The kind of the file operation.
     */
    func addFileProgress(url: URL, kind: FileOperationKind = .downloading) {
        Swift.debugPrint("addFileProgress", url, isPublished)
        guard self.fileURL != url else { return }
        self.fileURL = url
        self.fileOperationKind = kind
        self.kind = .file
        if isPublished == false {
            Swift.debugPrint("addFileProgress publish", url)
            self.publish()
            self.isPublished = true
        }
    }
    
    /// Removes reflecting the file progress.
    func removeFileProgress() {
        Swift.debugPrint("removeFileProgress", self.fileURL ?? "nil")
        guard isPublished, self.fileURL != nil else { return }
        /*
        Swift.debugPrint("removeFileProgress unpublish", self.fileURL ?? "nil")
        self.unpublish()
        self.isPublished = false
         */
        self.fileURL = nil
        self.fileOperationKind = nil
        self.kind = nil
    }
    
    /**
     Creates a file progress.
     
     A file progress will show a progress bar in the Finder. If `cancellationHandler` is provided, the user will be able to cancel the progress. If `pauseHandler` is provided, the user will be able to pause the progress.
     
     - Parameters:
     - url: The URL of the file.
     - kind: The kind of the file operation.
     - size: The size of the file in `DataSize` format.
     - pauseHandler: The block to invoke when pausing progress. If a handler is provided, the progress will be pausable.
     - cancellationHandler: he block to invoke when canceling progress. If a handler is provided, the progress will be cancellable.
     
     - Returns: A `Progress` object representing the file progress.
     */
    static func file(url: URL, kind: Progress.FileOperationKind, completed: DataSize? = nil, size: DataSize? = nil) -> Progress {
        let progress = Progress()
        progress.kind = .file
        progress.fileURL = url
        progress.fileOperationKind = kind
        progress.totalUnitCount = Int64(size?.bytes ?? 0)
        progress.completedUnitCount = Int64(completed?.bytes ?? Int(progress.completedUnitCount))
        progress.publish()
        return progress
    }
#endif
    
    internal var estimatedTimeProgressObserver: KeyValueObserver<Progress>? {
        get { getAssociatedValue(key: "Progress_estimatedTimeProgressObserver", object: self, initialValue: nil) }
        set { set(associatedValue: newValue, key: "Progress_estimatedTimeProgressObserver", object: self) }
    }
    
    internal var estimatedTimeStartDate: Date {
        get { getAssociatedValue(key: "Progress_estimatedTimeStartDate", object: self, initialValue: Date()) }
        set {  set(associatedValue: newValue, key: "Progress_estimatedTimeStartDate", object: self) }
    }
    
    internal var estimatedTimeCompletedUnits: Int64 {
        get { getAssociatedValue(key: "Progress_estimatedTimeCompletedUnits", object: self, initialValue: self.completedUnitCount) }
        set {
            guard estimatedTimeCompletedUnits != newValue else { return }
            set(associatedValue: newValue, key: "Progress_estimatedTimeCompletedUnits", object: self) }
    }
    
    internal var isPublished: Bool {
        get { getAssociatedValue(key: "isPublished", object: self, initialValue: false) }
        set {
            set(associatedValue: newValue, key: "isPublished", object: self) }
    }
    
    internal func setupEstimatedTimeProgressObserver(includingFraction: Bool = false) {
        if estimatedTimeProgressObserver == nil {
            estimatedTimeProgressObserver = KeyValueObserver(self)
            
            estimatedTimeProgressObserver?.add(\.isPaused) { old, new in
                guard old != new else { return }
                self.estimatedTimeStartDate = Date()
                self.estimatedTimeCompletedUnits = self.completedUnitCount
                self.updateEstimatedTimeRemaining()
            }
            
            estimatedTimeProgressObserver?.add(\.isCancelled) { old, new in
                guard old != new else { return }
                self.updateEstimatedTimeRemaining()
            }
        }
        
        if includingFraction {
            estimatedTimeProgressObserver?.add(\.fractionCompleted, sendInitalValue: true) { old, new in
                guard old != new else { return }
                self.updateEstimatedTimeRemaining()
            }
        } else {
            estimatedTimeProgressObserver?.remove(\.fractionCompleted)
        }
    }
}
