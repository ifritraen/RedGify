import 'package:flutter/foundation.dart';

class SubscriptionProvider extends ChangeNotifier {
  final Map<String, bool> _subscribed = {};

  bool isSubscribed(String userName) => _subscribed[userName] ?? false;

  void toggle(String userName) {
    _subscribed[userName] = !(isSubscribed(userName));
    notifyListeners();
  }
}
