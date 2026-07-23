import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/routes/app_router.dart';
import 'package:shoto/core/theme/app_theme.dart';
import 'firebase_options.dart'; // 👈 1. استيراد ملف الإعدادات المولد تلقائياً

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👈 2. تمرير إعدادات المنصة الحالية للفايربيس
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      // 👈 3. استخدام builder هنا ضروري جداً لتهيئة ScreenUtil بالشكل الصحيح
      builder: (context, child) {
        return MaterialApp.router(
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
        );
      },
    );
  }
}
