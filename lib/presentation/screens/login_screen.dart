import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qlnh_app/logic/blocs/auth/auth_bloc.dart';
import 'package:qlnh_app/data/models/user_model.dart';
import 'package:qlnh_app/data/services/api_service.dart';
import 'package:qlnh_app/data/services/biometric_service.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:simple_animations/simple_animations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// === WIDGET NÚT BẤM ĐÃ SỬA LỖI (Bỏ InkWell) ===
class AnimatedNumberButton extends StatefulWidget {
  final String value;
  final VoidCallback onPressed;

  const AnimatedNumberButton({
    super.key,
    required this.value,
    required this.onPressed,
  });

  @override
  State<AnimatedNumberButton> createState() => _AnimatedNumberButtonState();
}

class _AnimatedNumberButtonState extends State<AnimatedNumberButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector( // Chỉ dùng GestureDetector
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed(); // Gọi callback khi thả tay
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale( // Widget tự động tạo hiệu ứng scale
        scale: _isPressed ? 0.9 : 1.0, // Scale nhỏ lại khi nhấn
        duration: const Duration(milliseconds: 100),
        // Dùng Container thay cho Material + InkWell
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias, // Vẫn giữ clip
          child: Center(
            child: Text(
              widget.value,
              style: TextStyle(fontSize: 32, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w400),
            ),
          ),
        ),
      ),
    );
  }
}
// ===============================================

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  String _pin = '';
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String value) {
    HapticFeedback.lightImpact();
    if (_pin.length < 4) {
      setState(() { _pin += value; });
      if (_pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), _onLoginPressed);
      }
    }
  }

  void _onDeletePressed() {
    HapticFeedback.lightImpact();
    if (_pin.isNotEmpty) {
      setState(() { _pin = _pin.substring(0, _pin.length - 1); });
    }
  }

  void _onLoginPressed() {
    if (_pin.length == 4) {
      context.read<AuthBloc>().add(LoginRequested(_pin));
    }
  }

  // --- Các hàm _showMasterPinDialog và _triggerBiometricAuth giữ nguyên ---
  void _showMasterPinDialog(UserModel adminUser) {
    final masterPinController = TextEditingController();
    final theme = Theme.of(context); // Lấy theme

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          // === Dùng màu từ Theme ===
          backgroundColor: theme.colorScheme.surface, // Nền dialog
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.shield_outlined, color: theme.colorScheme.primary), // Màu primary
              // === THÊM CONST ===
              const SizedBox(width: 12),
              Text('Xác thực Admin', style: TextStyle(color: theme.colorScheme.onSurface)), // Màu chữ trên nền
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Xin chào, ${adminUser.name}.\nVui lòng nhập Master PIN để tiếp tục.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant), // Màu chữ phụ
              ),
              // === THÊM CONST ===
              const SizedBox(height: 24),
              TextField(
                controller: masterPinController,
                obscureText: true,
                autofocus: true,
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18), // Màu chữ
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: 'Master PIN',
                  // labelStyle: TextStyle(color: Colors.grey.shade400), // Sẽ tự lấy từ theme
                  // filled: true, // Đã đặt trong theme
                  // fillColor: Colors.black.withOpacity(0.2), // Đã đặt trong theme
                  // === THÊM CONST + Dùng màu từ theme ===
                  prefixIcon: Icon(Icons.password_outlined, color: theme.colorScheme.onSurfaceVariant),
                  // enabledBorder / focusedBorder sẽ tự lấy style từ theme
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthBloc>().add(LogoutRequested());
                setState(() { _pin = ''; });
              },
              // === THÊM CONST + Dùng màu từ theme ===
              child: Text('Hủy', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary, // Màu primary
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final masterPin = masterPinController.text;
                if (masterPin.isNotEmpty) {
                  context.read<AuthBloc>().add(VerifyAdminRequested(
                    userId: adminUser.id,
                    masterPin: masterPin,
                  ));
                  Navigator.of(dialogContext).pop();
                }
              },
              // === THÊM CONST ===
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }
  void _triggerBiometricAuth(UserModel adminUser) async {
    bool canAuth = await BiometricService.canAuthenticate();
    final theme = Theme.of(context); // Lấy theme
    if (!canAuth && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Thiết bị không hỗ trợ xác thực sinh trắc học.'), backgroundColor: theme.colorScheme.secondary), // <<< Dùng màu secondary (cam)
      );
      context.read<AuthBloc>().add(LogoutRequested());
      setState(() { _pin = ''; });
      return;
    }

    final isAuthenticated = await BiometricService.authenticate(
        'Quét vân tay hoặc khuôn mặt để xác thực quyền Admin'
    );

    if (mounted && isAuthenticated) {
      try {
        final userWithToken = await context.read<ApiService>().completeAdminLogin(adminUser.id);
        context.read<AuthBloc>().emit(AuthState(
            status: AuthStatus.authenticated,
            user: userWithToken
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi hoàn tất đăng nhập: $e'), backgroundColor: theme.colorScheme.error), // <<< Dùng màu error
        );
        context.read<AuthBloc>().add(LogoutRequested());
        setState(() { _pin = ''; });
      }

    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        // === THÊM CONST ===
        SnackBar(content: const Text('Xác thực sinh trắc học thất bại.'), backgroundColor: theme.colorScheme.error), // <<< Dùng màu error
      );
      context.read<AuthBloc>().add(LogoutRequested());
      setState(() { _pin = ''; });
    }
  }
  // -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final tween = MovieTween()
      ..tween('color1', ColorTween(begin: colorScheme.surface, end: colorScheme.background), duration: const Duration(seconds: 4))
      ..tween('color2', ColorTween(begin: colorScheme.background, end: colorScheme.surface), duration: const Duration(seconds: 4));

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: PlayAnimationBuilder<Movie>(
              tween: tween,
              duration: tween.duration,
              builder: (context, value, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [ value.get('color1'), value.get('color2') ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state.status == AuthStatus.adminBiometricRequired && state.user != null) {
                  _triggerBiometricAuth(state.user!);
                }
                else if (state.status == AuthStatus.adminVerificationRequired && state.user != null) {
                  _showMasterPinDialog(state.user!);
                  setState(() { _pin = ''; });
                }
                else if ((state.status == AuthStatus.unauthenticated || (state.status == AuthStatus.adminVerificationRequired && state.errorMessage.isNotEmpty)) && state.errorMessage.isNotEmpty) {
                  _shakeController.forward(from: 0.0);
                  setState(() { _pin = ''; });
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: ${state.errorMessage}'),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                }
              },
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rice_bowl_outlined, color: colorScheme.primary, size: 64)
                            .animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
                        const SizedBox(height: 24),
                        Text(
                          'POS Pro',
                          style: textTheme.headlineLarge?.copyWith(
                            color: colorScheme.onSurface, fontWeight: FontWeight.bold, letterSpacing: 3,
                          ),
                        ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
                        const SizedBox(height: 8),
                        Text(
                          'Vui lòng nhập mã PIN',
                          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                        ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
                      ],
                    ),
                  ),
                  _buildPinDisplay(),
                  const SizedBox(height: 24),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (state.status == AuthStatus.inProgress) {
                        return SizedBox(height: 24, child: CircularProgressIndicator(color: colorScheme.onSurface));
                      }
                      return const SizedBox(height: 24);
                    },
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: GridView.count(
                        crossAxisCount: 3, mainAxisSpacing: 16, crossAxisSpacing: 16,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          ...List.generate(9, (index) => AnimatedNumberButton(
                            value: '${index + 1}',
                            onPressed: () => _onNumberPressed('${index + 1}'),
                          )),
                          const SizedBox(), // Placeholder
                          AnimatedNumberButton(
                            value: '0',
                            onPressed: () => _onNumberPressed('0'),
                          ),
                          _buildIconButton(Icons.backspace_outlined, _onDeletePressed),
                        ],
                      ),
                    ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 500.ms, curve: Curves.easeOut),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPinDisplay() {
    final colorScheme = Theme.of(context).colorScheme; // Lấy theme

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final sine = math.sin(math.pi * 6 * _shakeController.value);
        return Transform.translate( offset: Offset(sine * 10, 0), child: child );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          bool isActive = index < _pin.length;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? colorScheme.primary : colorScheme.surfaceVariant,
              boxShadow: [
                if (isActive)
                  BoxShadow( color: colorScheme.primary.withOpacity(0.5), blurRadius: 10, spreadRadius: 2 )
              ],
            ),
          );
        }),
      ).animate().fadeIn(duration: 600.ms, delay: 500.ms), // <<<--- DẤU ';' ĐÃ ĐƯỢC THÊM
    );
  }

  // --- Widget Nút Icon (Giữ nguyên) ---
  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    final theme = Theme.of(context); // Lấy theme
    // === SỬA LẠI: Dùng GestureDetector + AnimatedScale giống nút số ===
    bool _isPressed = false; // Cần quản lý state nhấn
    return StatefulBuilder( // Dùng StatefulBuilder để quản lý _isPressed cục bộ
        builder: (context, setBtnState) {
          return GestureDetector(
            onTapDown: (_) => setBtnState(() => _isPressed = true),
            onTapUp: (_) {
              setBtnState(() => _isPressed = false);
              onPressed();
            },
            onTapCancel: () => setBtnState(() => _isPressed = false),
            child: AnimatedScale(
              scale: _isPressed ? 0.9 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Container( // Dùng Container thay Material
                decoration: const BoxDecoration(
                  color: Colors.transparent, // Nền trong suốt
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(
                  child: Icon(icon, size: 28, color: theme.colorScheme.onSurface),
                ),
              ),
            ),
          );
        }
    );
    // =============================================================
  }
}