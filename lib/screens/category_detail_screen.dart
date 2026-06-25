import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wedding_category.dart';
import '../providers/wedding_provider.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final String categoryId;

  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  late TextEditingController _notesController;
  late TextEditingController _estCostController;
  late TextEditingController _actCostController;
  late TextEditingController _vendorNameController;
  late TextEditingController _vendorPhoneController;
  PreparationStatus _status = PreparationStatus.none;

  @override
  void initState() {
    super.initState();
    final weddingState = ref.read(weddingProvider);
    final category = weddingState.categories.firstWhere((c) => c.id == widget.categoryId);

    _notesController = TextEditingController(text: category.notes);
    _estCostController = TextEditingController(text: category.estimatedCost.toString());
    _actCostController = TextEditingController(text: category.actualCost.toString());
    _vendorNameController = TextEditingController(text: category.vendorName);
    _vendorPhoneController = TextEditingController(text: category.vendorPhone);
    _status = category.status;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _estCostController.dispose();
    _actCostController.dispose();
    _vendorNameController.dispose();
    _vendorPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weddingState = ref.watch(weddingProvider);
    final category = weddingState.categories.firstWhere((c) => c.id == widget.categoryId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final estCost = int.tryParse(_estCostController.text) ?? 0;
              final actCost = int.tryParse(_actCostController.text) ?? 0;

              final updated = category.copyWith(
                status: _status,
                estimatedCost: estCost,
                actualCost: actCost,
                notes: _notesController.text,
                vendorName: _vendorNameController.text,
                vendorPhone: _vendorPhoneController.text,
                updatedBy: weddingState.currentUser?.name ?? '사용자',
                updatedAt: DateTime.now(),
              );

              ref.read(weddingProvider.notifier).updateCategory(updated);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('준비 정보가 저장되었습니다! 💾')),
              );
            },
            child: const Text(
              '저장',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF5271), fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 진행 상태 셀렉터
            const Text(
              '진행 상태',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: PreparationStatus.values.map((status) {
                final isSelected = _status == status;
                Color statusColor = const Color(0xFF757575);
                Color selectedBg = const Color(0xFFEEEEEE);

                if (status == PreparationStatus.inProgress) {
                  statusColor = const Color(0xFFFF9800);
                  selectedBg = const Color(0xFFFFF3E0);
                } else if (status == PreparationStatus.done) {
                  statusColor = const Color(0xFFFF5271);
                  selectedBg = const Color(0xFFFFF0F2);
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _status = status;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? selectedBg : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? statusColor : const Color(0xFFDDDDDD),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          status.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? statusColor : const Color(0xFF757575),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 예산 항목
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '예상 금액 (원)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _estCostController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '예상 지출액',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '실제 금액 (원)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _actCostController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '실제 지출액',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 업체 연락처 정보
            const Text(
              '계약 업체 정보',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _vendorNameController,
                    decoration: const InputDecoration(
                      labelText: '업체명 / 담당자 이름',
                      prefixIcon: Icon(Icons.business, color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(),
                  TextField(
                    controller: _vendorPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: '연락처 (전화번호)',
                      prefixIcon: Icon(Icons.phone, color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 자유 메모
            const Text(
              '메모 및 기록',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '계약 조건, 미팅 날짜, 드레스 스타일 등 자유롭게 메모해 두세요.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
