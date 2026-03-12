import AppKit

/// Checks GitHub Releases for a newer version of Popy.
final class UpdateManager {

    static let shared = UpdateManager()

    private let repo = "anuragxxd/popy"
    private let releasesURL: URL

    /// The currently running app version (from Info.plist).
    var currentVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    private init() {
        releasesURL = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
    }

    // MARK: - Check for Updates

    /// Checks GitHub for a newer release. Calls back on the main thread.
    func checkForUpdates(completion: @escaping (UpdateResult) -> Void) {
        var request = URLRequest(url: releasesURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    completion(.error("Could not reach GitHub: \(error.localizedDescription)"))
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String else {
                    completion(.error("Could not parse release info."))
                    return
                }

                // tag_name is like "v1.0.0" — strip the "v" prefix
                let latestVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
                let downloadURL = json["html_url"] as? String ?? "https://github.com/\(self.repo)/releases/latest"

                if self.isVersion(latestVersion, newerThan: self.currentVersion) {
                    completion(.updateAvailable(latestVersion: latestVersion, downloadURL: downloadURL))
                } else {
                    completion(.upToDate)
                }
            }
        }.resume()
    }

    // MARK: - Version Comparison

    /// Simple semantic version comparison: "1.2.3" > "1.2.0"
    private func isVersion(_ a: String, newerThan b: String) -> Bool {
        let partsA = a.split(separator: ".").compactMap { Int($0) }
        let partsB = b.split(separator: ".").compactMap { Int($0) }

        let count = max(partsA.count, partsB.count)
        for i in 0..<count {
            let va = i < partsA.count ? partsA[i] : 0
            let vb = i < partsB.count ? partsB[i] : 0
            if va > vb { return true }
            if va < vb { return false }
        }
        return false
    }

    // MARK: - Result Type

    enum UpdateResult {
        case upToDate
        case updateAvailable(latestVersion: String, downloadURL: String)
        case error(String)
    }
}
