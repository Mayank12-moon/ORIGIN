import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class ResultScreen extends StatelessWidget {
  final ApiService api; final TraceResult trace; final List<TraceResult>? dateResults;
  const ResultScreen({super.key,required this.api,required this.trace,this.dateResults});

  String exportText(){
    final ex=trace.exceptions.isEmpty?'None':trace.exceptions.map((e)=>'- ${e.field}: ${e.message}').join('\n');
    return "Settlement Q&A — ${trace.transactionId}\nOverall status: ${trace.overallStatus}\nConfidence: ${(trace.confidence*100).round()}%\n\nExplanation:\n${trace.explanation}\n\nTimeline:\n${trace.timeline.map((x)=>'${x.stage}: ${x.status} @ ${x.timestamp??"n/a"}').join("\n")}\n\nException List:\n$ex";
  }

  Widget build(BuildContext context){
    final wide=MediaQuery.of(context).size.width>900;
    return Scaffold(appBar:AppBar(title:Text(trace.transactionId,style:const TextStyle(fontWeight:FontWeight.w800)),backgroundColor:Colors.transparent,actions:[
      IconButton(onPressed:(){Clipboard.setData(ClipboardData(text:exportText()));ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Trace copied to clipboard')));},icon:const Icon(Icons.copy_rounded)),
      IconButton(onPressed:()=>Share.share(exportText()),icon:const Icon(Icons.ios_share_rounded)),
    ]),body:SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(20,8,20,50),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1180),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      header(context),const SizedBox(height:20),if(dateResults!=null&&dateResults!.length>1)dateStrip(context),const SizedBox(height:20),
      if(wide)Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:timelineCard(context)),const SizedBox(width:20),Expanded(child:Column(children:[explanationCard(context),const SizedBox(height:20),exceptionsCard(context)]))])
      else Column(children:[timelineCard(context),const SizedBox(height:20),explanationCard(context),const SizedBox(height:20),exceptionsCard(context)])
    ])))));
  }

  Widget header(BuildContext c)=>GradientCard(child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('Settlement outcome',style:TextStyle(color:Colors.white54,fontSize:13)),const SizedBox(height:8),
    Row(children:[StatusBadge(status:trace.overallStatus),const SizedBox(width:10),Text(trace.transactionId,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:18))]),
    const SizedBox(height:14),Text(headline(),style:const TextStyle(fontSize:16,fontWeight:FontWeight.w700))
  ])),AnimatedConfidenceRing(confidence:trace.confidence)]));
  String headline()=>switch(trace.overallStatus){'settled'=>'Evidence supports a completed settlement.','delayed'=>'Settlement is not complete end-to-end yet.','failed'=>'The payment did not complete successfully.','mismatched'=>'Source records disagree and need reconciliation.',_=>'The available evidence is incomplete.'};

  Widget timelineCard(BuildContext c)=>GradientCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('Trace timeline',style:TextStyle(fontWeight:FontWeight.w900,fontSize:19)),const SizedBox(height:6),const Text('Tap a stage to inspect raw source fields.',style:TextStyle(color:Colors.white54)),const SizedBox(height:22),
    if(trace.timeline.isEmpty)const Text('No source records were found.') else ...trace.timeline.asMap().entries.map((e)=>TimelineNode(stage:e.value,last:e.key==trace.timeline.length-1))
  ]));
  Widget explanationCard(BuildContext c)=>GradientCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Row(children:[Icon(Icons.auto_awesome_rounded,color:AppTheme.teal),SizedBox(width:9),Text('Plain-English Explanation',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18))]),const SizedBox(height:14),SelectableText(trace.explanation,style:const TextStyle(fontSize:15,height:1.55))]));
  Widget exceptionsCard(BuildContext c)=>GradientCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Icon(trace.exceptions.isEmpty?Icons.check_circle_outline:Icons.warning_amber_rounded,color:trace.exceptions.isEmpty?AppTheme.green:AppTheme.amber),const SizedBox(width:9),const Text('Exception List',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18)),const Spacer(),Text('${trace.exceptions.length}',style:const TextStyle(fontWeight:FontWeight.w900))]),
    const SizedBox(height:8),const Text('Nothing uncertain is hidden from the support agent.',style:TextStyle(color:Colors.white54)),const SizedBox(height:16),
    if(trace.exceptions.isEmpty)const Text('No missing, conflicting, or suspicious fields were detected.',style:TextStyle(color:AppTheme.green)) else ...trace.exceptions.map((x)=>ExceptionTile(item:x))
  ]));
  Widget dateStrip(BuildContext c)=>SizedBox(height:58,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:dateResults!.length,separatorBuilder:(_,__)=>const SizedBox(width:8),itemBuilder:(_,i)=>OutlinedButton(onPressed:()=>Navigator.pushReplacement(c,MaterialPageRoute(builder:(_)=>ResultScreen(api:api,trace:dateResults![i],dateResults:dateResults))),child:Row(children:[StatusBadge(status:dateResults![i].overallStatus),const SizedBox(width:8),Text(dateResults![i].transactionId)]))));
}
