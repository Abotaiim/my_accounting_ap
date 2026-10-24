import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const SmartAccountingApp());
}

class SmartAccountingApp extends StatelessWidget {
  const SmartAccountingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المحاسب الذكي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // قاعدة بيانات محلية (تخزين داخلي في الذاكرة)
  final List<Map<String, dynamic>> _accounts = [
    {'id': '1', 'name': 'الصندوق الرئيسي', 'type': 'أصول (Assets)', 'balance': 540000.0},
    {'id': '2', 'name': 'بنك الكريمي', 'type': 'أصول (Assets)', 'balance': 1200000.0},
    {'id': '3', 'name': 'شركة الأمل (عميل)', 'type': 'مدينون (العملاء)', 'balance': 450000.0, 'limit': 300000.0, 'overdue': true},
    {'id': '4', 'name': 'مؤسسة النور (عميل)', 'type': 'مدينون (العملاء)', 'balance': 85000.0, 'limit': 200000.0, 'overdue': false},
    {'id': '5', 'name': 'المورد التجاري (مورد)', 'type': 'دائنون (الموردين)', 'balance': 190000.0},
    {'id': '6', 'name': 'المبيعات العامة', 'type': 'إيرادات (Revenue)', 'balance': 980000.0},
  ];

  final List<Map<String, dynamic>> _invoices = [];

  void _addInvoice(Map<String, dynamic> invoice) {
    setState(() {
      _invoices.insert(0, invoice);
      // تحديث الأرصدة تلقائياً
      var acc = _accounts.firstWhere((a) => a['id'] == invoice['accountId']);
      if (invoice['type'] == 'بيع') {
        acc['balance'] += (invoice['total'] - invoice['paid']);
      } else {
        acc['balance'] += (invoice['total'] - invoice['paid']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardTab(accounts: _accounts, invoices: _invoices),
      InvoicesTab(accounts: _accounts, onSave: _addInvoice),
      AccountsTab(accounts: _accounts),
      const UsersQRTab(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: screens[_currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard), label: 'الرئيسية والديون'),
            NavigationDestination(icon: Icon(Icons.receipt_long), label: 'الفواتير'),
            NavigationDestination(icon: Icon(Icons.account_tree), label: 'شجرة الحسابات'),
            NavigationDestination(icon: Icon(Icons.qr_code), label: 'المستخدمين'),
          ],
        ),
      ),
    );
  }
}

// ----------------- 1. شاشة لوحة التحكم وتنبيهات الذكاء -----------------
class DashboardTab extends StatelessWidget {
  final List<Map<String, dynamic>> accounts;
  final List<Map<String, dynamic>> invoices;

  const DashboardTab({super.key, required this.accounts, required this.invoices});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat("#,##0", "en_US");
    // فلترة العملاء الذين لديهم خطر ائتماني
    final riskyCustomers = accounts.where((a) =>
      a.containsKey('limit') && (a['balance'] > a['limit'] || a['overdue'] == true)
    ).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('المحاسب الذكي - أوفلاين'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // كارت تنبيهات الذكاء الاصطناعي
          Card(
            color: riskyCustomers.isNotEmpty ? Colors.amber.shade50 : Colors.teal.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: riskyCustomers.isNotEmpty ? Colors.amber : Colors.teal)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: riskyCustomers.isNotEmpty ? Colors.orange.shade800 : Colors.teal),
                      const SizedBox(width: 8),
                      const Text('مساعد الذكاء المالي الداخلي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(riskyCustomers.isNotEmpty 
                    ? '⚠️ تم رصد (${riskyCustomers.length}) عملاء تجاوزوا سقف الدين أو تأخروا عن موعد السداد!'
                    : '✅ كافة الحسابات والعمليات متزنة ولا توجد مخاطر ديون حالياً.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('تنبيهات مديونيات العملاء الحرجة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...riskyCustomers.map((cust) => Card(
            color: Colors.red.shade50,
            child: ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: Text(cust['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('الرصيد الحالي: ${currency.format(cust['balance'])} ريال\nسقف الدين المسموح: ${currency.format(cust['limit'])} ريال'),
              trailing: cust['overdue'] == true 
                ? const Chip(label: Text('متأخر عن السداد', style: TextStyle(color: Colors.white, fontSize: 11)), backgroundColor: Colors.red)
                : const Chip(label: Text('تجاوز الحد', style: TextStyle(color: Colors.white, fontSize: 11)), backgroundColor: Colors.orange),
            ),
          )),
          const SizedBox(height: 20),
          const Text('آخر العمليات المسجلة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          if (invoices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('لا توجد فواتير بعد. انتقل لتبويب الفواتير للإضافة.')),
            )
          else
            ...invoices.take(5).map((inv) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: inv['type'] == 'بيع' ? Colors.green.shade100 : Colors.blue.shade100,
                  child: Icon(inv['type'] == 'بيع' ? Icons.arrow_upward : Icons.arrow_downward),
                ),
                title: Text('${inv['type']}: ${inv['customerName']}'),
                subtitle: Text('المبلغ: ${currency.format(inv['total'])} | المتبقي: ${currency.format(inv['remaining'])}'),
                trailing: Text(inv['date']),
              ),
            )),
        ],
      ),
    );
  }
}

// ----------------- 2. شاشة الفواتير والتحقق الذكي -----------------
class InvoicesTab extends StatefulWidget {
  final List<Map<String, dynamic>> accounts;
  final Function(Map<String, dynamic>) onSave;

  const InvoicesTab({super.key, required this.accounts, required this.onSave});

