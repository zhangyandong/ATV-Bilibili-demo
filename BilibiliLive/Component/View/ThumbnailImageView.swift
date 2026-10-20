import Kingfisher
import UIKit

/// Loads only while attached to a window and resumes cancelled work when shown again.
final class ThumbnailImageView: UIImageView {
    private var thumbnailURL: URL?
    private var thumbnailSize = CGSize.zero
    private var roundCorners = false
    private var requestID: UUID?

    func configure(url: URL?, size: CGSize, roundCorners: Bool = false) {
        let url = url?.bilibiliThumbnailURL(width: Int(size.width), height: Int(size.height))
        guard thumbnailURL != url || thumbnailSize != size || self.roundCorners != roundCorners else {
            resumeLoading()
            return
        }
        cancelLoading()
        thumbnailURL = url
        thumbnailSize = size
        self.roundCorners = roundCorners
        image = nil
        resumeLoading()
    }

    func cancelLoading() {
        requestID = nil
        kf.cancelDownloadTask()
        // Invalidate processing/cache callbacks too, without clearing an already displayed image.
        kf.setImage(with: nil as URL?, placeholder: image)
    }

    func resumeLoading() {
        guard window != nil, image == nil, requestID == nil, let thumbnailURL else { return }
        let id = UUID()
        requestID = id
        var processor: any ImageProcessor = DownsamplingImageProcessor(size: thumbnailSize)
        if roundCorners {
            processor = processor |> RoundCornerImageProcessor(radius: .widthFraction(0.5))
        }
        var options: KingfisherOptionsInfo = [.processor(processor), .scaleFactor(1), .backgroundDecode]
        if roundCorners {
            options.append(.cacheSerializer(FormatIndicatedCacheSerializer.png))
        }
        kf.setImage(with: thumbnailURL, options: options) { [weak self] _ in
            guard self?.requestID == id else { return }
            self?.requestID = nil
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            cancelLoading()
        } else {
            resumeLoading()
        }
    }
}
