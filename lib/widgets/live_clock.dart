import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LiveClock extends StatefulWidget {
  const LiveClock({super.key});

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm:ss').format(_now);
    final dateStr = DateFormat('dd/MM/yyyy').format(_now);

    return Column(
      children: [
        Text(
          timeStr,
          style: TextStyle(
            color: const Color(0xFFFFA500),
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        // SizedBox(height: 2.h),
        // Text(
        //   dateStr,
        //   style: TextStyle(
        //     color: const Color(0xFFFFA500),
        //     fontSize: 11.sp,
        //     fontWeight: FontWeight.w500,
        //   ),
        // ),
      ],
    );
  }
}
