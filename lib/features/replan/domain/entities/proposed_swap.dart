import '../../../budget/domain/entities/expense.dart';

class ProposedSwap {
  final String oldTitle;
  final int oldCost;
  final String newTitle;
  final int newCost;
  final SpendCategory category;

  const ProposedSwap({
    required this.oldTitle,
    required this.oldCost,
    required this.newTitle,
    required this.newCost,
    required this.category,
  });

  int get savings => oldCost - newCost;
}
