import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // 플러터 엔진 바인딩 보장
  WidgetsFlutterBinding.ensureInitialized();
  
  // 네이티브 플러그인 에러 방어
  try {
    await HomeWidget.setAppGroupId('group.pocket_money_app');
  } catch (e) {
    debugPrint('HomeWidget init error: $e');
  }

  runApp(const PocketMoneyApp());
}

class PocketMoneyApp extends StatelessWidget {
  const PocketMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '얼마남았지?',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MoneyTrackerPage(),
    );
  }
}

class MoneyTrackerPage extends StatefulWidget {
  const MoneyTrackerPage({super.key});

  @override
  State<MoneyTrackerPage> createState() => _MoneyTrackerPageState();
}

class _MoneyTrackerPageState extends State<MoneyTrackerPage> {
  DateTime currentMonth = DateTime.now();
  final Map<String, int> monthlyBudgets = {};
  final history = [];

  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadSavedData();
  }

  // 1. 스마트폰 내부 저장소 불러오기
  Future<void> loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedBudgets = prefs.getString('saved_budgets');
      if (savedBudgets != null) {
        final decoded = jsonDecode(savedBudgets);
        if (decoded is Map) {
          monthlyBudgets.clear();
          decoded.forEach((k, v) {
            monthlyBudgets[k.toString()] = v as int;
          });
        }
      }

      final savedHistory = prefs.getString('saved_history');
      if (savedHistory != null) {
        final decoded = jsonDecode(savedHistory);
        if (decoded is List) {
          history.clear();
          history.addAll(decoded);
        }
      }
      setState(() {});
    } catch (e) {
      debugPrint('Load data error: $e');
    }
    updateAppWidget();
  }

  // 2. 스마트폰 내부 저장소에 영구 저장
  Future<void> persistData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_budgets', jsonEncode(monthlyBudgets));
      await prefs.setString('saved_history', jsonEncode(history));
    } catch (e) {
      debugPrint('Save data error: $e');
    }
    updateAppWidget();
  }

  String get currentMonthKey =>
      '${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}';

  int get currentBudget => monthlyBudgets[currentMonthKey] ?? 300000;

  List get currentHistory =>
      history.where((item) => item['yearMonth'] == currentMonthKey).toList();

  int get currentSpent {
    int sum = 0;
    for (var item in currentHistory) {
      sum += (item['amount'] as int);
    }
    return sum;
  }

  int get currentRemaining => currentBudget - currentSpent;

  String formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  void updateAppWidget() {
    try {
      HomeWidget.saveWidgetData<String>('balance_text', '${formatCurrency(currentRemaining)}원');
      HomeWidget.updateWidget(
        name: 'PocketWidgetProvider',
        androidName: 'PocketWidgetProvider',
      );
    } catch (e) {
      debugPrint('Widget update error: $e');
    }
  }

  void prevMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    });
    updateAppWidget();
  }

  void nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    });
    updateAppWidget();
  }

  void showSetBalanceDialog() {
    final setBudgetController = TextEditingController(text: currentBudget.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${currentMonth.month}월 용돈 설정'),
          content: TextField(
            controller: setBudgetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '이번 달 받은 총 용돈 (원)',
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
                final newBudget = int.tryParse(setBudgetController.text.trim());
                if (newBudget != null && newBudget >= 0) {
                  setState(() {
                    monthlyBudgets[currentMonthKey] = newBudget;
                  });
                  persistData();
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
      history.insert(0, {
        'title': title,
        'amount': amount,
        'time': timeStr,
        'memo': memo,
        'yearMonth': currentMonthKey,
      });
    });

    persistData();
    titleController.clear();
    amountController.clear();
    memoController.clear();
    FocusScope.of(context).unfocus();
  }

  void deleteExpense(Map item) {
    setState(() {
      history.remove(item);
    });
    persistData();
  }

  void showEditDialog(Map item) {
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
                  decoration: const InputDecoration(labelText: '사용내역'),
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
                    item['title'] = newTitle;
                    item['amount'] = newAmount;
                    item['memo'] = newMemo;
                  });
                  persistData();
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
    final double progress = currentBudget > 0 ? (currentSpent / currentBudget).clamp(0.0, 1.0) : 0.0;
    final double percent = currentBudget > 0 ? ((currentSpent / currentBudget) * 100) : 0.0;
    final filteredList = currentHistory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('얼마남았지?'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 28),
                  onPressed: prevMonth,
                  tooltip: '이전 달',
                ),
                Text(
                  '${currentMonth.year}년 ${currentMonth.month}월',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 28),
                  onPressed: nextMonth,
                  tooltip: '다음 달',
                ),
              ],
            ),
            Card(
              color: Colors.teal.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('남은 용돈', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 15, color: Colors.grey),
                          onPressed: showSetBalanceDialog,
                          tooltip: '해당 월 용돈 설정',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatCurrency(currentRemaining)}원',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.teal.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress >= 0.9 ? Colors.redAccent : Colors.teal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${percent.toStringAsFixed(1)}% 사용',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: progress >= 0.9 ? Colors.redAccent : Colors.teal.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFD4ECE7)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('받은 용돈', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 4),
                            Text(
                              '${formatCurrency(currentBudget)}원',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(height: 24, width: 1, color: Colors.grey.shade300),
                        Column(
                          children: [
                            const Text('쓴 돈', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 4),
                            Text(
                              '${formatCurrency(currentSpent)}원',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${currentMonth.month}월 지출 내역 (${filteredList.length}건)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Text(
                        '${currentMonth.month}월 지출 내역이 없어요',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
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
                                    '-${formatCurrency(item['amount'] as int)}원',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                                    onPressed: () => showEditDialog(item),
                                    tooltip: '수정',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                    onPressed: () => deleteExpense(item),
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
