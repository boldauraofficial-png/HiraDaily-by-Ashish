import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const HiraDailyApp());

const gold = Color(0xFFD6AD55);
const red = Color(0xFF9E2638);
const bg = Color(0xFF080A0F);
const panel = Color(0xFF151923);

class HiraDailyApp extends StatelessWidget {
  const HiraDailyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'HiraDaily by Ashish',
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(primary: gold, secondary: red),
      appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: gold),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: const Color(0xFF202633),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        labelStyle: const TextStyle(color: gold),
      ),
    ),
    home: const Dashboard(),
  );
}

class WorkEntry {
  int count; double rate;
  WorkEntry(this.count, this.rate);
  Map<String,dynamic> toJson() => {'count':count,'rate':rate};
  factory WorkEntry.fromJson(Map<String,dynamic> j) => WorkEntry(j['count'] ?? 0, (j['rate'] ?? 0).toDouble());
}
class CashEntry {
  String id; double amount; String note;
  CashEntry(this.id,this.amount,this.note);
  Map<String,dynamic> toJson()=>{'id':id,'amount':amount,'note':note};
  factory CashEntry.fromJson(Map<String,dynamic> j)=>CashEntry(j['id'],(j['amount']??0).toDouble(),j['note']??'');
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override State<Dashboard> createState()=>_DashboardState();
}
class _DashboardState extends State<Dashboard> {
  DateTime month = DateTime.now();
  Map<String,WorkEntry> work = {};
  Map<String,List<CashEntry>> advances = {};
  Map<String,List<CashEntry>> payments = {};
  bool fixedRate = true;
  double defaultRate = 2;
  int tab = 0;
  bool loaded = false;

  String keyDate(DateTime d)=>'${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  String monthKey()=>'${month.year}-${month.month.toString().padLeft(2,'0')}';
  String money(double n)=>'₹${n.toStringAsFixed(n.truncateToDouble()==n ? 0 : 2)}';
  bool inMonth(String k)=>k.startsWith(monthKey());

  @override void initState(){super.initState(); load();}
  Future<void> load() async {
    final p=await SharedPreferences.getInstance();
    final w=p.getString('work')??'{}', a=p.getString('advances')??'{}', pay=p.getString('payments')??'{}';
    setState((){
      (jsonDecode(w) as Map<String,dynamic>).forEach((k,v)=>work[k]=WorkEntry.fromJson(v));
      (jsonDecode(a) as Map<String,dynamic>).forEach((k,v)=>advances[k]=(v as List).map((e)=>CashEntry.fromJson(e)).toList());
      (jsonDecode(pay) as Map<String,dynamic>).forEach((k,v)=>payments[k]=(v as List).map((e)=>CashEntry.fromJson(e)).toList());
      fixedRate=p.getBool('fixedRate')??true; defaultRate=p.getDouble('rate')??2; loaded=true;
    });
  }
  Future<void> save() async {
    final p=await SharedPreferences.getInstance();
    await p.setString('work',jsonEncode(work.map((k,v)=>MapEntry(k,v.toJson()))));
    await p.setString('advances',jsonEncode(advances.map((k,v)=>MapEntry(k,v.map((e)=>e.toJson()).toList()))));
    await p.setString('payments',jsonEncode(payments.map((k,v)=>MapEntry(k,v.map((e)=>e.toJson()).toList()))));
    await p.setBool('fixedRate',fixedRate); await p.setDouble('rate',defaultRate);
  }
  double get totalWork=>work.entries.where((e)=>inMonth(e.key)).fold(0,(s,e)=>s+e.value.count*e.value.rate);
  int get totalHira=>work.entries.where((e)=>inMonth(e.key)).fold(0,(s,e)=>s+e.value.count);
  double get totalUpad=>advances.entries.where((e)=>inMonth(e.key)).fold(0,(s,e)=>s+e.value.fold(0,(x,c)=>x+c.amount));
  double get totalJama=>payments.entries.where((e)=>inMonth(e.key)).fold(0,(s,e)=>s+e.value.fold(0,(x,c)=>x+c.amount));
  double get balance=>totalWork-totalJama-totalUpad;

