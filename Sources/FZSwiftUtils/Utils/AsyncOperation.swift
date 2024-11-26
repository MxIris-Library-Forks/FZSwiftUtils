//
//  AsyncOperation.swift
//
//
//  Created by Florian Zand on 23.02.23.
//

import Foundation

/**
 A asynchronous, pausable operation.
 
 Override ``main()`` to perform your desired task and finish the operation by calling ``finish()``.
  
 Always call `super` when overriding `start()`, `cancel()`, `finish()`, `pause()` or `resume()`.
 */
open class AsyncOperation: Operation {
    
    private let stateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier ?? Bundle.main.bundlePath + ".AsyncOperationState", attributes: .concurrent)
    private let pauseSemaphore = DispatchSemaphore(value: 0) // Semaphore to pause/resume
    private var _state: State = .ready
    
    /// The handler that is called when the operation starts executing.
    open var startHandler: (()->())? = nil
    
    /// The state of the operation.
    @objc public enum State: Int, Hashable, CustomStringConvertible {
        /// The operation is ready to start.
        case ready
        /// The operation is executing.
        case executing
        /// The operation is finished.
        case finished
        /// The operation is cancelled.
        case cancelled
        /// The operation is paused.
        case paused
        
        public var description: String {
            switch self {
            case .ready: return "ready"
            case .executing: return "executing"
            case .finished: return "finished"
            case .cancelled: return "cancelled"
            case .paused: return "paused"
            }
        }
    }
    
    /// The state of the operation.
    @objc dynamic open internal(set) var state: State {
        get { stateQueue.sync { _state } }
        set {
            guard newValue != state else { return }
            if validateState(newValue) {
                stateQueue.async(flags: .barrier) { self._state = newValue }
            } else {
                debugPrint("\(Self.className()): Invalid change from `\(state)` to `\(newValue)`")
            }
        }
    }
        
    private func validateState(_ newState: State) -> Bool {
        switch newState {
        case .ready:
            return false
        case .executing:
            return state == .ready || state == .paused
        case .finished:
            return state != .cancelled
        case .cancelled:
            return true
        case .paused:
            return state != .cancelled && state != .finished
        }
    }
    
    override open var isReady: Bool {
        state == .ready
    }

    override open var isExecuting: Bool {
        state == .executing || state == .paused
    }

    override open var isFinished: Bool {
        state == .finished || state == .cancelled
    }
    
    override open var isAsynchronous: Bool {
        true
    }
    
    /// A Boolean value indicating whether the operation has been paused.
    open var isPaused: Bool {
        state == .paused
    }
    
    override open func start() {
        guard !isCancelled, !isExecuting, !isFinished else { return }
        state = .executing
        startHandler?()
        main()
    }
    
    override open func main() {
      fatalError("Subclasses of `AsyncOperation` must implement `main()`.")
    }
    
    override open func cancel() {
        super.cancel()
        if isPaused {
            pauseSemaphore.signal()
        }
        state = .cancelled
    }
    
    /// Finishes the operation.
    open func finish() {
        guard isExecuting, !isPaused else { return }
        state = .finished
    }

    /// Pauses the operation.
    open func pause() {
        guard isExecuting, state != .paused else { return }
        state = .paused
    }
    
    /// Resumes the operation, if it's paused.
    open func resume() {
        guard isExecuting, state == .paused else { return }
        state = .executing
    }
    
    /**
     Conditionally blocks the current thread if the operation is paused, and waits until it is resumed or cancelled.

     Use this method within your `main()` implementation to handle scenarios where the operation might be paused. If the operation is not paused, this method returns immediately.
     
     Example usage:
     
     ```swift
     override func main() {
         while someCondition {
            // Pause execution if the operation is paused
            waitIfPaused()
     
            // Perform a unit of work
            processWorkUnit()
         }
        finish()
     }
     ```
     */
    open func waitIfPaused() {
        guard isPaused else { return }
        pauseSemaphore.wait()
    }
    
    override open class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        if ["isReady", "isFinished", "isExecuting"].contains(key) {
            return ["state"]
        }
        return super.keyPathsForValuesAffectingValue(forKey: key)
    }
}


/// A asynchronous, pausable operation executing a specifed handler.
open class AsyncBlockOperation: AsyncOperation {
    /// The handler to execute.
    public let closure: (AsyncBlockOperation) -> Void

    /**
     Initalize a new operation with the specified handler.

     - Parameter closure: The handler to execute.
     - Returns: A new `AsyncBlockOperation` object.
     */
    public init(closure: @escaping ((AsyncBlockOperation) -> Void)) {
        self.closure = closure
    }
    
    override open func main() {
        closure(self)
        finish()
    }
}
