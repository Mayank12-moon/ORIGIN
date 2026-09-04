import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  final ApiService api; const HistoryScreen({super.key,required this.api});
  State<HistoryScreen> createState()=>_HistoryScreenState();
}
class _HistoryScreenState extends State<HistoryScreen>{
  List<String> history=[]; String filter='';
  void initState(){super.initState();load();}
  Future<void> load()async{final p=await SharedPreferences.getInstance();setState(()=>history=p.getStringList('recent_searches')??[]);}
  Future<void> del(int i)async{final p=await SharedPreferences.getInstance();history.removeAt(i);await p.setStringList('recent_searches',history);setState((){});}
  Widget build(BuildContext c){final shown=history.where((x)=>x.toLowerCase().contains(filter.toLowerCase())).toList();return Scaffold(appBar:AppBar(title:const Text('Query history',style:TextStyle(fontWeight:FontWeight.w900))),body:Column(children:[
    Padding(padding:const EdgeInsets.all(16),child:TextField(onChanged:(v)=>setState(()=>filter=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search history'))),
    Expanded(child:shown.isEmpty?const Center(child:Text('No saved searches yet.')):ListView.builder(itemCount:shown.length,itemBuilder:(_,i)=>Dismissible(key:ValueKey(shown[i]),direction:DismissDirection.endToStart,onDismissed:(_)=>del(history.indexOf(shown[i])),background:Container(color:Colors.redAccent,alignment:Alignment.centerRight,padding:const EdgeInsets.only(right:20),child:const Icon(Icons.delete_outline)),child:ListTile(leading:const Icon(Icons.history_rounded),title:Text(shown[i]),trailing:const Icon(Icons.chevron_right),onTap:()async{try{final tr=await widget.api.trace(shown[i]);if(c.mounted)Navigator.push(c,MaterialPageRoute(builder:(_)=>ResultScreen(api:widget.api,trace:tr)));}catch(_){}}))))
  ]));}
}
