import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'screens/search_screen.dart';

void main()=>runApp(const SettlementApp());

class SettlementApp extends StatefulWidget {
  const SettlementApp({super.key});
  State<SettlementApp> createState()=>_SettlementAppState();
}
class _SettlementAppState extends State<SettlementApp>{
  bool dark=true; late ApiService api;
  void initState(){super.initState();const url=String.fromEnvironment('BACKEND_URL',defaultValue:'http://127.0.0.1:8000');api=ApiService(baseUrl:url);}
  Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'Settlement Q&A Agent',theme:AppTheme.light(),darkTheme:AppTheme.dark(),themeMode:dark?ThemeMode.dark:ThemeMode.light,home:SearchScreen(api:api,darkMode:dark,onThemeToggle:(v)=>setState(()=>dark=v)));
}
