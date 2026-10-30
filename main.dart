import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const HiraDailyApp());

// Premium HiraDaily palette
const gold = Color(0xFFD6AD55);
const goldLight = Color(0xFFF3D98B);
const red = Color(0xFF9E2638);
const bg = Color(0xFF08090C);
const panel = Color(0xFF15171D);
const panel2 = Color(0xFF20232B);

class HiraDailyApp extends StatelessWidget {
  const HiraDailyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'HiraDaily By Ashish',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: bg,
          colorScheme: const ColorScheme.dark(
            primary: gold,
            secondary: red,
            surface: panel,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: bg,
            foregroundColor: goldLight,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: panel,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: gold.withOpacity(.22)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: panel2,
            labelStyle: const TextStyle(color: gold),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: panel,
            indicatorColor: gold.withOpacity(.16),
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          useMaterial3: true,
        ),
        home: const Dashboard(),
      );
}

class WorkEntry {
  int count;
  double rate;
  WorkEntry(this.count, this.rate);
  Map<String, dynamic> toJson() => {'count': count, 'rate': rate};
  factory WorkEntry.fromJson(Map<String, dynamic> j) =>
      WorkEntry(j['count'] ?? 0, (j['rate'] ?? 0).toDouble());
}

class CashEntry {
  String id;
  double amount;
  String note;
  CashEntry(this.id, this.amount, this.note);
  Map<String, dynamic> toJson() =>
      {'id': id, 'amount': amount, 'note': note};
  factory CashEntry.fromJson(Map<String, dynamic> j) =>
      CashEntry(j['id'], (j['amount'] ?? 0).toDouble(), j['note'] ?? '');
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  DateTime month = DateTime.now();
  Map<String, WorkEntry> work = {};
  Map<String, List<CashEntry>> advances = {};
  Map<String, List<CashEntry>> payments = {};
  bool fixedRate = true;
  double defaultRate = 2;
  int tab = 0;
  bool loaded = false;
  String language = 'en';

