import SwiftUI
import AVFoundation
import UIKit

/// A view that provides a custom camera interface
struct CameraView: View {
    // MARK: - Properties
    
    var selectedChallenge: Challenge?
    var selectedAngle: Binding<PhotoAngle>
    var onPhotoTaken: (UIImage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraController = CameraController()
    
    @State private var showingCameraPermissionAlert = false
    @State private var showingCountdown = false
    @State private var countdown = 3
    @State private var timer: Timer?
    @State private var flashMode: AVCaptureDevice.FlashMode = .off
    @State private var isFrontCamera = false
    @State private var cameraInitialized = false
    @State private var showDebugInfo = false
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var capturedImage: UIImage?
    @State private var showingCapturedImage = false
    @State private var isFlashOn = false
    @State private var error: String?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if cameraInitialized {
                CameraPreviewView(camera: cameraController)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            isFlashOn.toggle()
                            cameraController.setFlashMode(isFlashOn ? .on : .off)
                        }) {
                            Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Display current angle being captured
                        Text(selectedAngle.wrappedValue.angleDescription)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                        
                        Spacer()
                        
                        Button(action: {
                            isFrontCamera.toggle()
                            cameraController.switchCamera()
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            capturePhoto()
                        }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 80, height: 80)
                                )
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // Additional action button
                        }) {
                            Image(systemName: "gear")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
            }
        }
        .onAppear {
            // Initialize camera with a short delay to ensure view is fully loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                setupCamera()
            }
        }
        .onDisappear {
            // Clean up when view disappears
            if cameraController.captureSession.isRunning {
                cameraController.captureSession.stopRunning()
            }
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: $inputImage)
        }
        .sheet(isPresented: $showingCapturedImage) {
            if let image = capturedImage {
                PhotoConfirmationView(image: image, isPresented: $showingCapturedImage) {
                    // When user confirms the photo, pass it to the onPhotoTaken handler
                    if let confirmedImage = capturedImage {
                        onPhotoTaken(confirmedImage)
                        dismiss()
                    }
                }
            }
        }
        .alert("Camera Access Required", isPresented: $showingCameraPermissionAlert) {
            Button("Cancel", role: .cancel) {
                dismiss()
            }
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Please allow camera access in Settings to take photos.")
        }
    }
    
    // MARK: - Methods
    
    private func setupCamera() {
        cameraController.checkAuthorization { granted in
            if granted {
                print("Camera permissions granted, setting up camera")
                cameraController.setupCaptureSession()
                DispatchQueue.main.async {
                    self.cameraInitialized = true
                }
            } else {
                print("Camera permissions denied")
            }
        }
    }
    
    private func capturePhoto() {
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Prevent multiple taps
        cameraInitialized = false
        
        cameraController.capturePhoto { image, error in
            DispatchQueue.main.async {
                if let image = image {
                    // If front camera, flip the image horizontally
                    if cameraController.isFrontCameraActive {
                        self.capturedImage = image.withHorizontallyFlippedOrientation()
                    } else {
                        self.capturedImage = image
                    }
                    print("Photo captured successfully and passed to handler")
                    self.showingCapturedImage = true
                } else if let error = error {
                    print("Error capturing photo: \(error.localizedDescription)")
                }
                // Re-enable camera
                self.cameraInitialized = true
            }
        }
    }
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        capturedImage = inputImage
        showingCapturedImage = true
    }
}

// MARK: - Camera Preview View

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var camera: CameraController
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        // Check if the preview layer is already initialized
        if camera.previewLayer == nil {
            // Initialize the capture session if needed
            if !camera.captureSession.isRunning {
                camera.captureSession.startRunning()
            }
            
            // Create a new preview layer
            let previewLayer = AVCaptureVideoPreviewLayer(session: camera.captureSession)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            
            // Set video orientation
            if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            
            // Store the preview layer in the camera controller
            camera.setupPreviewLayer(previewLayer)
            
            // Add the preview layer to the view
            view.layer.addSublayer(previewLayer)
        } else {
            // Use the existing preview layer
            camera.previewLayer.frame = view.bounds
            view.layer.addSublayer(camera.previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Make sure the camera session is running
        if !camera.captureSession.isRunning {
            camera.captureSession.startRunning()
            print("Camera session started running in updateUIView")
        }
    }
}

// MARK: - Camera Controller

