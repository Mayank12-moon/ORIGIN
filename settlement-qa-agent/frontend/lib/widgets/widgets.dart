import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

Color statusColor(String s)=>switch(s){'settled'=>AppTheme.green,'delayed'=>AppTheme.amber,'failed'=>AppTheme.red,'mismatched'=>Colors.orangeAccent,_=>AppTheme.blue};

class GradientCard extends StatelessWidget {
  final Widget child; final EdgeInsets padding;
  const GradientCard({super.key,required this.child,this.padding=const EdgeInsets.all(20)});
  Widget build(BuildContext c)=>Container(padding:padding,decoration:BoxDecoration(color:Theme.of(c).cardColor,borderRadius:BorderRadius.circular(22),gradient:LinearGradient(colors:[Theme.of(c).cardColor,Theme.of(c).cardColor.withOpacity(.82)]),boxShadow:[BoxShadow(color:Colors.black.withOpacity(.16),blurRadius:30,offset:const Offset(0,14))]),child:child);
}
class StatusBadge extends StatelessWidget {
  final String status; const StatusBadge({super.key,required this.status});
  Widget build(BuildContext c){final col=statusColor(status);return Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:7),decoration:BoxDecoration(color:col.withOpacity(.13),borderRadius:BorderRadius.circular(30),border:Border.all(color:col.withOpacity(.35))),child:Text(status.toUpperCase(),style:TextStyle(color:col,fontWeight:FontWeight.w800,fontSize:11,letterSpacing:.7)));}
}
class AnimatedConfidenceRing extends StatelessWidget {
  final double confidence; const AnimatedConfidenceRing({super.key,required this.confidence});
  Widget build(BuildContext c)=>TweenAnimationBuilder<double>(tween:Tween(begin:0,end:confidence),duration:const Duration(milliseconds:900),builder:(_,v,__)=>
    SizedBox(width:92,height:92,child:Stack(alignment:Alignment.center,children:[SizedBox(width:82,height:82,child:CircularProgressIndicator(value:v,strokeWidth:8,backgroundColor:Colors.white10,color:v>=.8?AppTheme.green:AppTheme.amber)),Text('${(v*100).round()}%',style:const TextStyle(fontWeight:FontWeight.w900,fontSize:18))])));
}
class TimelineNode extends StatefulWidget {
  final TimelineStage stage; final bool last;
  const TimelineNode({super.key,required this.stage,required this.last});
  State<TimelineNode> createState()=>_TimelineNodeState();
}
class _TimelineNodeState extends State<TimelineNode> {
  bool expanded=false;
  Widget build(BuildContext c){
    final col=statusColor(widget.stage.status);
    String tm=widget.stage.timestamp??'Timestamp unavailable';
    try{tm=DateFormat('dd MMM yyyy • HH:mm').format(DateTime.parse(tm).toLocal());}catch(_){}
    return Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      SizedBox(width:34,child:Column(children:[Container(width:18,height:18,decoration:BoxDecoration(shape:BoxShape.circle,color:col,boxShadow:[BoxShadow(color:col.withOpacity(.35),blurRadius:14)])),if(!widget.last)Container(width:2,height:100,margin:const EdgeInsets.only(top:5),color:Colors.white10)])),
      const SizedBox(width:14),
      Expanded(child:Padding(padding:const EdgeInsets.only(bottom:22),child:InkWell(borderRadius:BorderRadius.circular(16),onTap:()=>setState(()=>expanded=!expanded),child:Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white.withOpacity(.035),borderRadius:BorderRadius.circular(16)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Text(widget.stage.stage,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16)),const Spacer(),StatusBadge(status:widget.stage.status)]),
        const SizedBox(height:7),Text(tm,style:const TextStyle(color:Colors.white54,fontSize:12)),Text(widget.stage.source,style:const TextStyle(color:Colors.white38,fontSize:11)),
        if(expanded)...[const SizedBox(height:14),Container(width:double.infinity,padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.black26,borderRadius:BorderRadius.circular(12)),child:SelectableText(widget.stage.rawFields.entries.map((e)=>'${e.key}: ${e.value}').join('\n'),style:const TextStyle(fontFamily:'monospace',fontSize:11,height:1.5)))]
      ])))),
    ]);
  }
}
class ExceptionTile extends StatelessWidget {
  final ExceptionItem item; const ExceptionTile({super.key,required this.item});
  Widget build(BuildContext c){final col=item.severity=='critical'?AppTheme.red:AppTheme.amber;return Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:col.withOpacity(.07),borderRadius:BorderRadius.circular(16),border:Border.all(color:col.withOpacity(.18))),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(item.severity=='critical'?Icons.error_outline:Icons.warning_amber_rounded,color:col),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(item.field,style:TextStyle(color:col,fontWeight:FontWeight.w800)),const SizedBox(height:3),Text(item.message,style:const TextStyle(color:Colors.white70,height:1.35))]))]));}
}
