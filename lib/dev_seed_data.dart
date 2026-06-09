import 'package:cloud_firestore/cloud_firestore.dart';

/// Seeds Firestore with demo buyers, sellers, and products.
///
/// This is intentionally idempotent:
/// - User docs use deterministic doc IDs (the username), and are only created if missing.
/// - Product docs use deterministic IDs (based on seller + index), and are only created if missing.
///
/// Enable from the command line:
/// `flutter run --dart-define=SEED_DB=true`
Future<void> seedDemoData({
  int buyerCount = 6,
  int sellerCount = 3,
  int productsPerSeller = 10,
}) async {
  final firestore = FirebaseFirestore.instance;
  final usersRef = firestore.collection('users');
  final productsRef = firestore.collection('products');

  final now = DateTime.now();
  final seedTag = 'seed_${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  // More realistic demo users.
  // IMPORTANT: Your login uses the Firestore doc ID as the username, so we keep
  // names simple (letters only) and unique.
  final sellerUsers = _buildSeedUsers(role: 'seller', count: sellerCount);
  final buyerUsers = _buildSeedUsers(role: 'buyer', count: buyerCount);

  // --- Users ---
  // Fetch existing usernames in one go (small N; keeps writes idempotent).
  final usernames = [...sellerUsers, ...buyerUsers].map((u) => u.username).toList();
  final existingUsers = <String>{};
  for (final name in usernames) {
    final snap = await usersRef.doc(name).get();
    if (snap.exists) existingUsers.add(name);
  }

  var batch = firestore.batch();
  var ops = 0;

  void addOp(DocumentReference ref, Map<String, dynamic> data) {
    batch.set(ref, data, SetOptions(merge: true));
    ops++;
  }

  Future<void> commitIfNeeded({bool force = false}) async {
    if (ops == 0) return;
    // Max is 500, keep buffer.
    if (!force && ops < 450) return;
    await batch.commit();
    batch = firestore.batch();
    ops = 0;
  }

  for (final u in [...sellerUsers, ...buyerUsers]) {
    if (existingUsers.contains(u.username)) continue;
    addOp(usersRef.doc(u.username), {
      'matriksNumber': u.matriksNumber,
      'username': u.username,
      'email': u.email,
      'phone': u.phone,
      'address': u.address,
      'userImage': '',
      'password': u.password,
      'role': u.role,
      'createdAt': FieldValue.serverTimestamp(),
      'seedTag': seedTag,
    });
    await commitIfNeeded();
  }

  // --- Products ---
  // Deterministic product IDs so re-running doesn’t keep adding duplicates.
  // Using simple IDs is fine; the app treats doc.id as the product ID.
  const categories = <String>[
    'Electronics',
    'Fashion',
    'Books',
    'Home & Garden',
    'Sports',
    'Other',
  ];
  const conditions = <String>['New', 'Used Lightly', 'Used Heavily'];

  for (final seller in sellerUsers) {
    for (var i = 1; i <= productsPerSeller; i++) {
      final safeSellerKey = _safeKey(seller.username);
      final productId = 'seed_${safeSellerKey}_p${i.toString().padLeft(2, '0')}';
      final ref = productsRef.doc(productId);
      final exists = (await ref.get()).exists;
      if (exists) continue;

      final category = categories[(i - 1) % categories.length];
      final condition = conditions[(i - 1) % conditions.length];
      final price = 8.0 + ((i * 9) % 110) + (safeSellerKey.codeUnitAt(safeSellerKey.length - 1) % 10) / 10.0;

      addOp(ref, {
        'name': _seedProductName(category: category, index: i),
        'description': _seedProductDescription(
          category: category,
          index: i,
          condition: condition,
        ),
        'price': double.parse(price.toStringAsFixed(2)),
        'condition': condition,
        'category': category,
        'imageUrl': '',
        'sellerName': seller.username,
        'sellerId': seller.matriksNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isAvailable': true,
        'seedTag': seedTag,
      });
      await commitIfNeeded();
    }
  }

  await commitIfNeeded(force: true);
}

