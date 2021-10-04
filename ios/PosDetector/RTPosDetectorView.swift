//
//  RTPosDetectorView.swift
//  BridgingDemo
//

import UIKit
import AVFoundation
import CoreVideo
import MLKit

//MARK: - Enum PosDetectorType
private enum PosDetectorType: String {
    case pose = "Pose Detection"
    case poseAccurate = "Pose Detection, accurate"
}

//MARK: - Enum Constant
private enum Constant {
    static let videoDataOutputQueueLabel = "com.google.mlkit.visiondetector.VideoDataOutputQueue"
    static let sessionQueueLabel = "com.google.mlkit.visiondetector.SessionQueue"
    static let smallDotRadius: CGFloat = 4.0
    static let lineWidth: CGFloat = 2.0
}

//MARK: - Class RTPosDetectorView
class RTPosDetectorView: UIView {
    private var currentDetector: PosDetectorType = .pose
    private var isUsingFrontCamera = true
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var lastFrame: CMSampleBuffer?
    /// Initialized when one of the pose detector rows are chosen. Reset to `nil` when neither are.
    private var poseDetector: PoseDetector? = nil
    /// The detector mode with which detection was most recently run. Only used on the video output
    /// queue. Useful for inferring when to reset detector instances which use a conventional
    /// lifecyle paradigm.
    private var lastDetector: PosDetectorType?
    private lazy var captureSession = AVCaptureSession()
    private lazy var sessionQueue = DispatchQueue(label: Constant.sessionQueueLabel)
    private lazy var previewOverlayView: UIImageView = {
        let previewOverlayView = UIImageView(frame: .zero)
        previewOverlayView.contentMode = UIView.ContentMode.scaleAspectFill
        previewOverlayView.translatesAutoresizingMaskIntoConstraints = false
        return previewOverlayView
    }()
    private lazy var annotationOverlayView: UIView = {
        let annotationOverlayView = UIView(frame: .zero)
        annotationOverlayView.translatesAutoresizingMaskIntoConstraints = false
        return annotationOverlayView
    }()
    
    /// It is used to indicate real time detection enable or not.
    @objc var isEnableDetaction: Bool = false {
        didSet {
            if isEnableDetaction {
                previewOverlayView.isHidden = false
                annotationOverlayView.isHidden = false
                startSession()
            }else{
                previewOverlayView.isHidden = true
                annotationOverlayView.isHidden = true
                stopSession()
            }
        }
    }
    
    @objc var onPoseDetect: RCTBubblingEventBlock?

    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareUIs()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareUIs()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = frame
    }
    
    deinit {
        print("Deallocated: \(classForCoder)")
    }
}

//MARK: UIRelated
extension RTPosDetectorView {
    
    private func prepareUIs() {
        preparePreviewLayerUIs()
        setUpPreviewOverlayView()
        setUpAnnotationOverlayView()
        setUpCaptureSessionOutput()
        setUpCaptureSessionInput()
    }
    
    private func preparePreviewLayerUIs() {
        clipsToBounds = true
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    }