  final Map<String, Map<String, String>> words = {
    'en': {
      'home':'Home','hisab':'Hisab','settings':'Settings','by':'By Ashish Meniya',
      'total_hira':'Total Diamonds','total_work':'Total Work','jama':'Jama',
      'upad':'Upad','remaining':'REMAINING BALANCE','fixed_rate':'Fixed Rate',
      'default_rate':'Default rate','daily_entries':'Daily Entries',
      'add_today':'Add Today','no_entry':'No entry','add_upad':'Add Upad',
      'add_jama':'Add Jama','upad_history':'Upad History','jama_history':'Jama History',
      'monthly_hisab':'Monthly Hisab','rate_label':'Default rate per diamond (â¹)',
      'fixed_default':'Use fixed rate by default','language':'App Language',
      'language_hint':'Choose your preferred language','english':'English',
      'hindi':'à¤¹à¤¿à¤à¤¦à¥','gujarati':'àªà«àªàª°àª¾àª¤à«','saved_phone':'Your data is saved on this phone.',
      'date':'Date','diamond_count':'Diamond quantity','rate':'Rate (â¹ per diamond)',
      'amount':'Amount (â¹)','note':'Note (optional)','delete':'Delete',
      'cancel':'Cancel','save':'Save','advance':'Upad / Advance',
      'payment':'Jama / Payment','max_upad':'Maximum 2 Upad entries are allowed per month.',
      'select_language':'Select Language','daily_diamond':'Daily Diamonds',
      'mon':'Mon','tue':'Tue','wed':'Wed','thu':'Thu','fri':'Fri','sat':'Sat','sun':'Sun',
      'total':'Total','report':'Reports'
    },
    'hi': {
      'home':'à¤¹à¥à¤®','hisab':'à¤¹à¤¿à¤¸à¤¾à¤¬','settings':'à¤¸à¥à¤à¤¿à¤à¤à¥à¤¸','by':'à¤¬à¤¾à¤¯ à¤à¤¶à¥à¤· à¤®à¥à¤¨à¤¿à¤¯à¤¾',
      'total_hira':'à¤à¥à¤² à¤¹à¥à¤°à¥','total_work':'à¤à¥à¤² à¤à¤¾à¤®','jama':'à¤à¤®à¤¾',
      'upad':'à¤à¤ªà¤¾à¤¡à¤¼','remaining':'à¤¬à¤¾à¤à¥ à¤¬à¥à¤²à¥à¤à¤¸','fixed_rate':'à¤«à¤¿à¤à¥à¤¸ à¤°à¥à¤',
      'default_rate':'à¤¡à¤¿à¤«à¤¼à¥à¤²à¥à¤ à¤°à¥à¤','daily_entries':'à¤°à¥à¤à¤¼ à¤à¥ à¤à¤à¤à¥à¤°à¥',
      'add_today':'à¤à¤ à¤à¥ à¤à¤à¤à¥à¤°à¥','no_entry':'à¤à¥à¤ à¤à¤à¤à¥à¤°à¥ à¤¨à¤¹à¥à¤','add_upad':'à¤à¤ªà¤¾à¤¡à¤¼ à¤à¥à¤¡à¤¼à¥à¤',
      'add_jama':'à¤à¤®à¤¾ à¤à¥à¤¡à¤¼à¥à¤','upad_history':'à¤à¤ªà¤¾à¤¡à¤¼ à¤¹à¤¿à¤¸à¥à¤à¥à¤°à¥','jama_history':'à¤à¤®à¤¾ à¤¹à¤¿à¤¸à¥à¤à¥à¤°à¥',
      'monthly_hisab':'à¤®à¤¹à¥à¤¨à¥ à¤à¤¾ à¤¹à¤¿à¤¸à¤¾à¤¬','rate_label':'à¤ªà¥à¤°à¤¤à¤¿ à¤¹à¥à¤°à¤¾ à¤¡à¤¿à¤«à¤¼à¥à¤²à¥à¤ à¤°à¥à¤ (â¹)',
      'fixed_default':'à¤¡à¤¿à¤«à¤¼à¥à¤²à¥à¤ à¤«à¤¿à¤à¥à¤¸ à¤°à¥à¤ à¤à¤¸à¥à¤¤à¥à¤®à¤¾à¤² à¤à¤°à¥à¤','language':'à¤à¤ª à¤à¥ à¤­à¤¾à¤·à¤¾',
      'language_hint':'à¤à¤ªà¤¨à¥ à¤ªà¤¸à¤à¤¦ à¤à¥ à¤­à¤¾à¤·à¤¾ à¤à¥à¤¨à¥à¤','english':'English',
      'hindi':'à¤¹à¤¿à¤à¤¦à¥','gujarati':'àªà«àªàª°àª¾àª¤à«','saved_phone':'à¤à¤ªà¤à¤¾ à¤¡à¥à¤à¤¾ à¤à¤¸à¥ à¤«à¥à¤¨ à¤®à¥à¤ à¤¸à¥à¤µ à¤¹à¥à¥¤',
      'date':'à¤¤à¤¾à¤°à¥à¤','diamond_count':'à¤¹à¥à¤°à¥à¤ à¤à¥ à¤¸à¤à¤à¥à¤¯à¤¾','rate':'à¤°à¥à¤ (â¹ à¤ªà¥à¤°à¤¤à¤¿ à¤¹à¥à¤°à¤¾)',
      'amount':'à¤°à¤à¤® (â¹)','note':'à¤¨à¥à¤ (à¤à¤¼à¤°à¥à¤°à¥ à¤¨à¤¹à¥à¤)','delete':'à¤¡à¤¿à¤²à¥à¤',
      'cancel':'à¤°à¤¦à¥à¤¦ à¤à¤°à¥à¤','save':'à¤¸à¥à¤µ à¤à¤°à¥à¤','advance':'à¤à¤ªà¤¾à¤¡à¤¼ / à¤à¤¡à¤µà¤¾à¤à¤¸',
      'payment':'à¤à¤®à¤¾ / à¤ªà¥à¤®à¥à¤à¤','max_upad':'à¤à¤ à¤®à¤¹à¥à¤¨à¥ à¤®à¥à¤ à¤à¤§à¤¿à¤à¤¤à¤® 2 à¤à¤ªà¤¾à¤¡à¤¼ à¤à¤à¤à¥à¤°à¥ à¤¹à¥ à¤¸à¤à¤¤à¥ à¤¹à¥à¤à¥¤',
      'select_language':'à¤­à¤¾à¤·à¤¾ à¤à¥à¤¨à¥à¤','daily_diamond':'à¤°à¥à¤à¤¼à¤¾à¤¨à¤¾ à¤¹à¥à¤°à¥',
      'mon':'à¤¸à¥à¤®','tue':'à¤®à¤à¤à¤²','wed':'à¤¬à¥à¤§','thu':'à¤à¥à¤°à¥','fri':'à¤¶à¥à¤à¥à¤°','sat':'à¤¶à¤¨à¤¿','sun':'à¤°à¤µà¤¿',
      'total':'à¤à¥à¤²','report':'à¤°à¤¿à¤ªà¥à¤°à¥à¤'
    },
    'gu': {
      'home':'àª¹à«àª®','hisab':'àª¹àª¿àª¸àª¾àª¬','settings':'àª¸à«àªàª¿àªàªà«àª¸','by':'àª¬àª¾àª¯ àªàª¶àª¿àª· àª®à«àª¨àª¿àª¯àª¾',
      'total_hira':'àªà«àª² àª¹à«àª°àª¾','total_work':'àªà«àª² àªàª¾àª®','jama':'àªàª®àª¾',
      'upad':'àªàªªàª¾àª¡','remaining':'àª¬àª¾àªà« àª¬à«àª²à«àª¨à«àª¸','fixed_rate':'àª«àª¿àªà«àª¸ àª°à«àª',
      'default_rate':'àª¡àª¿àª«à«àª²à«àª àª°à«àª','daily_entries':'àª°à«àªàª¨à« àªàª¨à«àªà«àª°à«',
      'add_today':'àªàªàª¨à« àªàª¨à«àªà«àª°à«','no_entry':'àªà«àª àªàª¨à«àªà«àª°à« àª¨àª¥à«','add_upad':'àªàªªàª¾àª¡ àªàª®à«àª°à«',
      'add_jama':'àªàª®àª¾ àªàª®à«àª°à«','upad_history':'àªàªªàª¾àª¡àª¨à« àªàª¤àª¿àª¹àª¾àª¸','jama_history':'àªàª®àª¾àª¨à« àªàª¤àª¿àª¹àª¾àª¸',
      'monthly_hisab':'àª®àª¹àª¿àª¨àª¾àª¨à« àª¹àª¿àª¸àª¾àª¬','rate_label':'àª¦àª° àª¹à«àª°àª¾àª¨à« àª¡àª¿àª«à«àª²à«àª àª­àª¾àªµ (â¹)',
      'fixed_default':'àª¡àª¿àª«à«àª²à«àª àª«àª¿àªà«àª¸ àª°à«àª àªµàª¾àªªàª°à«','language':'àªàªªàª¨à« àª­àª¾àª·àª¾',
      'language_hint':'àª¤àª®àª¾àª°à« àªªàª¸àªàª¦àªà«àª¨à« àª­àª¾àª·àª¾ àªªàª¸àªàª¦ àªàª°à«','english':'English',
      'hindi':'à¤¹à¤¿à¤à¤¦à¥','gujarati':'àªà«àªàª°àª¾àª¤à«','saved_phone':'àª¤àª®àª¾àª°à« àª¡à«àªàª¾ àª àª«à«àª¨àª®àª¾àª àª¸à«àªµ àªà«.',
      'date':'àª¤àª¾àª°à«àª','diamond_count':'àª¹à«àª°àª¾àª¨à« àª¸àªàªà«àª¯àª¾','rate':'àª­àª¾àªµ (â¹ àªªà«àª°àª¤àª¿ àª¹à«àª°à«)',
      'amount':'àª°àªàª® (â¹)','note':'àª¨à«àªàª§ (àªµà«àªàª²à«àªªàª¿àª)','delete':'àª¡àª¿àª²à«àª',
      'cancel':'àª°àª¦ àªàª°à«','save':'àª¸à«àªµ àªàª°à«','advance':'àªàªªàª¾àª¡ / àªàª¡àªµàª¾àª¨à«àª¸',
      'payment':'àªàª®àª¾ / àªªà«àª®à«àª¨à«àª','max_upad':'àªàª àª®àª¹àª¿àª¨àª¾àª®àª¾àª àªµàª§à«àª®àª¾àª àªµàª§à« 2 àªàªªàª¾àª¡ àªàª¨à«àªà«àª°à« àª¥àª àª¶àªà« àªà«.',
      'select_language':'àª­àª¾àª·àª¾ àªªàª¸àªàª¦ àªàª°à«','daily_diamond':'àª°à«àªàª¨àª¾ àª¹à«àª°àª¾',
      'mon':'àª¸à«àª®','tue':'àª®àªàªàª³','wed':'àª¬à«àª§','thu':'àªà«àª°à«','fri':'àª¶à«àªà«àª°','sat':'àª¶àª¨àª¿','sun':'àª°àªµàª¿',
      'total':'àªà«àª²','report':'àª°àª¿àªªà«àª°à«àª'
    }
  };

