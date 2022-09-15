//
//  ViewController.swift
//  Hello-World
//
//  Created by Roberto Perez Cubero on 11/08/16.
//  Copyright © 2016 tokbox. All rights reserved.
//

import UIKit
import OpenTok
import WatchRTC_SDK_iOS
import SwiftyJSON

// *** Fill the following variables using your own Project info  ***
// ***            https://tokbox.com/account/#/                  ***
// Replace with your OpenTok API key
let kApiKey = ""
// Replace with your generated session ID
let kSessionId = ""
// Replace with your generated token
let kToken = ""

let kWidgetHeight = 240
let kWidgetWidth = 320

class ViewController: UIViewController {
    lazy var session: OTSession = {
        return OTSession(apiKey: kApiKey, sessionId: kSessionId, delegate: self)!
    }()
    
    lazy var publisher: OTPublisher = {
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        return OTPublisher(delegate: self, settings: settings)!
    }()
    
    var subscriber: OTSubscriber?
    
    private var watchRtc: WatchRTC?
    
    fileprivate var rtcStatsReportCallback: ((RTCStatsReport) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        publisher.rtcStatsReportDelegate = self
        
        let con: WatchRTCConfig = WatchRTCConfig(rtcApiKey: "staging:6d3873f0-f06e-4aea-9a25-1a959ab988cc", rtcRoomId: "VonageTest1", keys: ["company":["YourCompanyName"]])
        self.watchRtc = WatchRTC(dataProvider: self)
        guard let watchRtc = self.watchRtc else {
            debugPrint("error with watchRtc initialization")
            return
        }
        watchRtc.setConfig(config: con)
        
        doConnect()
    }
    
    /**
     * Asynchronously begins the session connect process. Some time later, we will
     * expect a delegate method to call us back with the results of this action.
     */
    fileprivate func doConnect() {
        var error: OTError?
        defer {
            processError(error)
        }
        
        session.connect(withToken: kToken, error: &error)
        
        watchRtc?.addEvent(name: "doConnect",
                           type: EventType.global,
                           parameters: ["sessionId" : session.sessionId])
    }
    
    /**
     * Sets up an instance of OTPublisher to use with this session. OTPubilsher
     * binds to the device camera and microphone, and will provide A/V streams
     * to the OpenTok session.
     */
    fileprivate func doPublish() {
        var error: OTError?
        defer {
            processError(error)
        }
        
        session.publish(publisher, error: &error)
        
        if let pubView = publisher.view {
            pubView.frame = CGRect(x: 0, y: 0, width: kWidgetWidth, height: kWidgetHeight)
            view.addSubview(pubView)
        }
        
        watchRtc?.addEvent(name: "doPublish",
                           type: EventType.global,
                           parameters: ["sessionId" : session.sessionId])
    }
    
    /**
     * Instantiates a subscriber for the given stream and asynchronously begins the
     * process to begin receiving A/V content for this stream. Unlike doPublish,
     * this method does not add the subscriber to the view hierarchy. Instead, we
     * add the subscriber only after it has connected and begins receiving data.
     */
    fileprivate func doSubscribe(_ stream: OTStream) {
        var error: OTError?
        defer {
            processError(error)
        }
        subscriber = OTSubscriber(stream: stream, delegate: self)
        subscriber?.rtcStatsReportDelegate = self
        
        session.subscribe(subscriber!, error: &error)
        
        watchRtc?.addEvent(name: "doSubscribe",
                           type: EventType.global,
                           parameters: ["sessionId" : session.sessionId,
                                        "streamId" : stream.streamId,
                                        "streamName" : stream.name,
                                        "creationTime" : "\(stream.creationTime.timeIntervalSince1970*1000)"])
    }
    
    fileprivate func cleanupSubscriber() {
        subscriber?.view?.removeFromSuperview()
        subscriber = nil
    }
    
    fileprivate func cleanupPublisher() {
        publisher.view?.removeFromSuperview()
    }
    
