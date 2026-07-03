import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/swipe_to_sos_widget.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> with SingleTickerProviderStateMixin {
  bool _isCheckedIn = false;
  late AnimationController _pulseController;
  
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSirenPlaying = false;
  
  List<Map<String, dynamic>> _emergencyContacts = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _checkLocationPermission();
    _fetchUserData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        
        // Fetch Check-in status
        if (data.containsKey('lastCheckIn')) {
          final lastCheckIn = (data['lastCheckIn'] as Timestamp).toDate();
          final now = DateTime.now();
          if (lastCheckIn.year == now.year && lastCheckIn.month == now.month && lastCheckIn.day == now.day) {
            setState(() {
              _isCheckedIn = true;
            });
          }
        }
        
        // Fetch Contacts
        if (data.containsKey('emergencyContacts')) {
          final contacts = List<Map<String, dynamic>>.from(data['emergencyContacts']);
          setState(() {
            _emergencyContacts = contacts;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  Future<void> _toggleCheckIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first')));
      return;
    }

    setState(() {
      _isCheckedIn = !_isCheckedIn;
    });

    try {
      if (_isCheckedIn) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'lastCheckIn': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'lastCheckIn': FieldValue.delete(),
        });
      }
    } catch (e) {
      debugPrint("Error saving check in: $e");
    }
  }
  
  Future<void> _addContact(String name, String phone) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final newContact = {'name': name, 'phone': phone};
    setState(() {
      _emergencyContacts.add(newContact);
    });
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'emergencyContacts': _emergencyContacts,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving contact: $e");
    }
  }

  Future<void> _removeContact(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() {
      _emergencyContacts.removeAt(index);
    });
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'emergencyContacts': _emergencyContacts,
      });
    } catch (e) {
      debugPrint("Error deleting contact: $e");
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setFallbackLocation();
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setFallbackLocation();
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _setFallbackLocation();
        return;
      } 

      await _getCurrentLocation();
    } catch (e) {
      debugPrint("Permission error: $e");
      _setFallbackLocation();
    }
  }

  void _setFallbackLocation() {
    if (mounted) {
      setState(() {
        _isLoadingLocation = false;
        // Fallback to New Delhi if location fails (good for testing)
        _currentPosition = Position(
          latitude: 28.6139,
          longitude: 77.2090,
          timestamp: DateTime.now(),
          accuracy: 100,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5), // Don't hang forever
        )
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      debugPrint("Location error: $e");
      _setFallbackLocation();
    }
  }

  Future<void> _triggerSOS() async {
    if (_emergencyContacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add emergency contacts first!')),
        );
      }
      return;
    }

    String locationText = 'unknown location';
    if (_currentPosition != null) {
      locationText = 'https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}';
    }
    
    final message = 'EMERGENCY! I need help. My location: $locationText';
    final numbers = _emergencyContacts.map((c) => c['phone']).join(',');
    
    // For iOS, the separator is usually & or , but url_launcher handles , mostly well.
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: numbers,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open messaging app.')),
        );
      }
    }
  }
  
  void _shareLocation() {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fetching location... please wait')));
      return;
    }
    final mapsLink = 'https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}';
    Share.share('Check out my current location: $mapsLink');
  }
  
  void _toggleSiren() async {
    if (_isSirenPlaying) {
      await _audioPlayer.stop();
      setState(() => _isSirenPlaying = false);
    } else {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(UrlSource('https://actions.google.com/sounds/v1/alarms/alarm_clock.ogg'));
      setState(() => _isSirenPlaying = true);
    }
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242434),
        title: const Text('Add Emergency Contact', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name (e.g. Mom)',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                _addContact(nameController.text, phoneController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A24), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Guardian Angel',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Daily Check-in Card
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: _isCheckedIn 
                      ? [Colors.green.shade800, Colors.teal.shade900]
                      : [const Color(0xFF2E1A47), const Color(0xFF1E1033)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isCheckedIn ? Colors.green.withValues(alpha: 0.2) : Colors.purple.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isCheckedIn ? 'Status: Safe' : 'Daily Check-in',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isCheckedIn ? 'Checked in securely' : 'Due by 9:00 PM',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          _isCheckedIn ? Icons.verified_user : Icons.shield_outlined,
                          color: _isCheckedIn ? Colors.greenAccent : Colors.purpleAccent,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: _toggleCheckIn,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _isCheckedIn ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.purpleAccent.withValues(alpha: 0.2),
                        border: Border.all(
                          color: _isCheckedIn ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.purpleAccent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _isCheckedIn ? 'UNDO CHECK-IN' : "I'M SAFE TODAY",
                          style: TextStyle(
                            color: _isCheckedIn ? Colors.greenAccent : Colors.purpleAccent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // Emergency Tools Grid
            const Text(
              'Quick Tools',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildToolCard(
                    Icons.call, 
                    'Fake Call', 
                    Colors.blue,
                    onTap: () {
                      context.go('/safety/fake-call');
                    },
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildToolCard(
                    _isSirenPlaying ? Icons.volume_off : Icons.campaign, 
                    _isSirenPlaying ? 'Stop Siren' : 'Loud Siren', 
                    Colors.orange,
                    onTap: _toggleSiren,
                    isActive: _isSirenPlaying,
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildToolCard(
                    Icons.share_location, 
                    'Share Loc', 
                    Colors.cyan,
                    onTap: _shareLocation,
                  )
                ),
              ],
            ),

            const SizedBox(height: 30),
            
            // Emergency Contacts Setup
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Emergency Contacts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                TextButton.icon(
                  onPressed: _showAddContactDialog, 
                  icon: const Icon(Icons.add, color: Colors.purpleAccent, size: 18), 
                  label: const Text('Add', style: TextStyle(color: Colors.purpleAccent))
                ),
              ],
            ),
            if (_emergencyContacts.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No contacts added. SOS slider will not work until you add at least one.',
                        style: TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._emergencyContacts.asMap().entries.map((entry) {
                final index = entry.key;
                final contact = entry.value;
                return Card(
                  color: const Color(0xFF242434),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purpleAccent.withValues(alpha: 0.2),
                      child: const Icon(Icons.person, color: Colors.purpleAccent),
                    ),
                    title: Text(contact['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(contact['phone'], style: const TextStyle(color: Colors.white70)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _removeContact(index),
                    ),
                  ),
                );
              }),
              
            const SizedBox(height: 30),

            // Live Safety Map
            const Text(
              'Live Safety Map',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildRealMap(),
            
            const SizedBox(height: 40),

            // SOS Slider
            SwipeToSosWidget(
              onSOS: _triggerSOS,
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(IconData icon, String title, Color color, {required VoidCallback onTap, bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : const Color(0xFF242434),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? color : Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealMap() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF12121A),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _isLoadingLocation 
            ? const Center(child: CircularProgressIndicator())
            : _currentPosition == null
                ? const Center(child: Text('Location unavailable', style: TextStyle(color: Colors.white70)))
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.solostep',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            width: 60,
                            height: 60,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 20 + (_pulseController.value * 40),
                                      height: 20 + (_pulseController.value * 40),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.blue.withValues(alpha: 0.3 * (1 - _pulseController.value)),
                                      ),
                                    ),
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.blueAccent,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: const [
                                          BoxShadow(color: Colors.blueAccent, blurRadius: 8, spreadRadius: 2),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }
}