  Future<void> editWork(DateTime d) async {
    final k=keyDate(d); final old=work[k];
    final count=TextEditingController(text:old?.count.toString()??'');
    final rate=TextEditingController(text:(old?.rate??defaultRate).toString());
    await showDialog(context:context,builder:(_)=>AlertDialog(
      backgroundColor:panel, title:Text('દૈનિક હીરા - ${d.day}/${d.month}/${d.year}',style:const TextStyle(color:gold)),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:count,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'હીરાની સંખ્યા')),
        const SizedBox(height:12),
        TextField(controller:rate,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'દર (₹ પ્રતિ હીરો)')),
      ]),
      actions:[
        if(old!=null) TextButton(onPressed:(){setState(()=>work.remove(k));save();Navigator.pop(context);},child:const Text('Delete',style:TextStyle(color:red))),
        TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),
        FilledButton(onPressed:(){
          final c=int.tryParse(count.text)??0, r=double.tryParse(rate.text)??defaultRate;
          setState(()=> c<=0 ? work.remove(k) : work[k]=WorkEntry(c,r));
          save(); Navigator.pop(context);
        },child:const Text('Save')),
      ],
    ));
  }
  Future<void> addCash({required bool isAdvance, String? editDate, int? editIndex}) async {
    final map=isAdvance?advances:payments;
    final list=map[editDate??'']??[];
    CashEntry? old;
    if(editDate!=null && editIndex!=null && editIndex<list.length) old=list[editIndex];
    final amount=TextEditingController(text:old?.amount.toString()??'');
    final note=TextEditingController(text:old?.note??'');
    await showDialog(context:context,builder:(_)=>AlertDialog(
      backgroundColor:panel,
      title:Text(isAdvance?'ઉપાડ / Advance':'જમા / Payment',style:const TextStyle(color:gold)),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'રકમ (₹)')),
        const SizedBox(height:12),TextField(controller:note,decoration:const InputDecoration(labelText:'નોંધ (optional)')),
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),
        FilledButton(onPressed:(){
          final v=double.tryParse(amount.text)??0; if(v<=0)return;
          setState((){
            final k=editDate??monthKey();
            final target=map.putIfAbsent(k,()=>[]);
            if(old!=null && editIndex!=null) target[editIndex]=CashEntry(old!.id,v,note.text);
            else target.add(CashEntry(DateTime.now().microsecondsSinceEpoch.toString(),v,note.text));
          });
          save();Navigator.pop(context);
        },child:const Text('Save')),
      ],
    ));
  }
  Future<void> addAdvance() async {
    final count=advances.entries.where((e)=>inMonth(e.key)).fold(0,(s,e)=>s+e.value.length);
    if(count>=2){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('આ મહિને વધુમાં વધુ 2 ઉપાડ જ કરી શકાય.')));return;}
    await addCash(isAdvance:true);
  }
  String monthName()=>['','January','February','March','April','May','June','July','August','September','October','November','December'][month.month];
  @override Widget build(BuildContext context){
    if(!loaded)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    return Scaffold(
      appBar:AppBar(toolbarHeight:82,title:Row(children:[
        Container(width:42,height:42,decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:gold,width:1.5),gradient:const LinearGradient(colors:[Color(0xFF332710),Color(0xFF090A0D)])),child:const Icon(Icons.diamond,color:gold)),
        const SizedBox(width:10),const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('HiraDaily',style:TextStyle(fontWeight:FontWeight.bold,letterSpacing:1.2)),Text('by Ashish',style:TextStyle(fontSize:11,color:red))])
      ]),actions:[IconButton(onPressed:()=>setState(()=>month=DateTime(month.year,month.month-1)),icon:const Icon(Icons.chevron_left)),Center(child:Text('${monthName()} ${month.year}',style:const TextStyle(color:gold,fontWeight:FontWeight.bold))),IconButton(onPressed:()=>setState(()=>month=DateTime(month.year,month.month+1)),icon:const Icon(Icons.chevron_right)),const SizedBox(width:8)]),
      body: tab==2 ? settings() : tab==1 ? hisab() : home(),
      bottomNavigationBar:NavigationBar(backgroundColor:panel,indicatorColor:gold.withOpacity(.15),selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const[
        NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home,color:gold),label:'Home'),
        NavigationDestination(icon:Icon(Icons.receipt_long_outlined),selectedIcon:Icon(Icons.receipt_long,color:gold),label:'Hisab'),
        NavigationDestination(icon:Icon(Icons.settings_outlined),selectedIcon:Icon(Icons.settings,color:gold),label:'Settings'),
      ]),
    );
  }
  Widget card(String title,String value,{IconData? icon})=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(18),border:Border.all(color:gold.withOpacity(.35))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[if(icon!=null)Icon(icon,color:gold),Text(title,style:const TextStyle(color:gold,fontSize:13)),const SizedBox(height:8),Text(value,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold))]));
  Widget home()=>ListView(padding:const EdgeInsets.all(16),children:[
    Row(children:[Expanded(child:card('Total Hira',totalHira.toString(),icon:Icons.diamond)),const SizedBox(width:10),Expanded(child:card('Total Work',money(totalWork),icon:Icons.currency_rupee))]),
    const SizedBox(height:12),
    Row(children:[Expanded(child:card('Jama',money(totalJama),icon:Icons.account_balance_wallet)),const SizedBox(width:10),Expanded(child:card('Upad',money(totalUpad),icon:Icons.history))]),
    const SizedBox(height:12),
    Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),gradient:const LinearGradient(colors:[Color(0xFF392B13),Color(0xFF151923)]),border:Border.all(color:gold)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('REMAINING BALANCE',style:TextStyle(color:gold)),const SizedBox(height:8),Text(money(balance),style:const TextStyle(fontSize:30,fontWeight:FontWeight.bold,color:Colors.white))])),
    const SizedBox(height:16),
    SwitchListTile(value:fixedRate,activeColor:gold,title:const Text('Fixed Rate'),subtitle:Text('Default rate: ${money(defaultRate)} per Hira'),onChanged:(v){setState(()=>fixedRate=v);save();}),
    const SizedBox(height:8),
    Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Daily entries',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:gold)),TextButton.icon(onPressed:()=>editWork(DateTime.now()),icon:const Icon(Icons.add),label:const Text('Add today'))]),
    ...List.generate(DateTime(month.year,month.month+1,0).day,(i){
      final d=DateTime(month.year,month.month,i+1), k=keyDate(d), e=work[k];
      return Card(color:panel,child:ListTile(onTap:()=>editWork(d),leading:CircleAvatar(backgroundColor:d.weekday==7?red:const Color(0xFF292F3C),child:Text('${d.day}',style:const TextStyle(color:gold))),title:Text(e==null?'No entry':'${e.count} 💎 × ${money(e.rate)}'),subtitle:Text(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d.weekday-1]),trailing:Text(e==null?'—':money(e.count*e.rate),style:const TextStyle(color:gold,fontWeight:FontWeight.bold))));
    }),
    const SizedBox(height:12),
    Row(children:[Expanded(child:FilledButton.icon(onPressed:addAdvance,icon:const Icon(Icons.add),label:const Text('Add Upad'))),const SizedBox(width:10),Expanded(child:OutlinedButton.icon(onPressed:()=>addCash(isAdvance:false),icon:const Icon(Icons.payments),label:const Text('Add Jama')))]),
    const SizedBox(height:12),cashHistory(true),cashHistory(false),
  ]);
  Widget cashHistory(bool adv){
    final m=adv?advances:payments;
    final rows=m.entries.where((e)=>inMonth(e.key)).expand((e)=>e.value.map((c)=>(e.key,c))).toList();
    return Card(color:panel,child:ExpansionTile(title:Text(adv?'Upad history':'Jama history',style:const TextStyle(color:gold)),children:rows.map((row){
      final date=row.$1, c=row.$2, idx=m[date]!.indexOf(c);
      return ListTile(title:Text(money(c.amount)),subtitle:Text('${date}${c.note.isEmpty?'':' • ${c.note}'}'),trailing:Wrap(children:[
        IconButton(onPressed:()=>addCash(isAdvance:adv,editDate:date,editIndex:idx),icon:const Icon(Icons.edit,color:gold)),
        IconButton(onPressed:(){setState(()=>m[date]!.removeAt(idx));save();},icon:const Icon(Icons.delete_outline,color:red)),
      ]));
    }).toList()));
  }
  Widget hisab()=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('Monthly Hisab',style:TextStyle(fontSize:22,color:gold,fontWeight:FontWeight.bold)),
    const SizedBox(height:16),card('Total Hira',totalHira.toString()),const SizedBox(height:10),
    card('Total Work',money(totalWork)),const SizedBox(height:10),card('Jama',money(totalJama)),const SizedBox(height:10),
    card('Upad',money(totalUpad)),const SizedBox(height:10),card('Remaining Balance',money(balance)),
    const SizedBox(height:16),cashHistory(false),cashHistory(true),
  ]);
  Widget settings()=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('Settings',style:TextStyle(fontSize:22,color:gold,fontWeight:FontWeight.bold)),
    const SizedBox(height:16),TextField(keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:'Default rate per Hira (₹)',hintText:defaultRate.toString()),onSubmitted:(v){final n=double.tryParse(v);if(n!=null){setState(()=>defaultRate=n);save();}}),
    const SizedBox(height:12),SwitchListTile(value:fixedRate,activeColor:gold,title:const Text('Use fixed rate by default'),onChanged:(v){setState(()=>fixedRate=v);save();}),
    const SizedBox(height:16),const Text('Data is saved on this phone. Export/restore and cloud backup can be added in a later version.',style:TextStyle(color:Colors.white70)),
  ]);
}
