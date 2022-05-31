import Metal

let device = MTLCreateSystemDefaultDevice()!

// MARK: Create data buffers

let bufferWidth = 16
let bufferHeight = 16
let inBuffer = device.makeBuffer(
    length: bufferWidth * bufferHeight,
    options: [.storageModeShared])!
let outBuffer = device.makeBuffer(
    length: bufferWidth * bufferHeight,
    options: [.storageModeShared])!

// MARK: Write data to input buffer

for x in 0 ..< bufferWidth {
    for y in 0 ..< bufferHeight {
        let value: UInt8
        if (
            ((x >= 3 && x <= 4) || (x >= 11 && x <= 12))
            && ((y >= 3 && y <= 4) || (y >= 11 && y <= 12))
        ) {
            value = 0
        } else {
            value = 255
        }
        let index = y * bufferWidth + x
        (inBuffer.contents() + index).storeBytes(of: value, as: UInt8.self)
    }
}

// MARK: Write original buffer to file

writeToDisk(
    contents: bufferToString(buffer: inBuffer.contents()),
    fileName: "inBuffer")

// MARK: Get blur filter function

let metalLibrary = device.makeDefaultLibrary()!
let blurFunctionConstants = MTLFunctionConstantValues()
let blurFunction = metalLibrary.makeFunction(name: "boxBlur")!
let blurFunctionPso =
    try! device.makeComputePipelineState(function: blurFunction)

// MARK: Apply blur filter function

let commandQueue = device.makeCommandQueue()!
let commandBuffer = commandQueue.makeCommandBuffer()!
let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
commandEncoder.setComputePipelineState(blurFunctionPso)
commandEncoder.setBytes(
    [UInt32(1)], length: MemoryLayout<UInt32>.size, index: 0) // blur size
commandEncoder.setBytes(
    [UInt32(bufferWidth)], length: MemoryLayout<UInt32>.size, index: 1)
commandEncoder.setBytes(
    [UInt32(bufferHeight)], length: MemoryLayout<UInt32>.size, index: 2)
commandEncoder.setBuffers(
    [inBuffer, outBuffer], offsets: [0, 0], range: 3 ..< 5)
let threadsPerThreadgroup = blurFunctionPso.maxTotalThreadsPerThreadgroup
let nThreadgroups = divideRoundingUp(
    bufferWidth * bufferHeight, threadsPerThreadgroup)
commandEncoder.dispatchThreadgroups(
    MTLSizeMake(nThreadgroups, 1, 1),
    threadsPerThreadgroup: MTLSizeMake(threadsPerThreadgroup, 1, 1))
commandEncoder.endEncoding()
commandBuffer.commit()
commandBuffer.waitUntilCompleted()

// MARK: Write blurred buffer to file

writeToDisk(
    contents: bufferToString(buffer: outBuffer.contents()),
    fileName: "outBuffer")



// MARK: - Helper functions

func writeToDisk(contents: String, fileName: String) {
    try! contents.write(
        toFile: "/Users/roysianez/Desktop/\(fileName).txt",
        atomically: false,
        encoding: .utf8)
}

func bufferToString(buffer: UnsafeMutableRawPointer) -> String {
    var result = ""
    for x in 0 ..< bufferWidth {
        for y in 0 ..< bufferHeight {
            let index = y * bufferWidth + x
            let value = (buffer + index).load(as: UInt8.self)
            result += padLeft(string: String(value), with: "0", length: 3)
            result += " "
        }
        result += "\n"
    }
    return result
}

func padLeft(string: String, with: Character, length: Int) -> String {
    if string.count >= length {
        return string
    }
    return String(repeating: with, count: length - string.count) + string
}

func divideRoundingUp(_ a: Int, _ b: Int) -> Int {
    if (a % b == 0) {
        return a / b
    } else {
        return (a / b) + 1
    }
}
