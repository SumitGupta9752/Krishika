class AppTranslations {
  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'appName': 'Krishika',
      'search': 'Search solutions...',
      'popularTreatments': 'Popular Treatments',
      'allSolutions': 'All Solutions',
      'addToCart': 'Add to Cart',
      'buyNow': 'Buy Now',
      'outOfStock': 'Out of Stock',
      'seeAll': 'See All',
      // Add more translations as needed
    },
    'hi': {
      'appName': 'कृषिका',
      'search': 'समाधान खोजें...',
      'popularTreatments': 'लोकप्रिय उपचार',
      'allSolutions': 'सभी समाधान',
      'addToCart': 'कार्ट में जोड़ें',
      'buyNow': 'अभी खरीदें',
      'outOfStock': 'स्टॉक में नहीं है',
      'seeAll': 'सभी देखें',
      // Add more translations as needed
    },
  };

  static String getText(String key, String languageCode) {
    return _translations[languageCode]?[key] ?? _translations['en']![key] ?? key;
  }
}