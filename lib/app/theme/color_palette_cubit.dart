import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppColorPalette {
  greenYellow,
  blueWhite,
  sunsetPeach,
  mintCream,
  oceanSlate,
}

extension AppColorPaletteX on AppColorPalette {
  String get storageValue {
    switch (this) {
      case AppColorPalette.greenYellow:
        return 'green_yellow';
      case AppColorPalette.blueWhite:
        return 'blue_white';
      case AppColorPalette.sunsetPeach:
        return 'sunset_peach';
      case AppColorPalette.mintCream:
        return 'mint_cream';
      case AppColorPalette.oceanSlate:
        return 'ocean_slate';
    }
  }

  String get displayName {
    switch (this) {
      case AppColorPalette.greenYellow:
        return 'Xanh lá - vàng';
      case AppColorPalette.blueWhite:
        return 'Xanh dương - trắng';
      case AppColorPalette.sunsetPeach:
        return 'Hoàng hôn đào';
      case AppColorPalette.mintCream:
        return 'Bạc hà - kem';
      case AppColorPalette.oceanSlate:
        return 'Biển đêm';
    }
  }

  String get description {
    switch (this) {
      case AppColorPalette.greenYellow:
        return 'Gam màu tươi, tạo cảm giác năng lượng và tập trung.';
      case AppColorPalette.blueWhite:
        return 'Gam màu dịu mắt, tối giản và cân bằng.';
      case AppColorPalette.sunsetPeach:
        return 'Tông cam hồng ấm, tạo cảm giác tích cực và gần gũi.';
      case AppColorPalette.mintCream:
        return 'Sắc bạc hà sáng, nhẹ nhàng và thư giãn khi học lâu.';
      case AppColorPalette.oceanSlate:
        return 'Xanh biển trầm hiện đại, tập trung và rõ tương phản.';
    }
  }
}

class ColorPaletteCubit extends Cubit<AppColorPalette> {
  ColorPaletteCubit() : super(AppColorPalette.greenYellow);

  static const String _prefsKey = 'app_color_palette';

  Future<void> loadPalette() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == null) {
      return;
    }

    emit(_deserialize(saved));
  }

  Future<void> setPalette(AppColorPalette palette) async {
    emit(palette);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, palette.storageValue);
  }

  static AppColorPalette _deserialize(String value) {
    switch (value) {
      case 'ocean_slate':
        return AppColorPalette.oceanSlate;
      case 'mint_cream':
        return AppColorPalette.mintCream;
      case 'sunset_peach':
        return AppColorPalette.sunsetPeach;
      case 'blue_white':
        return AppColorPalette.blueWhite;
      case 'green_yellow':
      default:
        return AppColorPalette.greenYellow;
    }
  }
}
