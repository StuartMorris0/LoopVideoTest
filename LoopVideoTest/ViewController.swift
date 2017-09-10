//
//  ViewController.swift
//  LoopVideoTest
//
//  Created by Alex Gibson on 9/9/17.
//  Copyright © 2017 AG. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        createLoopVideo30Seconds()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createLoopVideo30Seconds(){
        //create a mix composition
        let avComposition = AVMutableComposition()
        
        //hard coded output urls
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory: NSURL = urls.first! as NSURL
        let videoOutputURL = documentDirectory.appendingPathComponent("OutputVideo.mp4")
        
        let videoComp = self.createVideoWithComposition(avComposition)
        
        //write to file
        if FileManager.default.fileExists(atPath: videoOutputURL!.path) {
            do {
                try FileManager.default.removeItem(atPath: videoOutputURL!.path)
            } catch {
                fatalError("Unable to delete file: \(error) : \(#function).")
            }
        }
        
        
        print("Starting exporter")
        let exporter = AVAssetExportSession(asset: avComposition, presetName: AVAssetExportPresetLowQuality)
        exporter?.outputURL = videoOutputURL
        exporter?.videoComposition = videoComp
        exporter?.audioMix = nil
        exporter?.outputFileType = AVFileTypeQuickTimeMovie
        exporter?.exportAsynchronously(completionHandler: {
            
            if exporter?.status == AVAssetExportSessionStatus.completed{
                print("Completed")
            }else if exporter?.status == .failed{
                print("failed with error : \(exporter?.error)")
            }
            
        })
    }
    
    func createVideoWithComposition(_ avComp: AVMutableComposition) -> (AVVideoComposition) {
        let desiredDuration = CMTimeMakeWithSeconds(30, 600)
        let firstAsset = AVURLAsset(url: Bundle.main.url(forResource:"Looping", withExtension: "mp4")!)
        
        let assetDuration = firstAsset.duration
        
        //create the first compositionTrack
        let firstTrack = avComp.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID:
            kCMPersistentTrackID_Invalid)
        
        let firstAssestDuration = CMTimeGetSeconds(firstAsset.duration)
        print("First assest duration: \(firstAssestDuration)")
        
        var videoTimeDuration = kCMTimeZero
        
        
        if(CMTimeCompare(desiredDuration, firstAsset.duration) == -1){
            do{
                try firstTrack.insertTimeRange(CMTimeRange(start: kCMTimeZero, duration: assetDuration), of: firstAsset.tracks(withMediaType: AVMediaTypeVideo).first!, at: kCMTimeZero)
                videoTimeDuration = CMTimeAdd(videoTimeDuration, assetDuration)
                
            }catch let error{
                print("error \(error)")
            }
        }else if(CMTimeCompare(desiredDuration, firstAsset.duration) == 1){
            var currentTime = kCMTimeZero
            while(true){
                var AD : CMTime = firstAsset.duration
                let totalDuration : CMTime = CMTimeAdd(currentTime,AD);
                if(CMTimeCompare(totalDuration, desiredDuration)==1){
                    AD = CMTimeSubtract(totalDuration,desiredDuration);
                }
                
                do{
                    try firstTrack.insertTimeRange(CMTimeRange(start: kCMTimeZero, duration: AD), of: firstAsset.tracks(withMediaType: AVMediaTypeVideo).first!, at: currentTime)
                    currentTime = CMTimeAdd(currentTime, AD)
                    videoTimeDuration = CMTimeAdd(videoTimeDuration, AD)
                    
                    if(CMTimeCompare(currentTime,desiredDuration) == 1 || CMTimeCompare(currentTime, desiredDuration) == 0){
                        print("Breaking...")
                        break;
                    }
                    print("updating track \(CMTimeGetSeconds(currentTime))")
                    
                }catch let error{
                    print("error \(error)")
                }
            }
        }
        
        
        
        
        // create avmutuablevideoComposition and set the longer asset here for instructions
        // this could be an animation in the future maybe
        let mainInstructions = AVMutableVideoCompositionInstruction()
        mainInstructions.timeRange = CMTimeRangeMake(kCMTimeZero, desiredDuration)
        
        
        //we will be making two layer instructions
        let firstLayerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: firstTrack)
        
        
        //combine instructions
        mainInstructions.layerInstructions = [firstLayerInstructions]
        mainInstructions.timeRange = CMTimeRangeMake(kCMTimeZero, videoTimeDuration)
        
        
        //main compositionobject
        let maincomposition = AVMutableVideoComposition()
        //add layer instructions from above
        maincomposition.instructions = [mainInstructions]
        //frames per second
        maincomposition.frameDuration = CMTimeMake(1, 30)
        maincomposition.renderScale = 1
        
        maincomposition.renderSize = firstTrack.naturalSize
        
        return maincomposition
    }
    
    
}


