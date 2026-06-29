import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  String? _selectedGender; // 'male' | 'female'
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '프로필 설정',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authProvider);

          return Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          '결혼 준비를 시작하기 위해\n본인의 프로필 정보를 설정해 주세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Name Input
                        const Text(
                          '이름',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: '이름을 입력해 주세요.',
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFFF5271), width: 1.5),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '이름은 필수 입력 항목입니다.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Gender Select
                        const Text(
                          '성별',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _GenderCard(
                                title: '남성',
                                isSelected: _selectedGender == 'male',
                                icon: Icons.male_rounded,
                                activeColor: const Color(0xFFFF5271),
                                onTap: () {
                                  setState(() {
                                    _selectedGender = 'male';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _GenderCard(
                                title: '여성',
                                isSelected: _selectedGender == 'female',
                                icon: Icons.female_rounded,
                                activeColor: const Color(0xFFFF5271),
                                onTap: () {
                                  setState(() {
                                    _selectedGender = 'female';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 64),

                        // Submit Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                if (_selectedGender == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('성별을 선택해 주세요.')),
                                  );
                                  return;
                                }

                                final success = await ref.read(authProvider.notifier).signUpProfile(
                                  name: _nameController.text.trim(),
                                  gender: _selectedGender!,
                                );

                                if (!success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('프로필 등록에 실패했습니다. 다시 시도해 주세요.')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5271),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '시작하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
          );
        },
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final IconData icon;
  final Color activeColor;
  final VoidCallback onTap;

  const _GenderCard({
    required this.title,
    required this.isSelected,
    required this.icon,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.06) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? activeColor : const Color(0xFFBDC3C7),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : const Color(0xFF7F8C8D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
