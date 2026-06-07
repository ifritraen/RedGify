import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';

class SubscribeButton extends StatelessWidget {
  final String creatorId;
  final bool compact;

  // const SubscribeButton({Key? key, required this.creatorId}) : super(key: key);
  const SubscribeButton({
    Key? key,
    required this.creatorId,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final library = Provider.of<LibraryProvider>(context);
    final isSubscribed = library.isSubscribed(creatorId);
    final bgColor = isSubscribed ? const Color(0xFF43A047) : const Color(0xFFE53935);
    // final label = isSubscribed ? 'Subscribed' : 'Subscribe';
    final label = compact
        ? (isSubscribed ? 'Sub\'d' : 'Sub')
        : (isSubscribed ? 'Subscribed' : 'Subscribe');

    final verticalPadding = compact ? 2.0 : 4.0;
    final horizontalPadding = compact ? 6.0 : 8.0;
    final fontSize = compact ? 8.0 : 10.0;
    final borderRadius = compact ? 8.0 : 12.0;

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
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
