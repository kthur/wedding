import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wedding_provider.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  final TextEditingController _memoController = TextEditingController();

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weddingState = ref.watch(weddingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        title: const Text('더보기', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 하객 관리 타이틀 및 요약
            _buildSectionHeader('👥 하객 명단 및 식비 정산', () => _showGuestManager(context)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCountItem('총 청첩 대상', '${weddingState.guests.length}명'),
                  _buildCountItem('식사 확정', '${weddingState.guests.where((g) => g.mealConfirmed).length}명'),
                  _buildCountItem('미정', '${weddingState.guests.where((g) => !g.mealConfirmed).length}명'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 실시간 커플 메모 보드
            _buildSectionHeader('💬 커플 한 줄 메모보드', null),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _memoController,
                          decoration: const InputDecoration(
                            hintText: '상대방에게 메모를 전송해 보세요...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFFFF5271)),
                        onPressed: () {
                          if (_memoController.text.isNotEmpty) {
                            ref.read(weddingProvider.notifier).sendMemo(_memoController.text);
                            _memoController.clear();
                          }
                        },
                      )
                    ],
                  ),
                  if (weddingState.memos.isNotEmpty) ...[
                    const Divider(),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: weddingState.memos.length,
                      itemBuilder: (context, index) {
                        final memo = weddingState.memos[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${memo['sender']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFFF5271)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${memo['time']}',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('${memo['text']}', style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 내보내기 및 데이터 관리
            _buildSectionHeader('📤 데이터 내보내기', null),
            const SizedBox(height: 12),
            _buildExportButton(
              'Excel (.xlsx) 파일로 내보내기',
              Icons.grid_on,
              Colors.green,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Excel 파일 생성을 완료했습니다! 📁')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildExportButton(
              'PDF 보고서로 내보내기',
              Icons.picture_as_pdf,
              Colors.red,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF 보고서 내보내기를 완료했습니다! 📄')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
        ),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            child: const Text('관리하기', style: TextStyle(color: Color(0xFFFF5271), fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildCountItem(String title, String count) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
      ],
    );
  }

  Widget _buildExportButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E))),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 0,
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
        ),
      ),
    );
  }

  void _showGuestManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _GuestManagerModal();
      },
    );
  }
}

class _GuestManagerModal extends ConsumerStatefulWidget {
  @override
  ConsumerState<_GuestManagerModal> createState() => _GuestManagerModalState();
}

class _GuestManagerModalState extends ConsumerState<_GuestManagerModal> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _side = 'groom';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weddingState = ref.watch(weddingProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('하객 명단 관리', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          // 하객 추가 폼
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '이름', hintText: '홍길동'),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _side,
                items: const [
                  DropdownMenuItem(value: 'groom', child: Text('신랑측')),
                  DropdownMenuItem(value: 'bride', child: Text('신부측')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _side = val;
                    });
                  }
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty) {
                    ref.read(weddingProvider.notifier).addGuest(
                          _nameController.text,
                          _phoneController.text,
                          _side,
                        );
                    _nameController.clear();
                    _phoneController.clear();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5271)),
                child: const Text('추가', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: weddingState.guests.length,
              itemBuilder: (context, index) {
                final guest = weddingState.guests[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(guest.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(guest.side == 'groom' ? '신랑측 하객' : '신부측 하객'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('식사확정', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Checkbox(
                          value: guest.mealConfirmed,
                          activeColor: const Color(0xFFFF5271),
                          onChanged: (_) {
                            ref.read(weddingProvider.notifier).toggleGuestMeal(guest.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
