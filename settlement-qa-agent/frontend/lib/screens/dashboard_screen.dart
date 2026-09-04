import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  final ApiService api; const DashboardScreen({super.key,required this.api});
  State<DashboardScreen> createState()=>_DashboardScreenState();
}
class _DashboardScreenState extends State<DashboardScreen>{
  Map<String,dynamic>? data; String? error;
  void initState(){super.initState();load();}
  Future<void> load()async{try{setState(()=>data=null);final d=await widget.api.analytics();if(mounted)setState(()=>data=d);}catch(e){if(mounted)setState(()=>error=e.toString());}}
  Widget build(BuildContext c){
    if(error!=null)return Scaffold(appBar:AppBar(title:const Text('Analytics')),body:Center(child:Text(error!)));
    if(data==null)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    final counts=Map<String,dynamic>.from(data!['status_counts']??{}), trend=List<Map<String,dynamic>>.from((data!['delay_trend']??[]).map((x)=>Map<String,dynamic>.from(x)));
    return Scaffold(appBar:AppBar(title:const Text('Settlement Intelligence',style:TextStyle(fontWeight:FontWeight.w900))),body:RefreshIndicator(onRefresh:load,child:SingleChildScrollView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.all(20),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1100),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Wrap(spacing:12,runSpacing:12,children:[metric('Average delay','${data!['average_settlement_delay_hours']}h',Icons.schedule_rounded),metric('Transactions','${counts.values.fold<int>(0,(a,b)=>a+(b as num).toInt())}',Icons.receipt_long_rounded),metric('Exceptions','${(data!['exception_frequency'] as Map).values.fold<int>(0,(a,b)=>a+(b as num).toInt())}',Icons.warning_amber_rounded)]),
      const SizedBox(height:20),Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Expanded(child:GradientCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Status breakdown',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18)),const SizedBox(height:18),SizedBox(height:270,child:PieChart(PieChartData(centerSpaceRadius:55,sectionsSpace:3,sections:counts.entries.map((e)=>PieChartSectionData(value:(e.value as num).toDouble(),title:'${e.value}',radius:85,color:statusColor(e.key),titleStyle:const TextStyle(fontWeight:FontWeight.w900))).toList()))),Wrap(spacing:10,children:counts.keys.map((k)=>Row(mainAxisSize:MainAxisSize.min,children:[Container(width:9,height:9,decoration:BoxDecoration(color:statusColor(k),shape:BoxShape.circle)),const SizedBox(width:5),Text(k)])).toList())]))),
        const SizedBox(width:20),
        Expanded(child:GradientCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Delay trend',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18)),const SizedBox(height:18),SizedBox(height:300,child:trend.isEmpty?const Center(child:Text('No delay data')):LineChart(LineChartData(gridData:const FlGridData(show:false),titlesData:const FlTitlesData(rightTitles:AxisTitles(sideTitles:SideTitles(showTitles:false)),topTitles:AxisTitles(sideTitles:SideTitles(showTitles:false))),lineBarsData:[LineChartBarData(spots:trend.asMap().entries.map((e)=>FlSpot(e.key.toDouble(),(e.value['average_delay_hours'] as num).toDouble())).toList(),isCurved:true,barWidth:3,dotData:const FlDotData(show:false))])))])))
      ]),
      const SizedBox(height:20),GradientCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Exception frequency by field',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18)),const SizedBox(height:15),...Map<String,dynamic>.from(data!['exception_frequency']??{}).entries.map((e)=>Padding(padding:const EdgeInsets.only(bottom:10),child:Row(children:[Expanded(child:Text(e.key)),Text('${e.value}',style:const TextStyle(fontWeight:FontWeight.w900))])))]))
    ])))));
  }
  Widget metric(String t,String v,IconData i)=>SizedBox(width:250,child:GradientCard(child:Row(children:[Icon(i,color:AppTheme.teal),const SizedBox(width:13),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t,style:const TextStyle(color:Colors.white54)),const SizedBox(height:4),Text(v,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900))])])));
}
