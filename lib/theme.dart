import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // 定义主色调
  static const Color primaryColor = Color(0xFF926B62);
  // 定义应用的全局背景色（极浅的暖白/灰白，让主色更突出）
  static const Color scaffoldBackgroundColor = Color(0xFFFDFBFB);

  static ThemeData get flatTheme {
    return ThemeData(
      useMaterial3: true,

      // 1. 全局色彩方案
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        // 次要颜色，可以稍微亮一点或暗一点，这里保持同频
        secondary: primaryColor.withValues(alpha: 0.8),
        surface: Colors.white,
      ),

      scaffoldBackgroundColor: scaffoldBackgroundColor,

      // 2. 导航栏 (AppBar)：改为主题色背景，白色文字
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      // 3. 卡片 (Card)：用细边框代替阴影
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          // 使用主色的 20% 透明度作为极细的描边，保持平面感
          side: BorderSide(
            color: primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),

      // 4. 实心按钮 (ElevatedButton)：纯色块，无阴影
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0, // 去除阴影
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48), // 默认大按钮
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // 5. 文本按钮 (TextButton)：用于次要操作
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // 6. 输入框 (TextField / TextFormField)：干净的底色填充，聚焦时才有主色边框
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        // 默认状态无边框
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        // 聚焦状态显示主色边框
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        // 提示文字颜色
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),

      // 7. 分割线 (Divider)：极细，颜色极浅
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 0.5,
        color: primaryColor.withValues(alpha: 0.1),
      ),
    );
  }
}
