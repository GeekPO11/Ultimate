import SwiftUI
import AVFoundation
import UIKit
import _Concurrency

/// High-performance camera view optimized for iOS 2025 best practices
struct OptimizedCameraView: View {
    // MARK: - Properties
    
    var selectedChallenge: Challenge?
    var selectedAngle: Binding<PhotoAngle>
    var onPhotoTaken: (UIImage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraController = OptimizedCameraController()
    
    @State private var showingPermissionAlert = false
    @State private var flashMode: AVCaptureDevice.FlashMode = .off
    @State private var isFrontCamera = false
    @State private var isReady = false
    @State private var isCapturing = false
    @State private var capturedPhoto: UIImage?
    @State private var showingConfirmation = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isReady {
                // Camera preview
                OptimizedCameraPreviewView(controller: cameraController)
                    .ignoresSafeArea()
                
                // UI Overlay
                VStack {
                    // Top controls with close button
                    HStack {
                        // Close button
                        Button(action: { dismiss() }) {
                            ZStack {
                                Circle()
                                    .fill(.black.opacity(0.3))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        // Flash control
                        Button(action: toggleFlashMode) {
                            ZStack {
                                Circle()
                                    .fill(.black.opacity(0.3))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: flashMode == .off ? "bolt.slash" : "bolt")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Camera switch
                        Button(action: toggleCamera) {
                            ZStack {
                                Circle()
                                    .fill(.black.opacity(0.3))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "arrow.triangle.2.circlepath.camera")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Current angle indicator
                    if let challenge = selectedChallenge {
                        VStack(spacing: 8) {
                            Text(challenge.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.black.opacity(0.5))
                                .cornerRadius(20)
                            
                            Text(selectedAngle.wrappedValue.description)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(.black.opacity(0.6))
                                .cornerRadius(25)
                        }
                    } else {
                        Text(selectedAngle.wrappedValue.description)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(.black.opacity(0.6))
                            .cornerRadius(25)
                    }
                    
                    Spacer()
                    
                    // Bottom controls
                    HStack {
                        Spacer()
                        
                        // Capture button
                        Button(action: capturePhoto) {
                            ZStack {
                                Circle()
                                    .stroke(.white, lineWidth: 4)
                                    .frame(width: 80, height: 80)
                                
                                if isCapturing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.2)
                                } else {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 60, height: 60)
                                }
                            }
                        }
                        .disabled(!cameraController.isReadyToCapture || isCapturing)
                        .opacity(cameraController.isReadyToCapture && !isCapturing && !showingConfirmation ? 1.0 : 0.5)
                        .scaleEffect(isCapturing ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isCapturing)
                        
                        Spacer()
                    }
                    .padding(.bottom, 40)
                }
                .opacity(showingConfirmation ? 0 : 1)
                
                // Photo confirmation overlay
                if showingConfirmation, let photo = capturedPhoto {
                    photoConfirmationOverlay(photo: photo)
                }
            } else {
                // Loading state
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                    
                    Text("Initializing Camera...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }

        }
        .onAppear {
            setupCamera()
        }
        .onDisappear {
            // CRITICAL: Cleanup camera resources when view disappears
            cameraController.stopSession()
            cameraController.cleanupResources()
        }
        .alert("Camera Access Required", isPresented: $showingPermissionAlert) {
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
    
    // MARK: - View Components
    
    private func photoConfirmationOverlay(photo: UIImage) -> some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Photo preview
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 400)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                
                // Action buttons
                HStack(spacing: 40) {
                    // Retake button
                    Button(action: retakePhoto) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.2))
                                    .frame(width: 70, height: 70)
                                
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Retake")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Accept button
                    Button(action: acceptPhoto) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 70, height: 70)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Use Photo")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: showingConfirmation)
    }
    
    private var topControlsView: some View {
        HStack {
            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.6))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Current angle indicator
            Text(selectedAngle.wrappedValue.description)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.black.opacity(0.6))
                .clipShape(Capsule())
            
            Spacer()
            
