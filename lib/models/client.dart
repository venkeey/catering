import 'package:uuid/uuid.dart';

class Client {
  final String id;
  final String clientName;
  final String? contactPerson;
  final String? phone1;
  final String? phone2;
  final String? email1;
  final String? email2;
  final String? billingAddress;
  final String? companyName;
  final String? notes;
  final DateTime createdAt;

  Client({
    String? id,
    required this.clientName,
    this.contactPerson,
    this.phone1,
    this.phone2,
    this.email1,
    this.email2,
    this.billingAddress,
    this.companyName,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Client copyWith({
    String? clientName,
    String? contactPerson,
    String? phone1,
    String? phone2,
    String? email1,
    String? email2,
    String? billingAddress,
    String? companyName,
    String? notes,
  }) {
    return Client(
      id: id,
      clientName: clientName ?? this.clientName,
      contactPerson: contactPerson ?? this.contactPerson,
      phone1: phone1 ?? this.phone1,
      phone2: phone2 ?? this.phone2,
      email1: email1 ?? this.email1,
      email2: email2 ?? this.email2,
      billingAddress: billingAddress ?? this.billingAddress,
      companyName: companyName ?? this.companyName,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientName': clientName,
      'contactPerson': contactPerson,
      'phone1': phone1,
      'phone2': phone2,
      'email1': email1,
      'email2': email2,
      'billingAddress': billingAddress,
      'companyName': companyName,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      clientName: map['clientName'],
      contactPerson: map['contactPerson'],
      phone1: map['phone1'],
      phone2: map['phone2'],
      email1: map['email1'],
      email2: map['email2'],
      billingAddress: map['billingAddress'],
      companyName: map['companyName'],
      notes: map['notes'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }
} 