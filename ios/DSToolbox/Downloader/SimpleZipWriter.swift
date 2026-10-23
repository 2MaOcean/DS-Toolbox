import Foundation
enum SimpleZipWriter {
    static func write(files: [URL], to dest: URL) throws {
        FileManager.default.createFile(atPath: dest.path, contents: nil)
        let out = try FileHandle(forWritingTo: dest); defer { try? out.close() }
        var central = Data(); var offset: UInt32 = 0; var written = 0; let chunkSize = 262_144

        for url in files {
            let nameData = url.lastPathComponent.data(using: .utf8) ?? Data()
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path), let fileSize = attrs[.size] as? Int64, fileSize <= Int64(UInt32.max) else { continue }
            let size = UInt32(fileSize); var crc: UInt32 = 0xFFFFFFFF; var localHeaderLength: UInt32 = 0
            do {
                let input = try FileHandle(forReadingFrom: url); defer { try? input.close() }
                while true { let chunk = try input.read(upToCount: chunkSize) ?? Data(); if chunk.isEmpty { break }; crc = CRC32.update(crc, chunk: chunk) }
                crc ^= 0xFFFFFFFF
                var local = Data()
                local.append(contentsOf: [0x50, 0x4b, 0x03, 0x04]); local.append(contentsOf: [20, 0, 0, 0, 0, 0, 0, 0, 0, 0])
                local.append(contentsOf: withUnsafeBytes(of: crc.littleEndian) { Data($0) })
                local.append(contentsOf: withUnsafeBytes(of: size.littleEndian) { Data($0) })
                local.append(contentsOf: withUnsafeBytes(of: size.littleEndian) { Data($0) })
                local.append(contentsOf: withUnsafeBytes(of: UInt16(nameData.count).littleEndian) { Data($0) })
                local.append(contentsOf: [0, 0]); local.append(nameData); try out.write(contentsOf: local)
                localHeaderLength = UInt32(local.count)
                try input.seek(toOffset: 0)
                while true { let chunk = try input.read(upToCount: chunkSize) ?? Data(); if chunk.isEmpty { break }; try out.write(contentsOf: chunk) }
            }
            var cd = Data()
            cd.append(contentsOf: [0x50, 0x4b, 0x01, 0x02]); cd.append(contentsOf: [20, 0, 20, 0, 0, 0, 0, 0, 0, 0])
            cd.append(contentsOf: withUnsafeBytes(of: crc.littleEndian) { Data($0) })
            cd.append(contentsOf: withUnsafeBytes(of: size.littleEndian) { Data($0) })
            cd.append(contentsOf: withUnsafeBytes(of: size.littleEndian) { Data($0) })
            cd.append(contentsOf: withUnsafeBytes(of: UInt16(nameData.count).littleEndian) { Data($0) })
            cd.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
            cd.append(contentsOf: withUnsafeBytes(of: offset.littleEndian) { Data($0) })
            cd.append(nameData); central.append(cd); offset += localHeaderLength + size; written += 1
        }
        let centralOffset = offset; try out.write(contentsOf: central)
        var end = Data()
        end.append(contentsOf: [0x50, 0x4b, 0x05, 0x06, 0, 0, 0, 0])
        end.append(contentsOf: withUnsafeBytes(of: UInt16(written).littleEndian) { Data($0) })
        end.append(contentsOf: withUnsafeBytes(of: UInt16(written).littleEndian) { Data($0) })
        end.append(contentsOf: withUnsafeBytes(of: UInt32(central.count).littleEndian) { Data($0) })
        end.append(contentsOf: withUnsafeBytes(of: centralOffset.littleEndian) { Data($0) })
        end.append(contentsOf: [0, 0]); try out.write(contentsOf: end)
    }
}