            // Flash toggle
            Button(action: toggleFlash) {
                Image(systemName: flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.6))
                    .clipShape(Circle())
            }

        }
        .padding()
    }
    
    private var bottomControlsView: some View {
        HStack {
            // Camera flip button
            Button(action: flipCamera) {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(.black.opacity(0.6))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Capture button
            Button(action: capturePhoto) {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    if isCapturing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    } else {
                        Circle()
                            .fill(.white)
                            .frame(width: 60, height: 60)
                    }
                }
            }
            .disabled(!cameraController.isReadyToCapture || isCapturing)
            .opacity(cameraController.isReadyToCapture && !isCapturing ? 1.0 : 0.5)
            .scaleEffect(isCapturing ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isCapturing)
            
            Spacer()
            
            // Empty space for symmetry
            Color.clear
                .frame(width: 50, height: 50)
        }
        .padding(.horizontal)
        .padding(.bottom, 50)
    }
    
    // MARK: - Methods
    
    private func setupCamera() {
        _Concurrency.Task {
            let hasPermission = await cameraController.requestCameraPermission()
            
            if hasPermission {
                await cameraController.configureSession()
                await MainActor.run {
                    isReady = true
                }
            } else {
                await MainActor.run {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func capturePhoto() {
        guard !isCapturing else { return }
        isCapturing = true
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        cameraController.capturePhoto { result in
            DispatchQueue.main.async {
                self.isCapturing = false
                
                switch result {
                case .success(let image):
                    // Success haptic feedback
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                    
                    // Show confirmation instead of immediately using photo
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.capturedPhoto = image
                        self.showingConfirmation = true
                    }
                    
                case .failure(let error):
                    // Error haptic feedback
                    let errorFeedback = UINotificationFeedbackGenerator()
                    errorFeedback.notificationOccurred(.error)
                    
                    print("Photo capture failed: \(error)")
                }
            }
        }
    }
    
    private func retakePhoto() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingConfirmation = false
            capturedPhoto = nil
        }
    }
    
    private func acceptPhoto() {
        guard let photo = capturedPhoto else { return }
        
        // Use the photo
        onPhotoTaken(photo)
        
        // Reset confirmation state
        withAnimation(.easeInOut(duration: 0.3)) {
            showingConfirmation = false
            capturedPhoto = nil
        }
    }
    
    private func toggleFlash() {
        flashMode = flashMode == .on ? .off : .on
        cameraController.setFlashMode(flashMode)
    }
    
    private func flipCamera() {
        isFrontCamera.toggle()
        cameraController.switchCamera()
    }
    
    private func toggleFlashMode() {
        flashMode = flashMode == .on ? .off : .on
        cameraController.setFlashMode(flashMode)
    }
    
    private func toggleCamera() {
        isFrontCamera.toggle()
        cameraController.switchCamera()
    }
}

// MARK: - Optimized Camera Controller

