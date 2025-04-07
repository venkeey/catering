import 'package:uuid/uuid.dart';
import 'quote_item.dart';

class Quote {
  final String id;
  final String? eventId;
  final String clientId;
  final DateTime quoteDate;
  final int totalGuestCount;
  final int guestsMale;
  final int guestsFemale;
  final int guestsElderly;
  final int guestsYouth;
  final int guestsChild;
  final String calculationMethod;
  final double overheadPercentage;
  final double calculatedTotalFoodCost;
  final double calculatedOverheadCost;
  final double grandTotal;
  final String? notes;
  final String? termsAndConditions;
  final String status;
  final List<QuoteItem> items;

  Quote({
    String? id,
    this.eventId,
    required this.clientId,
    required this.quoteDate,
    required this.totalGuestCount,
    required this.guestsMale,
    required this.guestsFemale,
    required this.guestsElderly,
    required this.guestsYouth,
    required this.guestsChild,
    required this.calculationMethod,
    required this.overheadPercentage,
    required this.calculatedTotalFoodCost,
    required this.calculatedOverheadCost,
    required this.grandTotal,
    this.notes,
    this.termsAndConditions,
    required this.status,
    required this.items,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'clientId': clientId,
      'quoteDate': quoteDate.toIso8601String(),
      'totalGuestCount': totalGuestCount,
      'guestsMale': guestsMale,
      'guestsFemale': guestsFemale,
      'guestsElderly': guestsElderly,
      'guestsYouth': guestsYouth,
      'guestsChild': guestsChild,
      'calculationMethod': calculationMethod,
      'overheadPercentage': overheadPercentage,
      'calculatedTotalFoodCost': calculatedTotalFoodCost,
      'calculatedOverheadCost': calculatedOverheadCost,
      'grandTotal': grandTotal,
      'notes': notes,
      'termsAndConditions': termsAndConditions,
      'status': status,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'],
      eventId: map['eventId'],
      clientId: map['clientId'],
      quoteDate: map['quoteDate'] != null ? DateTime.parse(map['quoteDate']) : DateTime.now(),
      totalGuestCount: map['totalGuestCount'] ?? 0,
      guestsMale: map['guestsMale'] ?? 0,
      guestsFemale: map['guestsFemale'] ?? 0,
      guestsElderly: map['guestsElderly'] ?? 0,
      guestsYouth: map['guestsYouth'] ?? 0,
      guestsChild: map['guestsChild'] ?? 0,
      calculationMethod: map['calculationMethod'] ?? 'Standard',
      overheadPercentage: map['overheadPercentage'] is int ? (map['overheadPercentage'] as int).toDouble() : (map['overheadPercentage'] ?? 0.0),
      calculatedTotalFoodCost: map['calculatedTotalFoodCost'] is int ? (map['calculatedTotalFoodCost'] as int).toDouble() : (map['calculatedTotalFoodCost'] ?? 0.0),
      calculatedOverheadCost: map['calculatedOverheadCost'] is int ? (map['calculatedOverheadCost'] as int).toDouble() : (map['calculatedOverheadCost'] ?? 0.0),
      grandTotal: map['grandTotal'] is int ? (map['grandTotal'] as int).toDouble() : (map['grandTotal'] ?? 0.0),
      notes: map['notes'],
      termsAndConditions: map['termsAndConditions'],
      status: map['status'] ?? 'Draft',
      items: map['items'] != null ? (map['items'] as List).map((item) => QuoteItem.fromMap(item)).toList() : [],
    );
  }
} 