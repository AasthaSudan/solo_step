import 'package:flutter/material.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  bool _isAccepted = false;
  int _callDuration = 0;
  bool _isRinging = true;

  @override
  void initState() {
    super.initState();
    // In a real app we'd trigger a ringtone audio here, but the SafetyScreen handles the ringing sound.
    // The SafetyScreen stops the audio when this screen pops or accepts.
  }

  void _acceptCall() {
    setState(() {
      _isAccepted = true;
      _isRinging = false;
    });
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isAccepted) return false;
      setState(() {
        _callDuration++;
      });
      return true;
    });
  }

  void _endCall() {
    Navigator.of(context).pop(true); // Return true to indicate the call ended
  }

  String _formatDuration(int seconds) {
    final m = (seconds / 60).floor().toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Caller Info
            const Text(
              'Mom',
              style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 10),
            Text(
              _isAccepted ? _formatDuration(_callDuration) : 'Mobile',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            
            const Spacer(),
            
            if (_isAccepted) ...[
              // In-call buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallOption(Icons.mic_off, 'mute'),
                  _buildCallOption(Icons.dialpad, 'keypad'),
                  _buildCallOption(Icons.volume_up, 'speaker'),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallOption(Icons.add, 'add call'),
                  _buildCallOption(Icons.video_call, 'FaceTime'),
                  _buildCallOption(Icons.account_circle, 'contacts'),
                ],
              ),
              const SizedBox(height: 80),
              // End call button
              GestureDetector(
                onTap: _endCall,
                child: Container(
                  width: 75,
                  height: 75,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call_end, color: Colors.white, size: 36),
                ),
              ),
            ] else ...[
              // Incoming call buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _endCall,
                        child: Container(
                          width: 75,
                          height: 75,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_end, color: Colors.white, size: 36),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('Decline', style: TextStyle(color: Colors.white, fontSize: 18)),
                    ],
                  ),
                  
                  // Accept
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _acceptCall,
                        child: Container(
                          width: 75,
                          height: 75,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call, color: Colors.white, size: 36),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 18)),
                    ],
                  ),
                ],
              )
            ],
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildCallOption(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}
