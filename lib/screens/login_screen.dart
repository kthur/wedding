import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': '실시간 커플 연동',
      'description': '서로를 연결하여 실시간으로 결혼 예산, 일정 및 체크리스트를 공유하고 함께 관리해 보세요.',
      'icon': 'favorite',
    },
    {
      'title': '스마트 예산 설계',
      'description': '카테고리별 예상 지출과 실제 지출을 직관적인 그래프로 파악하고 효율적으로 예산을 분담하세요.',
      'icon': 'account_balance_wallet',
    },
    {
      'title': '준비 일정 & 사진 기록',
      'description': '타임라인 체크리스트로 일정을 놓치지 않고, 계약서와 영수증 사진을 안전하게 기록 보관하세요.',
      'icon': 'assignment_turned_in',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // PageView Walkthrough
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _onboardingData.length,
                      itemBuilder: (context, index) {
                        final data = _onboardingData[index];
                        IconData iconData = Icons.favorite_rounded;
                        if (data['icon'] == 'account_balance_wallet') {
                          iconData = Icons.account_balance_wallet_rounded;
                        } else if (data['icon'] == 'assignment_turned_in') {
                          iconData = Icons.assignment_turned_in_rounded;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF5271).withValues(alpha: 0.15),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  iconData,
                                  size: 64,
                                  color: const Color(0xFFFF5271),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                data['title']!,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                data['description']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF7F8C8D),
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFFFF5271)
                              : const Color(0xFFFF5271).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

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
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Loading Overlay
          if (authState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
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
            color: Colors.black.withValues(alpha: 0.05),
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