class OptimizedCameraController: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    @Published var isReadyToCapture = false
    @Published var isSessionRunning = false
    
    // MARK: - Private Properties
    
    private let captureSession = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // Background queue optimized for camera operations
    private let sessionQueue = DispatchQueue(
        label: "camera.session.queue",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    
    // Current camera position
    private var currentPosition: AVCaptureDevice.Position = .back
    
    // Photo capture completion handlers - with cleanup tracking
    private var photoCaptureCompletions: [Int64: (Result<UIImage, Error>) -> Void] = [:]
    private let completionCleanupQueue = DispatchQueue(label: "completion.cleanup", qos: .utility)
    
    override init() {
        super.init()
        
        // Add memory pressure monitoring
        setupMemoryPressureMonitoring()
        
        // Cleanup timer to prevent completion handler accumulation
        setupCleanupTimer()
    }
    
    deinit {
        // CRITICAL: Properly cleanup all resources
        cleanupResources()
    }
    
    // MARK: - Memory Management
    
    private func setupMemoryPressureMonitoring() {
        // Monitor memory pressure and cleanup when needed
        let source = DispatchSource.makeMemoryPressureSource(eventMask: .all, queue: sessionQueue)
        source.setEventHandler { [weak self] in
            self?.handleMemoryPressure()
        }
        source.resume()
    }
    
    private func setupCleanupTimer() {
        // Cleanup old completion handlers every 30 seconds
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.cleanupOldCompletionHandlers()
        }
    }
    
    private func handleMemoryPressure() {
        // Force cleanup on memory pressure
        cleanupOldCompletionHandlers()
        
        // Reduce image processing quality temporarily
        if let output = photoOutput {
            output.maxPhotoQualityPrioritization = .speed
        }
    }
    
    private func cleanupOldCompletionHandlers() {
        completionCleanupQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Remove completion handlers older than 5 minutes (should never happen in normal use)
            let cutoffTime = Date().timeIntervalSince1970 - 300
            let keysToRemove = self.photoCaptureCompletions.keys.filter { key in
                TimeInterval(key) < cutoffTime
            }
            
            for key in keysToRemove {
                self.photoCaptureCompletions.removeValue(forKey: key)
            }
            
            print("Cleaned up \(keysToRemove.count) old completion handlers")
        }
    }
    
    func cleanupResources() {
        // Stop session immediately
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        
        // Clear all completion handlers
        photoCaptureCompletions.removeAll()
        
        // Remove all inputs and outputs
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        
        // Clear references
        videoDeviceInput = nil
        photoOutput = nil
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        
        // Update state
        DispatchQueue.main.async { [weak self] in
            self?.isSessionRunning = false
            self?.isReadyToCapture = false
        }
    }
    
    // MARK: - Permission Handling
    
    func requestCameraPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
    
    // MARK: - Session Configuration
    
    func configureSession() async {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                _Concurrency.Task { @MainActor in
                    await self.configureSessionOnSessionQueue()
                    continuation.resume()
                }
            }
        }
    }
    
    @MainActor
    private func configureSessionOnSessionQueue() async {
        guard !isSessionRunning else { return }
        
        captureSession.beginConfiguration()
        
        // Set session preset for optimal photo capture
        if captureSession.canSetSessionPreset(.photo) {
            captureSession.sessionPreset = .photo
        }
        
        // Configure video input
        await setupVideoInput()
        
        // Configure photo output
        await setupPhotoOutput()
        
        captureSession.commitConfiguration()
        
        // Start session
        captureSession.startRunning()
        
        self.isSessionRunning = self.captureSession.isRunning
        self.isReadyToCapture = self.captureSession.isRunning
    }
    
    @MainActor
    private func setupVideoInput() async {
        // Remove existing video input
        if let existingInput = videoDeviceInput {
            captureSession.removeInput(existingInput)
        }
        
        // Get the appropriate camera device
        guard let videoDevice = getCamera(for: currentPosition) else {
            print("Failed to get camera device")
            return
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                // Configure device for optimal performance
                try configureDevice(videoDevice)
            }
        } catch {
            print("Failed to create video device input: \(error)")
        }
    }
    
    @MainActor
    private func setupPhotoOutput() async {
        // Remove existing photo output
        if let existingOutput = photoOutput {
            captureSession.removeOutput(existingOutput)
        }
        
        let photoOutput = AVCapturePhotoOutput()
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            self.photoOutput = photoOutput
            
            // Configure photo output for optimal performance
            configurePhotoOutput(photoOutput)
        }
    }
    
    private func configureDevice(_ device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        
        // Enable optimal focus and exposure modes
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }
        
        // Note: activeVideoStabilizationMode is not available on AVCaptureDevice
        // Video stabilization is configured on the connection level during photo capture
    }
    
    private func configurePhotoOutput(_ output: AVCapturePhotoOutput) {
        // Use maxPhotoDimensions instead of deprecated isHighResolutionCaptureEnabled
        if #available(iOS 16.0, *) {
            // Set maximum photo dimensions for high resolution
            output.maxPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024)
        } else {
            // Fall back to the older API for iOS 15 and below
            output.isHighResolutionCaptureEnabled = true
        }
        
        // Set optimal quality prioritization for balanced performance
        if #available(iOS 13.0, *) {
            output.maxPhotoQualityPrioritization = .balanced
        }
        
        // Enable responsive capture APIs if available (iOS 17+)
        if #available(iOS 17.0, *) {
            if output.isResponsiveCaptureSupported {
                output.isResponsiveCaptureEnabled = true
            }
            
            // Enable zero shutter lag if supported
            if output.isZeroShutterLagSupported {
                output.isZeroShutterLagEnabled = true
            }
        }
    }
    
    private func getCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        // Use the discovery session for better device management
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTripleCamera],
            mediaType: .video,
            position: position
        )
        
        return discoverySession.devices.first
    }
    
    // MARK: - Camera Controls
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            _Concurrency.Task { @MainActor in
                self.currentPosition = self.currentPosition == .back ? .front : .back
                await self.setupVideoInput()
            }
        }
    }
    
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            _Concurrency.Task { @MainActor in
                guard let device = self.videoDeviceInput?.device,
                      device.hasFlash else { return }
                
                do {
                    try device.lockForConfiguration()
                    // Flash mode is set per photo capture, not on device
                    device.unlockForConfiguration()
                } catch {
                    print("Failed to configure flash: \(error)")
                }
            }
        }
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto(completion: @escaping (Result<UIImage, Error>) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self else {
                completion(.failure(CameraError.notConfigured))
                return
            }
            
            _Concurrency.Task { @MainActor in
                guard let photoOutput = self.photoOutput else {
                    completion(.failure(CameraError.notConfigured))
                    return
                }
                
                // Create photo settings
                var photoSettings = AVCapturePhotoSettings()
                
                // Configure format if HEVC is available
                if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                    photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                }
                
                // Configure flash
                if let device = self.videoDeviceInput?.device, device.hasFlash {
                    photoSettings.flashMode = .auto // Let iOS decide
                }
                
                // Fix photo orientation - minimal approach
                if let photoConnection = photoOutput.connection(with: .video), 
                   photoConnection.isVideoOrientationSupported {
                    photoConnection.videoOrientation = .portrait
                }
                
                // Store completion handler
                let captureID = photoSettings.uniqueID
                self.photoCaptureCompletions[captureID] = completion
                
                // Capture photo
                photoOutput.capturePhoto(with: photoSettings, delegate: self)
            }
        }
    }
    
    // MARK: - Session Lifecycle
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            _Concurrency.Task { @MainActor in
                if self.captureSession.isRunning {
                    self.captureSession.stopRunning()
                    
                    self.isSessionRunning = false
                    self.isReadyToCapture = false
                }
            }
        }
    }
    
    // MARK: - Preview Layer Management
    
    func createPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        
        // Fix orientation - minimal approach
        if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        
        self.previewLayer = previewLayer
        return previewLayer
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension OptimizedCameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let captureID = photo.resolvedSettings.uniqueID
        
        // Process on background queue to avoid main thread blocking
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Get completion handler
            guard let completion = self.photoCaptureCompletions[captureID] else { return }
            
            // Clean up completion handler immediately
            self.photoCaptureCompletions.removeValue(forKey: captureID)
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // Memory-efficient image processing
            autoreleasepool {
                guard let imageData = photo.fileDataRepresentation() else {
                    DispatchQueue.main.async {
                        completion(.failure(CameraError.imageProcessingFailed))
                    }
                    return
                }
                
                // Create image with reduced memory pressure
                guard let image = self.createOptimizedImage(from: imageData) else {
                    DispatchQueue.main.async {
                        completion(.failure(CameraError.imageProcessingFailed))
                    }
                    return
                }
                
                // Process orientation
                let processedImage = self.processImageOrientation(image, isFrontCamera: self.currentPosition == .front)
                
                // Return on main queue
                DispatchQueue.main.async {
                    completion(.success(processedImage))
                }
            }
        }
    }
    
    private func createOptimizedImage(from data: Data) -> UIImage? {
        // Create image with memory optimization
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        
        // Get image properties without loading the full image
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return UIImage(data: data)
        }
        
        // Check if we need to scale down for memory
        let pixelWidth = properties[kCGImagePropertyPixelWidth] as? Int ?? 0
        let pixelHeight = properties[kCGImagePropertyPixelHeight] as? Int ?? 0
        
        // If image is very large, create a scaled down version
        let maxDimension = 2048
        if pixelWidth > maxDimension || pixelHeight > maxDimension {
            let scale = min(Double(maxDimension) / Double(pixelWidth), Double(maxDimension) / Double(pixelHeight))
            
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: Int(Double(max(pixelWidth, pixelHeight)) * scale)
            ]
            
            guard let scaledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                return UIImage(data: data)
            }
            
            return UIImage(cgImage: scaledImage)
        }
        
        return UIImage(data: data)
    }
    
    private func processImageOrientation(_ image: UIImage, isFrontCamera: Bool) -> UIImage {
        // Memory-efficient orientation processing
        autoreleasepool {
            if isFrontCamera {
                return image.withHorizontallyFlippedOrientation()
            } else {
                return image.fixedOrientation()
            }
        }
    }
}

// MARK: - Optimized Camera Preview

struct OptimizedCameraPreviewView: UIViewRepresentable {
    let controller: OptimizedCameraController
    
    func makeUIView(context: Context) -> CameraPreview {
        let view = CameraPreview()
        let previewLayer = controller.createPreviewLayer()
        view.setPreviewLayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: CameraPreview, context: Context) {
        // No updates needed
    }
}

class CameraPreview: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        // Clean up existing layer first
        if let existingLayer = previewLayer {
            existingLayer.removeFromSuperlayer()
        }
        
        previewLayer = layer
        layer.frame = bounds
        self.layer.addSublayer(layer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
    
    deinit {
        // Ensure preview layer is removed
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
    }
}

// MARK: - Error Types

enum CameraError: Error {
    case notConfigured
    case imageProcessingFailed
    case permissionDenied
}
