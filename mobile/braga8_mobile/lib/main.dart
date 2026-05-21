import 'package:braga8_mobile/ApiService.dart';
import 'package:braga8_mobile/views/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart'; 

final ApiService apiService = ApiService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  await requestPermissions();
  
  runApp(const MyApp());
}

Future<void> requestPermissions() async {
  await [
    Permission.camera,
    Permission.locationWhenInUse,
    Permission.photos,
    Permission.notification,
  ].request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter(apiService);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Braga 8 System',
      theme: ThemeData(fontFamily: 'SFUIDisplay'),
      initialRoute: '/',
      onGenerateRoute: router.onGenerateRoute,
    );
  }
}