/// Controller for managing the camera
class CameraController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isAuthorized = false
    @Published var setupComplete = false
    @Published var isConfiguring = false
    @Published var previewActive = false
    
    let captureSession = AVCaptureSession()
    private(set) var previewLayer: AVCaptureVideoPreviewLayer!
    
    private var frontCamera: AVCaptureDevice?
    private var backCamera: AVCaptureDevice?
    private var currentCamera: AVCaptureDevice?
    private var photoOutput: AVCapturePhotoOutput?
    private var photoCaptureCompletionBlock: ((UIImage?, Error?) -> Void)?
    private var currentFlashMode: AVCaptureDevice.FlashMode = .off
    private var sessionQueue = DispatchQueue(label: "com.ultimate.camera.session")
    var error: String?
    private var isSessionRunning = false
    
    // Add a flag to prevent duplicate captures
    private var isProcessingCapture = false
    
    override init() {
        super.init()
        print("CameraController: Initializing")
        
        // Initialize the preview layer with the capture session
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        
        // Add notification observers for session interruptions
        NotificationCenter.default.addObserver(self, 
                                              selector: #selector(sessionRuntimeError), 
                                              name: AVCaptureSession.runtimeErrorNotification, 
                                              object: captureSession)
        NotificationCenter.default.addObserver(self, 
                                              selector: #selector(sessionWasInterrupted), 
                                              name: AVCaptureSession.wasInterruptedNotification, 
                                              object: captureSession)
        NotificationCenter.default.addObserver(self, 
                                              selector: #selector(sessionInterruptionEnded), 
                                              name: AVCaptureSession.interruptionEndedNotification, 
                                              object: captureSession)
        
        // Add app lifecycle observers
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(appDidEnterBackground),
                                              name: UIApplication.didEnterBackgroundNotification,
                                              object: nil)
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(appWillEnterForeground),
                                              name: UIApplication.willEnterForegroundNotification,
                                              object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("CameraController: Deinitializing")
    }
    
    @objc func appDidEnterBackground() {
        print("CameraController: App entered background, stopping session")
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                self.isSessionRunning = false
            }
        }
    }
    
    @objc func appWillEnterForeground() {
        print("CameraController: App will enter foreground, restarting session")
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning && self.setupComplete {
                self.captureSession.startRunning()
                self.isSessionRunning = self.captureSession.isRunning
                
                DispatchQueue.main.async {
                    self.previewActive = self.isSessionRunning
                }
            }
        }
    }
    
    @objc func sessionRuntimeError(notification: Notification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        print("Capture session runtime error: \(error)")
        
        // Restart session if media services were reset
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                self.captureSession.startRunning()
                self.isSessionRunning = self.captureSession.isRunning
            }
        }
    }
    
    @objc func sessionWasInterrupted(notification: Notification) {
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
           let reasonIntegerValue = userInfoValue.integerValue,
           let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason: \(reason)")
        }
    }
    
    @objc func sessionInterruptionEnded(notification: Notification) {
        print("Capture session interruption ended")
        // Resume session if needed
        sessionQueue.async {
            self.captureSession.startRunning()
            self.isSessionRunning = self.captureSession.isRunning
        }
    }
    
    /// Checks camera authorization
    func checkAuthorization(completion: @escaping (Bool) -> Void) {
        print("Checking camera authorization")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("Camera access already authorized")
            DispatchQueue.main.async {
                self.isAuthorized = true
                completion(true)
            }
        case .notDetermined:
            print("Requesting camera access")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    print("Camera access \(granted ? "granted" : "denied")")
                    self?.isAuthorized = granted
                    completion(granted)
                }
            }
        default:
            print("Camera access not authorized")
            DispatchQueue.main.async {
                self.isAuthorized = false
                completion(false)
            }
        }
    }
    
    /// Sets up the capture session
    func setupCaptureSession() {
        guard !setupComplete else { 
            print("CameraController: Setup already complete, skipping")
            return 
        }
        
        // Check if running in simulator
        #if targetEnvironment(simulator)
        print("CameraController: Running in simulator, skipping camera setup")
        DispatchQueue.main.async {
            self.setupComplete = true
            self.isConfiguring = false
            self.previewActive = false
            self.error = "Camera not available in simulator"
        }
        return
        #endif
        
        print("CameraController: Setting up capture session")
        
        DispatchQueue.main.async {
            self.isConfiguring = true
            self.setupComplete = false
            self.previewActive = false
        }
        
        // Stop the session if it's running
        if captureSession.isRunning {
            captureSession.stopRunning()
            isSessionRunning = false
            print("CameraController: Stopped existing capture session")
        }
        
        captureSession.beginConfiguration()
        
        // Reset any existing configuration
        for input in captureSession.inputs {
            captureSession.removeInput(input)
            print("CameraController: Removed existing input")
        }
        
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
            print("CameraController: Removed existing output")
        }
        
        // Configure for high quality photo capture
        if captureSession.canSetSessionPreset(.photo) {
            captureSession.sessionPreset = .photo
            print("CameraController: Set session preset to photo")
        } else {
            print("CameraController: Unable to set session preset to photo")
        }
        
        // Setup back camera
        if let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            self.backCamera = backCamera
            self.currentCamera = backCamera
            print("CameraController: Found back camera")
            
            do {
                let input = try AVCaptureDeviceInput(device: backCamera)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                    print("CameraController: Added back camera input to session")
                } else {
                    print("CameraController: Could not add back camera input to session")
                }
            } catch {
                print("CameraController: Error setting up back camera: \(error)")
            }
        } else {
            print("CameraController: Back camera not available")
        }
        
        // Setup front camera
        if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            self.frontCamera = frontCamera
            print("CameraController: Found front camera")
        } else {
            print("CameraController: Front camera not available")
        }
        
        // Setup photo output
        let photoOutput = AVCapturePhotoOutput()
        print("CameraController: Created photo output")
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            self.photoOutput = photoOutput
            print("CameraController: Added photo output to session")
            
            // Configure photo output settings
            if #available(iOS 16.0, *) {
                // Only set maxPhotoDimensions if we have a valid camera input and active format
                if let connection = photoOutput.connection(with: .video),
                   let input = connection.inputPorts.first?.input as? AVCaptureDeviceInput,
                   input.device.activeFormat != nil {
                    photoOutput.maxPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024)
                    print("CameraController: Set max photo dimensions")
                } else {
                    print("CameraController: Skipped setting max photo dimensions - no valid camera input")
                }
            } else {
                photoOutput.isHighResolutionCaptureEnabled = true
                print("CameraController: Enabled high resolution capture")
            }
            
            // Set photo quality prioritization
            if #available(iOS 13.0, *) {
                photoOutput.maxPhotoQualityPrioritization = .balanced
                print("CameraController: Set maxPhotoQualityPrioritization to balanced")
            }
            
            // Configure video orientation
            if let connection = photoOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                    print("CameraController: Set video orientation to portrait")
                } else {
                    print("CameraController: Video orientation not supported")
                }
                
                // Set mirroring for front camera
                if self.currentCamera?.position == .front {
                    connection.isVideoMirrored = true
                    print("CameraController: Set video mirroring for front camera")
                }
            } else {
                print("CameraController: No video connection available")
            }
        } else {
            print("CameraController: Could not add photo output to session")
        }
        
        captureSession.commitConfiguration()
        print("CameraController: Committed session configuration")
        
        // Start session immediately on a background thread
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            print("CameraController: Starting capture session")
            self.captureSession.startRunning()
            self.isSessionRunning = self.captureSession.isRunning
            print("CameraController: Capture session running: \(self.isSessionRunning)")
            
            DispatchQueue.main.async {
                self.setupComplete = true
                self.isConfiguring = false
                self.previewActive = self.isSessionRunning
                print("CameraController: Setup complete, preview active: \(self.previewActive)")
            }
        }
    }
    
    /// Switches between front and back camera
    func switchCamera() {
        guard !isConfiguring else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isConfiguring = true
            }
            
            self.captureSession.beginConfiguration()
            
            // Remove existing input
            for input in self.captureSession.inputs {
                self.captureSession.removeInput(input)
            }
            
            // Get new camera
            let newCamera = self.currentCamera?.position == .back ? self.frontCamera : self.backCamera
            self.currentCamera = newCamera
            
            // Add new input
            if let newCamera = newCamera {
                do {
                    let input = try AVCaptureDeviceInput(device: newCamera)
                    if self.captureSession.canAddInput(input) {
                        self.captureSession.addInput(input)
                        
                        // Configure video orientation and mirroring
                        if let connection = self.photoOutput?.connection(with: .video) {
                            // Always set to portrait orientation
                            connection.videoOrientation = .portrait
                            
                            // Mirror for front camera
                            connection.isVideoMirrored = newCamera.position == .front
                            
                            print("CameraController: Set camera orientation to portrait, mirrored: \(newCamera.position == .front)")
                        }
                    }
                } catch {
                    print("Error switching camera: \(error)")
                }
            }
            
            self.captureSession.commitConfiguration()
            
            DispatchQueue.main.async {
                self.isConfiguring = false
            }
        }
    }
    
    /// Sets the flash mode
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        currentFlashMode = mode
        print("Set flash mode to \(mode)")
    }
    
    /// Captures a photo
    func capturePhoto(completion: @escaping (UIImage?, Error?) -> Void) {
        print("CameraController: capturePhoto called")
        
        // Prevent duplicate captures
        guard !isProcessingCapture else {
            print("CameraController: Already processing a capture, ignoring duplicate request")
            return
        }
        
        // Set the flag to indicate we're processing a capture
        isProcessingCapture = true
        
        // Check if running in simulator
        #if targetEnvironment(simulator)
        print("CameraController: Running in simulator, returning mock image")
        // Create a simple colored square as a mock image
        let size = CGSize(width: 1024, height: 1024)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        UIColor.systemBlue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let mockImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(mockImage, nil)
        }
        return
        #endif
        
        // Check if we're still configuring the camera
        guard !isConfiguring else {
            print("CameraController: Cannot capture photo while camera is configuring")
            completion(nil, NSError(domain: "CameraError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot capture photo while camera is configuring"]))
            return
        }
        
        // Ensure photoOutput is available
        guard let photoOutput = self.photoOutput else {
            print("CameraController: photoOutput is nil, cannot capture photo")
            completion(nil, NSError(domain: "CameraError", code: 0, userInfo: [NSLocalizedDescriptionKey: "photoOutput is nil, cannot capture photo"]))
            return
        }
        
        // Store the completion handler
        self.photoCaptureCompletionBlock = completion
        
        // Configure settings for the capture
        let settings = AVCapturePhotoSettings()
        
        // Set the flash mode if using back camera
        if let deviceInput = captureSession.inputs.first as? AVCaptureDeviceInput, deviceInput.device.position == .back {
            if deviceInput.device.isFlashAvailable {
                settings.flashMode = currentFlashMode
                print("CameraController: Set flash mode to \(currentFlashMode.rawValue)")
            }
        }
        
        // Set the photo quality prioritization
        if #available(iOS 13.0, *) {
            settings.photoQualityPrioritization = .balanced
        }
        
        // Ensure the video orientation is set correctly
        if let connection = photoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
                print("CameraController: Set video orientation to portrait for capture")
            }
        }
        
        print("CameraController: Capturing photo with settings: \(settings)")
        
        // Capture the photo
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // Reset the processing flag when we're done, regardless of success or failure
        defer { isProcessingCapture = false }
        
        if let error = error {
            print("CameraController: Error capturing photo: \(error.localizedDescription)")
            self.photoCaptureCompletionBlock?(nil, error)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("CameraController: Error: could not get image data from photo")
            self.photoCaptureCompletionBlock?(nil, NSError(domain: "CameraError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not get image data"]))
            return
        }
        
        guard let image = UIImage(data: imageData) else {
            print("CameraController: Error: could not create image from data")
            self.photoCaptureCompletionBlock?(nil, NSError(domain: "CameraError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not create image from data"]))
            return
        }
        
        // Fix orientation to ensure the image is correctly oriented
        let fixedImage = image.fixOrientation()
        print("CameraController: Photo captured successfully with correct orientation")
        
        self.photoCaptureCompletionBlock?(fixedImage, nil)
    }
    
    // Add a computed property to check if front camera is active
    var isFrontCameraActive: Bool {
        guard let currentCamera = currentCamera else { return false }
        return currentCamera.position == .front
    }
    
    // Add a method to set up the preview layer
    func setupPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = layer
    }
}

