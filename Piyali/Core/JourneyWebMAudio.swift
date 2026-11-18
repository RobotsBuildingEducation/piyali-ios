import Foundation

/// Repackages the Opus packets emitted by the web Journey recorder for Core Audio.
/// The encrypted recording and its downloadable WebM bytes stay in their original format.
enum JourneyWebMAudio {
    private typealias Bytes = ArraySlice<UInt8>
    private enum Failure: Error { case invalidRecording }

    private struct Element {
        let id: Int
        let contents: Bytes
        let openEnded: Bool

        init(reading bytes: inout Bytes) throws {
            id = try readInteger(&bytes, keepMarker: true).value
            let size = try readInteger(&bytes)
            openEnded = size.value == (1 << (7 * size.width)) - 1
            guard !openEnded || id == 0x18538067 || id == 0x1F43B675 else { throw Failure.invalidRecording }
            let length = openEnded ? bytes.count : size.value
            guard length <= bytes.count else { throw Failure.invalidRecording }
            contents = bytes.prefix(length)
            bytes = bytes.dropFirst(length)
        }
    }

    private static func readInteger(_ bytes: inout Bytes, keepMarker: Bool = false) throws -> (value: Int, width: Int) {
        guard let first = bytes.popFirst(), first != 0 else { throw Failure.invalidRecording }
        let width = first.leadingZeroBitCount + 1
        guard bytes.count >= width - 1, !keepMarker || width <= 4 else { throw Failure.invalidRecording }
        let mask = (1 << (8 - width)) - 1
        var value = keepMarker ? Int(first) : Int(first) & mask
        for byte in bytes.prefix(width - 1) { value = value << 8 | Int(byte) }
        bytes = bytes.dropFirst(width - 1)
        return (value, width)
    }

    private struct Track {
        let number: Int
        let channels: Int
        let priming: Int
    }

    private static func opusTrack(_ tracks: Bytes) throws -> Track? {
        var entries = tracks
        while !entries.isEmpty {
            let entry = try Element(reading: &entries)
            guard entry.id == 0xAE else { continue }
            var fields = entry.contents
            var number = 0, audio = false, opus = false, header = [UInt8]()
            while !fields.isEmpty {
                let field = try Element(reading: &fields)
                switch field.id {
                case 0xD7:
                    guard field.contents.count <= 4 else { throw Failure.invalidRecording }
                    number = field.contents.reduce(0) { $0 << 8 | Int($1) }
                case 0x83: audio = field.contents.elementsEqual([2])
                case 0x86: opus = field.contents.elementsEqual("A_OPUS".utf8)
                case 0x63A2: header = Array(field.contents.prefix(19))
                default: break
                }
            }
            guard audio && opus else { continue }
            guard number > 0, header.count == 19, header.prefix(8).elementsEqual("OpusHead".utf8),
                  header[8] == 1, (1...2).contains(header[9]), header[16...18].allSatisfy({ $0 == 0 })
            else { throw Failure.invalidRecording }
            return Track(number: number, channels: Int(header[9]), priming: Int(header[10]) | Int(header[11]) << 8)
        }
        return nil
    }

    private static func frameCount(_ packet: Bytes) throws -> Int {
        guard let toc = packet.first else { throw Failure.invalidRecording }
        let config = Int(toc >> 3)
        let samples: Int
        switch config {
        case 0...11: samples = [480, 960, 1920, 2880][config % 4]
        case 12...15: samples = [480, 960][config % 2]
        default: samples = [120, 240, 480, 960][config % 4]
        }
        let frames: Int
        switch toc & 3 {
        case 0: frames = 1
        case 1, 2: frames = 2
        default:
            guard let count = packet.dropFirst().first else { throw Failure.invalidRecording }
            frames = Int(count & 63)
        }
        guard frames > 0, frames * samples <= 5760 else { throw Failure.invalidRecording }
        return frames * samples
    }

