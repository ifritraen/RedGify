import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';

class SubscribeButton extends StatelessWidget {
  final String creatorId;
  const SubscribeButton({Key? key, required this.creatorId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final library = Provider.of<LibraryProvider>(context);
    final isSubscribed = library.isSubscribed(creatorId);
    final bgColor = isSubscribed ? const Color(0xFF43A047) : const Color(0xFFE53935);
    final label = isSubscribed ? 'Subscribed' : 'Subscribe';
    return GestureDetector(
      onTap: () async {
        if (isSubscribed) {
          await library.unsubscribeCreator(creatorId);
        } else {
          await library.subscribeCreator(creatorId);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
