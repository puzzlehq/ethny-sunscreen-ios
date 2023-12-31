// This file was autogenerated by some hot garbage in the `uniffi` crate.
// Trust me, you don't want to mess with it!
import Foundation

// Depending on the consumer's build setup, the low-level FFI code
// might be in a separate module, or it might be compiled inline into
// this module. This is a bit of light hackery to work with both.
#if canImport(sunscreen_ballotFFI)
    import sunscreen_ballotFFI
#endif

private extension RustBuffer {
    // Allocate a new buffer, copying the contents of a `UInt8` array.
    init(bytes: [UInt8]) {
        let rbuf = bytes.withUnsafeBufferPointer { ptr in
            RustBuffer.from(ptr)
        }
        self.init(capacity: rbuf.capacity, len: rbuf.len, data: rbuf.data)
    }

    static func from(_ ptr: UnsafeBufferPointer<UInt8>) -> RustBuffer {
        try! rustCall { ffi_sunscreen_ballot_rustbuffer_from_bytes(ForeignBytes(bufferPointer: ptr), $0) }
    }

    // Frees the buffer in place.
    // The buffer must not be used after this is called.
    func deallocate() {
        try! rustCall { ffi_sunscreen_ballot_rustbuffer_free(self, $0) }
    }
}

private extension ForeignBytes {
    init(bufferPointer: UnsafeBufferPointer<UInt8>) {
        self.init(len: Int32(bufferPointer.count), data: bufferPointer.baseAddress)
    }
}

// For every type used in the interface, we provide helper methods for conveniently
// lifting and lowering that type from C-compatible data, and for reading and writing
// values of that type in a buffer.

// Helper classes/extensions that don't change.
// Someday, this will be in a library of its own.

private extension Data {
    init(rustBuffer: RustBuffer) {
        // TODO: This copies the buffer. Can we read directly from a
        // Rust buffer?
        self.init(bytes: rustBuffer.data!, count: Int(rustBuffer.len))
    }
}

// Define reader functionality.  Normally this would be defined in a class or
// struct, but we use standalone functions instead in order to make external
// types work.
//
// With external types, one swift source file needs to be able to call the read
// method on another source file's FfiConverter, but then what visibility
// should Reader have?
// - If Reader is fileprivate, then this means the read() must also
//   be fileprivate, which doesn't work with external types.
// - If Reader is internal/public, we'll get compile errors since both source
//   files will try define the same type.
//
// Instead, the read() method and these helper functions input a tuple of data

private func createReader(data: Data) -> (data: Data, offset: Data.Index) {
    (data: data, offset: 0)
}

// Reads an integer at the current offset, in big-endian order, and advances
// the offset on success. Throws if reading the integer would move the
// offset past the end of the buffer.
private func readInt<T: FixedWidthInteger>(_ reader: inout (data: Data, offset: Data.Index)) throws -> T {
    let range = reader.offset ..< reader.offset + MemoryLayout<T>.size
    guard reader.data.count >= range.upperBound else {
        throw UniffiInternalError.bufferOverflow
    }
    if T.self == UInt8.self {
        let value = reader.data[reader.offset]
        reader.offset += 1
        return value as! T
    }
    var value: T = 0
    let _ = withUnsafeMutableBytes(of: &value) { reader.data.copyBytes(to: $0, from: range) }
    reader.offset = range.upperBound
    return value.bigEndian
}

// Reads an arbitrary number of bytes, to be used to read
// raw bytes, this is useful when lifting strings
private func readBytes(_ reader: inout (data: Data, offset: Data.Index), count: Int) throws -> [UInt8] {
    let range = reader.offset ..< (reader.offset + count)
    guard reader.data.count >= range.upperBound else {
        throw UniffiInternalError.bufferOverflow
    }
    var value = [UInt8](repeating: 0, count: count)
    value.withUnsafeMutableBufferPointer { buffer in
        reader.data.copyBytes(to: buffer, from: range)
    }
    reader.offset = range.upperBound
    return value
}

// Reads a float at the current offset.
private func readFloat(_ reader: inout (data: Data, offset: Data.Index)) throws -> Float {
    return try Float(bitPattern: readInt(&reader))
}

// Reads a float at the current offset.
private func readDouble(_ reader: inout (data: Data, offset: Data.Index)) throws -> Double {
    return try Double(bitPattern: readInt(&reader))
}

// Indicates if the offset has reached the end of the buffer.
private func hasRemaining(_ reader: (data: Data, offset: Data.Index)) -> Bool {
    return reader.offset < reader.data.count
}

// Define writer functionality.  Normally this would be defined in a class or
// struct, but we use standalone functions instead in order to make external
// types work.  See the above discussion on Readers for details.

