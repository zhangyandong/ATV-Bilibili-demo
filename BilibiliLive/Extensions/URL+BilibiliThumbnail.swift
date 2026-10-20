import Foundation

extension URL {
    func bilibiliThumbnailURL(width: Int, height: Int) -> URL {
        let normalized = scheme == nil ? URL(string: "https:\(absoluteString)") ?? self : self
        guard width > 0, height > 0,
              var components = URLComponents(url: normalized, resolvingAgainstBaseURL: false),
              let host = components.host?.lowercased(),
              host == "hdslb.com" || host.hasSuffix(".hdslb.com"),
              components.query == nil,
              components.fragment == nil
        else { return normalized }

        // Do not alter signed URLs or other image services. Replace existing CDN transforms.
        let originalPath = components.path.components(separatedBy: "@")[0]
        let fileExtension = (originalPath as NSString).pathExtension.lowercased()
        guard ["jpg", "jpeg", "png", "webp"].contains(fileExtension) else { return normalized }
        components.path = originalPath + "@\(width)w_\(height)h.jpg"
        return components.url ?? normalized
    }
}
