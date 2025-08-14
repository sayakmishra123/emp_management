import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show WriteBuffer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart' as gm;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;

class FaceDetectionScreen extends StatefulWidget {
  const FaceDetectionScreen({super.key});
  @override
  State<FaceDetectionScreen> createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Scan line anim
  late final AnimationController _scanCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  // Camera
  CameraController? _camera;
  List<CameraDescription> _cameras = [];
  int _cameraIndex =
      1; // try 1 to prefer front camera; will fallback if invalid
  bool _initializingCam = false;

  // Throttling
  Timer? _throttle;
  static const int _throttleMs = 80; // ~12.5 fps for ML Kit detection

  // ML Kit face detector
  late final FaceDetector _detector;

  // Live state
  bool _scanning = false;
  List<Face> _faces = [];
  Size? _latestImageSize;
  bool get _isFront =>
      _cameras.isNotEmpty &&
      _cameras[_cameraIndex].lensDirection == CameraLensDirection.front;

  // UI
  bool _flashOn = false;

  // Enrollment / verification
  List<double>? _enrolledVec;
  bool get _isEnrolled => _enrolledVec != null;
  bool _busyCapture = false;

  // Live recognition throttle
  DateTime? _lastEmbedAt;
  static const Duration _embedGap = Duration(milliseconds: 350);

