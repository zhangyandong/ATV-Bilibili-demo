//
//  Settings.swift
//  BilibiliLive
//
//  Created by whw on 2022/10/19.
//

import Foundation

enum FeedDisplayStyle: Codable, CaseIterable {
    case large
    case normal
    case sideBar

    var hideInSetting: Bool {
        self == .sideBar
    }
}

enum Settings {
    @UserDefaultCodable("Settings.displayStyle", defaultValue: .normal)
    static var displayStyle: FeedDisplayStyle

    @UserDefault("Settings.direatlyEnterVideo", defaultValue: false)
    static var direatlyEnterVideo: Bool

    @UserDefaultCodable("Settings.mediaQuality", defaultValue: .quality_1080p)
    static var mediaQuality: MediaQualityEnum

    @UserDefaultCodable("Settings.mediaPlayerSpeed", defaultValue: PlaySpeed.default)
    static var mediaPlayerSpeed: PlaySpeed

    @UserDefault("Settings.losslessAudio", defaultValue: false)
    static var losslessAudio: Bool

    @UserDefault("Settings.preferAvc", defaultValue: false)
    static var preferAvc: Bool

    @UserDefault("Settings.multiCDNEnabled", defaultValue: false)
    static var multiCDNEnabled: Bool

    @UserDefault("Settings.loadHighestVideoOnly", defaultValue: false)
    static var loadHighestVideoOnly: Bool

    @UserDefault("Settings.contentMatch", defaultValue: true)
    static var contentMatch: Bool

    @UserDefault("Settings.contentMatchOnlyInHDR", defaultValue: true)
    static var contentMatchOnlyInHDR: Bool

    @UserDefault("Settings.continuePlay", defaultValue: true)
    static var continuePlay: Bool

    @UserDefault("DLNA.uuid", defaultValue: "")
    static var uuid: String

    @UserDefault("DLNA.enable", defaultValue: true)
    static var enableDLNA: Bool

    @UserDefault("Settings.continouslyPlay", defaultValue: true)
    static var continouslyPlay: Bool

    @UserDefault("Settings.loopPlay", defaultValue: false)
    static var loopPlay: Bool

    @UserDefault("Settings.play.autoSkip", defaultValue: true)
    static var autoSkip: Bool

    @UserDefault("Settings.showRelatedVideoInCurrentVC", defaultValue: true)
    static var showRelatedVideoInCurrentVC: Bool

    @UserDefault("Settings.requestHotWithoutCookie", defaultValue: false)
    static var requestHotWithoutCookie: Bool

    @UserDefault("Settings.arealimit.unlock", defaultValue: false)
    static var areaLimitUnlock: Bool

    @UserDefault("Settings.arealimit.customServer", defaultValue: "")
    static var areaLimitCustomServer: String

    @UserDefault("Settings.ui.sideMenuAutoSelectChange", defaultValue: false)
    static var sideMenuAutoSelectChange: Bool

    @UserDefaultCodable("Settings.featuredDurationLimit", defaultValue: .minutes10)
    static var featuredDurationLimit: FeaturedDurationLimit

    @UserDefault("Settings.recommendFeedFlowEnabled", defaultValue: false)
    static var recommendFeedFlowEnabled: Bool

    @UserDefault("Settings.feedAutoPreviewEnabled", defaultValue: false)
    static var feedAutoPreviewEnabled: Bool

    @UserDefault("Settings.featuredContentSafetyFilterEnabled", defaultValue: true)
    static var featuredContentSafetyFilterEnabled: Bool

    @UserDefault("Settings.followsFeedFlowEnabled", defaultValue: false)
    static var followsFeedFlowEnabled: Bool

    @UserDefaultCodable("Settings.SponsorBlockType", defaultValue: SponsorBlockType.none)
    static var enableSponsorBlock: SponsorBlockType

    @UserDefaultCodable("Search.histories", defaultValue: [])
    static var searchHistories: [String]
}

extension Settings {
    static func addHistory(_ query: String, limitSize: Int = 6) {
        if query.isEmpty {
            return
        }

        var histories = Settings.searchHistories
        if histories.first == query {
            return
        }

        if let i = histories.firstIndex(of: query) {
            histories.remove(at: i)
        }

        histories.insert(query, at: 0)
        if histories.count > limitSize {
            histories.removeLast()
        }
        Settings.searchHistories = histories
    }

    static func clearHistory() {
        Settings.searchHistories = []
    }
}

struct MediaQuality {
    var qn: Int
    var fnval: Int
}

enum SponsorBlockType: String, Codable, CaseIterable {
    case none
    case jump
    case tip

    var title: String {
        switch self {
        case .none:
            return "关"
        case .jump:
            return "自动跳过"
        case .tip:
            return "手动跳过"
        }
    }
}

enum FeaturedDurationLimit: Codable, CaseIterable, Equatable {
    case minutes3
    case minutes5
    case minutes10
    case minutes15
    case unlimited
}

extension FeaturedDurationLimit {
    var title: String {
        switch self {
        case .minutes3:
            return "3 分钟"
        case .minutes5:
            return "5 分钟"
        case .minutes10:
            return "10 分钟"
        case .minutes15:
            return "15 分钟"
        case .unlimited:
            return "不限"
        }
    }

    var maxDuration: Int? {
        switch self {
        case .minutes3:
            return 3 * 60
        case .minutes5:
            return 5 * 60
        case .minutes10:
            return 10 * 60
        case .minutes15:
            return 15 * 60
        case .unlimited:
            return nil
        }
    }
}

enum MediaQualityEnum: Codable, CaseIterable {
    case quality_1080p
    case quality_2160p
    case quality_hdr_dolby
}

extension MediaQualityEnum {
    var desp: String {
        switch self {
        case .quality_1080p:
            return "1080p"
        case .quality_2160p:
            return "4K"
        case .quality_hdr_dolby:
            return "杜比视界"
        }
    }

    var qn: Int {
        switch self {
        case .quality_1080p:
            return 116
        case .quality_2160p:
            return 120
        case .quality_hdr_dolby:
            return 126
        }
    }

    var fnval: Int {
        switch self {
        case .quality_1080p:
            return 16
        case .quality_2160p:
            return 144
        case .quality_hdr_dolby:
            return 976
        }
    }
}
