import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService {
  final _supabase = Supabase.instance.client;

  String get currentUserId => _supabase.auth.currentUser!.id;

  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  Future<List<Map<String, dynamic>>> syncContacts() async {
    final hasPermission = await requestContactsPermission();
    if (!hasPermission) {
      // Fallback: return all registered app users
      return getAllAppUsers();
    }

    // Read device contacts
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    // Extract all phone numbers (normalized)
    final phoneNumbers = <String>[];
    for (final contact in contacts) {
      for (final phone in contact.phones) {
        final normalized = _normalizePhone(phone.number);
        if (normalized.isNotEmpty) {
          phoneNumbers.add(normalized);
        }
      }
    }

    if (phoneNumbers.isEmpty) {
      return getAllAppUsers();
    }

    // Match against users table
    try {
      final matched = await _supabase
          .from('users')
          .select()
          .neq('id', currentUserId)
          .inFilter('phone', phoneNumbers)
          .order('username', ascending: true);

      return List<Map<String, dynamic>>.from(matched);
    } catch (_) {
      return getAllAppUsers();
    }
  }

  Future<List<Map<String, dynamic>>> getAllAppUsers() async {
    final response = await _supabase
        .from('users')
        .select()
        .neq('id', currentUserId)
        .order('username', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }
}