String _seedProductName({required String category, required int index}) {
  final items = _productTitlesByCategory[category] ?? _productTitlesByCategory['Other']!;
  final title = items[(index - 1) % items.length];
  // Add a small variant suffix to make duplicates less obvious.
  final variant = ((index - 1) % 3) + 1;
  return '$title (V$variant)';
}

String _seedProductDescription({
  required String category,
  required int index,
  required String condition,
}) {
  final meetups = <String>[
    'Meet-up: UTM Skudai / Library',
    'Meet-up: Student Mall / KK5',
    'Meet-up: FKE / N24',
  ];
  final meetup = meetups[(index - 1) % meetups.length];

  final notes = _productNotesByCategory[category] ?? _productNotesByCategory['Other']!;
  final note = notes[(index - 1) % notes.length];

  return '$condition item. $note. $meetup. Chat for more details.';
}

String _safeKey(String input) {
  final lower = input.toLowerCase();
  final only = lower.replaceAll(RegExp(r'[^a-z]'), '');
  return only.isEmpty ? 'user' : only;
}

List<_SeedUser> _buildSeedUsers({required String role, required int count}) {
  final profiles = role == 'seller' ? _seedSellerProfiles : _seedBuyerProfiles;
  final takeCount = count.clamp(0, profiles.length);
  return profiles.take(takeCount).map((p) => p.copyWith(role: role)).toList();
}

const Map<String, List<String>> _productTitlesByCategory = {
  'Electronics': [
    'Logitech Wireless Mouse',
    'Anker USB-C Cable 1m',
    'Samsung Fast Charger',
    'Xiaomi Power Bank 10000mAh',
    'USB Hub 4-Port',
    'Noise-Cancelling Earbuds',
    'Laptop Stand (Adjustable)',
  ],
  'Fashion': [
    'Oversized Hoodie',
    'Denim Jacket',
    'Plain T-Shirt (Unisex)',
    'Slim Fit Jeans',
    'Canvas Tote Bag',
    'Sports Cap',
  ],
  'Books': [
    'Calculus 1 Notes (Printed)',
    'Programming Fundamentals Book',
    'Discrete Math Revision Pack',
    'English Presentation Guide',
    'SPM Add Maths Reference',
  ],
  'Home & Garden': [
    'Table Lamp (LED)',
    'Hanger Set (10 pcs)',
    'Mini Desk Fan',
    'Storage Box (Foldable)',
    'Water Bottle 1L',
  ],
  'Sports': [
    'Badminton Racket',
    'Yoga Mat',
    'Dumbbell 5kg',
    'Skipping Rope',
    'Football (Size 5)',
  ],
  'Other': [
    'Stationery Bundle',
    'Reusable Lunch Box',
    'Phone Case',
    'Notebook Set',
    'Gift Wrap Pack',
  ],
};

const Map<String, List<String>> _productNotesByCategory = {
  'Electronics': [
    'Tested and working well',
    'Good for daily use and study',
    'Kept in a clean, dry place',
  ],
  'Fashion': [
    'Worn a few times only',
    'No stains, kept neatly',
    'Comfortable fit, good condition',
  ],
  'Books': [
    'Some highlights/notes inside',
    'Useful for exams and assignments',
    'Pages are intact, no missing chapters',
  ],
  'Home & Garden': [
    'Perfect for dorm/room setup',
    'Lightweight and easy to carry',
    'Works great and looks clean',
  ],
  'Sports': [
    'Good for casual training',
    'Used lightly, still solid',
    'Great for beginners',
  ],
  'Other': [
    'Practical item, good deal',
    'Clean and ready to use',
    'Quick sale, price negotiable',
  ],
};

class _SeedProfile {
  final String username;
  final String matriksNumber;
  final String email;
  final String phone;
  final String address;
  final String password;
  final String role;

  const _SeedProfile({
    required this.username,
    required this.matriksNumber,
    required this.email,
    required this.phone,
    required this.address,
    required this.password,
    required this.role,
  });

  _SeedUser copyWith({required String role}) {
    return _SeedUser(
      username: username,
      matriksNumber: matriksNumber,
      role: role,
      email: email,
      phone: phone,
      address: address,
      password: password,
    );
  }
}