    fileprivate func processError(_ error: OTError?) {
        if let err = error {
            DispatchQueue.main.async {
                let controller = UIAlertController(title: "Error", message: err.localizedDescription, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(controller, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - OTSession delegate callbacks
extension ViewController: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        print("Session connected")
        
        do
        {
            try watchRtc?.connect()
            watchRtc?.setUserRating(rating: 4, ratingComment: "Put your rating value")
            watchRtc?.addEvent(name: "sessionDidConnect", type: EventType.global, parameters: ["sessionId": session.sessionId])
        } catch {
            debugPrint(error)
        }
        
        doPublish()
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print("Session disconnected")
        
        watchRtc?.addEvent(name: "sessionDidDisconnect", type: EventType.global, parameters: ["sessionId": session.sessionId])
        
        watchRtc?.disconnect()
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("Session streamCreated: \(stream.streamId)")
        
        watchRtc?.addEvent(name: "sessionStreamCreated",
                           type: EventType.global,
                           parameters: ["sessionId" : session.sessionId,
                                        "streamId" : stream.streamId,
                                        "streamName" : stream.name,
                                        "creationTime" : "\(stream.creationTime.timeIntervalSince1970*1000)"])
        
        if subscriber == nil {
            doSubscribe(stream)
        }
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("Session streamDestroyed: \(stream.streamId)")
        
        watchRtc?.addEvent(name: "sessionStreamDestroyed",
                           type: EventType.global,
                           parameters: ["sessionId" : session.sessionId,
                                        "streamId" : stream.streamId,
                                        "streamName" : stream.name,
                                        "creationTime" : "\(stream.creationTime.timeIntervalSince1970*1000)"])
        
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("session Failed to connect: \(error.localizedDescription)")
        
        watchRtc?.addEvent(name: "sessionDidFailWithError",
                           type: EventType.global,
                           parameters: ["sessionId" : session.sessionId,
                                        "error" : error.localizedDescription])
    }
    
}

// MARK: - OTPublisher delegate callbacks
extension ViewController: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        print("Publishing")
        
        watchRtc?.addEvent(name: "publisherStreamCreated",
                           type: EventType.global,
                           parameters: ["publisherName" : publisher.name,
                                        "streamId" : stream.streamId,
                                        "streamName" : stream.name,
                                        "creationTime" : "\(stream.creationTime.timeIntervalSince1970*1000)"])
    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        watchRtc?.addEvent(name: "publisherStreamDestroyed",
                           type: EventType.global,
                           parameters: ["publisherName" : publisher.name,
                                        "streamId" : stream.streamId,
                                        "streamName" : stream.name,
                                        "creationTime" : "\(stream.creationTime.timeIntervalSince1970*1000)"])
        
        cleanupPublisher()
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("Publisher failed: \(error.localizedDescription)")
        
        watchRtc?.addEvent(name: "publisherDidFailWithError",
                           type: EventType.global,
                           parameters: ["publisherName" : publisher.name,
                                        "error" : error.localizedDescription])
    }
}

// MARK: - OTSubscriber delegate callbacks
extension ViewController: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        watchRtc?.addEvent(name: "subscriberDidConnectToStream",
                           type: EventType.global,
                           parameters: nil)
        
        if let subsView = subscriber?.view {
            subsView.frame = CGRect(x: 0, y: kWidgetHeight, width: kWidgetWidth, height: kWidgetHeight)
            view.addSubview(subsView)
        }
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
        
        watchRtc?.addEvent(name: "subscriberDidFailWithError",
                           type: EventType.global,
                           parameters: ["error" : error.localizedDescription])
    }
}

private extension ViewController {
    func parseRTCStatsJsonString(jsonArrayOfReports: String) -> RTCStatsReport {
        let statsJson = JSON(parseJSON: jsonArrayOfReports)

        let timestamp = statsJson["timestamp"].int64 ?? Int64(Date().timeIntervalSince1970*1000)
        
        var dict = [String: RTCStat]()

        for (_, value) in statsJson {
            let statTimestamp = value["timestamp"].int64 ?? Int64(Date().timeIntervalSince1970*1000)
            let rtcStat = RTCStat(timestamp: statTimestamp, properties: value.dictionaryValue)
            dict[value["id"].stringValue] = rtcStat
        }

        let rtcStatsReport = RTCStatsReport(report: dict, timestamp: timestamp)
        
        return rtcStatsReport
    }
}

extension ViewController: OTSubscriberKitRtcStatsReportDelegate {
    func subscriber(_ subscriber: OTSubscriberKit, rtcStatsReport jsonArrayOfReports: String) {
        print("subscriber stats fired")
        
        let rtcStatReport = self.parseRTCStatsJsonString(jsonArrayOfReports: jsonArrayOfReports)

        rtcStatsReportCallback?(rtcStatReport)
    }
}

extension ViewController: OTPublisherKitRtcStatsReportDelegate {
    func publisher(_ publisher: OTPublisherKit, rtcStatsReport stats: [OTPublisherRtcStats]) {
        print("publisher stats fired")
        
        guard let jsonArrayOfReports = stats.first?.jsonArrayOfReports else {
            print("publisher stats are empty")
            
            return
        }
        
        let rtcStatReport = self.parseRTCStatsJsonString(jsonArrayOfReports: jsonArrayOfReports)

        rtcStatsReportCallback?(rtcStatReport)
    }
}

extension ViewController: RtcDataProvider {
    func getStats(callback: @escaping (RTCStatsReport) -> Void) {
        self.rtcStatsReportCallback = callback
        
        publisher.getRtcStatsReport()
        subscriber?.getRtcStatsReport()
    }
}
