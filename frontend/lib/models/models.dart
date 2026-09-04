class TimelineStage {
  final String stage,status,source;
  final String? timestamp;
  final Map<String,dynamic> rawFields;
  TimelineStage({required this.stage,required this.status,this.timestamp,required this.source,required this.rawFields});
  factory TimelineStage.fromJson(Map<String,dynamic> j)=>TimelineStage(stage:j['stage']??'',status:j['status']??'unknown',timestamp:j['timestamp'],source:j['source']??'',rawFields:Map<String,dynamic>.from(j['raw_fields']??{}));
  Map<String,dynamic> toJson()=>{'stage':stage,'status':status,'timestamp':timestamp,'source':source,'raw_fields':rawFields};
}
class ExceptionItem {
  final String field,severity,message;
  ExceptionItem({required this.field,required this.severity,required this.message});
  factory ExceptionItem.fromJson(Map<String,dynamic> j)=>ExceptionItem(field:j['field']??'',severity:j['severity']??'warning',message:j['message']??'');
  Map<String,dynamic> toJson()=>{'field':field,'severity':severity,'message':message};
}
class TraceResult {
  final String transactionId,overallStatus,explanation,generatedAt;
  final double confidence;
  final List<TimelineStage> timeline;
  final List<ExceptionItem> exceptions;
  TraceResult({required this.transactionId,required this.overallStatus,required this.confidence,required this.timeline,required this.explanation,required this.exceptions,required this.generatedAt});
  factory TraceResult.fromJson(Map<String,dynamic> j)=>TraceResult(transactionId:j['transaction_id']??'',overallStatus:j['overall_status']??'unknown',confidence:(j['confidence']??0).toDouble(),timeline:(j['timeline'] as List? ?? []).map((x)=>TimelineStage.fromJson(Map<String,dynamic>.from(x))).toList(),explanation:j['explanation']??'',exceptions:(j['exceptions'] as List? ?? []).map((x)=>ExceptionItem.fromJson(Map<String,dynamic>.from(x))).toList(),generatedAt:j['generated_at']??'');
  Map<String,dynamic> toJson()=>{'transaction_id':transactionId,'overall_status':overallStatus,'confidence':confidence,'timeline':timeline.map((x)=>x.toJson()).toList(),'explanation':explanation,'exceptions':exceptions.map((x)=>x.toJson()).toList(),'generated_at':generatedAt};
}
class Transaction {
  final String transactionId,overallStatus;
  final String? merchantId, currency,gatewayStatus,bankStatus,ledgerStatus,gatewayTimestamp,settlementDate;
  final double? amount;
  Transaction({required this.transactionId,this.merchantId,this.amount,this.currency,this.gatewayStatus,this.bankStatus,this.ledgerStatus,required this.overallStatus,this.gatewayTimestamp,this.settlementDate});
  factory Transaction.fromJson(Map<String,dynamic> j)=>Transaction(transactionId:j['transaction_id']??'',merchantId:j['merchant_id'],amount:j['amount']==null?null:(j['amount'] as num).toDouble(),currency:j['currency'],gatewayStatus:j['gateway_status'],bankStatus:j['bank_status'],ledgerStatus:j['ledger_status'],overallStatus:j['overall_status']??'unknown',gatewayTimestamp:j['gateway_timestamp'],settlementDate:j['settlement_date']);
  Map<String,dynamic> toJson()=>{'transaction_id':transactionId,'merchant_id':merchantId,'amount':amount,'currency':currency,'gateway_status':gatewayStatus,'bank_status':bankStatus,'ledger_status':ledgerStatus,'overall_status':overallStatus,'gateway_timestamp':gatewayTimestamp,'settlement_date':settlementDate};
}
