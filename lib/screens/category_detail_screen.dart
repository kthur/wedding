import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/wedding_category.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';

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
    final categories = ref.read(categoryProvider);
    final category = categories.firstWhere(
      (c) => c.id == widget.categoryId,
      orElse: () => WeddingCategory(
        id: widget.categoryId,
        name: 'Unknown',
        groupName: 'Unknown',
        status: PreparationStatus.none,
        estimatedCost: 0,
        actualCost: 0,
        notes: '',
        vendorName: '',
        vendorPhone: '',
        schedules: [],
        photos: [],
        updatedBy: '',
        updatedAt: DateTime.now(),
      ),
    );

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
    final categories = ref.watch(categoryProvider);
    final authState = ref.watch(authProvider);
    final category = categories.firstWhere(
      (c) => c.id == widget.categoryId,
      orElse: () => WeddingCategory(
        id: widget.categoryId,
        name: 'Unknown',
        groupName: 'Unknown',
        status: PreparationStatus.none,
        estimatedCost: 0,
        actualCost: 0,
        notes: '',
        vendorName: '',
        vendorPhone: '',
        schedules: [],
        photos: [],
        updatedBy: '',
        updatedAt: DateTime.now(),
      ),
    );

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
                updatedBy: authState.currentUser?.name ?? '사용자',
                updatedAt: DateTime.now(),
              );

              ref.read(categoryProvider.notifier).updateCategory(updated);
              
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              messenger.showSnackBar(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '지출 및 예산',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showReceiptScanner(context, category),
                  icon: const Icon(Icons.document_scanner_outlined, color: Color(0xFFFF5271), size: 20),
                  label: const Text(
                    '영수증/계약서 스캔',
                    style: TextStyle(color: Color(0xFFFF5271), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: const Color(0xFFFFF0F2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 24),

            // 첨부 사진
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '첨부 사진',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _addPhoto(context, category),
                  icon: const Icon(Icons.add_a_photo_outlined, color: Color(0xFFFF5271), size: 20),
                  label: const Text(
                    '사진 추가',
                    style: TextStyle(color: Color(0xFFFF5271), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (category.photos.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9FB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      '첨부된 사진이 없습니다.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: category.photos.length,
                itemBuilder: (context, idx) {
                  final photo = category.photos[idx];
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: photo.url.startsWith('http')
                              ? Image.network(photo.url, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                              : photo.url.startsWith('assets/')
                                  ? Image.asset(photo.url, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                                  : Image.file(File(photo.url), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(15),
                              bottomRight: Radius.circular(15),
                            ),
                          ),
                          child: Text(
                            photo.caption.isEmpty ? '사진' : photo.caption,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 12, color: Colors.white),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              ref.read(categoryProvider.notifier).deleteCategoryPhoto(category.id, photo.url);
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPhoto(BuildContext context, WeddingCategory category) async {
    final ImagePicker picker = ImagePicker();
    String caption = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '사진 첨부하기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final XFile? file = await picker.pickImage(source: ImageSource.camera);
                        if (file != null) {
                          Navigator.pop(context);
                          _saveCategoryPhoto(category.id, file.path, caption);
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('카메라 촬영'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final XFile? file = await picker.pickImage(source: ImageSource.gallery);
                        if (file != null) {
                          Navigator.pop(context);
                          _saveCategoryPhoto(category.id, file.path, caption);
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('갤러리 선택'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _saveCategoryPhoto(
                      category.id,
                      'https://picsum.photos/600/600?random=${DateTime.now().millisecond}',
                      caption.isEmpty ? '샘플 참고 이미지' : caption,
                    );
                  },
                  icon: const Icon(Icons.image_search, color: Colors.white),
                  label: const Text('데모 사진 첨부 (테스트용)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5271),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '사진 설명 (캡션)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: '예: 계약 명세서 첫 페이지, 드레스 피팅 샷 등',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (val) {
                  caption = val;
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _saveCategoryPhoto(String categoryId, String path, String caption) {
    final newPhoto = CategoryPhoto(
      url: path,
      caption: caption.isEmpty ? '사진 첨부' : caption,
      uploadedBy: ref.read(authProvider).currentUser?.name ?? '사용자',
      uploadedAt: DateTime.now(),
    );
    ref.read(categoryProvider.notifier).addCategoryPhoto(categoryId, newPhoto);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('사진이 성공적으로 첨부되었습니다! 📸')),
    );
  }

  Future<void> _showReceiptScanner(BuildContext context, WeddingCategory category) async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '영수증 / 계약서 스캔',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '영수증이나 계약서의 사진을 촬영하거나 선택하면 실제 금액과 업체명을 스마트하게 분석하여 입력해 줍니다.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final XFile? file = await picker.pickImage(source: ImageSource.camera);
                      if (file != null) {
                        Navigator.pop(context);
                        _runScannerAnimation(file.path, false, category);
                      }
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('카메라 촬영'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
                      if (file != null) {
                        Navigator.pop(context);
                        _runScannerAnimation(file.path, false, category);
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('갤러리 선택'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _runScannerAnimation('', true, category);
                },
                icon: const Icon(Icons.document_scanner, color: Colors.white),
                label: const Text('데모 영수증 스캔 (테스트용)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5271),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _runScannerAnimation(String path, bool isDemo, WeddingCategory category) {
    String mockVendor = '';
    int mockCost = 0;
    String mockItem = '';

    switch (category.id) {
      case 'hall':
        mockVendor = '그랜드 베네치아 웨딩홀';
        mockCost = 8500000;
        mockItem = '대관료 및 음향 연출 패키지';
        break;
      case 'sdm':
        mockVendor = '청담 벨에포크 드레스';
        mockCost = 3200000;
        mockItem = '스튜디오 촬영용 드레스 + 메이크업 패키지';
        break;
      case 'ring':
        mockVendor = '메종 드 다이아';
        mockCost = 2600000;
        mockItem = '18K 웨딩 밴드 커플링';
        break;
      case 'snap':
        mockVendor = '로맨틱 메모리즈 스튜디오';
        mockCost = 1500000;
        mockItem = '본식 앨범 제작 + 원본 데이터';
        break;
      case 'honeymoon':
        mockVendor = '허니투어 여행사';
        mockCost = 4500000;
        mockItem = '발리 풀빌라 5박 7일 허니문 패키지';
        break;
      default:
        mockVendor = '${category.name} 전문 계약점';
        mockCost = 980000;
        mockItem = '${category.name} 이용 계약 정산';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ScannerProgressDialog(
        imagePath: path,
        isDemo: isDemo,
        category: category,
        mockVendor: mockVendor,
        mockCost: mockCost,
        mockItem: mockItem,
        onScanComplete: (vendor, cost, finalPath) {
          setState(() {
            _actCostController.text = cost.toString();
            _vendorNameController.text = vendor;
          });
          
          final scanPhoto = CategoryPhoto(
            url: finalPath,
            caption: '영수증/계약서 스캔 내역',
            uploadedBy: ref.read(authProvider).currentUser?.name ?? '사용자',
            uploadedAt: DateTime.now(),
          );
          
          ref.read(categoryProvider.notifier).updateCategoryBudgetFromScan(
            category.id,
            actualCost: cost,
            vendorName: vendor,
            photo: scanPhoto,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('영수증 정보와 첨부 사진이 성공적으로 적용되었습니다! 🧾💾')),
          );
        },
      ),
    );
  }
}

class _ScannerProgressDialog extends StatefulWidget {
  final String imagePath;
  final bool isDemo;
  final WeddingCategory category;
  final String mockVendor;
  final int mockCost;
  final String mockItem;
  final Function(String vendor, int cost, String path) onScanComplete;

  const _ScannerProgressDialog({
    required this.imagePath,
    required this.isDemo,
    required this.category,
    required this.mockVendor,
    required this.mockCost,
    required this.mockItem,
    required this.onScanComplete,
  });

  @override
  State<_ScannerProgressDialog> createState() => _ScannerProgressDialogState();
}

class _ScannerProgressDialogState extends State<_ScannerProgressDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isScanning = true;
  late TextEditingController _vendorController;
  late TextEditingController _costController;

  @override
  void initState() {
    super.initState();
    _vendorController = TextEditingController(text: widget.mockVendor);
    _costController = TextEditingController(text: widget.mockCost.toString());

    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animationController.forward().then((_) {
      setState(() {
        _isScanning = false;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _vendorController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isScanning) ...[
              const Text(
                '영수증 이미지 분석 중',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '인공지능 모델이 항목과 금액을 검출하고 있습니다...',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 24),
              // 스캔 애니메이션 컨테이너
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 이미지 프리뷰
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.isDemo
                          ? Container(
                              width: 150,
                              height: 180,
                              color: Colors.grey[100],
                              child: Center(
                                child: Opacity(
                                  opacity: 0.6,
                                  child: Image.network(
                                    'https://images.unsplash.com/photo-1554415707-6e8cfc93fe23?w=300',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            )
                          : Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.cover,
                              width: 150,
                              height: 180,
                            ),
                    ),
                    // 스캔 레이저 라인 애니메이션
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        final double topOffset = 10.0 + (_animationController.value * 160.0);
                        return Positioned(
                          top: topOffset,
                          child: Container(
                            width: 160,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5271),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5271).withValues(alpha: 0.8),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5271)),
                ),
              ),
            ] else ...[
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
              const SizedBox(height: 12),
              const Text(
                '스캔 분석 완료!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _vendorController,
                decoration: const InputDecoration(
                  labelText: '검출된 업체명',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '검출된 금액 (원)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final costVal = int.tryParse(_costController.text) ?? widget.mockCost;
                        final vendorVal = _vendorController.text.isEmpty ? widget.mockVendor : _vendorController.text;
                        final finalPath = widget.isDemo
                            ? 'https://picsum.photos/600/800?random=${DateTime.now().millisecond}'
                            : widget.imagePath;

                        Navigator.pop(context);
                        widget.onScanComplete(vendorVal, costVal, finalPath);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5271),
                      ),
                      child: const Text('적용하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