private func createWriter() -> [UInt8] {
    return []
}

private func writeBytes<S>(_ writer: inout [UInt8], _ byteArr: S) where S: Sequence, S.Element == UInt8 {
    writer.append(contentsOf: byteArr)
}

// Writes an integer in big-endian order.
//
// Warning: make sure what you are trying to write
// is in the correct type!
private func writeInt<T: FixedWidthInteger>(_ writer: inout [UInt8], _ value: T) {
    var value = value.bigEndian
    withUnsafeBytes(of: &value) { writer.append(contentsOf: $0) }
}

private func writeFloat(_ writer: inout [UInt8], _ value: Float) {
    writeInt(&writer, value.bitPattern)
}

private func writeDouble(_ writer: inout [UInt8], _ value: Double) {
    writeInt(&writer, value.bitPattern)
}

// Protocol for types that transfer other types across the FFI. This is
// analogous go the Rust trait of the same name.
private protocol FfiConverter {
    associatedtype FfiType
    associatedtype SwiftType

    static func lift(_ value: FfiType) throws -> SwiftType
    static func lower(_ value: SwiftType) -> FfiType
    static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> SwiftType
    static func write(_ value: SwiftType, into buf: inout [UInt8])
}

// Types conforming to `Primitive` pass themselves directly over the FFI.
private protocol FfiConverterPrimitive: FfiConverter where FfiType == SwiftType {}

extension FfiConverterPrimitive {
    public static func lift(_ value: FfiType) throws -> SwiftType {
        return value
    }

    public static func lower(_ value: SwiftType) -> FfiType {
        return value
    }
}

// Types conforming to `FfiConverterRustBuffer` lift and lower into a `RustBuffer`.
// Used for complex types where it's hard to write a custom lift/lower.
private protocol FfiConverterRustBuffer: FfiConverter where FfiType == RustBuffer {}

extension FfiConverterRustBuffer {
    public static func lift(_ buf: RustBuffer) throws -> SwiftType {
        var reader = createReader(data: Data(rustBuffer: buf))
        let value = try read(from: &reader)
        if hasRemaining(reader) {
            throw UniffiInternalError.incompleteData
        }
        buf.deallocate()
        return value
    }

    public static func lower(_ value: SwiftType) -> RustBuffer {
        var writer = createWriter()
        write(value, into: &writer)
        return RustBuffer(bytes: writer)
    }
}

// An error type for FFI errors. These errors occur at the UniFFI level, not
// the library level.
private enum UniffiInternalError: LocalizedError {
    case bufferOverflow
    case incompleteData
    case unexpectedOptionalTag
    case unexpectedEnumCase
    case unexpectedNullPointer
    case unexpectedRustCallStatusCode
    case unexpectedRustCallError
    case unexpectedStaleHandle
    case rustPanic(_ message: String)

    public var errorDescription: String? {
        switch self {
        case .bufferOverflow: return "Reading the requested value would read past the end of the buffer"
        case .incompleteData: return "The buffer still has data after lifting its containing value"
        case .unexpectedOptionalTag: return "Unexpected optional tag; should be 0 or 1"
        case .unexpectedEnumCase: return "Raw enum value doesn't match any cases"
        case .unexpectedNullPointer: return "Raw pointer value was null"
        case .unexpectedRustCallStatusCode: return "Unexpected RustCallStatus code"
        case .unexpectedRustCallError: return "CALL_ERROR but no errorClass specified"
        case .unexpectedStaleHandle: return "The object in the handle map has been dropped already"
        case let .rustPanic(message): return message
        }
    }
}

private let CALL_SUCCESS: Int8 = 0
private let CALL_ERROR: Int8 = 1
private let CALL_PANIC: Int8 = 2

private extension RustCallStatus {
    init() {
        self.init(
            code: CALL_SUCCESS,
            errorBuf: RustBuffer(
                capacity: 0,
                len: 0,
                data: nil
            )
        )
    }
}

private func rustCall<T>(_ callback: (UnsafeMutablePointer<RustCallStatus>) -> T) throws -> T {
    try makeRustCall(callback, errorHandler: nil)
}

private func rustCallWithError<T>(
    _ errorHandler: @escaping (RustBuffer) throws -> Error,
    _ callback: (UnsafeMutablePointer<RustCallStatus>) -> T
) throws -> T {
    try makeRustCall(callback, errorHandler: errorHandler)
}

