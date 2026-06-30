import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../providers/checklist_provider.dart';
import 'package:flutter/services.dart';
import '../models/wedding_category.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final categories = ref.watch(categoryProvider);
    final timelineChecklist = ref.watch(checklistProvider);

    final isLinked = authState.coupleInfo != null;
    final currentUser = authState.currentUser;
    final coupleInfo = authState.coupleInfo;

    final weddingDate = coupleInfo?.weddingDate;

    // D-Day 계산
    String dDayStr = 'D-기한 없음';
    if (weddingDate != null) {
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day);
      final end = DateTime(weddingDate.year, weddingDate.month, weddingDate.day);
      final diff = end.difference(start).inDays;
      dDayStr = diff == 0 ? 'D-Day' : (diff > 0 ? 'D-$diff' : 'D+${diff.abs()}');
    }

    // 전체 진행률 계산 (해당없음 제외)
    final activeCategories = categories.where((c) => c.status != PreparationStatus.skipped).toList();
    final total = activeCategories.length;
    final completed = activeCategories.where((c) => c.status == PreparationStatus.done).length;
    final inProgress = activeCategories.where((c) => c.status == PreparationStatus.inProgress).length;
    final progressPercentage = total > 0 ? ((completed / total) * 100).toInt() : 0;

    // 다가오는 일정 (최대 3개)
    final upcomingTasks = timelineChecklist
        .where((t) => !t.isDone)
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '안녕하세요, ${currentUser?.name ?? "사용자"}님',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF757575),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLinked ? '우리의 행복한 결혼 준비' : '파트너를 연결해 보세요',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD1D8)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite, size: 16, color: Color(0xFFFF5271)),
                        const SizedBox(width: 4),
                        Text(
                          isLinked ? '연동 완료' : '연동 대기 중',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF5271),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              GestureDetector(
                onTap: () async {
                  final initialDate = weddingDate ?? DateTime.now().add(const Duration(days: 180));
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    await ref.read(authProvider.notifier).updateWeddingDate(picked);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7B93), Color(0xFFFF5271)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5271).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dDayStr,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                          if (weddingDate != null)
                            Text(
                              DateFormat('yyyy년 MM월 dd일').format(weddingDate),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else
                            const Row(
                              children: [
                                Text(
                                  '터치하여 날짜 등록',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.edit_calendar_rounded, size: 16, color: Colors.white70),
                              ],
                            ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      '결혼 준비 진행률',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progressPercentage / 100,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$progressPercentage%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '완료 $completed건 / 진행 $inProgress건',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '남은 카테고리 ${total - completed}개',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

              // 파트너 연동 안내 (연동 안 되어있을 시)
              if (!isLinked) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.link, color: Color(0xFFFF5271)),
                          SizedBox(width: 8),
                          Text(
                            '파트너와 연동하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '초대 코드를 파트너 앱에 입력하면 예산, 일정 및 체크리스트가 실시간으로 동기화됩니다.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF757575),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE9ECEF)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '나의 초대 코드: ${currentUser?.inviteCode ?? ""}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: currentUser?.inviteCode ?? ''));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('초대 코드가 클립보드에 복사되었습니다.')),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 16, color: Color(0xFFFF5271)),
                              label: const Text(
                                '복사',
                                style: TextStyle(color: Color(0xFFFF5271), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            _showLinkCodeDialog(context, ref);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5271),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('초대 코드 입력하기', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // 다가오는 일정 체크리스트
              const Text(
                '우선순위 준비 항목',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 12),
              if (upcomingTasks.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      '모든 필수 준비 단계가 완료되었습니다! 🎉',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: upcomingTasks.length,
                  itemBuilder: (context, index) {
                    final task = upcomingTasks[index];
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F6F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.phase,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF5271),
                            ),
                          ),
                        ),
                        title: Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        trailing: Checkbox(
                          value: task.isDone,
                          activeColor: const Color(0xFFFF5271),
                          onChanged: (_) {
                            ref.read(checklistProvider.notifier).toggleTimelineTask(task.id);
                          },
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLinkCodeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _LinkCodeDialog(ref: ref),
    );
  }
}

// Memory-leak free Stateful Dialog Component
class _LinkCodeDialog extends StatefulWidget {
  final WidgetRef ref;
  const _LinkCodeDialog({required this.ref});

  @override
  State<_LinkCodeDialog> createState() => _LinkCodeDialogState();
}

class _LinkCodeDialogState extends State<_LinkCodeDialog> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        '파트너 코드 입력',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '파트너 화면에 보이는 3자리 초대 코드를 입력해 주세요.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLength: 3,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
            decoration: const InputDecoration(
              hintText: 'ABC',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () async {
            final success = await widget.ref
                .read(authProvider.notifier)
                .linkPartner(_textController.text.toUpperCase());
            if (context.mounted) {
              Navigator.pop(context);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('파트너와 성공적으로 연결되었습니다! 🎉')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('코드가 바르지 않습니다. 다시 입력해 주세요.')),
                );
              }
            }
          },
          child: const Text('연결하기', style: TextStyle(color: Color(0xFFFF5271), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