// MARK: - UIImage Extensions

extension UIImage {
    /// Fixes the orientation of the image to be up
    func fixOrientation() -> UIImage {
        // If the orientation is already up, return the image as is
        if self.imageOrientation == .up {
            return self
        }
        
        // Create a new image with the correct orientation
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
    
    /// Returns a horizontally flipped version of the image
    func withHorizontallyFlippedOrientation() -> UIImage {
        if let cgImage = self.cgImage {
            return UIImage(cgImage: cgImage, scale: self.scale, orientation: .upMirrored)
        }
        return self
    }
}

// MARK: - Shape Helper

struct AnyShape: Shape {
    var path: @Sendable (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        path = { @Sendable rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        path(rect)
    }
}

// MARK: - Haptic Feedback

enum HapticFeedback {
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Preview

#Preview {
    CameraView(
        selectedChallenge: nil,
        selectedAngle: .constant(.front),
        onPhotoTaken: { _ in }
    )
}

// Add ImagePicker struct
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// Replace CapturedImageView with PhotoConfirmationView
struct PhotoConfirmationView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    var onConfirm: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
                
                HStack(spacing: 40) {
                    Button(action: {
                        isPresented = false
                    }) {
                        VStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                            Text("Retake")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                        }
                        .frame(width: 80, height: 80)
                        .background(Color.red.opacity(0.8))
                        .clipShape(Circle())
                    }
                    
                    Button(action: {
                        onConfirm()
                    }) {
                        VStack {
                            Image(systemName: "checkmark")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                            Text("Use Photo")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                        }
                        .frame(width: 80, height: 80)
                        .background(Color.green.opacity(0.8))
                        .clipShape(Circle())
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// Keep the existing CapturedImageView for compatibility
struct CapturedImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Save to photo library
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    }) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
            }
        }
    }
}

// Add PhotoAngle extension for description
extension PhotoAngle {
    var angleDescription: String {
        switch self {
        case .front:
            return "Front View"
        case .leftSide:
            return "Left Side View"
        case .rightSide:
            return "Right Side View"
        case .back:
            return "Back View"
        }
    }
} 