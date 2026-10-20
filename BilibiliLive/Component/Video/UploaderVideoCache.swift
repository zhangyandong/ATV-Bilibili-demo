import Foundation

actor UploaderVideoCache {
    static let shared = UploaderVideoCache()

    private struct Key: Hashable {
        let ownerMid: Int
        let accountMid: Int
    }

    private struct Entry {
        let videos: [PlayInfo]
        let expiresAt: Date
    }

    private let lifetime: TimeInterval = 5 * 60
    private let capacity = 8
    private var entries = [Key: Entry]()
    private var accessOrder = [Key]()

    func videos(ownerMid: Int, accountMid: Int) async throws -> [PlayInfo] {
        try Task.checkCancellation()
        let key = Key(ownerMid: ownerMid, accountMid: accountMid)
        if let entry = entries[key], entry.expiresAt > Date() {
            touch(key)
            return entry.videos
        }
        let records = try await ApiRequest.requestUpSpaceVideo(mid: ownerMid, lastAid: nil, pageSize: 18)
        try Task.checkCancellation()
        var seenAids = Set<Int>()
        let videos = records.compactMap { record -> PlayInfo? in
            guard record.aid > 0, seenAids.insert(record.aid).inserted else { return nil }
            return PlayInfo(aid: record.aid,
                            title: record.title,
                            ownerName: record.ownerName,
                            coverURL: record.pic)
        }
        // Cache the full page so opening another video by the same uploader can reuse it.
        entries[key] = Entry(videos: videos, expiresAt: Date().addingTimeInterval(lifetime))
        touch(key)
        while accessOrder.count > capacity {
            entries.removeValue(forKey: accessOrder.removeFirst())
        }
        return videos
    }

    private func touch(_ key: Key) {
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
    }
}
