import 'package:flutter/material.dart';

void main() => runApp(const PocketMoneyApp());

class PocketMoneyApp extends StatelessWidget {
  const PocketMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MoneyTrackerPage(),
    );
  }
}

class MoneyTrackerPage extends StatefulWidget {
  const MoneyTrackerPage({super.key});

  @override
  State<MoneyTrackerPage> createState() => _MoneyTrackerPageState();
}

class _MoneyTrackerPageState extends State<MoneyTrackerPage> {
  int balance = 300000;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController memoController = TextEditingController();
  final history = [];

  void showSetBalanceDialog() {
    final setBalanceController = TextEditingController(text: balance.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('용돈 설정'),
          content: TextField(
            controller: setBalanceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '새로운 용돈 금액 (원)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final newBudget = int.tryParse(setBalanceController.text.trim());
                if (newBudget != null && newBudget >= 0) {
                  setState(() {
                    balance = newBudget;
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void addExpense() {
    final String title = titleController.text.trim();
    final int? amount = int.tryParse(amountController.text.trim());
    final String memo = memoController.text.trim();

    if (title.isEmpty || amount == null || amount <= 0) {
      return;
    }

    final now = DateTime.now();
    final String timeStr =
        '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      balance -= amount;
      history.insert(0, {
        'title': title,
        'amount': amount,
        'time': timeStr,
        'memo': memo,
      });
    });

    titleController.clear();
    amountController.clear();
    memoController.clear();
    FocusScope.of(context).unfocus();
  }

  void deleteExpense(int index) {
    setState(() {
      balance += (history[index]['amount'] as int);
      history.removeAt(index);
    });
  }

  void showEditDialog(int index) {
    final item = history[index];
    final editTitle = TextEditingController(text: item['title']);
    final editAmount = TextEditingController(text: item['amount'].toString());
    final editMemo = TextEditingController(text: item['memo'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('지출 내역 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: editTitle,
                  decoration: const InputDecoration(labelText: '사용처'),
                ),
                TextField(
                  controller: editAmount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '금액 (원)'),
                ),
                TextField(
                  controller: editMemo,
                  decoration: const InputDecoration(labelText: '감정 / 장소 메모'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final newTitle = editTitle.text.trim();
                final newAmount = int.tryParse(editAmount.text.trim());
                final newMemo = editMemo.text.trim();

                if (newTitle.isNotEmpty && newAmount != null && newAmount > 0) {
                  setState(() {
                    balance = balance + (item['amount'] as int) - newAmount;
                    item['title'] = newTitle;
                    item['amount'] = newAmount;
                    item['memo'] = newMemo;
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('수정 완료'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('초간단 용돈기록장'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.teal.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('남은 용돈', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                          onPressed: showSetBalanceDialog,
                          tooltip: '용돈 금액 설정',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${balance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: '사용내역 (예: 커피)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '금액 (원)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: memoController,
                    decoration: const InputDecoration(
                      hintText: '메모 (어디서? 어떤 감정이었는지)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: addExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  child: const Text('지출'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('최근 지출 내역', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: history.isEmpty
                  ? const Center(child: Text('아직 지출 내역이 없어요', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        final String memoText = item['memo'] ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['time'] ?? '',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  if (memoText.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        '💬 $memoText',
                                        style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 13),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '-${item['amount'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원',
                                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                                    onPressed: () => showEditDialog(index),
                                    tooltip: '수정',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                    onPressed: () => deleteExpense(index),
                                    tooltip: '삭제',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
