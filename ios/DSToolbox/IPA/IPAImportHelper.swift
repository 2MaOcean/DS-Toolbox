import Foundation

enum IPAImportHelper {
    static func importFromURL(_ urlString: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "IPA", code: 1, userInfo: [NSLocalizedDescriptionKey: "无效 URL"])))
            return
        }
        let dest = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(url.lastPathComponent)
        URLSession.shared.downloadTask(with: url) { tmp, _, err in
            if let err { completion(.failure(err)); return }
            guard let tmp else { completion(.failure(NSError(domain: "IPA", code: 2))); return }
            do {
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.moveItem(at: tmp, to: dest)
                completion(.success(dest))
            } catch { completion(.failure(error)) }
        }.resume()
    }
}
