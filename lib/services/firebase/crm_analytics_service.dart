import '../../data/models/crm_model.dart';

class CrmAnalyticsService {
  int totalContacts(List<Contact> contacts) => contacts.length;

  int companiesCount(List<Contact> contacts) {
    final set = <String>{};
    for (final c in contacts) {
      if (c.company.isNotEmpty) set.add(c.company);
    }
    return set.length;
  }

  Map<String, int> contactsPerCompany(List<Contact> contacts) {
    final map = <String, int>{};
    for (final c in contacts) {
      if (c.company.isNotEmpty) {
        map[c.company] = (map[c.company] ?? 0) + 1;
      }
    }
    return map;
  }

  Contact? mostFrequentCompanyContact(List<Contact> contacts) {
    if (contacts.isEmpty) return null;

    final map = contactsPerCompany(contacts);
    String? top;
    int max = 0;

    map.forEach((key, value) {
      if (value > max) {
        top = key;
        max = value;
      }
    });

    if (top == null) return null;
    return contacts.firstWhere((c) => c.company == top, orElse: () => contacts.first);
  }
}