    // Chrome uses unlaced SimpleBlocks and may leave both Segment and Cluster sizes unknown.
    static func playbackData(_ original: Data) throws -> Data {
        guard original.starts(with: [0x1A, 0x45, 0xDF, 0xA3]) else { return original }
        guard original.count <= VoiceJourneyModel.maxBytes else { throw Failure.invalidRecording }
        var bytes = Array(original)[...]
        var header = try Element(reading: &bytes).contents
        var webm = false
        while !header.isEmpty {
            let field = try Element(reading: &header)
            if field.id == 0x4282 { webm = field.contents.elementsEqual("webm".utf8) }
        }
        guard webm else { throw Failure.invalidRecording }
        let segment = try Element(reading: &bytes)
        guard segment.id == 0x18538067 else { throw Failure.invalidRecording }
        var children = segment.contents
        var track: Track?
        var packets = [(bytes: Bytes, frames: Int)]()
        var totalFrames = 0

        while !children.isEmpty {
            let item = try Element(reading: &children)
            if item.id == 0x1654AE6B {
                track = try opusTrack(item.contents)
            } else if item.id == 0x1F43B675 {
                guard let track else { throw Failure.invalidRecording }
                var blocks = item.contents
                while !blocks.isEmpty {
                    let before = blocks
                    let block = try Element(reading: &blocks)
                    if item.openEnded && [0x1F43B675, 0x1C53BB6B, 0x1254C367, 0x114D9B74].contains(block.id) {
                        children = before
                        break
                    }
                    // The source recorder uses SimpleBlock, never silently omit a different packet layout.
                    guard block.id != 0xA0 else { throw Failure.invalidRecording }
                    guard block.id == 0xA3 else { continue }
                    var payload = block.contents
                    let number = try readInteger(&payload).value
                    guard number == track.number else { continue }
                    guard payload.count > 3, payload[payload.startIndex + 2] & 0x06 == 0 else { throw Failure.invalidRecording }
                    let packet = payload.dropFirst(3)
                    let frames = try frameCount(packet)
                    totalFrames += frames
                    guard totalFrames <= 48_000 * (VoiceJourneyModel.maxSeconds + 2) else { throw Failure.invalidRecording }
                    packets.append((packet, frames))
                }
            }
        }
        guard let track, let first = packets.first, totalFrames > track.priming else { throw Failure.invalidRecording }
        let fixedFrames = packets.allSatisfy { $0.frames == first.frames } ? first.frames : 0

        var format = Data()
        format.appendBigEndian(Double(48_000).bitPattern)
        format.append(contentsOf: "opus".utf8)
        for field in [0, 0, fixedFrames, track.channels, 0] { format.appendBigEndian(UInt32(field)) }
        var table = Data()
        table.appendBigEndian(Int64(packets.count))
        table.appendBigEndian(Int64(totalFrames - track.priming))
        table.appendBigEndian(Int32(track.priming))
        table.appendBigEndian(Int32(0))
        var audio = Data(repeating: 0, count: 4) // CAF edit count
        for packet in packets {
            table.appendPacketInteger(packet.bytes.count)
            if fixedFrames == 0 { table.appendPacketInteger(packet.frames) }
            audio.append(contentsOf: packet.bytes)
        }
        var caf = Data("caff".utf8)
        caf.appendBigEndian(UInt16(1))
        caf.appendBigEndian(UInt16(0))
        for (id, chunk) in [("desc", format), ("pakt", table), ("data", audio)] {
            caf.append(contentsOf: id.utf8)
            caf.appendBigEndian(Int64(chunk.count))
            caf.append(chunk)
        }
        return caf
    }
}

private extension Data {
    mutating func appendBigEndian<T: FixedWidthInteger>(_ number: T) {
        Swift.withUnsafeBytes(of: number.bigEndian) { append(contentsOf: $0) }
    }

    mutating func appendPacketInteger(_ value: Int) {
        var groups = [UInt8(value & 127)]
        var remainder = value >> 7
        while remainder > 0 {
            groups.append(UInt8(remainder & 127) | 0x80)
            remainder >>= 7
        }
        append(contentsOf: groups.reversed())
    }
}
