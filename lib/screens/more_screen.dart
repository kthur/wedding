import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/guest_provider.dart';
import '../providers/memo_provider.dart';
import '../providers/category_provider.dart';
import '../models/guest_item.dart';

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
    final guests = ref.watch(guestProvider);
    final memos = ref.watch(memoProvider);
    final authState = ref.watch(authProvider);

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
                  _buildCountItem('총 청첩 대상', '${guests.length}명'),
                  _buildCountItem('식사 확정', '${guests.where((g) => g.mealConfirmed).length}명'),
                  _buildCountItem('미정', '${guests.where((g) => !g.mealConfirmed).length}명'),
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
                            ref.read(memoProvider.notifier).sendMemo(_memoController.text);
                            _memoController.clear();
                          }
                        },
                      )
                    ],
                  ),
                  if (memos.isNotEmpty) ...[
                    const Divider(),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: memos.length,
                      itemBuilder: (context, index) {
                        final memo = memos[index];
                        final isCurrentUser = memo['sender'] == (authState.currentUser?.name ?? '나');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Align(
                            // Fixed left alignment issue (M-5 equivalent UX improvement)
                            alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isCurrentUser) ...[
                                      Text(
                                        '${memo['sender']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFFF5271)),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      '${memo['time']}',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                    if (isCurrentUser) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '${memo['sender']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isCurrentUser ? const Color(0xFFE3F2FD) : const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('${memo['text']}', style: const TextStyle(fontSize: 14)),
                                ),
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
              () => _exportToExcel(context),
            ),
            const SizedBox(height: 12),
            _buildExportButton(
              'PDF 보고서로 내보내기',
              Icons.picture_as_pdf,
              Colors.red,
              () => _exportToPdf(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToExcel(BuildContext context) async {
    try {
      final categories = ref.read(categoryProvider);
      final guestList = ref.read(guestProvider);

      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];
      sheet.name = '결혼 준비 카테고리';

      sheet.getRangeByName('A1').setText('결혼 준비 카테고리 지출 현황');
      sheet.getRangeByName('A1').cellStyle.bold = true;
      sheet.getRangeByName('A1').cellStyle.fontSize = 14;

      sheet.getRangeByName('A3').setText('카테고리명');
      sheet.getRangeByName('B3').setText('그룹명');
      sheet.getRangeByName('C3').setText('진행상태');
      sheet.getRangeByName('D3').setText('예상예산');
      sheet.getRangeByName('E3').setText('실제지출');
      sheet.getRangeByName('F3').setText('메모');

      int row = 4;
      for (var cat in categories) {
        sheet.getRangeByIndex(row, 1).setText(cat.name);
        sheet.getRangeByIndex(row, 2).setText(cat.groupName);
        sheet.getRangeByIndex(row, 3).setText(cat.status.displayName);
        sheet.getRangeByIndex(row, 4).setNumber(cat.estimatedCost.toDouble());
        sheet.getRangeByIndex(row, 5).setNumber(cat.actualCost.toDouble());
        sheet.getRangeByIndex(row, 6).setText(cat.notes);
        row++;
      }

      final xlsio.Worksheet guestSheet = workbook.worksheets.addWithName('하객 명단');
      guestSheet.getRangeByName('A1').setText('하객 명단 및 식사 여부');
      guestSheet.getRangeByName('A1').cellStyle.bold = true;

      guestSheet.getRangeByName('A3').setText('이름');
      guestSheet.getRangeByName('B3').setText('연락처');
      guestSheet.getRangeByName('C3').setText('구분');
      guestSheet.getRangeByName('D3').setText('식사확정');

      int gRow = 4;
      for (var guest in guestList) {
        guestSheet.getRangeByIndex(gRow, 1).setText(guest.name);
        guestSheet.getRangeByIndex(gRow, 2).setText(guest.phone);
        guestSheet.getRangeByIndex(gRow, 3).setText(guest.side == 'groom' ? '신랑측' : '신부측');
        guestSheet.getRangeByIndex(gRow, 4).setText(guest.mealConfirmed ? '확정' : '미정');
        gRow++;
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final Directory directory = await getTemporaryDirectory();
      final File file = File('${directory.path}/wedding_planner_export.xlsx');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles([XFile(file.path)], text: '결혼 준비 현황 엑셀 내보내기');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel 파일 생성에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _exportToPdf(BuildContext context) async {
    try {
      final categories = ref.read(categoryProvider);
      final coupleInfo = ref.read(authProvider).coupleInfo;

      final pdfDoc = pw.Document();

      pdfDoc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Wedding Planner Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                pw.Text('Wedding Date: ${coupleInfo?.weddingDate != null ? DateFormat('yyyy-MM-dd').format(coupleInfo!.weddingDate!) : "Not Set"}'),
                pw.Text('Budget Goal: ${coupleInfo?.budgetGoal ?? 0} Won'),
                pw.SizedBox(height: 20),
                pw.Text('Category Budgets Summary:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                ...categories.map((cat) {
                  return pw.Bullet(
                    text: '${cat.name} (${cat.groupName}): Estimated: ${cat.estimatedCost} | Actual: ${cat.actualCost} | Status: ${cat.status.name}'
                  );
                }),
              ],
            );
          },
        ),
      );

      final List<int> bytes = await pdfDoc.save();

      final Directory directory = await getTemporaryDirectory();
      final File file = File('${directory.path}/wedding_report.pdf');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles([XFile(file.path)], text: '결혼 준비 보고서 PDF 내보내기');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 파일 생성에 실패했습니다: $e')),
        );
      }
    }
  }

  void _showGuestManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _GuestManagerModal();
      },
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
}

class _GuestManagerModal extends ConsumerStatefulWidget {
  const _GuestManagerModal();

  @override
  ConsumerState<_GuestManagerModal> createState() => _GuestManagerModalState();
}

class _GuestManagerModalState extends ConsumerState<_GuestManagerModal> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String _side = 'groom';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guests = ref.watch(guestProvider);

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
                    ref.read(guestProvider.notifier).addGuest(
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
              itemCount: guests.length,
              itemBuilder: (context, index) {
                final GuestItem guest = guests[index];
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
                            ref.read(guestProvider.notifier).toggleGuestMeal(guest.id);
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
