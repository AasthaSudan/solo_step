import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  final err = AsyncValue<int>.error(Exception("Test"), StackTrace.current);
  try {
    final res = err.maybeWhen(
      data: (d) => "data",
      orElse: () => "orElse",
    );
    print("maybeWhen returned: $res");
  } catch (e) {
    print("maybeWhen threw: $e");
  }
}