private func makeRustCall<T>(
    _ callback: (UnsafeMutablePointer<RustCallStatus>) -> T,
    errorHandler: ((RustBuffer) throws -> Error)?
) throws -> T {
    uniffiEnsureInitialized()
    var callStatus = RustCallStatus()
    let returnedVal = callback(&callStatus)
    try uniffiCheckCallStatus(callStatus: callStatus, errorHandler: errorHandler)
    return returnedVal
}

private func uniffiCheckCallStatus(
    callStatus: RustCallStatus,
    errorHandler: ((RustBuffer) throws -> Error)?
) throws {
    switch callStatus.code {
    case CALL_SUCCESS:
        return

    case CALL_ERROR:
        if let errorHandler = errorHandler {
            throw try errorHandler(callStatus.errorBuf)
        } else {
            callStatus.errorBuf.deallocate()
            throw UniffiInternalError.unexpectedRustCallError
        }

    case CALL_PANIC:
        // When the rust code sees a panic, it tries to construct a RustBuffer
        // with the message.  But if that code panics, then it just sends back
        // an empty buffer.
        if callStatus.errorBuf.len > 0 {
            throw try UniffiInternalError.rustPanic(FfiConverterString.lift(callStatus.errorBuf))
        } else {
            callStatus.errorBuf.deallocate()
            throw UniffiInternalError.rustPanic("Rust panic")
        }

    default:
        throw UniffiInternalError.unexpectedRustCallStatusCode
    }
}

// Public interface members begin here.

private struct FfiConverterUInt64: FfiConverterPrimitive {
    typealias FfiType = UInt64
    typealias SwiftType = UInt64

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> UInt64 {
        return try lift(readInt(&buf))
    }

    public static func write(_ value: SwiftType, into buf: inout [UInt8]) {
        writeInt(&buf, lower(value))
    }
}

private struct FfiConverterString: FfiConverter {
    typealias SwiftType = String
    typealias FfiType = RustBuffer

    public static func lift(_ value: RustBuffer) throws -> String {
        defer {
            value.deallocate()
        }
        if value.data == nil {
            return String()
        }
        let bytes = UnsafeBufferPointer<UInt8>(start: value.data!, count: Int(value.len))
        return String(bytes: bytes, encoding: String.Encoding.utf8)!
    }

    public static func lower(_ value: String) -> RustBuffer {
        return value.utf8CString.withUnsafeBufferPointer { ptr in
            // The swift string gives us int8_t, we want uint8_t.
            ptr.withMemoryRebound(to: UInt8.self) { ptr in
                // The swift string gives us a trailing null byte, we don't want it.
                let buf = UnsafeBufferPointer(rebasing: ptr.prefix(upTo: ptr.count - 1))
                return RustBuffer.from(buf)
            }
        }
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> String {
        let len: Int32 = try readInt(&buf)
        return try String(bytes: readBytes(&buf, count: Int(len)), encoding: String.Encoding.utf8)!
    }

    public static func write(_ value: String, into buf: inout [UInt8]) {
        let len = Int32(value.utf8.count)
        writeInt(&buf, len)
        writeBytes(&buf, value.utf8)
    }
}

private let UNIFFI_RUST_TASK_CALLBACK_SUCCESS: Int8 = 0
private let UNIFFI_RUST_TASK_CALLBACK_CANCELLED: Int8 = 1
private let UNIFFI_FOREIGN_EXECUTOR_CALLBACK_SUCCESS: Int8 = 0
private let UNIFFI_FOREIGN_EXECUTOR_CALLBACK_CANCELED: Int8 = 1
private let UNIFFI_FOREIGN_EXECUTOR_CALLBACK_ERROR: Int8 = 2

// Encapsulates an executor that can run Rust tasks
//
// On Swift, `Task.detached` can handle this we just need to know what priority to send it.
public struct UniFfiForeignExecutor {
    var priority: TaskPriority

    public init(priority: TaskPriority) {
        self.priority = priority
    }

    public init() {
        priority = Task.currentPriority
    }
}

private struct FfiConverterForeignExecutor: FfiConverter {
    typealias SwiftType = UniFfiForeignExecutor
    // Rust uses a pointer to represent the FfiConverterForeignExecutor, but we only need a u8.
    // let's use `Int`, which is equivalent to `size_t`
    typealias FfiType = Int

    public static func lift(_ value: FfiType) throws -> SwiftType {
        UniFfiForeignExecutor(priority: TaskPriority(rawValue: numericCast(value)))
    }

    public static func lower(_ value: SwiftType) -> FfiType {
        numericCast(value.priority.rawValue)
    }

    public static func read(from _: inout (data: Data, offset: Data.Index)) throws -> SwiftType {
        fatalError("FfiConverterForeignExecutor.read not implemented yet")
    }

