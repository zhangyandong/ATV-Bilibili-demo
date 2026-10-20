//
//  VideoPlayerInfoTabsPlugin.swift
//  BilibiliLive
//
//  Created by OpenAI on 2026/4/5.
//

import AVKit
import UIKit

final class VideoPlayerInfoTabsPlugin: NSObject, CommonPlayerPlugin {
    private enum DiscoverySource {
        case uploader
        case related

        var tabTitle: String {
            switch self {
            case .uploader:
                return "博主视频"
            case .related:
                return "相关视频"
            }
        }

        var emptyText: String {
            switch self {
            case .uploader:
                return "当前没有可展示的博主视频"
            case .related:
                return "当前没有可展示的相关视频"
            }
        }
    }

    var onSelectDiscovery: ((PlayInfo) -> Void)?

    private let currentPlayInfo: PlayInfo
    private let sequenceProvider: VideoSequenceProvider?
    private let uploaderInfoViewController = VideoPlayerDiscoveryInfoViewController(title: DiscoverySource.uploader.tabTitle,
                                                                                    emptyText: DiscoverySource.uploader.emptyText)
    private let relatedInfoViewController = VideoPlayerDiscoveryInfoViewController(title: DiscoverySource.related.tabTitle,
                                                                                   emptyText: DiscoverySource.related.emptyText)
    private let actionInfoViewController: VideoPlayerActionInfoViewController
    private let relatedCandidates: [PlayInfo]
    private let ownerMid: Int
    private var uploaderEntries = [PlayInfo]()
    private var uploaderLoadTask: Task<Void, Never>?
    private var uploaderLoaded = false
    private var uploaderLoadID: UUID?
    private weak var playerVC: AVPlayerViewController?

    init(detail: VideoDetail?, currentPlayInfo: PlayInfo, sequenceProvider: VideoSequenceProvider?) {
        self.currentPlayInfo = currentPlayInfo
        self.sequenceProvider = sequenceProvider
        ownerMid = detail?.View.owner.mid ?? 0
        relatedCandidates = Self.makeRelatedEntries(detail: detail, currentPlayInfo: currentPlayInfo)
        actionInfoViewController = VideoPlayerActionInfoViewController(detail: detail)
        super.init()

        let onSelect: (PlayInfo) -> Void = { [weak self] playInfo in
            guard let self else { return }
            let currentSequenceKey = self.sequenceProvider.flatMap { provider in
                MainActor.assumeIsolated {
                    provider.current()?.sequenceKey
                }
            } ?? self.currentPlayInfo.sequenceKey
            guard currentSequenceKey != playInfo.sequenceKey else { return }
            self.onSelectDiscovery?(playInfo)
        }
        uploaderInfoViewController.onSelect = onSelect
        relatedInfoViewController.onSelect = onSelect
        uploaderInfoViewController.onAppear = { [weak self] in
            self?.loadUploaderEntriesIfNeeded()
        }
        refreshDiscoveryTabs()
    }

    deinit {
        uploaderLoadTask?.cancel()
    }

    func playerDidLoad(playerVC: AVPlayerViewController) {
        self.playerVC = playerVC
        refreshCustomInfoViewControllers()
    }

    func playerDidDismiss(playerVC: AVPlayerViewController) {
        removeCustomInfoViewControllers()
        cancelUploaderLoad()
    }

    func playerWillCleanUp(playerVC: AVPlayerViewController) {
        removeCustomInfoViewControllers()
        cancelUploaderLoad()
    }

    private func cancelUploaderLoad() {
        uploaderLoadID = nil
        uploaderLoadTask?.cancel()
        uploaderLoadTask = nil
    }

    private func loadUploaderEntriesIfNeeded() {
        guard ownerMid > 0, !uploaderLoaded, uploaderLoadTask == nil else { return }
        let ownerMid = ownerMid
        let accountMid = AccountManager.shared.activeAccount?.profile.mid ?? 0
        let loadID = UUID()
        uploaderLoadID = loadID
        uploaderInfoViewController.update(entries: [], emptyMessage: "正在加载博主视频…")
        uploaderLoadTask = Task { @MainActor [weak self] in
            do {
                let videos = try await UploaderVideoCache.shared.videos(ownerMid: ownerMid, accountMid: accountMid)
                guard !Task.isCancelled, let self, self.uploaderLoadID == loadID else { return }
                self.uploaderLoadTask = nil
                self.uploaderLoaded = true
                self.uploaderEntries = Array(videos.filter { $0.aid != self.currentPlayInfo.aid }.prefix(6))
                self.refreshDiscoveryTabs()
            } catch {
                guard !Task.isCancelled, let self, self.uploaderLoadID == loadID else { return }
                self.uploaderLoadTask = nil
                self.uploaderInfoViewController.update(entries: [], emptyMessage: "加载失败，重新打开此面板可重试")
                Logger.warn(error)
            }
        }
    }

    private func refreshDiscoveryTabs() {
        uploaderInfoViewController.update(entries: uploaderEntries.prefix(6).map(makeViewEntry(from:)))
        relatedInfoViewController.update(entries: relatedCandidates.prefix(6).map(makeViewEntry(from:)))
    }

    private func makeViewEntry(from playInfo: PlayInfo) -> VideoPlayerDiscoveryInfoViewController.Entry {
        VideoPlayerDiscoveryInfoViewController.Entry(playInfo: playInfo,
                                                     displayData: VideoPlayerDiscoveryInfoViewController.DiscoveryDisplayData(title: playInfo.title ?? "",
                                                                                                                              ownerName: playInfo.ownerName ?? "",
                                                                                                                              pic: playInfo.coverURL))
    }

    private func refreshCustomInfoViewControllers() {
        guard let playerVC else { return }
        var controllers = playerVC.customInfoViewControllers.filter {
            $0 !== uploaderInfoViewController &&
                $0 !== relatedInfoViewController &&
                $0 !== actionInfoViewController
        }
        controllers.append(uploaderInfoViewController)
        controllers.append(relatedInfoViewController)
        controllers.append(actionInfoViewController)
        playerVC.customInfoViewControllers = controllers
    }

    private func removeCustomInfoViewControllers() {
        guard let playerVC else { return }
        playerVC.customInfoViewControllers.removeAll {
            $0 === uploaderInfoViewController ||
                $0 === relatedInfoViewController ||
                $0 === actionInfoViewController
        }
    }

    private static func makeRelatedEntries(detail: VideoDetail?, currentPlayInfo: PlayInfo) -> [PlayInfo] {
        let related = detail?.Related ?? []
        var seenAids = Set<Int>()
        return related.compactMap { info -> PlayInfo? in
            guard info.aid > 0,
                  info.aid != currentPlayInfo.aid,
                  seenAids.insert(info.aid).inserted
            else {
                return nil
            }

            return PlayInfo(aid: info.aid,
                            cid: info.cid,
                            title: info.title,
                            ownerName: info.ownerName,
                            coverURL: info.pic)
        }
    }
}