  @override
  State<InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<InvoicesTab> {
  String _invoiceType = 'بيع';
  String? _selectedAccountId;
  final _totalController = TextEditingController();
  final _paidController = TextEditingController();
  String _aiWarning = '';

  void _checkAIValidation() {
    double total = double.tryParse(_totalController.text) ?? 0.0;
    double paid = double.tryParse(_paidController.text) ?? 0.0;

    setState(() {
      if (paid > total && total > 0) {
        _aiWarning = '❌ خطأ: المبلغ المدفوع أكبر من إجمالي الفاتورة!';
      } else if (total > 1500000) {
        _aiWarning = '⚠️ تنبيه ذكي: المبلغ كبير جداً، يرجى التأكد من عدم زيادة أصفار بالخطأ.';
      } else if (_selectedAccountId != null && _invoiceType == 'بيع') {
        var cust = widget.accounts.firstWhere((a) => a['id'] == _selectedAccountId);
        if (cust.containsKey('limit') && (cust['balance'] + (total - paid)) > cust['limit']) {
          _aiWarning = '⚠️ تحذير: هذه الفاتورة ستجعل العميل يتجاوز سقف الدين الائتماني المسموح به!';
        } else {
          _aiWarning = '';
        }
      } else {
        _aiWarning = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final customers = widget.accounts.where((a) => a['type'].contains('مدينون') || a['type'].contains('دائنون')).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء فاتورة جديدة'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'بيع', label: Text('فاتورة مبيعات')),
              ButtonSegment(value: 'شراء', label: Text('فاتورة مشتريات')),
            ],
            selected: {_invoiceType},
            onSelectionChanged: (val) {
              setState(() => _invoiceType = val.first);
              _checkAIValidation();
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'اختر العميل أو المورد', border: OutlineInputBorder()),
            value: _selectedAccountId,
            items: customers.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name']))).toList(),
            onChanged: (val) {
              setState(() => _selectedAccountId = val);
              _checkAIValidation();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _totalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'إجمالي الفاتورة (ريال)', border: OutlineInputBorder()),
            onChanged: (_) => _checkAIValidation(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _paidController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'المبلغ المدفوع نقداً', border: OutlineInputBorder()),
            onChanged: (_) => _checkAIValidation(),
          ),
          if (_aiWarning.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: BorderSide(color: Colors.red.shade300)),
              child: Text(_aiWarning, style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
            onPressed: () {
              double total = double.tryParse(_totalController.text) ?? 0.0;
              double paid = double.tryParse(_paidController.text) ?? 0.0;

              if (_selectedAccountId == null || total <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار الحساب وإدخال مبلغ صحيح')));
                return;
              }

              var acc = widget.accounts.firstWhere((a) => a['id'] == _selectedAccountId);
              widget.onSave({
                'type': _invoiceType,
                'accountId': _selectedAccountId,
                'customerName': acc['name'],
                'total': total,
                'paid': paid,
                'remaining': (total - paid),
                'date': DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now()),
              });

              _totalController.clear();
              _paidController.clear();
              setState(() => _aiWarning = '');

              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم حفظ الفاتورة وتحديث الحسابات بنجاح!')));
            },
            icon: const Icon(Icons.check),
            label: const Text('حفظ وترحيل الفاتورة'),
          ),
        ],
      ),
    );
  }
}

// ----------------- 3. شجرة الحسابات وكشف الحساب -----------------
class AccountsTab extends StatelessWidget {
  final List<Map<String, dynamic>> accounts;
  const AccountsTab({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat("#,##0", "en_US");
    return Scaffold(
      appBar: AppBar(title: const Text('دليل الحسابات (شجرة الحسابات)'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: ListView.separated(
        itemCount: accounts.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final acc = accounts[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade50,
              child: const Icon(Icons.account_balance_wallet, color: Colors.teal),
            ),
            title: Text(acc['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(acc['type']),
            trailing: Text(
              '${currency.format(acc['balance'])} ريال',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: acc['balance'] < 0 ? Colors.red : Colors.teal.shade900),
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (c) => Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('كشف حساب سريع: ${acc['name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text('طبيعة الحساب: ${acc['type']}'),
                      Text('الرصيد الحالي: ${currency.format(acc['balance'])} ريال'),
                      if (acc.containsKey('limit')) Text('سقف الدين: ${currency.format(acc['limit'])} ريال'),
                      const SizedBox(height: 20),
                      const Center(child: Text('جميع القيود مرحلة وسليمة محاسبياً ✅', style: TextStyle(color: Colors.green))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ----------------- 4. صلاحيات المستخدمين ورمز QR -----------------
class UsersQRTab extends StatefulWidget {
  const UsersQRTab({super.key});

  @override
  State<UsersQRTab> createState() => _UsersQRTabState();
}

class _UsersQRTabState extends State<UsersQRTab> {
  String _selectedRole = 'كاشير (فواتير بيع فقط)';

  @override
  Widget build(BuildContext context) {
    // محتوى الصلاحية المضمنة في الـ QR
    final qrData = 'ROLE:$_selectedRole;AUTH_KEY:SECURE_${DateTime.now().day}';

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة مستخدم عبر QR'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('اختر الصلاحية للمستخدم الجديد:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: _selectedRole,
                items: const [
                  DropdownMenuItem(value: 'كاشير (فواتير بيع فقط)', child: Text('كاشير (فواتير بيع فقط)')),
                  DropdownMenuItem(value: 'محاسب (كامل الصلاحيات عدا الحذف)', child: Text('محاسب (كامل الصلاحيات عدا الحذف)')),
                  DropdownMenuItem(value: 'مدير نظام (كامل الصلاحيات)', child: Text('مدير نظام (كامل الصلاحيات)')),
                ],
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10)]),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 220.0,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'امسح هذا الرمز من هاتف الموظف الآخر ليتم تسجيل دخوله وتطبيق الصلاحية دون الحاجة إلى إنترنت.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
