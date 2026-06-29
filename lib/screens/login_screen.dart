import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFE5EC), // Very soft pink
                  Colors.white,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  // App Logo / Symbol
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5271).withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 64,
                        color: Color(0xFFFF5271),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Title
                  const Text(
                    'Wedding Planner',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  const Text(
                    '우리의 특별한 하루를 위한 완벽한 동반자\n서로를 연결하여 실시간으로 결혼 준비를 함께 해보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF7F8C8D),
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  // Social Login Buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Google Sign In Button
                      _SocialLoginButton(
                        icon: Icons.g_mobiledata_rounded,
                        text: 'Google 계정으로 계속하기',
                        textColor: const Color(0xFF2C3E50),
                        backgroundColor: Colors.white,
                        onPressed: () async {
                          final success = await ref.read(authProvider.notifier).signInWithGoogle();
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('구글 로그인에 실패했습니다. 다시 시도해 주세요.')),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      // Apple Sign In Button
                      _SocialLoginButton(
                        icon: Icons.apple_rounded,
                        text: 'Apple ID로 계속하기',
                        textColor: Colors.white,
                        backgroundColor: Colors.black,
                        onPressed: () async {
                          final success = await ref.read(authProvider.notifier).signInWithApple();
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('애플 로그인에 실패했습니다. 다시 시도해 주세요.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
          // Loading Overlay
          if (authState.isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5271)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color textColor;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _SocialLoginButton({
    required this.icon,
    required this.text,
    required this.textColor,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