    private func setUpPreviewOverlayView() {
        addSubview(previewOverlayView)
        NSLayoutConstraint.activate([
            previewOverlayView.centerXAnchor.constraint(equalTo: centerXAnchor),
            previewOverlayView.centerYAnchor.constraint(equalTo: centerYAnchor),
            previewOverlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewOverlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    
    private func setUpAnnotationOverlayView() {
        addSubview(annotationOverlayView)
        NSLayoutConstraint.activate([
            annotationOverlayView.topAnchor.constraint(equalTo: topAnchor),
            annotationOverlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            annotationOverlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            annotationOverlayView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func removeDetectionAnnotations() {
        for annotationView in annotationOverlayView.subviews {
            annotationView.removeFromSuperview()
        }
    }
    
    private func updatePreviewOverlayViewWithLastFrame() {
        guard let lastFrame = lastFrame,
              let imageBuffer = CMSampleBufferGetImageBuffer(lastFrame)
        else {
            return
        }
        updatePreviewOverlayViewWithImageBuffer(imageBuffer)
    }
    
    private func updatePreviewOverlayViewWithImageBuffer(_ imageBuffer: CVImageBuffer?) {
        guard let imageBuffer = imageBuffer else {
            return
        }
        let orientation: UIImage.Orientation = isUsingFrontCamera ? .leftMirrored : .right
        let image = UIUtilities.createUIImage(from: imageBuffer, orientation: orientation)
        previewOverlayView.image = image
    }
}

//MARK: AVCapture
extension RTPosDetectorView: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private func startSession() {
        weak var weakSelf = self
        sessionQueue.async {
            guard let strongSelf = weakSelf else {
                print("Self is nil!")
                return
            }
            strongSelf.captureSession.startRunning()
        }
    }
    
    private func stopSession() {
        sessionQueue.async {
            self.captureSession.stopRunning()
        }
    }
    
    private func setUpCaptureSessionOutput() {
        sessionQueue.async {
            self.captureSession.beginConfiguration()
            // When performing latency tests to determine ideal capture settings,
            // run the app in 'release' mode to get accurate performance metrics
            self.captureSession.sessionPreset = AVCaptureSession.Preset.medium
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
            output.alwaysDiscardsLateVideoFrames = true
            let outputQueue = DispatchQueue(label: Constant.videoDataOutputQueueLabel)
            output.setSampleBufferDelegate(self, queue: outputQueue)
            guard self.captureSession.canAddOutput(output) else {
                print("Failed to add capture session output.")
                return
            }
            self.captureSession.addOutput(output)
            self.captureSession.commitConfiguration()
        }
    }
    
    private func setUpCaptureSessionInput() {
        weak var weakSelf = self
        sessionQueue.async {
            guard let strongSelf = weakSelf else {
                print("Self is nil!")
                return
            }
            let cameraPosition: AVCaptureDevice.Position = strongSelf.isUsingFrontCamera ? .front : .back
            guard let device = strongSelf.captureDevice(cameraPosition) else {
                print("Failed to get capture device for camera position: \(cameraPosition)")
                return
            }
            do {
                strongSelf.captureSession.beginConfiguration()
                let currentInputs = strongSelf.captureSession.inputs
                for input in currentInputs {
                    strongSelf.captureSession.removeInput(input)
                }
                
                let input = try AVCaptureDeviceInput(device: device)
                guard strongSelf.captureSession.canAddInput(input) else {
                    print("Failed to add capture session input.")
                    return
                }
                strongSelf.captureSession.addInput(input)
                strongSelf.captureSession.commitConfiguration()
            } catch {
                print("Failed to create capture device input: \(error.localizedDescription)")
            }
        }
    }
    
    private func captureDevice(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        return discoverySession.devices.first { $0.position == position }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get image buffer from sample buffer.")
            return
        }
        // Evaluate `self.currentDetector` once to ensure consistency throughout this method since it
        // can be concurrently modified from the main thread.
        let activeDetector = currentDetector
        resetManagedLifecycleDetectors(activeDetector)
        
        lastFrame = sampleBuffer
        let visionImage = VisionImage(buffer: sampleBuffer)
        let orientation = UIUtilities.imageOrientation(
            fromDevicePosition: isUsingFrontCamera ? .front : .back
        )
        
        visionImage.orientation = orientation
        let imageWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))
        switch activeDetector {
            case .pose, .poseAccurate:
                detectPose(visionImage, width: imageWidth, height: imageHeight)
        }
    }

}

//MARK: PosDetector
extension RTPosDetectorView {
    
    private func normalizedPoint(_ point: VisionPoint, width: CGFloat, height: CGFloat) -> CGPoint {
        let cgPoint = CGPoint(x: point.x, y: point.y)
        var normalizedPoint = CGPoint(x: cgPoint.x / width, y: cgPoint.y / height)
        normalizedPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
        return normalizedPoint
    }
    
    private func detectPose(_ image: VisionImage, width: CGFloat, height: CGFloat) {
        if let poseDetector = poseDetector, let onPoseDetect = onPoseDetect {
            var params: [AnyHashable : Any] = [AnyHashable : Any]()
            var poses: [Pose] = [Pose]()
            do {
                poses = try poseDetector.results(in: image)
            } catch let error {
                params = ["poses" : poses, "error" : "Failed to detect poses with error: \(error.localizedDescription)."]
                onPoseDetect(params)
                print("Failed to detect poses with error: \(error.localizedDescription).")
                return
            }
            weak var weakSelf = self
            DispatchQueue.main.sync {
                guard let strongSelf = weakSelf else {
                    print("Self is nil!")
                    return
                }
                strongSelf.updatePreviewOverlayViewWithLastFrame()
                strongSelf.removeDetectionAnnotations()
            }
            guard !poses.isEmpty else {
                params = ["poses" : poses, "error" : "Pose detector returned no results."]
                onPoseDetect(params)
                print("Pose detector returned no results.")
                return
            }
            DispatchQueue.main.sync {
                guard let strongSelf = weakSelf else {
                    print("Self is nil!")
                    return
                }

                // Pose detected. Currently, only single person detection is supported.
                poses.forEach { pose in
                    let poseOverlayView = UIUtilities.createPoseOverlayView(
                        forPose: pose,
                        inViewWithBounds: strongSelf.annotationOverlayView.bounds,
                        lineWidth: Constant.lineWidth,
                        dotRadius: Constant.smallDotRadius,
                        positionTransformationClosure: { (position) -> CGPoint in
                            return strongSelf.normalizedPoint(position, width: width, height: height)
                        }
                    )
                    strongSelf.annotationOverlayView.addSubview(poseOverlayView)
                }
                
                print("Poses: - \(poses.count)")
                guard let firstPose = poses.first else{return}
                for (index, landmark) in firstPose.landmarks.enumerated() {
                    print("Index: \(index)")
                    let position = landmark.position
                    params[landmark.type.rawValue] = ["position" : ["x" : position.x, "y" : position.y, "z" : position.z]]
                }
                onPoseDetect(params)
            }
        }
    }
    
    /// Resets any detector instances which use a conventional lifecycle paradigm. This method is
    /// expected to be invoked on the AVCaptureOutput queue - the same queue on which detection is
    /// run.
    private func resetManagedLifecycleDetectors(_ activeDetector: PosDetectorType) {
        if activeDetector == self.lastDetector {
            // Same row as before, no need to reset any detectors.
            return
        }
        // Clear the old detector, if applicable.
        switch self.lastDetector {
            case .pose, .poseAccurate:
                self.poseDetector = nil
                break
            default:
                break
        }
        // Initialize the new detector, if applicable.
        switch activeDetector {
            case .pose, .poseAccurate:
                // The `options.detectorMode` defaults to `.stream`
                let options = activeDetector == .pose ? PoseDetectorOptions() : AccuratePoseDetectorOptions()
                self.poseDetector = PoseDetector.poseDetector(options: options)
                break
        }
        self.lastDetector = activeDetector
    }
}
