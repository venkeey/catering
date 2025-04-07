import 'package:uuid/uuid.dart';

class Event {
  final String id;
  final String clientId;
  final String? eventName;
  final DateTime? eventDate;
  final String? venueAddress;
  final String? eventType;
  final int? totalGuestCount;
  final int guestsMale;
  final int guestsFemale;
  final int guestsElderly;
  final int guestsYouth;
  final int guestsChild;
  final String status;
  final String? notes;
  final DateTime createdAt;

  Event({
    String? id,
    required this.clientId,
    this.eventName,
    this.eventDate,
    this.venueAddress,
    this.eventType,
    this.totalGuestCount,
    this.guestsMale = 0,
    this.guestsFemale = 0,
    this.guestsElderly = 0,
    this.guestsYouth = 0,
    this.guestsChild = 0,
    this.status = 'Planning',
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Event copyWith({
    String? clientId,
    String? eventName,
    DateTime? eventDate,
    String? venueAddress,
    String? eventType,
    int? totalGuestCount,
    int? guestsMale,
    int? guestsFemale,
    int? guestsElderly,
    int? guestsYouth,
    int? guestsChild,
    String? status,
    String? notes,
  }) {
    return Event(
      id: id,
      clientId: clientId ?? this.clientId,
      eventName: eventName ?? this.eventName,
      eventDate: eventDate ?? this.eventDate,
      venueAddress: venueAddress ?? this.venueAddress,
      eventType: eventType ?? this.eventType,
      totalGuestCount: totalGuestCount ?? this.totalGuestCount,
      guestsMale: guestsMale ?? this.guestsMale,
      guestsFemale: guestsFemale ?? this.guestsFemale,
      guestsElderly: guestsElderly ?? this.guestsElderly,
      guestsYouth: guestsYouth ?? this.guestsYouth,
      guestsChild: guestsChild ?? this.guestsChild,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'eventName': eventName,
      'eventDate': eventDate?.toIso8601String(),
      'venueAddress': venueAddress,
      'eventType': eventType,
      'totalGuestCount': totalGuestCount,
      'guestsMale': guestsMale,
      'guestsFemale': guestsFemale,
      'guestsElderly': guestsElderly,
      'guestsYouth': guestsYouth,
      'guestsChild': guestsChild,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      clientId: map['clientId'],
      eventName: map['eventName'],
      eventDate: map['eventDate'] != null ? DateTime.parse(map['eventDate']) : null,
      venueAddress: map['venueAddress'],
      eventType: map['eventType'],
      totalGuestCount: map['totalGuestCount'],
      guestsMale: map['guestsMale'] ?? 0,
      guestsFemale: map['guestsFemale'] ?? 0,
      guestsElderly: map['guestsElderly'] ?? 0,
      guestsYouth: map['guestsYouth'] ?? 0,
      guestsChild: map['guestsChild'] ?? 0,
      status: map['status'] ?? 'Planning',
      notes: map['notes'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }
} 