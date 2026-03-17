import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  // Kiểm tra xem thiết bị có hỗ trợ xác thực sinh trắc học không
  static Future<bool> canAuthenticate() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException catch (e) {
      print("Lỗi kiểm tra sinh trắc học: $e");
      return false;
    }
  }

  // Hàm chính để yêu cầu xác thực
  static Future<bool> authenticate(String reason) async {
    try {
      if (!await canAuthenticate()) return false;

      // --- THỬ GỌI HÀM THEO CÁCH TỐI GIẢN NHẤT ---
      // Chỉ truyền vào tham số bắt buộc localizedReason
      return await _auth.authenticate(
        localizedReason: reason, // Lý do hiển thị cho người dùng
      );

    } on PlatformException catch (e) {
      print("Lỗi xác thực: $e");
      return false;
    }
  }
}