  String tr(String key) => words[language]?[key] ?? words['en']![key] ?? key;
  String keyDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String monthKey() => '${month.year}-${month.month.toString().padLeft(2, '0')}';
  String money(double n) =>
      'â¹${n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2)}';
  bool inMonth(String k) => k.startsWith(monthKey());

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final w = p.getString('work') ?? '{}';
    final a = p.getString('advances') ?? '{}';
    final pay = p.getString('payments') ?? '{}';
    setState(() {
      (jsonDecode(w) as Map<String, dynamic>).forEach(
          (k, v) => work[k] = WorkEntry.fromJson(v));
      (jsonDecode(a) as Map<String, dynamic>).forEach((k, v) =>
          advances[k] =
              (v as List).map((e) => CashEntry.fromJson(e)).toList());
      (jsonDecode(pay) as Map<String, dynamic>).forEach((k, v) =>
          payments[k] =
              (v as List).map((e) => CashEntry.fromJson(e)).toList());
      fixedRate = p.getBool('fixedRate') ?? true;
      defaultRate = p.getDouble('rate') ?? 2;
      language = p.getString('language') ?? 'en';
      loaded = true;
    });
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'work', jsonEncode(work.map((k, v) => MapEntry(k, v.toJson()))));
    await p.setString(
        'advances',
        jsonEncode(advances.map(
            (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()))));
    await p.setString(
        'payments',
        jsonEncode(payments.map(
            (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()))));
    await p.setBool('fixedRate', fixedRate);
    await p.setDouble('rate', defaultRate);
    await p.setString('language', language);
  }

  double get totalWork => work.entries
      .where((e) => inMonth(e.key))
      .fold(0, (s, e) => s + e.value.count * e.value.rate);
  int get totalHira => work.entries
      .where((e) => inMonth(e.key))
      .fold(0, (s, e) => s + e.value.count);
  double get totalUpad => advances.entries
      .where((e) => inMonth(e.key))
      .fold(0, (s, e) => s + e.value.fold(0, (x, c) => x + c.amount));
  double get totalJama => payments.entries
      .where((e) => inMonth(e.key))
      .fold(0, (s, e) => s + e.value.fold(0, (x, c) => x + c.amount));
  double get balance => totalWork - totalJama - totalUpad;

  Future<void> changeLanguage(String value) async {
    setState(() => language = value);
    await save();
  }

  Future<void> editWork(DateTime d) async {
    final k = keyDate(d);
    final old = work[k];
    final count = TextEditingController(text: old?.count.toString() ?? '');
    final rate =
        TextEditingController(text: (old?.rate ?? defaultRate).toString());
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: panel,
              title: Text('${tr('daily_diamond')} - ${d.day}/${d.month}/${d.year}',
                  style: const TextStyle(color: gold)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: count,
                    keyboardType: TextInputType.number,
                    decoration:
                        InputDecoration(labelText: tr('diamond_count'))),
                const SizedBox(height: 12),
                TextField(
                    controller: rate,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: tr('rate'))),
              ]),
              actions: [
                if (old != null)
                  TextButton(
                      onPressed: () {
                        setState(() => work.remove(k));
                        save();
                        Navigator.pop(context);
                      },
                      child: Text(tr('delete'),
                          style: const TextStyle(color: red))),
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(tr('cancel'))),
                FilledButton(
                    onPressed: () {
                      final c = int.tryParse(count.text) ?? 0;
                      final r = double.tryParse(rate.text) ?? defaultRate;
                      setState(() => c <= 0
                          ? work.remove(k)
                          : work[k] = WorkEntry(c, r));
                      save();
                      Navigator.pop(context);
                    },
                    child: Text(tr('save'))),
              ],
            ));
  }

  Future<void> addCash(
      {required bool isAdvance, String? editDate, int? editIndex}) async {
    final map = isAdvance ? advances : payments;
    final list = map[editDate ?? ''] ?? [];
    CashEntry? old;
    if (editDate != null && editIndex != null && editIndex < list.length) {
      old = list[editIndex];
    }
    final amount = TextEditingController(text: old?.amount.toString() ?? '');
    final note = TextEditingController(text: old?.note ?? '');
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: panel,
              title: Text(isAdvance ? tr('advance') : tr('payment'),
                  style: const TextStyle(color: gold)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: tr('amount'))),
                const SizedBox(height: 12),
                TextField(
                    controller: note,
                    decoration: InputDecoration(labelText: tr('note'))),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(tr('cancel'))),
                FilledButton(
                    onPressed: () {
                      final v = double.tryParse(amount.text) ?? 0;
                      if (v <= 0) return;
                      setState(() {
                        final k = editDate ?? monthKey();
                        final target = map.putIfAbsent(k, () => []);
                        if (old != null && editIndex != null) {
                          target[editIndex] =
                              CashEntry(old!.id, v, note.text);
                        } else {
                          target.add(CashEntry(
                              DateTime.now().microsecondsSinceEpoch.toString(),
                              v,
                              note.text));
                        }
                      });
                      save();
                      Navigator.pop(context);
                    },
                    child: Text(tr('save'))),
              ],
            ));
  }

  Future<void> addAdvance() async {
    final count = advances.entries
        .where((e) => inMonth(e.key))
        .fold(0, (s, e) => s + e.value.length);
    if (count >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('max_upad'))));
      return;
    }
    await addCash(isAdvance: true);
  }

  String monthName() => [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ][month.month];

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: gold)));
    }
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 88,
        titleSpacing: 16,
        title: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Color(0xFF4B3918), Color(0xFF111111)]),
              border: Border.all(color: gold, width: 1.6),
              boxShadow: [
                BoxShadow(color: gold.withOpacity(.18), blurRadius: 12)
              ],
            ),
            child: const Icon(Icons.diamond_outlined,
                color: goldLight, size: 27),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('HiraDaily',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 21,
                          letterSpacing: .5,
                          color: goldLight)),
                  Text(tr('by'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: .8,
                          color: gold)),
                ]),
          ),
        ]),
        actions: [
          IconButton(
              onPressed: () =>
                  setState(() => month = DateTime(month.year, month.month - 1)),
              icon: const Icon(Icons.chevron_left)),
          Center(
              child: Text('${monthName()} ${month.year}',
                  style: const TextStyle(
                      color: goldLight, fontWeight: FontWeight.bold))),
          IconButton(
              onPressed: () =>
                  setState(() => month = DateTime(month.year, month.month + 1)),
              icon: const Icon(Icons.chevron_right)),
          const SizedBox(width: 4)
        ],
      ),
      body: tab == 2
          ? settings()
          : tab == 1
              ? hisab()
              : home(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: panel,
        indicatorColor: gold.withOpacity(.15),
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home, color: gold),
              label: tr('home')),
          NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long, color: gold),
              label: tr('hisab')),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings, color: gold),
              label: tr('settings')),
        ],
      ),
    );
  }

  Widget sectionTitle(String title, {String? subtitle}) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: goldLight, fontSize: 19, fontWeight: FontWeight.w800)),
          if (subtitle != null)
            Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12))),
        ]),
      );

  Widget card(String title, String value,
          {IconData? icon, bool highlight = false}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: highlight ? gold.withOpacity(.8) : gold.withOpacity(.25)),
          boxShadow: highlight
              ? [BoxShadow(color: gold.withOpacity(.08), blurRadius: 16)]
              : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (icon != null) ...[
            Icon(icon, color: gold, size: 21),
            const SizedBox(height: 9)
          ],
          Text(title,
              style: const TextStyle(
                  color: gold, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ]),
      );

  Widget home() => ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF352817), Color(0xFF17130E), panel]),
            border: Border.all(color: gold.withOpacity(.65)),
          ),
          child: Row(children: [
            const Icon(Icons.diamond, color: goldLight, size: 34),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('HiraDaily',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: goldLight)),
                  Text(tr('by'),
                      style: const TextStyle(
                          color: gold, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  const Text('DAILY HISAB  â¢  SIMPLE  â¢  SECURE',
                      style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.1,
                          color: Colors.white70)),
                ])),
          ]),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
              child: card(tr('total_hira'), totalHira.toString(),
                  icon: Icons.diamond)),
          const SizedBox(width: 10),
          Expanded(
              child: card(tr('total_work'), money(totalWork),
                  icon: Icons.currency_rupee)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: card(tr('jama'), money(totalJama),
                  icon: Icons.account_balance_wallet)),
          const SizedBox(width: 10),
          Expanded(
              child: card(tr('upad'), money(totalUpad), icon: Icons.history)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                  colors: [Color(0xFF5A421A), Color(0xFF20180D), panel]),
              border: Border.all(color: gold, width: 1.2)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('remaining'),
                    style: const TextStyle(
                        color: goldLight,
                        fontSize: 12,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(money(balance),
                    style: const TextStyle(
                        fontSize: 31,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ]),
        ),
        const SizedBox(height: 18),
        sectionTitle(tr('daily_entries')),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          value: fixedRate,
          activeColor: gold,
          title: Text(tr('fixed_rate')),
          subtitle: Text('${tr('default_rate')}: ${money(defaultRate)}'),
          onChanged: (v) {
            setState(() => fixedRate = v);
            save();
          },
        ),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('daily_entries'),
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: goldLight)),
              TextButton.icon(
                  onPressed: () => editWork(DateTime.now()),
                  icon: const Icon(Icons.add),
                  label: Text(tr('add_today'))),
            ]),
        ...List.generate(DateTime(month.year, month.month + 1, 0).day, (i) {
          final d = DateTime(month.year, month.month, i + 1);
          final k = keyDate(d);
          final e = work[k];
          final dayNames = [
            tr('mon'), tr('tue'), tr('wed'), tr('thu'),
            tr('fri'), tr('sat'), tr('sun')
          ];
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(.045))),
            child: ListTile(
              dense: true,
              onTap: () => editWork(d),
              leading: CircleAvatar(
                  backgroundColor: d.weekday == 7 ? red : const Color(0xFF302719),
                  child: Text('${d.day}',
                      style: const TextStyle(
                          color: goldLight, fontWeight: FontWeight.bold))),
              title: Text(e == null
                  ? tr('no_entry')
                  : '${e.count} ð Ã ${money(e.rate)}'),
              subtitle: Text(dayNames[d.weekday - 1],
                  style: const TextStyle(color: Colors.white54)),
              trailing: Text(e == null ? 'â' : money(e.count * e.rate),
                  style: const TextStyle(
                      color: goldLight, fontWeight: FontWeight.bold)),
            ),
          );
        }),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: gold, foregroundColor: Colors.black),
                  onPressed: addAdvance,
                  icon: const Icon(Icons.add),
                  label: Text(tr('add_upad')))),
          const SizedBox(width: 10),
          Expanded(
              child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: goldLight,
                      side: const BorderSide(color: gold)),
                  onPressed: () => addCash(isAdvance: false),
                  icon: const Icon(Icons.payments),
                  label: Text(tr('add_jama')))),
        ]),
        const SizedBox(height: 12),
        cashHistory(true),
        cashHistory(false),
      ]);

  Widget cashHistory(bool adv) {
    final m = adv ? advances : payments;
    final rows = m.entries
        .where((e) => inMonth(e.key))
        .expand((e) => e.value.map((c) => (e.key, c)))
        .toList();
    return Card(
      child: ExpansionTile(
        iconColor: gold,
        collapsedIconColor: gold,
        title: Text(adv ? tr('upad_history') : tr('jama_history'),
            style: const TextStyle(color: goldLight, fontWeight: FontWeight.bold)),
        children: rows.map((row) {
          final date = row.$1;
          final c = row.$2;
          final idx = m[date]!.indexOf(c);
          return ListTile(
            title: Text(money(c.amount)),
            subtitle: Text('$date${c.note.isEmpty ? '' : ' â¢ ${c.note}'}'),
            trailing: Wrap(children: [
              IconButton(
                  onPressed: () =>
                      addCash(isAdvance: adv, editDate: date, editIndex: idx),
                  icon: const Icon(Icons.edit, color: gold)),
              IconButton(
                  onPressed: () {
                    setState(() => m[date]!.removeAt(idx));
                    save();
                  },
                  icon: const Icon(Icons.delete_outline, color: red)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget hisab() => ListView(padding: const EdgeInsets.all(16), children: [
        sectionTitle(tr('monthly_hisab'),
            subtitle: '${monthName()} ${month.year}'),
        card(tr('total_hira'), totalHira.toString(), icon: Icons.diamond),
        const SizedBox(height: 10),
        card(tr('total_work'), money(totalWork),
            icon: Icons.currency_rupee),
        const SizedBox(height: 10),
        card(tr('jama'), money(totalJama),
            icon: Icons.account_balance_wallet),
        const SizedBox(height: 10),
        card(tr('upad'), money(totalUpad), icon: Icons.history),
        const SizedBox(height: 10),
        card(tr('remaining'), money(balance), highlight: true),
        const SizedBox(height: 16),
        cashHistory(false),
        cashHistory(true),
      ]);

  Widget settings() => ListView(padding: const EdgeInsets.all(16), children: [
        sectionTitle(tr('settings')),
        Text(tr('language'),
            style: const TextStyle(
                color: goldLight, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 5),
        Text(tr('language_hint'),
            style: const TextStyle(color: Colors.white54)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: gold.withOpacity(.35))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: language,
              isExpanded: true,
              dropdownColor: panel,
              iconEnabledColor: gold,
              items: [
                DropdownMenuItem(
                    value: 'en', child: Text('ð¬ð§  ${tr('english')}')),
                DropdownMenuItem(
                    value: 'hi', child: Text('ð®ð³  ${tr('hindi')}')),
                DropdownMenuItem(
                    value: 'gu', child: Text('ð®ð³  ${tr('gujarati')}')),
              ],
              onChanged: (v) {
                if (v != null) changeLanguage(v);
              },
            ),
          ),
        ),
        const SizedBox(height: 22),
        TextField(
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: tr('rate_label'),
                hintText: defaultRate.toString()),
            onSubmitted: (v) {
              final n = double.tryParse(v);
              if (n != null) {
                setState(() => defaultRate = n);
                save();
              }
            }),
        const SizedBox(height: 12),
        SwitchListTile(
            value: fixedRate,
            activeColor: gold,
            title: Text(tr('fixed_default')),
            onChanged: (v) {
              setState(() => fixedRate = v);
              save();
            }),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: gold.withOpacity(.2))),
          child: Row(children: [
            const Icon(Icons.lock_outline, color: gold),
            const SizedBox(width: 10),
            Expanded(
                child: Text(tr('saved_phone'),
                    style: const TextStyle(color: Colors.white70))),
          ]),
        ),
        const SizedBox(height: 22),
        const Center(
            child: Text('HiraDaily  â¢  By Ashish Meniya',
                style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1))),
      ]);
}
