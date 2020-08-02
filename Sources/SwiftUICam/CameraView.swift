//
//  CameraView.swift
//  SwiftUICam
//
//  Created by Pierre Véron on 31.03.20.
//  Copyright © 2020 Pierre Véron. All rights reserved.
//

import SwiftUI
import AVFoundation

// MARK: CameraView
public struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var events: UserEvents
    //To enable call to updateUIView() on change of UserEvents() bc there is a bug
    class RandomClass { }
    let x = RandomClass()
    
    private var applicationName: String
    private var preferredStartingCameraType: AVCaptureDevice.DeviceType
    private var preferredStartingCameraPosition: AVCaptureDevice.Position
    
    private var focusImage: String?
    
    private var pinchToZoom: Bool
    private var tapToFocus: Bool
    private var doubleTapCameraSwitch: Bool

    private var disableAudioRecording: Bool
    
    public init(events: UserEvents, applicationName: String, preferredStartingCameraType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera, preferredStartingCameraPosition: AVCaptureDevice.Position = .back, focusImage: String? = nil, pinchToZoom: Bool = true, tapToFocus: Bool = true, doubleTapCameraSwitch: Bool = true, disableAudioRecording: Bool = false) {
        self.events = events
        
        self.applicationName = applicationName
        
        self.focusImage = focusImage
        self.preferredStartingCameraType = preferredStartingCameraType
        self.preferredStartingCameraPosition = preferredStartingCameraPosition
        
        self.pinchToZoom = pinchToZoom
        self.tapToFocus = tapToFocus
        self.doubleTapCameraSwitch = doubleTapCameraSwitch

        self.disableAudioRecording = disableAudioRecording
    }
    
    public func makeUIViewController(context: Context) -> CameraViewController {
        let cameraViewController = CameraViewController()
        cameraViewController.audioEnabled = !self.disableAudioRecording
        cameraViewController.delegate = context.coordinator
        
        cameraViewController.applicationName = applicationName
        cameraViewController.preferredStartingCameraType = preferredStartingCameraType
        cameraViewController.preferredStartingCameraPosition = preferredStartingCameraPosition
        
        cameraViewController.focusImage = focusImage
        
        cameraViewController.pinchToZoom = pinchToZoom
        cameraViewController.tapToFocus = tapToFocus
        cameraViewController.doubleTapCameraSwitch = doubleTapCameraSwitch
        
        return cameraViewController
    }
    
    public func updateUIViewController(_ cameraViewController: CameraViewController, context: Context) {
        if events.didAskToCapturePhoto {
            cameraViewController.takePhoto()
        }
        
        if events.didAskToRotateCamera {
            cameraViewController.rotateCamera()
        }
        
        if events.didAskToChangeFlashMode {
            cameraViewController.changeFlashMode()
        }
        
        if events.didAskToRecordVideo || events.didAskToStopRecording {
            cameraViewController.toggleMovieRecording()
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: Coordinator
    public class Coordinator: NSObject, CameraViewControllerDelegate {
        
        var parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        public func cameraSessionStarted() {
                print("Camera session started")
            }
            
        public func noCameraDetected() {
                print("No camera detected")
            }
            
        public func didRotateCamera() {
                parent.events.didAskToRotateCamera = false
            }
            
        public func didCapturePhoto() {
                parent.events.didAskToCapturePhoto = false
            }
        
        public func didCaptureFrame(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            let image = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            parent.events.frameImage = image
            }
        
        public func didChangeFlashMode() {
                parent.events.didAskToChangeFlashMode = false
            }
            
        public func didFinishProcessingPhoto(_ image: UIImage) {
                //Not yet implemented
            }
            
        public func didFinishSavingWithError(_ image: UIImage, error: NSError?, contextInfo: UnsafeRawPointer) {
                //Not yet implemented
            }
            
        public func didChangeZoomLevel(_ zoom: CGFloat) {
                print("New zoom value: \(zoom)")
            }
            
        public func didFocusOnPoint(_ point: CGPoint) {
                print("Focus on point \(point) made")
            }
            
        public func didStartVideoRecording() {
                print("Video recording started")
            }
            
        public func didFinishVideoRecording() {
                parent.events.didAskToRecordVideo = false
                parent.events.didAskToStopRecording = false
                print("Video recording finished")
            }
            
        public func didSavePhoto() {
                print("Save photo to library")
            }
            
        public func didChangeMaximumVideoDuration(_ duration: Double) {
        //        parent.events.maximumVideoDuration = duration
                print("Change maximumVideoDuration to \(duration)")
            }
        
        private func imageFromSampleBuffer(sampleBuffer : CMSampleBuffer) -> UIImage{
            
           // Get a CMSampleBuffer's Core Video image buffer for the media data
           let  imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
           // Lock the base address of the pixel buffer
           CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);


           // Get the number of bytes per row for the pixel buffer
           let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer!);

           // Get the number of bytes per row for the pixel buffer
           let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!);
           // Get the pixel buffer width and height
           let width = CVPixelBufferGetWidth(imageBuffer!);
           let height = CVPixelBufferGetHeight(imageBuffer!);

           // Create a device-dependent RGB color space
           let colorSpace = CGColorSpaceCreateDeviceRGB();

           // Create a bitmap graphics context with the sample buffer data
           var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
           bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
           //let bitmapInfo: UInt32 = CGBitmapInfo.alphaInfoMask.rawValue
           let context = CGContext.init(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
           // Create a Quartz image from the pixel data in the bitmap graphics context
           let quartzImage = context?.makeImage();
           // Unlock the pixel buffer
           CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);

           // Create an image object from the Quartz image
           let image = UIImage.init(cgImage: quartzImage!);

           return (image);
         }
    }
}





