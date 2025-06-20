import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:demo/models/user.dart';
import 'package:demo/utils/session_manager.dart';
import 'FaceDetectionScreen.dart';
import 'package:demo/widgets/live_clock.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MenuScreen extends StatefulWidget {
  final User activeUser;

  const MenuScreen({super.key, required this.activeUser});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final FlutterTts tts = FlutterTts();

  @override
  void initState() {
    super.initState();

    // Gọi hàm chào khi mở màn hình
    Future.delayed(Duration.zero, () {
      speakGreeting(widget.activeUser.name);
    });
  }

  Future<void> speakGreeting(String name) async {
    try {
      await tts.awaitSpeakCompletion(true);
      await tts.setLanguage("vi-VN");
      await tts.setPitch(1.0);
      await tts.setSpeechRate(0.4);

      // Optional: chọn đúng voice nếu có
      final voices = await tts.getVoices;
      final viVoice = voices.firstWhere(
        (v) => v["locale"] == "vi-VN",
        orElse: () => null,
      );

      if (viVoice != null) {
        final voiceMap = Map<String, String>.from(Map.castFrom(viVoice));
        await tts.setVoice(voiceMap);
      }

      await tts.speak("Xin chào $name");
      debugPrint("🔊 Đọc lời chào: Xin chào $name");
    } catch (e) {
      debugPrint("❌ Lỗi TTS: $e");
    }
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset('assets/images/bg4.jpg', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 10.h),

                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 50.w,
                    height: 50.w,
                  ),
                ),

                SizedBox(height: 5.h),

                // Clock
                const LiveClock(),

                // Text(
                //   "00:00",
                //   style: TextStyle(
                //     color: const Color(0xFFFFA500),
                //     fontSize: 13.sp,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                SizedBox(height: 10.h),

                // Greeting
                Text(
                  "Hello,",
                  style: TextStyle(
                    color: const Color(0xFFFFA500),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    "${widget.activeUser.name}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFFFA500),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                SizedBox(height: 5.h),

                // Question
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    "What do you want to do today?",
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFA500),
                    ),
                  ),
                ),

                const Spacer(),

                // Buttons
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 27.h),
                          backgroundColor: const Color(0xFFFFA500),
                        ),
                        child: Text(
                          "Start Camera",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 27.h),
                          backgroundColor: const Color(0xFFFFA500),
                        ),
                        child: Text(
                          "Setting",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      ElevatedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Row(
                                children: [
                                  const Icon(
                                    Icons.logout,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Xác nhận đăng xuất',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              content: const Text(
                                'Bạn có chắc chắn muốn đăng xuất không?',
                                style: TextStyle(fontSize: 14),
                              ),
                              actionsPadding: const EdgeInsets.only(
                                right: 16,
                                bottom: 10,
                              ),
                              actions: [
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey[700],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Không'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Có'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            // 👉 Xóa session
                            await clearUserSession();

                            // 👉 Quay lại màn hình nhận diện
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FacePreviewScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 27.h),
                          backgroundColor: const Color(0xFFFFA500),
                        ),
                        child: Text(
                          "Exit",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8.h),

                // Notification
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Text(
                    '123213123123123123123123123',
                    style: TextStyle(fontSize: 8.sp, color: Colors.red),
                  ),
                ),

                // Language
                // Trong Stack, sau SafeArea
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 3.w, bottom: 3.h),
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: 30.w,
                        maxWidth: 40.w,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE5B4),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: const Color(0xFFFFA500),
                          width: 1.w,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: "vi", // 👈 Default selected
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFFFFA500),
                            size: 10,
                          ),
                          dropdownColor: const Color(0xFFFFE5B4),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          items: const [
                            DropdownMenuItem(value: "en", child: Text("EN")),
                            DropdownMenuItem(value: "vi", child: Text("VI")),
                            DropdownMenuItem(value: "cn", child: Text("CN")),
                          ],
                          onChanged: (val) {
                            // handle language change
                          },
                        ),
                      ),
                    ),
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
