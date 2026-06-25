import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/wedding_provider.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weddingState = ref.watch(weddingProvider);

    int estimatedTotal = 0;
    int actualTotal = 0;

    for (var cat in weddingState.categories) {
      estimatedTotal += cat.estimatedCost;
      actualTotal += cat.actualCost;
    }

    final goal = weddingState.coupleInfo?.budgetGoal ?? 35000000;
    final remains = goal - actualTotal;

    // 그룹별 비용 정보
    final Map<String, int> groupCostMap = {};
    for (var cat in weddingState.categories) {
      groupCostMap.update(cat.groupName, (val) => val + cat.actualCost, ifAbsent: () => cat.actualCost);
    }

    // 파이차트 섹션 만들기
    List<PieChartSectionData> sections = [];
    final colors = [
      const Color(0xFFFF5271),
      const Color(0xFFFF9800),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
    ];
    int colorIdx = 0;

    groupCostMap.forEach((groupName, cost) {
      if (cost > 0) {
        sections.add(
          PieChartSectionData(
            value: cost.toDouble(),
            title: groupName,
            color: colors[colorIdx % colors.length],
            radius: 50,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
        colorIdx++;
      }
    });

    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          value: 1,
          title: '비용 없음',
          color: Colors.grey[300],
          radius: 50,
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        title: const Text('예산 관리', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 전체 현황 카드
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                children: [
                  _buildBudgetRow('목표 예산', '${_formatPrice(goal)}원', Colors.black, true),
                  const Divider(height: 24),
                  _buildBudgetRow('예상 금액 합계', '${_formatPrice(estimatedTotal)}원', Colors.grey, false),
                  const SizedBox(height: 8),
                  _buildBudgetRow('실제 지출 합계', '${_formatPrice(actualTotal)}원', const Color(0xFFFF5271), true),
                  const Divider(height: 24),
                  _buildBudgetRow(
                    remains >= 0 ? '남은 예산 여유' : '예산 초과 경고',
                    '${_formatPrice(remains.abs())}원',
                    remains >= 0 ? Colors.blue : Colors.red,
                    true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              '지출 카테고리 비율',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
            ),
            const SizedBox(height: 20),
            // 파이차트
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 그룹별 상세 금액 목록
            const Text(
              '그룹별 지출 요약',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
            ),
            const SizedBox(height: 12),
            ...groupCostMap.entries.map((entry) {
              return Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: ListTile(
                  title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text(
                    '${_formatPrice(entry.value)}원',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetRow(String title, String price, Color color, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF555555),
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
