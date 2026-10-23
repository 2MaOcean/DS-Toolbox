import Foundation
indirect enum BencodeValue {
    case int(Int), string(String), data(Data), list([BencodeValue]), dict([String: BencodeValue])
}
struct BencodeEncoder {
    func encode(_ value: BencodeValue) -> Data {
        switch value {
        case .int(let i): return Data("i\(i)e".utf8)
        case .string(let s): let b = Data(s.utf8); return Data("\(b.count):".utf8) + b
        case .data(let d): return Data("\(d.count):".utf8) + d
        case .list(let items): var o = Data("l".utf8); for i in items { o.append(encode(i)) }; o.append(Data("e".utf8)); return o
        case .dict(let dict): var o = Data("d".utf8); for k in dict.keys.sorted() { o.append(encode(.string(k))); o.append(encode(dict[k]!)) }; o.append(Data("e".utf8)); return o
        }
    }
}
