import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'result_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';

class SearchScreen extends StatefulWidget {
  final ApiService api; final ValueChanged<bool> onThemeToggle; final bool darkMode;
  const SearchScreen({super.key,required this.api,required this.onThemeToggle,required this.darkMode});
  State<SearchScreen> createState()=>_SearchScreenState();
}
class _SearchScreenState extends State<SearchScreen>{
  final controller=TextEditingController(); List<String> recent=[]; String? filter,error; bool loading=false;
  void initState(){super.initState();load();}
  Future<void> load()async{final p=await SharedPreferences.getInstance();setState(()=>recent=p.getStringList('recent_searches')??[]);}
  Future<void> save(String q)async{final p=await SharedPreferences.getInstance();recent.remove(q);recent.insert(0,q);recent=recent.take(8).toList();await p.setStringList('recent_searches',recent);setState((){});}
  Future<void> search([String? explicit])async{
    final q=(explicit??controller.text).trim();if(q.isEmpty)return;
    setState((){loading=true;error=null;});
    try{
      if(RegExp(r'^\\d{4}-\\d{2}-\\d{2}$').hasMatch(q)){
        final rs=await widget.api.traceDate(q);await save(q);
        if(!mounted)return;
        if(rs.isEmpty)setState(()=>error='No transactions found for $q.');else Navigator.push(context,MaterialPageRoute(builder:(_)=>ResultScreen(api:widget.api,trace:rs.first,dateResults:rs)));
      }else{final tr=await widget.api.trace(q);await save(q);if(mounted)Navigator.push(context,MaterialPageRoute(builder:(_)=>ResultScreen(api:widget.api,trace:tr)));}
    }catch(e){if(mounted)setState(()=>error=e.toString());}finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> pickDate()async{final d=await showDatePicker(context:context,firstDate:DateTime(2026,1),lastDate:DateTime(2027,12),initialDate:DateTime(2026,3));if(d!=null){controller.text=DateFormat('yyyy-MM-dd').format(d);search();}}
  Widget build(BuildContext c){return Scaffold(body:SafeArea(child:LayoutBuilder(builder:(_,size){final wide=size.maxWidth>900;return SingleChildScrollView(padding:EdgeInsets.symmetric(horizontal:wide?size.maxWidth*.12:20,vertical:28),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Container(width:46,height:46,decoration:BoxDecoration(color:AppTheme.teal.withOpacity(.13),borderRadius:BorderRadius.circular(15)),child:const Icon(Icons.account_tree_rounded,color:AppTheme.teal)),const SizedBox(width:12),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Settlement Q&A',style:TextStyle(fontWeight:FontWeight.w900,fontSize:20)),Text('Trace the money. Explain the outcome.',style:TextStyle(color:Colors.white54))])),IconButton(onPressed:()=>widget.onThemeToggle(!widget.darkMode),icon:Icon(widget.darkMode?Icons.light_mode_rounded:Icons.dark_mode_rounded)),IconButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>DashboardScreen(api:widget.api))),icon:const Icon(Icons.insights_rounded)),IconButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>HistoryScreen(api:widget.api))),icon:const Icon(Icons.history_rounded))]),
    const SizedBox(height:60),Text('Where did this settlement go?',style:Theme.of(c).textTheme.displaySmall?.copyWith(fontWeight:FontWeight.w900,height:1.05)),const SizedBox(height:12),const Text('Enter a transaction ID or choose a date. The agent cross-checks gateway, bank and ledger evidence before explaining what happened.',style:TextStyle(color:Colors.white54,fontSize:15,height:1.5)),const SizedBox(height:28),
    Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:Theme.of(c).cardColor,borderRadius:BorderRadius.circular(22),border:Border.all(color:Colors.white10)),child:Row(children:[const SizedBox(width:12),const Icon(Icons.search_rounded,color:AppTheme.teal),const SizedBox(width:10),Expanded(child:TextField(controller:controller,onSubmitted:(_)=>search(),decoration:const InputDecoration(hintText:'TXN100123 or 2026-03-12',border:InputBorder.none,enabledBorder:InputBorder.none,focusedBorder:InputBorder.none,fillColor:Colors.transparent))),IconButton(onPressed:pickDate,icon:const Icon(Icons.calendar_month_rounded)),FilledButton(onPressed:loading?null:search,child:loading?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Text('Trace'))])),
    if(error!=null)...[const SizedBox(height:14),GradientCard(child:Row(children:[const Icon(Icons.error_outline,color:AppTheme.red),const SizedBox(width:10),Expanded(child:Text(error!))]))],
    const SizedBox(height:26),Wrap(spacing:8,runSpacing:8,children:['delayed','failed','mismatched','settled'].map((s)=>FilterChip(label:Text(s[0].toUpperCase()+s.substring(1)),selected:filter==s,onSelected:(_)async{setState(()=>filter=s);try{final txs=await widget.api.transactions(status:s);if(txs.isNotEmpty&&mounted){controller.text=txs.first.transactionId;search();}}catch(e){setState(()=>error=e.toString());}})).toList()),
    const SizedBox(height:38),if(recent.isNotEmpty)...[Row(children:[const Text('Recent searches',style:TextStyle(fontWeight:FontWeight.w800)),const Spacer(),TextButton(onPressed:()async{final p=await SharedPreferences.getInstance();await p.remove('recent_searches');setState(()=>recent=[]);},child:const Text('Clear'))]),const SizedBox(height:10),Wrap(spacing:10,runSpacing:10,children:recent.map((q)=>ActionChip(label:Text(q),onPressed:(){controller.text=q;search();})).toList())],
    const SizedBox(height:40),GradientCard(child:Row(children:[const Icon(Icons.verified_user_outlined,color:AppTheme.teal,size:30),const SizedBox(width:14),const Expanded(child:Text('Evidence-first by design. Missing or conflicting source data is surfaced as an exception instead of being guessed away.',style:TextStyle(color:Colors.white70,height:1.4)))]))
  ]);}),));}
}
