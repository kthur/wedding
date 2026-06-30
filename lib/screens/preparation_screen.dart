import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wedding_category.dart';
import '../providers/category_provider.dart';
import '../providers/checklist_provider.dart';
import 'category_detail_screen.dart';

class PreparationScreen extends ConsumerStatefulWidget {
  const PreparationScreen({super.key});

  @override
  ConsumerState<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends ConsumerState<PreparationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final timelineChecklist = ref.watch(checklistProvider);

    // 그룹별 카테고리 묶기
    final Map<String, List<WeddingCategory>> groupMap = {};
    for (var cat in categories) {
      groupMap.putIfAbsent(cat.groupName, () => []).add(cat);
    }

    // 시기별 할 일 묶기
    final Map<String, List<dynamic>> phaseMap = {
      'D-6m': [],
      'D-5m': [],
      'D-3m': [],
      'D-1m': [],
      'D-2w': [],
    };
    for (var task in timelineChecklist) {
      if (phaseMap.containsKey(task.phase)) {
        phaseMap[task.phase]!.add(task);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        title: const Text(
          '결혼 준비',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF5271),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFF5271),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: '카테고리별'),
            Tab(text: '시기별 D-Day'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 📁 카테고리별 뷰
          ListView(
            padding: const EdgeInsets.all(16),
            children: groupMap.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF5271)),
                    ),
                  ),
                  ...entry.value.map((cat) {
                    Color statusColor = Colors.grey;
                    if (cat.status == PreparationStatus.inProgress) {
                      statusColor = Colors.orange;
                    } else if (cat.status == PreparationStatus.done) {
                      statusColor = const Color(0xFFFF5271);
                    } else if (cat.status == PreparationStatus.skipped) {
                      statusColor = const Color(0xFF9E9E9E);
                    }

                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryDetailScreen(categoryId: cat.id),
                            ),
                          );
                        },
                        title: Text(
                          cat.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                cat.status.displayName,
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (cat.actualCost > 0)
                              Text(
                                '실제금액: ${_formatPrice(cat.actualCost)}원',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              )
                            else if (cat.estimatedCost > 0)
                              Text(
                                '예상금액: ${_formatPrice(cat.estimatedCost)}원',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              )
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],
              );
            }).toList(),
          ),

          // 📅 시기별 체크리스트 뷰
          ListView(
            padding: const EdgeInsets.all(16),
            children: phaseMap.entries.map((entry) {
              String headerTitle = '';
              switch (entry.key) {
                case 'D-6m':
                  headerTitle = '결혼 준비 시작 ~ D-6개월 전 (뼈대 구축)';
                  break;
                case 'D-5m':
                  headerTitle = 'D-5개월 ~ D-4개월 전 (외모/촬영 준비)';
                  break;
                case 'D-3m':
                  headerTitle = 'D-3개월 ~ D-2개월 전 (세부 예약)';
                  break;
                case 'D-1m':
                  headerTitle = 'D-1개월 전 (최종 점검 & 부케)';
                  break;
                case 'D-2w':
                  headerTitle = 'D-2주 전 ~ 결혼식 당일';
                  break;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      headerTitle,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
                    ),
                  ),
                  ...entry.value.map((task) {
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      child: CheckboxListTile(
                        value: task.isDone,
                        activeColor: const Color(0xFFFF5271),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14,
                            decoration: task.isDone ? TextDecoration.lineThrough : null,
                            color: task.isDone ? Colors.grey : const Color(0xFF333333),
                          ),
                        ),
                        onChanged: (_) {
                          ref.read(checklistProvider.notifier).toggleTimelineTask(task.id);
                        },
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
