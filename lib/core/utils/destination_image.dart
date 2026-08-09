/// Stable, destination-specific hero images for the demo experience.
///
/// A random image service makes a destination card feel disconnected from
/// its content. These curated Unsplash images keep the visual story stable
/// while the AI can still recommend any destination.
String destinationImageUrl(String destinationName) {
  final name = destinationName.toLowerCase();

  if (name.contains('jaipur')) {
    return 'https://images.unsplash.com/photo-1477587458883-47145ed94245?auto=format&fit=crop&w=1200&q=85';
  }
  if (name.contains('goa')) {
    return 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?auto=format&fit=crop&w=1200&q=85';
  }
  if (name.contains('manali') || name.contains('himachal')) {
    return 'https://images.unsplash.com/photo-1597074866923-dc0589150358?auto=format&fit=crop&w=1200&q=85';
  }
  if (name.contains('tirthan') || name.contains('jibhi')) {
    return 'https://images.unsplash.com/photo-1597074866923-dc0589150358?auto=format&fit=crop&w=1200&q=85';
  }
  if (name.contains('rishikesh')) {
    return 'https://images.unsplash.com/photo-1720863458635-849623bae4d3?auto=format&fit=crop&w=1200&q=85';
  }
  if (name.contains('gokarna')) {
    return 'https://images.unsplash.com/photo-1733158714880-95917a61b973?auto=format&fit=crop&w=1200&q=85';
  }
  if (name.contains('kerala') ||
      name.contains('alleppey') ||
      name.contains('munnar')) {
    return 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=1200&q=85';
  }
  if (name.contains('varanasi')) {
    return 'https://images.unsplash.com/photo-1762513907666-29901bf5899a?auto=format&fit=crop&w=1200&q=85';
  }
  if (name.contains('delhi') || name.contains('agra')) {
    return 'https://images.unsplash.com/photo-1564507592333-c60657eea523?auto=format&fit=crop&w=1200&q=85';
  }
  if (name.contains('mumbai')) {
    return 'https://images.unsplash.com/photo-1570168007204-dfb528c6958f?auto=format&fit=crop&w=1200&q=85';
  }

  // Dynamic fallback image based on the destination name using loremflickr
  final query = Uri.encodeComponent('$name,travel');
  return 'https://loremflickr.com/1200/800/$query/all';
}


double normalizedDailyBudget(String destinationName, num value) {
  final name = destinationName.toLowerCase();
  final fallback = name.contains('mumbai')
      ? 4500.0
      : name.contains('goa')
      ? 4000.0
      : name.contains('kerala') || name.contains('munnar')
      ? 3500.0
      : name.contains('manali') || name.contains('himachal')
      ? 3200.0
      : name.contains('varanasi')
      ? 2800.0
      : name.contains('jaipur') || name.contains('delhi')
      ? 3000.0
      : 3000.0;

  // Gemini occasionally returns a value such as 65 instead of 6500.
  if (value < 1200 || value > 15000) return fallback;
  return value.toDouble();
}

List<String> destinationFallbackHighlights(String destinationName) {
  final name = destinationName.toLowerCase();
  if (name.contains('rishikesh')) {
    return ['Ganga riverfront', 'Yoga and ashrams', 'Rafting and waterfalls'];
  }
  if (name.contains('tirthan') || name.contains('jibhi')) {
    return ['Mountain trails', 'Tirthan River', 'Quiet village stays'];
  }
  if (name.contains('gokarna')) {
    return ['Om Beach', 'Coastal trails', 'Temple town culture'];
  }
  if (name.contains('munnar')) {
    return ['Tea plantations', 'Misty viewpoints', 'Eravikulam National Park'];
  }
  if (name.contains('varanasi')) {
    return ['Ganga Aarti', 'Sarnath', 'Old-city food walks'];
  }
  return ['Local landmarks', 'Regional food', 'A neighbourhood experience'];
}
