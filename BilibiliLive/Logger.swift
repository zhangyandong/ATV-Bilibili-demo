//
//  Logger.swift
//  BilibiliLive
//
//  Created by yicheng on 2022/12/9.
//

import CocoaLumberjackSwift
import Foundation

class Logger {
    private static let fileLogger = DDFileLogger()
    static func setup() {
        #if DEBUG
            let level: DDLogLevel = .all
        #else
            let level: DDLogLevel = .warning
        #endif
        DDLog.add(DDOSLogger.sharedInstance, with: level)
        let dataFormatter = DateFormatter()
        dataFormatter.setLocalizedDateFormatFromTemplate("YYYY/MM/dd HH:mm:ss:SSS")
        fileLogger.logFormatter = DDLogFileFormatterDefault(dateFormatter: dataFormatter)
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 2
        fileLogger.doNotReuseLogFiles = true
        fileLogger.maximumFileSize = 1024 * 1024 * 5
        DDLog.add(fileLogger, with: level)
    }

    static func debug(_ message: @autoclosure () -> DDLogMessageFormat,
                      file: StaticString = #file,
                      function: StaticString = #function,
                      line: UInt = #line)
    {
        #if DEBUG
            DDLogDebug(message(), file: file, function: function, line: line)
        #endif
    }

    static func info(_ message: @autoclosure () -> DDLogMessageFormat,
                     file: StaticString = #file,
                     function: StaticString = #function,
                     line: UInt = #line)
    {
        #if DEBUG
            DDLogInfo(message(), file: file, function: function, line: line)
        #endif
    }

    static func warn(_ message: @autoclosure () -> DDLogMessageFormat,
                     file: StaticString = #file,
                     function: StaticString = #function,
                     line: UInt = #line)
    {
        DDLogWarn(message(), file: file, function: function, line: line)
    }

    static func warn(_ error: Any,
                     file: StaticString = #file,
                     function: StaticString = #function,
                     line: UInt = #line)
    {
        DDLogWarn("\(error)", file: file, function: function, line: line)
    }

    static func latestLogPath() -> String? {
        fileLogger.logFileManager.sortedLogFilePaths.first
    }

    static func oldestLogPath() -> String? {
        fileLogger.logFileManager.sortedLogFilePaths.last
    }
}
