import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SmsService {
  static const String _accountSid = 'ACe23da6c992aa955eff69eb985c22daa7';
  static const String _authToken = 'ec5a659a0d991d0666f8d5c098db74c0'; // Placeholder as requested, user should replace this
  static const String _messagingServiceSid = 'MG52846b202ea0e7d9247bcde9c4102460';
  static const String _contactsKey = 'jepo_family_contacts';

  /// Sends an emergency SMS to all saved contacts.
  static Future<void> sendEmergencyAlerts(String messageBody) async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsJson = prefs.getString(_contactsKey);

    if (contactsJson == null) {
      debugPrint("No contacts found to notify.");
      return;
    }

    final List<dynamic> contacts = jsonDecode(contactsJson);
    
    for (var contact in contacts) {
      final String? phoneNumber = contact['phone'];
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        await _sendTwilioSms(phoneNumber, messageBody);
      }
    }
  }

  static Future<void> _sendTwilioSms(String to, String body) async {
    final Uri url = Uri.parse(
      'https://api.twilio.com/2010-04-01/Accounts/$_accountSid/Messages.json',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_accountSid:$_authToken'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'To': to,
          'MessagingServiceSid': _messagingServiceSid,
          'Body': body,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("SMS sent successfully to $to: ${response.body}");
      } else {
        debugPrint("Failed to send SMS to $to: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Error sending SMS: $e");
    }
  }

  // --- Methods for managing contacts (used by UI) ---

  static Future<List<Map<String, String>>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsJson = prefs.getString(_contactsKey);
    if (contactsJson == null) return [];
    
    // Convert dynamic list to List<Map<String, String>>
    return List<Map<String, String>>.from(
      jsonDecode(contactsJson).map((x) => Map<String, String>.from(x))
    );
  }

  static Future<void> saveContact(String name, String phone, String relation) async {
    final contacts = await getContacts();
    contacts.add({
      'name': name,
      'phone': phone,
      'relation': relation,
      'status': 'Unknown', // Default status
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_contactsKey, jsonEncode(contacts));
  }

  static Future<void> removeContact(int index) async {
    final contacts = await getContacts();
    if (index >= 0 && index < contacts.length) {
      contacts.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_contactsKey, jsonEncode(contacts));
    }
  }
}
