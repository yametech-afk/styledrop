/// Represents learned user style preferences ("Style DNA")
class StyleDna {
  List<String> preferredStyles;
  List<String> favoriteColors;
  String preferredFit;
  List<String> avoidColors;
  Map<String, double> styleAffinity; // style -> percentage (0-100)

  StyleDna({
    List<String>? preferredStyles,
    List<String>? favoriteColors,
    this.preferredFit = 'Oversized',
    List<String>? avoidColors,
    Map<String, double>? styleAffinity,
  }) : preferredStyles =
           preferredStyles ?? ['Streetwear', 'Casual', 'Minimalist'],
       favoriteColors = favoriteColors ?? ['Black', 'White', 'Gray'],
       avoidColors = avoidColors ?? ['Bright colors'],
       styleAffinity =
           styleAffinity ?? {'Streetwear': 87, 'Minimalist': 72, 'Casual': 61};

  Map<String, dynamic> toMap() => {
    'preferredStyles': preferredStyles,
    'favoriteColors': favoriteColors,
    'preferredFit': preferredFit,
    'avoidColors': avoidColors,
    'styleAffinity': styleAffinity,
  };

  factory StyleDna.fromMap(Map<dynamic, dynamic> map) {
    return StyleDna(
      preferredStyles: List<String>.from(map['preferredStyles'] as List? ?? []),
      favoriteColors: List<String>.from(map['favoriteColors'] as List? ?? []),
      preferredFit: map['preferredFit'] as String? ?? 'Oversized',
      avoidColors: List<String>.from(map['avoidColors'] as List? ?? []),
      styleAffinity: Map<String, double>.from(
        (map['styleAffinity'] as Map? ?? {}).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      ),
    );
  }
}

class UserProfile {
  String name;
  String email;
  String? photoPath;
  bool isGuest;
  StyleDna styleDna;
  String subscriptionTier; // FREE, PRO, PRO_PLUS

  UserProfile({
    this.name = 'Alex Rivera',
    this.email = '',
    this.photoPath,
    this.isGuest = false,
    StyleDna? styleDna,
    this.subscriptionTier = 'FREE',
  }) : styleDna = styleDna ?? StyleDna();

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'photoPath': photoPath,
    'isGuest': isGuest,
    'styleDna': styleDna.toMap(),
    'subscriptionTier': subscriptionTier,
  };

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    return UserProfile(
      name: map['name'] as String? ?? 'Alex Rivera',
      email: map['email'] as String? ?? '',
      photoPath: map['photoPath'] as String?,
      isGuest: map['isGuest'] as bool? ?? false,
      styleDna: StyleDna.fromMap(map['styleDna'] as Map? ?? {}),
      subscriptionTier: map['subscriptionTier'] as String? ?? 'FREE',
    );
  }
}