    public static func write(_: SwiftType, into _: inout [UInt8]) {
        fatalError("FfiConverterForeignExecutor.read not implemented yet")
    }
}

private func uniffiForeignExecutorCallback(executorHandle: Int, delayMs: UInt32, rustTask: UniFfiRustTaskCallback?, taskData: UnsafeRawPointer?) -> Int8 {
    if let rustTask = rustTask {
        let executor = try! FfiConverterForeignExecutor.lift(executorHandle)
        Task.detached(priority: executor.priority) {
            if delayMs != 0 {
                let nanoseconds: UInt64 = numericCast(delayMs * 1_000_000)
                try! await Task.sleep(nanoseconds: nanoseconds)
            }
            rustTask(taskData, UNIFFI_RUST_TASK_CALLBACK_SUCCESS)
        }
        return UNIFFI_FOREIGN_EXECUTOR_CALLBACK_SUCCESS
    } else {
        // When rustTask is null, we should drop the foreign executor.
        // However, since its just a value type, we don't need to do anything here.
        return UNIFFI_FOREIGN_EXECUTOR_CALLBACK_SUCCESS
    }
}

private func uniffiInitForeignExecutor() {
    ffi_sunscreen_ballot_foreign_executor_callback_set(uniffiForeignExecutorCallback)
}

private struct FfiConverterSequenceUInt64: FfiConverterRustBuffer {
    typealias SwiftType = [UInt64]

    public static func write(_ value: [UInt64], into buf: inout [UInt8]) {
        let len = Int32(value.count)
        writeInt(&buf, len)
        for item in value {
            FfiConverterUInt64.write(item, into: &buf)
        }
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> [UInt64] {
        let len: Int32 = try readInt(&buf)
        var seq = [UInt64]()
        seq.reserveCapacity(Int(len))
        for _ in 0 ..< len {
            try seq.append(FfiConverterUInt64.read(from: &buf))
        }
        return seq
    }
}

private struct FfiConverterSequenceString: FfiConverterRustBuffer {
    typealias SwiftType = [String]

