import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const navy=Color(0xFF09111F), surface=Color(0xFF111B2C), surface2=Color(0xFF172337);
  static const teal=Color(0xFF20D6C7), amber=Color(0xFFF4B740), red=Color(0xFFFF6B7A), green=Color(0xFF55D68B), blue=Color(0xFF70A7FF);

  static ThemeData dark(){
    final b=ThemeData.dark(useMaterial3:true);
    return b.copyWith(
      scaffoldBackgroundColor:navy,
      colorScheme:const ColorScheme.dark(primary:teal,secondary:amber,surface:surface,error:red),
      textTheme:GoogleFonts.interTextTheme(b.textTheme).apply(bodyColor:Colors.white,displayColor:Colors.white),
      cardTheme:CardThemeData(color:surface,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22))),
      inputDecorationTheme:InputDecorationTheme(
        filled:true,fillColor:surface,
        border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none),
        enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide(color:Colors.white10)),
        focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:const BorderSide(color:teal)),
      ),
      chipTheme:b.chipTheme.copyWith(backgroundColor:surface2,selectedColor:teal.withOpacity(.18)),
    );
  }
  static ThemeData light()=>dark().copyWith(scaffoldBackgroundColor:const Color(0xFFF3F6FA),colorScheme:ColorScheme.fromSeed(seedColor:teal,brightness:Brightness.light),cardTheme:CardThemeData(color:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22))));
}
