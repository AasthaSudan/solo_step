import re

with open('lib/features/return_signal/presentation/widgets/return_signal_card.dart', 'r') as f:
    content = f.read()

# 1. Imports
imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/check_in.dart';
import '../providers/check_in_provider.dart';"""
content = re.sub(r"import 'package:flutter/material.dart';\nimport '../../domain/entities/check_in.dart';", imports, content)

# 2. Convert ReturnSignalCard to ConsumerWidget
old_class = """class ReturnSignalCard extends StatelessWidget {
  final CheckIn checkIn;
  final VoidCallback onImBack;

  const ReturnSignalCard({
    super.key,
    required this.checkIn,
    required this.onImBack,
  });

  static const String _dummyCountdown = '01h 42m';

  @override
  Widget build(BuildContext context) {"""
new_class = """class ReturnSignalCard extends ConsumerWidget {
  const ReturnSignalCard({super.key});

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkInState = ref.watch(checkInProvider);
    final checkIn = checkInState.checkIn;
    
    if (checkIn == null) {
      return const SizedBox.shrink();
    }
    
    final formattedCountdown = _formatDuration(checkInState.remaining);
    final onImBack = () {
      ref.read(checkInProvider.notifier).imBack();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome back! Check-in completed.')),
      );
    };"""
content = content.replace(old_class, new_class)

# 3. Pass formatted countdown to _SignalContent
content = content.replace("Expanded(child: _SignalContent(checkIn: checkIn))", "Expanded(child: _SignalContent(checkIn: checkIn, countdownStr: formattedCountdown))")
content = content.replace("_SignalContent(checkIn: checkIn),", "_SignalContent(checkIn: checkIn, countdownStr: formattedCountdown),")

# 4. Update _SignalContent to take countdownStr
old_signal = """class _SignalContent extends StatelessWidget {
  final CheckIn checkIn;

  const _SignalContent({required this.checkIn});"""
new_signal = """class _SignalContent extends StatelessWidget {
  final CheckIn checkIn;
  final String countdownStr;

  const _SignalContent({required this.checkIn, required this.countdownStr});"""
content = content.replace(old_signal, new_signal)

content = content.replace("ReturnSignalCard._dummyCountdown", "countdownStr")

with open('lib/features/return_signal/presentation/widgets/return_signal_card.dart', 'w') as f:
    f.write(content)
