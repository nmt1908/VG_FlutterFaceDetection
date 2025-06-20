import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:face_camera/face_camera.dart';
import 'package:cross_file/cross_file.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'MenuScreen.dart';
import 'package:demo/models/user.dart';
import 'package:demo/utils/session_manager.dart';
import 'package:audioplayers/audioplayers.dart';

class FacePreviewScreen extends StatefulWidget {
  const FacePreviewScreen({super.key});

  @override
  State<FacePreviewScreen> createState() => _FacePreviewScreenState();
}

class _FacePreviewScreenState extends State<FacePreviewScreen> {
  late final FaceCameraController controller;
  Timer? _timer;
  bool _isProcessing = false;
  bool _takePicture = false;
  XFile? _capturedImage;
  String? _recognizedName;
  String? _recognizedCardId;
  String? _similarityStr;
  bool _showOverlay = false;
  final _audioPlayer = AudioPlayer();
  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      debugPrint("🔊 Phát âm thanh thành công");
    } catch (e) {
      print("🚫 Lỗi phát âm thanh: $e");
    }
  }

  

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 2000), () async {
      setState(() {
        _takePicture = true;
        _isProcessing = true;
      });

      // try {
      //   final picture = await controller.takePicture();

      //   if (picture != null) {
      //     final resizedFile = await resizeImageAndSaveToDownload(
      //       picture,
      //     ); // ✅ không còn lỗi
      //     setState(() {
      //       _capturedImage = XFile(resizedFile.path);
      //     });
      //     debugPrint("✅ Path ảnh đã resize: ${resizedFile.path}");
      //   } else {
      //     debugPrint("❌ Không nhận được ảnh từ camera");
      //   }
      // } catch (e) {
      //   debugPrint("❌ Lỗi khi chụp hoặc resize ảnh: $e");
      // }
      try {
        final picture = await controller.takePicture();
        if (picture != null) {
          final bytes = await picture.readAsBytes();

          // 📦 Log size ảnh
          debugPrint(
            "📏 Kích thước ảnh: ${bytes.lengthInBytes} bytes ≈ ${(bytes.lengthInBytes / 1024).toStringAsFixed(2)} KB",
          );
          ui.decodeImageFromList(bytes, (ui.Image img) {
            debugPrint("📐 Width: ${img.width}px, Height: ${img.height}px");
          });

          await uploadImageBytesToApi(bytes);

          setState(() {
            _capturedImage = picture;
          });
        }
      } catch (e) {
        debugPrint("❌ Lỗi khi chụp hoặc lưu ảnh: $e");
      }

      // Hiển thị ảnh 0.5s rồi reset
      Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _takePicture = false;
          _capturedImage = null;
          _timer = null;
          _isProcessing = false;
        });
      });
    });
  }

  Future<File> resizeImage(XFile originalFile, {int targetWidth = 500}) async {
    final rawBytes = await originalFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(rawBytes);
    if (originalImage == null) throw Exception("Không đọc được ảnh");
    img.Image resizedImage = img.copyResize(originalImage, width: targetWidth);
    final resizedBytes = img.encodeJpg(resizedImage, quality: 85);
    final dir = await getTemporaryDirectory();
    final resizedPath =
        '${dir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final resizedFile = File(resizedPath);
    await resizedFile.writeAsBytes(resizedBytes);

    return resizedFile;
  }

  Future<File> saveOriginalImageToDownload(XFile originalFile) async {
    final bytes = await originalFile.readAsBytes();

    final Directory? externalDir = await getExternalStorageDirectory();
    if (externalDir == null) throw Exception("Không lấy được thư mục external");

    final downloadDir = Directory('${externalDir.path}/Download');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }

    final filePath =
        '${downloadDir.path}/original_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = File(filePath);
    await savedFile.writeAsBytes(bytes);

    return savedFile;
  }

  Future<void> uploadImageBytesToApi(Uint8List bytes) async {
    final now = DateTime.now();
    final currentTime =
        "${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)} "
        "${_twoDigits(now.hour)}:${_twoDigits(now.minute)}:${_twoDigits(now.second)}";

    final headersPrimary = {"X-API-Key": "vg_login_app", "X-Time": currentTime};

    final uriPrimary = Uri.parse(
      "http://10.13.32.51:5001/recognize-anti-spoofing",
    );
    final uriFallback = Uri.parse(
      "http://10.1.16.23:8001/api/x/fr/env/face_search",
    );

    final fileName = "captured_${DateTime.now().millisecondsSinceEpoch}.jpg";

    final requestPrimary = http.MultipartRequest("POST", uriPrimary)
      ..headers.addAll(headersPrimary)
      ..files.add(
        http.MultipartFile.fromBytes(
          'image_file',
          bytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

    try {
      final response = await requestPrimary.send().timeout(
        const Duration(seconds: 5),
      );
      final resBody = await response.stream.bytesToString();
      debugPrint("✅ Primary API response: $resBody");

      if (response.statusCode == 200) {
        // _playSuccessSound();
        _handleApiResponse(resBody);
      } else {
        throw Exception("Primary API failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("🔁 Primary API failed, switching to fallback...");

      final requestFallback = http.MultipartRequest("POST", uriFallback)
        ..fields['env_token'] = "8d59d8d588f84fc0a24291b8c36b6206"
        ..files.add(
          http.MultipartFile.fromBytes(
            'image_file',
            bytes,
            filename: fileName,
            contentType: MediaType('image', 'jpeg'),
          ),
        );

      final response = await requestFallback.send();
      final resBody = await response.stream.bytesToString();
      debugPrint("🟡 Fallback API response: $resBody");

      if (response.statusCode == 200) {
        // _playSuccessSound();

        _handleApiResponse(resBody);
      } else {
        debugPrint("❌ Fallback API also failed: ${response.statusCode}");
      }
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  void _handleApiResponse(String responseBody) async {
    try {
      final json = jsonDecode(responseBody);

      if ((json['is_recognized'] ?? 0) == 1) {
        final name = json['name'] ?? '';
        final cardId = json['id_string'] ?? '';
        final similarity = (json['similarity'] ?? 0.0) * 100;
        final similarityStr = "${similarity.toStringAsFixed(2)}%";

        setState(() {
          _recognizedName = name;
          _recognizedCardId = cardId;
          _similarityStr = similarityStr;
          _showOverlay = true;
        });
        final user = User(id: cardId, name: name);
        await saveUserSession(user);
        await Future.delayed(const Duration(milliseconds: 700));

        if (!mounted) return;

        setState(() {
          _showOverlay = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MenuScreen(activeUser: user)),
        );
        if (!mounted) return;
      } else {
        debugPrint("❌ Không nhận diện được khuôn mặt");
      }
    } catch (e) {
      debugPrint("❌ Lỗi khi xử lý JSON: $e");
    }
  }

  Future<File> resizeImageAndSaveToDownload(
    XFile originalFile, {
    int targetWidth = 550,
  }) async {
    final rawBytes = await originalFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(rawBytes);
    if (originalImage == null) throw Exception("Không đọc được ảnh");

    img.Image resizedImage = img.copyResize(originalImage, width: targetWidth);
    final resizedBytes = img.encodeJpg(resizedImage, quality: 85);

    // Lưu vào thư mục external riêng của app
    final Directory? externalDir = await getExternalStorageDirectory();
    if (externalDir == null) throw Exception("Không lấy được thư mục external");

    final downloadDir = Directory('${externalDir.path}/Download');
    if (!await downloadDir.exists()) await downloadDir.create(recursive: true);

    final filePath =
        '${downloadDir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final resizedFile = File(filePath);
    await resizedFile.writeAsBytes(resizedBytes);

    return resizedFile;
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _takePicture = false;
      _capturedImage = null;
      _isProcessing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    controller = FaceCameraController(
      autoCapture: false,
      defaultCameraLens: CameraLens.front,
      onFaceDetected: (face) {
        if (face == null) {
          debugPrint("❌ Không phát hiện khuôn mặt");
          _resetTimer();
          return;
        }

        final angleY = face.headEulerAngleY ?? 1000;
        debugPrint("✅ Khuôn mặt phát hiện - Góc Y: $angleY");

        if (angleY >= -10 && angleY <= 10) {
          debugPrint("🟢 Mặt đang nhìn thẳng");

          if (_timer == null && !_isProcessing) {
            debugPrint("⏱️ Bắt đầu đếm 1 giây để chụp");
            _startTimer();
          }
        } else {
          debugPrint("🔴 Mặt không còn nhìn thẳng");
          _resetTimer();
        }
      },
      onCapture: (_) {},
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            SmartFaceCamera(
              controller: controller,
              showControls: false,
              showFlashControl: false,
              showCaptureControl: false,
              showCameraLensControl: false,
              message: null,
              indicatorShape: IndicatorShape.circle,
            ),
            Positioned(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 59, 58, 58).withOpacity(0.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 90,
                      height: 90,
                    ),
                    const Spacer(),
                    const Text(
                      'Face Detection',
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            if (_showOverlay)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FractionallySizedBox(
                  widthFactor: 1,
                  child: Container(
                    padding: EdgeInsets.all(16.w), // 👈 responsive padding
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                        255,
                        59,
                        58,
                        58,
                      ).withOpacity(0.9),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r), // 👈 responsive radius
                        topRight: Radius.circular(16.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🟢 DETECTION SUCCESSFUL',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h), // 👈 responsive spacing
                        Text(
                          'NAME: $_recognizedName',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'CARD NUMBER: $_recognizedCardId',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'SIMILARITY: $_similarityStr',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