  // Live recognition result (used for overlay color)
  bool _lastMatch = false;
  DateTime? _lastMatchAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableContours: true,
        enableClassification: true,
        enableLandmarks: true,
        minFaceSize: 0.1,
      ),
    );

    _initCamera();
    _loadTemplate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _throttle?.cancel();
    _stopStream();
    _camera?.dispose();
    _detector.close();
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_camera == null) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopStream();
      _camera?.dispose();
      _camera = null;
    } else if (state == AppLifecycleState.resumed) {
      _startCamera(_cameraIndex).then((_) {
        if (_scanning) _startStream();
      });
    }
  }

  // ---------------- Camera ----------------

  Future<void> _initCamera() async {
    if (_initializingCam) return;
    _initializingCam = true;
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras found on this device')),
          );
        }
        return;
      }
      // If requested index is out of range, fallback to 0
      if (_cameraIndex < 0 || _cameraIndex >= _cameras.length) _cameraIndex = 0;
      await _startCamera(_cameraIndex);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    } finally {
      _initializingCam = false;
    }
  }

  Future<void> _startCamera(int index) async {
    final desc = _cameras[index];
    final ctrl = CameraController(
      desc,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup:
          Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
    );
    await ctrl.initialize();
    await ctrl.lockCaptureOrientation(DeviceOrientation.portraitUp);
    setState(() {
      _camera = ctrl;
      _faces = [];
      _latestImageSize = null;
    });
    if (_scanning) _startStream();
  }

  Future<void> _startStream() async {
    if (_camera == null || !_camera!.value.isInitialized) return;
    if (_camera!.value.isStreamingImages) return;
    _faces = [];
    _latestImageSize = null;

    await _camera!.startImageStream((CameraImage image) {
      if (_throttle?.isActive ?? false) return;
      _throttle = Timer(const Duration(milliseconds: _throttleMs), () {});
      _latestImageSize = Size(image.width.toDouble(), image.height.toDouble());
      _processCameraImage(image);
    });
  }

  Future<void> _stopStream() async {
    if (_camera?.value.isStreamingImages == true) {
      await _camera!.stopImageStream();
    }
    _throttle?.cancel();
    _throttle = null;
  }

  // --------------- LIVE: detection + recognition ---------------

  Future<void> _processCameraImage(CameraImage image) async {
    // Build InputImage for ML Kit (planeData no longer required on latest)
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane p in image.planes) {
      allBytes.putUint8List(p.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final imgSize = Size(image.width.toDouble(), image.height.toDouble());
    final rotation = gm.InputImageRotationValue.fromRawValue(
          _camera!.description.sensorOrientation,
        ) ??
        gm.InputImageRotation.rotation0deg;

    final format = Platform.isIOS
        ? gm.InputImageFormat.bgra8888
        : gm.InputImageFormat.nv21;

    final metadata = gm.InputImageMetadata(
      size: imgSize,
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    final input = InputImage.fromBytes(bytes: bytes, metadata: metadata);
    final faces = await _detector.processImage(input);

    if (!mounted) return;
    setState(() => _faces = faces);

    // recognition only if enrolled and a face is present
    if (!_isEnrolled || faces.isEmpty) return;

    // throttle embeddings
    final now = DateTime.now();
    if (_lastEmbedAt != null && now.difference(_lastEmbedAt!) < _embedGap)
      return;
    _lastEmbedAt = now;

    try {
      // Convert current camera frame to upright RGB for cropping/embedding
      final rgbUpright = _cameraImageToUprightRgb(image, rotation);

      // Largest face
      faces.sort((a, b) => (b.boundingBox.width * b.boundingBox.height)
          .compareTo(a.boundingBox.width * a.boundingBox.height));
      final Rect bb = faces.first.boundingBox;

      // Crop with padding
      int x = bb.left.floor().clamp(0, rgbUpright.width - 1);
      int y = bb.top.floor().clamp(0, rgbUpright.height - 1);
      int w = bb.width.floor().clamp(1, rgbUpright.width - x);
      int h = bb.height.floor().clamp(1, rgbUpright.height - y);

      const pad = 0.15;
      final xp = (w * pad).round();
      final yp = (h * pad).round();
      x = (x - xp).clamp(0, rgbUpright.width - 1);
      y = (y - yp).clamp(0, rgbUpright.height - 1);
      w = (w + 2 * xp).clamp(1, rgbUpright.width - x);
      h = (h + 2 * yp).clamp(1, rgbUpright.height - y);

      final cropped = img.copyCrop(rgbUpright, x: x, y: y, width: w, height: h);
      final resized = img.copyResize(cropped, width: 112, height: 112);

      final vec = await _FaceEmbedder.embed(resized);
      final d = _l2(vec, _enrolledVec!);
      const threshold = 1.0; // tune 0.9–1.1 per model

      setState(() {
        _lastMatch = d <= threshold;
        _lastMatchAt = DateTime.now();
      });
    } catch (_) {
      // one-frame error ignored
    }
  }

  // Convert CameraImage to upright RGB
  img.Image _cameraImageToUprightRgb(
      CameraImage image, gm.InputImageRotation rotation) {
    // Convert to RGB
    final img.Image rgb = Platform.isIOS
        ? _bgra8888ToImage(image) // iOS BGRA
        : _yuv420ToImage(image); // Android YUV420

    // Rotate to upright to align with ML Kit's upright boxes
    switch (rotation) {
      case gm.InputImageRotation.rotation90deg:
        return img.copyRotate(rgb, angle: 90);
      case gm.InputImageRotation.rotation180deg:
        return img.copyRotate(rgb, angle: 180);
      case gm.InputImageRotation.rotation270deg:
        return img.copyRotate(rgb, angle: 270);
      case gm.InputImageRotation.rotation0deg:
      default:
        return rgb;
    }
  }

  img.Image _bgra8888ToImage(CameraImage image) {
    // iOS gives BGRA in plane 0, with a row stride that can be > width * 4
    final plane = image.planes[0];
    final int w = image.width;
    final int h = image.height;

    final Uint8List src = plane.bytes;
    final int srcStride = plane.bytesPerRow; // bytes in the *source* row
    final int tightStride = w * 4; // BGRA/RGBA = 4 bytes per pixel

    // 1) Repack into a tightly packed buffer (no padding at end of each row)
    Uint8List packed;
    if (srcStride == tightStride) {
      packed = src;
    } else {
      packed = Uint8List(tightStride * h);
      for (int y = 0; y < h; y++) {
        final int srcOff = y * srcStride;
        final int dstOff = y * tightStride;
        packed.setRange(dstOff, dstOff + tightStride, src, srcOff);
      }
    }

    // 2) Convert BGRA -> RGBA by swapping B and R for each pixel
    //    (G and A stay as-is)
    for (int i = 0; i < packed.length; i += 4) {
      final int b = packed[i];
      final int r = packed[i + 2];
      packed[i] = r; // R
      packed[i + 2] = b; // B
    }

    // 3) Build an Image from tightly-packed **RGBA** bytes.
    //    On image ^4.x this ctor expects a ByteBuffer and channel count.
    return img.Image.fromBytes(
      width: w,
      height: h,
      bytes: packed.buffer, // <-- ByteBuffer (not Uint8List)
      numChannels: 4, // RGBA
    );
  }

  img.Image _yuv420ToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 2; // usually 2

    final out = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      final yRow = y * yRowStride;
      final uvRow = (y ~/ 2) * uvRowStride;
      for (int x = 0; x < width; x++) {
        final yIndex = yRow + x;
        final uvIndex = uvRow + (x ~/ 2) * uvPixelStride;

        final Y = yBytes[yIndex].toInt();
        final U = uBytes[uvIndex].toInt();
        final V = vBytes[uvIndex].toInt();

        // YUV420 -> RGB (BT.601)
        final yf = Y.toDouble();
        final uf = U.toDouble() - 128.0;
        final vf = V.toDouble() - 128.0;

        int r = (yf + 1.403 * vf).round();
        int g = (yf - 0.344 * uf - 0.714 * vf).round();
        int b = (yf + 1.770 * uf).round();

        if (r < 0)
          r = 0;
        else if (r > 255) r = 255;
        if (g < 0)
          g = 0;
        else if (g > 255) g = 255;
        if (b < 0)
          b = 0;
        else if (b > 255) b = 255;

        out.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return out;
  }

  // ---------------- Enroll / Verify (capture still) ----------------

  Future<void> _loadTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString('face_template');
      if (raw != null) {
        _enrolledVec = (jsonDecode(raw) as List)
            .map((e) => (e as num).toDouble())
            .toList();
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _saveTemplate(List<double> v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('face_template', jsonEncode(v));
    _enrolledVec = v;
    setState(() {});
  }

  Future<String?> _captureJpeg() async {
    if (_camera == null || !_camera!.value.isInitialized) return null;
    if (_camera!.value.isStreamingImages) await _stopStream();
    try {
      final file = await _camera!.takePicture();
      return file.path;
    } catch (_) {
      return null;
    } finally {
      if (_scanning) _startStream();
    }
  }

  Future<void> _enrollNow() async {
    if (_busyCapture) return;
    _busyCapture = true;

    final path = await _captureJpeg();
    if (path == null) {
      _busyCapture = false;
      _toast('Could not capture photo');
      return;
    }
    final vec = await _embedFromPhoto(path);
    _busyCapture = false;

    if (vec == null) {
      _showDialog(const Color(0xFFEF4444), 'Face not found',
          'Try again with better lighting & fill the frame.');
      return;
    }
    await _saveTemplate(vec);
    _showDialog(const Color(0xFF10B981), 'Face setup complete',
        'Next time I will verify your face automatically.');
  }

  Future<void> _verifyNow() async {
    if (!_isEnrolled || _busyCapture) return;
    _busyCapture = true;

    final path = await _captureJpeg();
    if (path == null) {
      _busyCapture = false;
      _toast('Could not capture photo');
      return;
    }
    final vec = await _embedFromPhoto(path);
    _busyCapture = false;

    if (vec == null) {
      _showDialog(const Color(0xFFEF4444), 'No face detected',
          'Keep your face inside the frame.');
      return;
    }

    final d = _l2(vec, _enrolledVec!);
    const threshold = 1.0;
    if (d <= threshold) {
      _showDialog(const Color(0xFF16A34A), 'Verified',
          'Face matched (distance ${d.toStringAsFixed(3)}).');
    } else {
      _showDialog(const Color(0xFFDC2626), 'Not a match',
          'Different face (distance ${d.toStringAsFixed(3)}).');
    }
  }

  Future<List<double>?> _embedFromPhoto(String path) async {
    // Detect faces on still image
    final faces = await _detector.processImage(InputImage.fromFilePath(path));
    if (faces.isEmpty) return null;

    // pick largest face
    faces.sort((a, b) => (b.boundingBox.width * b.boundingBox.height)
        .compareTo(a.boundingBox.width * a.boundingBox.height));
    final faceRect = faces.first.boundingBox;

    // read & crop
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    // Apply EXIF orientation if present
    final original = img.bakeOrientation(decoded);

    int x = faceRect.left.floor().clamp(0, original.width - 1);
    int y = faceRect.top.floor().clamp(0, original.height - 1);
    int w = faceRect.width.floor().clamp(1, original.width - x);
    int h = faceRect.height.floor().clamp(1, original.height - y);

    const pad = 0.15;
    final xp = (w * pad).round();
    final yp = (h * pad).round();
    x = (x - xp).clamp(0, original.width - 1);
    y = (y - yp).clamp(0, original.height - 1);
    w = (w + 2 * xp).clamp(1, original.width - x);
    h = (h + 2 * yp).clamp(1, original.height - y);

    final cropped = img.copyCrop(original, x: x, y: y, width: w, height: h);
    final resized = img.copyResize(cropped, width: 112, height: 112);

    return _FaceEmbedder.embed(resized);
  }

  // ---------------- UI Actions ----------------

  Future<void> _toggleScanning() async {
    if (_camera == null) {
      await _initCamera();
    }
    setState(() => _scanning = !_scanning);
    if (_scanning) {
      await _startStream();
    } else {
      await _stopStream();
      if (mounted) setState(() => _faces = []);
    }
  }

  Future<void> _toggleFlash() async {
    if (_camera == null) return;
    try {
      if (_flashOn) {
        await _camera!.setFlashMode(FlashMode.off);
      } else {
        await _camera!.setFlashMode(FlashMode.torch);
      }
      setState(() => _flashOn = !_flashOn);
    } catch (_) {
      _toast('Flash not supported on this camera');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _stopStream();
    await _camera?.dispose();
    setState(() {
      _camera = null;
      _faces = [];
    });
    await _startCamera(_cameraIndex);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showDialog(Color color, String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  double _l2(List<double> a, List<double> b) {
    final n = math.min(a.length, b.length);
    double s = 0.0;
    for (int i = 0; i < n; i++) {
      final d = a[i] - b[i];
      s += d * d;
    }
    return math.sqrt(s);
  }

  void _clearFace() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('face_template');
    _enrolledVec = null;
    setState(() {});
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    const pageX = 16.0;
    const cardDarkTop = Color(0xFF121821);
    const cardDarkBottom = Color(0xFF0E141B);
    const corner = Color(0xFFBFD4FF);
    const grid = Color(0xFF5A6B80);
    const primary = Color(0xFF0D80F2);

    final cs = Theme.of(context).colorScheme;

    // Box color logic for overlay
    final now = DateTime.now();
    final recentDecision = _lastMatchAt != null &&
        now.difference(_lastMatchAt!) < const Duration(seconds: 2);

    final Color boxColor = !_isEnrolled
        ? const Color(0xFF00E5FF) // cyan while only detecting
        : recentDecision
            ? (_lastMatch ? const Color(0xFF22C55E) : const Color(0xFFEF4444))
            : const Color(0xFF00E5FF);

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back, size: 22),
                      splashRadius: 20,
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Face Detection',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.info_outline, size: 20),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Guidance
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 10),
              child: Text(
                _isEnrolled
                    ? 'Look straight & keep face centered to verify'
                    : 'Align your face within the frame to set up',
                style: GoogleFonts.inter(
                  color: cs.onSurfaceVariant,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Camera card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: pageX),
              child: _CameraCard(
                controller: _scanCtrl,
                flashOn: _flashOn,
                onToggleFlash: _toggleFlash,
                onTapGallery: _pickFromGalleryAndRecognize,
                onTapSwitch: _switchCamera,
                onTapShutter: _toggleScanning,
                scanning: _scanning,
                // styling
                cornerColor: corner,
                gridColor: grid.withOpacity(.20),
                bgTop: cardDarkTop,
                bgBottom: cardDarkBottom,
                // preview + overlay
                cameraController: _camera,
                faces: _faces,
                latestImageSize: _latestImageSize,
                isFrontCamera: _isFront,
                boxColor: boxColor,
                // optional center indicator
                showCenterIcon: _isEnrolled && recentDecision,
                centerIcon:
                    _lastMatch ? Icons.verified_rounded : Icons.error_rounded,
              ),
            ),

            const SizedBox(height: 14),

            // Primary action button (Enroll / Verify)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isEnrolled ? _verifyNow : _enrollNow,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    _isEnrolled ? 'Verify Face' : 'Set Up Face',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ),

            // Clear template
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: SizedBox(
                height: 38,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isEnrolled ? _clearFace : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text(
                    'Clear',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ),

            // Privacy caption
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'All on-device • No data stored except a small template',
                style: GoogleFonts.inter(
                  color: cs.onSurface.withOpacity(.55),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pick from gallery: enroll if not enrolled, otherwise verify
  Future<void> _pickFromGalleryAndRecognize() async {
    final picker = ImagePicker();
    final x =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (x == null) return;

    final vec = await _embedFromPhoto(x.path);
    if (vec == null) {
      _showDialog(const Color(0xFFEF4444), 'No face found',
          'Choose another photo with a clear face.');
      return;
    }

    if (!_isEnrolled) {
      await _saveTemplate(vec);
      _showDialog(const Color(0xFF10B981), 'Face setup from photo',
          'Template saved from selected photo.');
      return;
    }

    final d = _l2(vec, _enrolledVec!);
    const threshold = 1.0;
    if (d <= threshold) {
      _showDialog(const Color(0xFF16A34A), 'Verified (Photo)',
          'Match (distance ${d.toStringAsFixed(3)}).');
    } else {
      _showDialog(const Color(0xFFDC2626), 'Not a match (Photo)',
          'Different face (distance ${d.toStringAsFixed(3)}).');
    }
  }
}

/// Camera-style card with preview, grid/corners, scan line, and controls
class _CameraCard extends StatelessWidget {
  final AnimationController controller;
  final bool flashOn;
  final VoidCallback onToggleFlash;
  final VoidCallback onTapGallery;
  final VoidCallback onTapSwitch;
  final VoidCallback onTapShutter;
  final bool scanning;

  final Color cornerColor;
  final Color gridColor;
  final Color bgTop;
  final Color bgBottom;

  final CameraController? cameraController;
  final List<Face> faces;
  final Size? latestImageSize;
  final bool isFrontCamera;

  final Color boxColor;
  final bool showCenterIcon;
  final IconData centerIcon;

  const _CameraCard({
    required this.controller,
    required this.flashOn,
    required this.onToggleFlash,
    required this.onTapGallery,
    required this.onTapSwitch,
    required this.onTapShutter,
    required this.scanning,
    required this.cornerColor,
    required this.gridColor,
    required this.bgTop,
    required this.bgBottom,
    this.cameraController,
    this.faces = const [],
    this.latestImageSize,
    this.isFrontCamera = false,
    this.boxColor = const Color(0xFF00E5FF),
    this.showCenterIcon = false,
    this.centerIcon = Icons.verified_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(24);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgBottom],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            color: cs.shadow.withOpacity(0.1),
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 350,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Camera preview
                    if (cameraController != null &&
                        cameraController!.value.isInitialized)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: cameraController!.value.previewSize!.width,
                            height: cameraController!.value.previewSize!.height,
                            child: CameraPreview(cameraController!),
                          ),
                        ),
                      )
                    else
                      Container(color: cs.surfaceVariant),

                    // Faces overlay
                    CustomPaint(
                      painter: _FacesPainter(
                        faces: faces,
                        imageSize: latestImageSize,
                        widgetSize:
                            Size(constraints.maxWidth, constraints.maxHeight),
                        isFrontCamera: isFrontCamera,
                        boxColor: boxColor,
                      ),
                    ),

                    // Optional center icon
                    if (showCenterIcon)
                      Center(
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.surface.withOpacity(0.7),
                          ),
                          child: Icon(centerIcon, color: cs.onSurface),
                        ),
                      ),

                    // Frame guides
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _FramePainter(
                          cornerColor: cs.primary.withOpacity(0.3),
                          gridColor: cs.onSurface.withOpacity(0.2),
                        ),
                      ),
                    ),

                    // Scan line
                    AnimatedBuilder(
                      animation: controller,
                      builder: (context, _) {
                        return Align(
                          alignment: Alignment(0, controller.value * 1.8 - 0.9),
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 28),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  cs.primary.withOpacity(.9),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Flash button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _CircleIconButton(
                        icon: flashOn ? Icons.bolt : Icons.bolt_outlined,
                        onTap: onToggleFlash,
                        size: 36,
                        iconSize: 18,
                        bg: cs.surface.withOpacity(0.1),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Controls row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _CircleIconButton(
                        icon: Icons.photo,
                        onTap: onTapGallery,
                        size: 44,
                        iconSize: 22,
                        bg: cs.surface.withOpacity(0.15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Photos',
                        style: GoogleFonts.inter(
                          color: cs.onSurface.withOpacity(.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: onTapShutter,
                      child: Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primary,
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            )
                          ],
                          border: Border.all(color: cs.surface, width: 3),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _CircleIconButton(
                            icon: Icons.autorenew,
                            onTap: null,
                            size: 36,
                            iconSize: 18,
                            bg: Color(0x22FFFFFF), // could theme if desired
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _CircleIconButton(
                        icon: Icons.cameraswitch,
                        onTap: onTapSwitch,
                        size: 44,
                        iconSize: 22,
                        bg: cs.surface.withOpacity(0.15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Switch',
                        style: GoogleFonts.inter(
                          color: cs.onSurface.withOpacity(.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? bg;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.size,
    required this.iconSize,
    this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg ?? cs.surfaceVariant.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: cs.onSurface.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: cs.onSurface,
        ),
      ),
    );
  }
}

/// Frame (corners + thirds grid)
class _FramePainter extends CustomPainter {
  final Color cornerColor;
  final Color gridColor;

  _FramePainter({required this.cornerColor, required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final inset = 18.0;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          inset, inset, size.width - inset * 2, size.height - inset * 2),
      const Radius.circular(18),
    );

    // light vignette
    final dimPaint = Paint()..color = const Color(0x11000000);
    canvas.drawRRect(r, dimPaint);

    // thirds
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final left = r.left, right = r.right, top = r.top, bottom = r.bottom;
    final w = r.width, h = r.height;

    canvas.drawLine(
        Offset(left + w / 3, top), Offset(left + w / 3, bottom), gridPaint);
    canvas.drawLine(
        Offset(right - w / 3, top), Offset(right - w / 3, bottom), gridPaint);
    canvas.drawLine(
        Offset(left, top + h / 3), Offset(right, top + h / 3), gridPaint);
    canvas.drawLine(
        Offset(left, bottom - h / 3), Offset(right, bottom - h / 3), gridPaint);

    // corners
    final c = Paint()
      ..color = cornerColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 26.0;
    canvas.drawPath(
        _cornerPath(
            Offset(left, top), const Radius.circular(16), len, Corner.tl),
        c);
    canvas.drawPath(
        _cornerPath(
            Offset(right, top), const Radius.circular(16), len, Corner.tr),
        c);
    canvas.drawPath(
        _cornerPath(
            Offset(left, bottom), const Radius.circular(16), len, Corner.bl),
        c);
    canvas.drawPath(
        _cornerPath(
            Offset(right, bottom), const Radius.circular(16), len, Corner.br),
        c);
  }

  Path _cornerPath(Offset pivot, Radius r, double len, Corner where) {
    final p = Path();
    switch (where) {
      case Corner.tl:
        p
          ..moveTo(pivot.dx, pivot.dy + len)
          ..lineTo(pivot.dx, pivot.dy + r.x)
          ..arcToPoint(Offset(pivot.dx + r.x, pivot.dy),
              radius: r, clockwise: false)
          ..lineTo(pivot.dx + len, pivot.dy);
        break;
      case Corner.tr:
        p
          ..moveTo(pivot.dx - len, pivot.dy)
          ..lineTo(pivot.dx - r.x, pivot.dy)
          ..arcToPoint(Offset(pivot.dx, pivot.dy + r.x),
              radius: r, clockwise: false)
          ..lineTo(pivot.dx, pivot.dy + len);
        break;
      case Corner.bl:
        p
          ..moveTo(pivot.dx, pivot.dy - len)
          ..lineTo(pivot.dx, pivot.dy - r.x)
          ..arcToPoint(Offset(pivot.dx + r.x, pivot.dy),
              radius: r, clockwise: false)
          ..lineTo(pivot.dx + len, pivot.dy);
        break;
      case Corner.br:
        p
          ..moveTo(pivot.dx - len, pivot.dy)
          ..lineTo(pivot.dx - r.x, pivot.dy)
          ..arcToPoint(Offset(pivot.dx, pivot.dy - r.x),
              radius: r, clockwise: false)
          ..lineTo(pivot.dx, pivot.dy - len);
        break;
    }
    return p;
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) =>
      old.cornerColor != cornerColor || old.gridColor != gridColor;
}

enum Corner { tl, tr, bl, br }

/// Draw face boxes mapped from image space to preview. Mirrors for front camera.
/// Color is provided (cyan/green/red) by the parent.
class _FacesPainter extends CustomPainter {
  final List<Face> faces;
  final Size? imageSize; // raw camera image (width x height)
  final Size widgetSize; // preview widget
  final bool isFrontCamera;
  final Color boxColor;

  _FacesPainter({
    required this.faces,
    required this.imageSize,
    required this.widgetSize,
    required this.isFrontCamera,
    required this.boxColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == null || faces.isEmpty) return;

    // In portrait, raw camera image is rotated; swap width/height.
    final double imgW = imageSize!.height;
    final double imgH = imageSize!.width;

    final scaleX = size.width / imgW;
    final scaleY = size.height / imgH;

    final paint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final f in faces) {
      Rect r = Rect.fromLTRB(
        f.boundingBox.left * scaleX,
        f.boundingBox.top * scaleY,
        f.boundingBox.right * scaleX,
        f.boundingBox.bottom * scaleY,
      );
      if (isFrontCamera) {
        r = Rect.fromLTWH(size.width - r.right, r.top, r.width, r.height);
      }
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(12)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FacesPainter old) {
    return old.faces != faces ||
        old.imageSize != imageSize ||
        old.isFrontCamera != isFrontCamera ||
        old.boxColor != boxColor;
  }
}

// -------------------- Face Embedding --------------------

class _FaceEmbedder {
  static tfl.Interpreter? _i;

  static Future<tfl.Interpreter> _get() async {
    _i ??=
        await tfl.Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
    return _i!;
  }

  /// Input: 112x112 RGB image. Output: L2-normalized embedding.
  static Future<List<double>> embed(img.Image rgb112) async {
    final i = await _get();
    const h = 112, w = 112;

    final input = List.generate(
      1,
      (_) => List.generate(
        h,
        (y) => List.generate(w, (x) {
          final p = rgb112.getPixel(x, y);
          final r = ((p.r / 255.0) - 0.5) * 2.0;
          final g = ((p.g / 255.0) - 0.5) * 2.0;
          final b = ((p.b / 255.0) - 0.5) * 2.0;
          return [r, g, b];
        }),
      ),
    );

    final outShape = i.getOutputTensor(0).shape; // e.g., [1,128] or [1,192]
    final outLen = outShape.reduce((a, b) => a * b);
    final output = _Reshape(List.filled(outLen, 0.0)).reshape([1, outLen]);

    i.run(input, output);
    final v = (output[0] as List).map((e) => (e as num).toDouble()).toList();

    // L2 normalize
    final norm = math.sqrt(v.fold(0.0, (s, x) => s + x * x));
    return v.map((x) => x / (norm == 0 ? 1 : norm)).toList();
  }
}

// simple list reshape helper
extension _Reshape on List {
  List reshape(List<int> dims) {
    if (dims.length == 1) return this;
    int idx = 0;
    List build(int d) {
      if (d == dims.length - 1) {
        final len = dims[d];
        final chunk = sublist(idx, idx + len);
        idx += len;
        return chunk;
      } else {
        return List.generate(dims[d], (_) => build(d + 1));
      }
    }

    return build(0);
  }
}
