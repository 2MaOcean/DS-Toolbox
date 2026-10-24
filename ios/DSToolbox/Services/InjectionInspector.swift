import Foundation
import MachO

enum InjectionInspector {
    static func currentImages() -> [String] {
        let count = _dyld_image_count()
        var list: [String] = []
        for i in 0..<count {
            if let name = _dyld_get_image_name(i) {
                list.append(String(cString: name))
            }
        }
        return list.sorted()
    }
}
