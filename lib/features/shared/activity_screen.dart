import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:foodbridge/core/utils/navigation_utils.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          await handleHomeNavigation(context, ref);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity'),
          leading: BackButton(
            onPressed: () async {
              if (context.canPop()) {
                context.pop();
              } else {
                await handleHomeNavigation(context, ref);
              }
            },
          ),
        ),
        body: const Center(
          child: Text('Your recent activity will appear here.'),
        ),
      ),
    );
  }
}