const List<_SeedProfile> _seedSellerProfiles = [
  _SeedProfile(
    username: 'Aiman',
    matriksNumber: '231045',
    email: 'aiman@gmail.com',
    phone: '01234567890',
    address: 'Kolej Kediaman 5, UTM Skudai',
    password: 'Password123',
    role: 'seller',
  ),
  _SeedProfile(
    username: 'Siti',
    matriksNumber: '231112',
    email: 'siti@gmail.com',
    phone: '01345678901',
    address: 'Kolej Kediaman 9, UTM Skudai',
    password: 'Password123',
    role: 'seller',
  ),
  _SeedProfile(
    username: 'Haziq',
    matriksNumber: '231207',
    email: 'haziq@gmail.com',
    phone: '01456789012',
    address: 'Kolej Kediaman 1, UTM Skudai',
    password: 'Password123',
    role: 'seller',
  ),
  _SeedProfile(
    username: 'Farah',
    matriksNumber: '231318',
    email: 'farah@gmail.com',
    phone: '01123456789',
    address: 'Kolej Kediaman 3, UTM Skudai',
    password: 'Password123',
    role: 'seller',
  ),
  _SeedProfile(
    username: 'Amir',
    matriksNumber: '231401',
    email: 'amir@gmail.com',
    phone: '01678901234',
    address: 'Kolej Kediaman 7, UTM Skudai',
    password: 'Password123',
    role: 'seller',
  ),
];

const List<_SeedProfile> _seedBuyerProfiles = [
  _SeedProfile(
    username: 'Nadia',
    matriksNumber: '241006',
    email: 'nadia@gmail.com',
    phone: '01789012345',
    address: 'Kolej Kediaman 2, UTM Skudai',
    password: 'Password123',
    role: 'buyer',
  ),
  _SeedProfile(
    username: 'Hafiz',
    matriksNumber: '241058',
    email: 'hafiz@gmail.com',
    phone: '01890123456',
    address: 'Kolej Kediaman 4, UTM Skudai',
    password: 'Password123',
    role: 'buyer',
  ),
  _SeedProfile(
    username: 'Alya',
    matriksNumber: '241102',
    email: 'alya@gmail.com',
    phone: '01901234567',
    address: 'Kolej Kediaman 10, UTM Skudai',
    password: 'Password123',
    role: 'buyer',
  ),
  _SeedProfile(
    username: 'Zahir',
    matriksNumber: '241155',
    email: 'zahir@gmail.com',
    phone: '01298765432',
    address: 'Kolej Kediaman 11, UTM Skudai',
    password: 'Password123',
    role: 'buyer',
  ),
  _SeedProfile(
    username: 'Izzat',
    matriksNumber: '241209',
    email: 'izzat@gmail.com',
    phone: '01387654321',
    address: 'Kolej Kediaman 6, UTM Skudai',
    password: 'Password123',
    role: 'buyer',
  ),
  _SeedProfile(
    username: 'Syafi',
    matriksNumber: '241266',
    email: 'syafi@gmail.com',
    phone: '01476543210',
    address: 'Kolej Kediaman 8, UTM Skudai',
    password: 'Password123',
    role: 'buyer',
  ),
  _SeedProfile(
    username: 'Hanna',
    matriksNumber: '241311',
    email: 'hanna@gmail.com',
    phone: '01187654321',
    address: 'Kolej Kediaman 12, UTM Skudai',
    password: 'Password123',
    role: 'buyer',
  ),
  _SeedProfile(
    username: 'Rizal',
    matriksNumber: '241358',
    email: 'rizal@gmail.com',
    phone: '01654321098',
    address: 'Kolej Kediaman 13, UTM Skudai',
    password: 'Password123',
    role: 'buyer',
  ),
];

class _SeedUser {
  final String username;
  final String matriksNumber;
  final String role;
  final String email;
  final String phone;
  final String address;
  final String password;

  const _SeedUser({
    required this.username,
    required this.matriksNumber,
    required this.role,
    required this.email,
    required this.phone,
    required this.address,
    required this.password,
  });
}