    public static func write(_ value: [String], into buf: inout [UInt8]) {
        let len = Int32(value.count)
        writeInt(&buf, len)
        for item in value {
            FfiConverterString.write(item, into: &buf)
        }
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> [String] {
        let len: Int32 = try readInt(&buf)
        var seq = [String]()
        seq.reserveCapacity(Int(len))
        for _ in 0 ..< len {
            try seq.append(FfiConverterString.read(from: &buf))
        }
        return seq
    }
} // Callbacks for async functions

// Callback handlers for an async calls.  These are invoked by Rust when the future is ready.  They
// lift the return value or error and resume the suspended function.
private func uniffiFutureCallbackHandlerString(
    rawContinutation: UnsafeRawPointer,
    returnValue: RustBuffer,
    callStatus: RustCallStatus
) {
    let continuation = rawContinutation.bindMemory(
        to: CheckedContinuation<String, Error>.self,
        capacity: 1
    )

    do {
        try uniffiCheckCallStatus(callStatus: callStatus, errorHandler: nil)
        try continuation.pointee.resume(returning: FfiConverterString.lift(returnValue))
    } catch {
        continuation.pointee.resume(throwing: error)
    }
}

private func uniffiFutureCallbackHandlerSequenceString(
    rawContinutation: UnsafeRawPointer,
    returnValue: RustBuffer,
    callStatus: RustCallStatus
) {
    let continuation = rawContinutation.bindMemory(
        to: CheckedContinuation<[String], Error>.self,
        capacity: 1
    )

    do {
        try uniffiCheckCallStatus(callStatus: callStatus, errorHandler: nil)
        try continuation.pointee.resume(returning: FfiConverterSequenceString.lift(returnValue))
    } catch {
        continuation.pointee.resume(throwing: error)
    }
}

public func addProposal(contractAddress: String, name: String, contents: String, publicKey: String, privateKey: String, walletKey: String) -> String {
    return try! FfiConverterString.lift(
        try! rustCall {
            uniffi_sunscreen_ballot_fn_func_add_proposal(
                FfiConverterString.lower(contractAddress),
                FfiConverterString.lower(name),
                FfiConverterString.lower(contents),
                FfiConverterString.lower(publicKey),
                FfiConverterString.lower(privateKey),
                FfiConverterString.lower(walletKey), $0
            )
        }
    )
}

public func deployContract(publicKey: String, privateKey: String, walletKey: String) -> String {
    return try! FfiConverterString.lift(
        try! rustCall {
            uniffi_sunscreen_ballot_fn_func_deploy_contract(
                FfiConverterString.lower(publicKey),
                FfiConverterString.lower(privateKey),
                FfiConverterString.lower(walletKey), $0
            )
        }
    )
}

public func generateKeysLocal() -> [String] {
    return try! FfiConverterSequenceString.lift(
        try! rustCall {
            uniffi_sunscreen_ballot_fn_func_generate_keys_local($0)
        }
    )
}

public func getProposalTallys(contractAddress: String, publicKey: String, privateKey: String, walletKey: String) -> [String] {
    return try! FfiConverterSequenceString.lift(
        try! rustCall {
            uniffi_sunscreen_ballot_fn_func_get_proposal_tallys(
                FfiConverterString.lower(contractAddress),
                FfiConverterString.lower(publicKey),
                FfiConverterString.lower(privateKey),
                FfiConverterString.lower(walletKey), $0
            )
        }
    )
}

public func getProposals(contractAddress: String, publicKey: String, privateKey: String, walletKey: String) -> [String] {
    return try! FfiConverterSequenceString.lift(
        try! rustCall {
            uniffi_sunscreen_ballot_fn_func_get_proposals(
                FfiConverterString.lower(contractAddress),
                FfiConverterString.lower(publicKey),
                FfiConverterString.lower(privateKey),
                FfiConverterString.lower(walletKey), $0
            )
        }
    )
}

public func submitVotes(contractAddress: String, publicKey: String, privateKey: String, walletKey: String, votes: [UInt64]) -> String {
    return try! FfiConverterString.lift(
        try! rustCall {
            uniffi_sunscreen_ballot_fn_func_submit_votes(
                FfiConverterString.lower(contractAddress),
                FfiConverterString.lower(publicKey),
                FfiConverterString.lower(privateKey),
                FfiConverterString.lower(walletKey),
                FfiConverterSequenceUInt64.lower(votes), $0
            )
        }
    )
}

public func tryWallet(privateKey: String) async -> String {
    var continuation: CheckedContinuation<String, Error>? = nil
    // Suspend the function and call the scaffolding function, passing it a callback handler from
    // `AsyncTypes.swift`
    //
    // Make sure to hold on to a reference to the continuation in the top-level scope so that
    // it's not freed before the callback is invoked.
    return try! await withCheckedThrowingContinuation {
        continuation = $0
        try! rustCall {
            uniffi_sunscreen_ballot_fn_func_try_wallet(
                FfiConverterString.lower(privateKey),
                FfiConverterForeignExecutor.lower(UniFfiForeignExecutor()),
                uniffiFutureCallbackHandlerString,
                &continuation,
                $0
            )
        }
    }
}

private enum InitializationResult {
    case ok
    case contractVersionMismatch
    case apiChecksumMismatch
}

// Use a global variables to perform the versioning checks. Swift ensures that
// the code inside is only computed once.
private var initializationResult: InitializationResult {
    // Get the bindings contract version from our ComponentInterface
    let bindings_contract_version = 23
    // Get the scaffolding contract version by calling the into the dylib
    let scaffolding_contract_version = ffi_sunscreen_ballot_uniffi_contract_version()
    if bindings_contract_version != scaffolding_contract_version {
        return InitializationResult.contractVersionMismatch
    }
    if uniffi_sunscreen_ballot_checksum_func_add_proposal() != 55074 {
        return InitializationResult.apiChecksumMismatch
    }
    if uniffi_sunscreen_ballot_checksum_func_deploy_contract() != 47773 {
        return InitializationResult.apiChecksumMismatch
    }
    if uniffi_sunscreen_ballot_checksum_func_generate_keys_local() != 22090 {
        return InitializationResult.apiChecksumMismatch
    }
    if uniffi_sunscreen_ballot_checksum_func_get_proposal_tallys() != 57347 {
        return InitializationResult.apiChecksumMismatch
    }
    if uniffi_sunscreen_ballot_checksum_func_get_proposals() != 13440 {
        return InitializationResult.apiChecksumMismatch
    }
    if uniffi_sunscreen_ballot_checksum_func_submit_votes() != 48656 {
        return InitializationResult.apiChecksumMismatch
    }
    if uniffi_sunscreen_ballot_checksum_func_try_wallet() != 32175 {
        return InitializationResult.apiChecksumMismatch
    }

    uniffiInitForeignExecutor()
    return InitializationResult.ok
}

private func uniffiEnsureInitialized() {
    switch initializationResult {
    case .ok:
        break
    case .contractVersionMismatch:
        fatalError("UniFFI contract version mismatch: try cleaning and rebuilding your project")
    case .apiChecksumMismatch:
        fatalError("UniFFI API checksum mismatch: try cleaning and rebuilding your project")
    }
}
