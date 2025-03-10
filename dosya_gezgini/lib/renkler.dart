import 'package:flutter/material.dart';

class AppTheme extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;
  late bool isdarkmode = false;
  late IconData temaiconu = Icons.light_mode;
  ThemeData get theme {
    if (themeMode == ThemeMode.light) {
      isdarkmode = false;
      return lightMode;
    } else {
      isdarkmode = true;
      return darkMode;
    }
  }

  void changetheme() {
    if (themeMode == ThemeMode.light) {
      themeMode = ThemeMode.dark;
      isdarkmode = true;
      temaiconu = Icons.dark_mode;
      notifyListeners();
    } else {
      themeMode = ThemeMode.light;
      isdarkmode = false;
      temaiconu = Icons.light_mode;
      notifyListeners();
    }
  }

  /// **Açık Tema (Light Mode)**
  static final ThemeData lightMode = ThemeData(
    brightness: Brightness.light, // Tema parlaklığını açık mod olarak ayarlar
    primaryColor: AppColors.kuyupembe, // Uygulamanın ana rengini belirler
    secondaryHeaderColor: const Color.fromARGB(223, 255, 196, 210),
    scaffoldBackgroundColor:
        AppColors.koyuBeyaz, // Sayfanın arka plan rengini belirler

    appBarTheme: AppBarTheme(
      backgroundColor:
          AppColors
              .kuyupembe, // Uygulama çubuğunun (AppBar) arka plan rengini belirler
      titleTextStyle: const TextStyle(
        color: Colors.white, // AppBar başlık rengini beyaz yapar
        fontSize: 20, // Başlık yazı boyutunu ayarlar
        fontWeight: FontWeight.bold, // Başlık yazısını kalın yapar
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
      ), // AppBar'daki ikon rengini beyaz yapar
    ),

    iconTheme: IconThemeData(
      color:
          AppColors
              .koyuGri, // Genel ikon rengini koyu gri yapar (örn: klasör ikonları)
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor:
          AppColors
              .kuyupembe, // FAB (Floating Action Button) rengini kırmızı yapar
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor:
          AppColors
              .koyuBeyaz, // Alt navigasyon çubuğunun arka plan rengini belirler
      indicatorColor:
          AppColors.kuyupembe, // Seçili ikonun arka plan rengini belirler

      labelTextStyle: WidgetStateProperty.all(
        TextStyle(
          color:
              AppColors
                  .koyuGri, // Alt navigasyon etiketi (label) rengini koyu gri yapar
          fontSize: 12, // Etiket yazı boyutunu belirler
          fontWeight: FontWeight.bold, // Etiket yazısını kalın yapar
        ),
      ),

      iconTheme: WidgetStateProperty.all(
        IconThemeData(
          color: AppColors.koyuGri,
        ), // Seçili olmayan ikonların rengini koyu gri yapar
      ),
    ),

    textTheme: TextTheme(
      bodyLarge: TextStyle(
        color: AppColors.koyuGri,
        fontSize: 16,
      ), // Genel metin stilini belirler (büyük)
      bodyMedium: TextStyle(
        color: AppColors.koyuGri,
        fontSize: 12,
      ), // Genel metin stilini belirler (orta)
      titleLarge: TextStyle(
        color: AppColors.bordo, // Başlık yazılarının rengini bordo yapar
        fontSize: 18, // Başlık yazılarının boyutunu belirler
        fontWeight: FontWeight.bold, // Başlık yazılarını kalın yapar
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            AppColors
                .kuyupembe, // Yükseltilmiş butonların (ElevatedButton) arka plan rengini belirler
        foregroundColor:
            Colors.white, // Buton içindeki yazının rengini beyaz yapar
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ), // Buton köşelerini yuvarlatır
      ),
    ),

    cardTheme: CardTheme(
      color: AppColors.krem, // Kartların arka plan rengini krem yapar
      elevation: 2, // Kartın gölge yüksekliğini belirler (2px)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ), // Kart köşelerini yuvarlatır
    ),
  );

  /// **Koyu Tema (Dark Mode)**
  static final ThemeData darkMode = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.kuyupembe, // Koyu mavi - Ana Renk
    secondaryHeaderColor: const Color.fromARGB(255, 158, 110, 122),

    scaffoldBackgroundColor: AppColors.siyah, // Siyah arka plan
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.kuyupembe, // Koyu başlık rengi
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    iconTheme: IconThemeData(
      color: AppColors.acikGri, // İkonlar için açık gri
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.kuyupembe, // Koyu temada buton bordo
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.siyah, // Arka plan rengi siyah
      indicatorColor: AppColors.acikpembe, // Seçili ikon arkaplanı sarı
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(
          color: AppColors.acikpembe,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: WidgetStateProperty.all(
        IconThemeData(color: AppColors.acikpembe), // Seçilmemiş ikon gri
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: AppColors.acikGri, fontSize: 16),
      bodyMedium: TextStyle(color: AppColors.acikGri, fontSize: 12),
      titleLarge: TextStyle(
        color: AppColors.kirmizi, // Koyu temada vurgu rengi yeşil
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.acikpembe, // Buton kırmızı
        foregroundColor: AppColors.siyah,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.koyuGri, // Klasör kutuları koyu gri
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

class AppColors {
  static const Color acikpembe = Color(0xFFffc4d2);
  static const Color kuyupembe = Color(0xFFd791a2);
  static const Color kirmizi = Color(0xFFD6453D); // Kırmızı
  static const Color yesil = Color(0xFFA1C181); // Yeşil
  static const Color mavi = Color(0xFF5E97B7); // Açık Mavi (Ana renk)
  static const Color koyuMavi = Color(
    0xFF002B5C,
  ); // Koyu Mavi (Koyu mod ana renk)
  static const Color acikGri = Color(0xFFD1D1D1); // Açık gri
  static const Color koyuGri = Color(0xFF505050); // Koyu gri
  static const Color sari = Color(0xFFF4A261); // Sarı
  static const Color koyuBeyaz = Color(
    0xFFF2ECEC,
  ); // Açık Beyaz (Light Mode Arka Plan)
  static const Color siyah = Color(0xFF121212); // Siyah (Dark Mode Arka Plan)
  static const Color bordo = Color(0xFF7A1E1E); // Bordo
  static const Color krem = Color(
    0xFFF4E1C0,
  ); // Krem (Light Mode'da Kart Rengi)
}
