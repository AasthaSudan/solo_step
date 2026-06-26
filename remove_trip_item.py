import re

with open('lib/features/archive/presentation/screens/trips_screen.dart', 'r') as f:
    content = f.read()

# Remove class _TripItem { ... } 
trip_item_pattern = re.compile(r"class _TripItem \{.*?\};\n\}\n", re.DOTALL)
content = trip_item_pattern.sub("", content)

with open('lib/features/archive/presentation/screens/trips_screen.dart', 'w') as f:
    f.write(content)
