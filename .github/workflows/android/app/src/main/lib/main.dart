import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const BTEqualizerApp());
}

class BTEqualizerApp extends StatelessWidget {
  const BTEqualizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BT Equalizer Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E17),
        sliderTheme: SliderThemeData(
          activeTrackColor: const Color(0xFF00FFCC),
          inactiveTrackColor: Colors.white10,
          thumbColor: const Color(0xFFBD00FF),
          overlayColor: const Color(0xFFBD00FF).withOpacity(0.2),
          trackHeight: 6,
        ),
      ),
      home: const EqualizerDashboard(),
    );
  }
}

class EqualizerDashboard extends StatefulWidget {
  const EqualizerDashboard({super.key});

  @override
  State<EqualizerDashboard> createState() => _EqualizerDashboardState();
}

class _EqualizerDashboardState extends State<EqualizerDashboard> {
  List<BluetoothDevice> connectedDevices = [];
  BluetoothDevice? selectedDevice;

  // EQ Sliders (0 - 100 scale)
  double subBass = 50.0;
  double bass = 65.0;
  double mid = 45.0;
  double presence = 55.0;
  double treble = 70.0;

  @override
  void initState() {
    super.initState();
    _fetchConnectedDevices();
  }

  void _fetchConnectedDevices() async {
    List<BluetoothDevice> devs = await FlutterBluePlus.connectedDevices;
    setState(() {
      connectedDevices = devs;
      if (devs.isNotEmpty) {
        selectedDevice = devs.first;
        _loadPresetForDevice(selectedDevice!.remoteId.str);
      }
    });
  }

  void _loadPresetForDevice(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      subBass = prefs.getDouble('${deviceId}_subBass') ?? 50.0;
      bass = prefs.getDouble('${deviceId}_bass') ?? 65.0;
      mid = prefs.getDouble('${deviceId}_mid') ?? 45.0;
      presence = prefs.getDouble('${deviceId}_presence') ?? 55.0;
      treble = prefs.getDouble('${deviceId}_treble') ?? 70.0;
    });
  }

  void _savePreset() async {
    if (selectedDevice == null) return;
    final prefs = await SharedPreferences.getInstance();
    String id = selectedDevice!.remoteId.str;
    await prefs.setDouble('${id}_subBass', subBass);
    await prefs.setDouble('${id}_bass', bass);
    await prefs.setDouble('${id}_mid', mid);
    await prefs.setDouble('${id}_presence', presence);
    await prefs.setDouble('${id}_treble', treble);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF131B2E),
        content: Text(
          'Preset saved for ${selectedDevice!.platformName.isEmpty ? "Current Device" : selectedDevice!.platformName}!',
          style: const TextStyle(color: Color(0xFF00FFCC), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AUDIO MATRIX // PRO',
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00FFCC)),
            onPressed: _fetchConnectedDevices,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device selector card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF131B2E), Color(0xFF1B243B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFF00FFCC).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.headphones_rounded, color: Color(0xFFBD00FF), size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<BluetoothDevice>(
                        dropdownColor: const Color(0xFF131B2E),
                        value: selectedDevice,
                        hint: const Text('Connect a Bluetooth Device', style: TextStyle(color: Colors.white54)),
                        isExpanded: true,
                        items: connectedDevices.map((dev) {
                          return DropdownMenuItem(
                            value: dev,
                            child: Text(
                              dev.platformName.isEmpty ? 'Wireless Headset' : dev.platformName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                        onChanged: (dev) {
                          if (dev != null) {
                            setState(() => selectedDevice = dev);
                            _loadPresetForDevice(dev.remoteId.str);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Sliders Section Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('EQUALIZATION', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.white70)),
                Text('32Hz - 16kHz', style: TextStyle(color: Color(0xFF00FFCC), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),

            _buildEQBand('Sub-Bass (32Hz)', subBass, (v) => setState(() => subBass = v)),
            _buildEQBand('Punch Bass (125Hz)', bass, (v) => setState(() => bass = v)),
            _buildEQBand('Acoustic Mids (1kHz)', mid, (v) => setState(() => mid = v)),
            _buildEQBand('Clarity (4kHz)', presence, (v) => setState(() => presence = v)),
            _buildEQBand('Air Treble (16kHz)', treble, (v) => setState(() => treble = v)),

            const SizedBox(height: 30),

            // Save Preset Button
            GestureDetector(
              onTap: _savePreset,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FFCC), Color(0xFFBD00FF)],
                  ),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF00FFCC).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))
                  ],
                ),
                child: const Center(
                  child: Text(
                    'LOCK PRESET TO DEVICE',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEQBand(String label, double value, ValueChanged<double> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111726),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
              Text('${value.round()} dB', style: const TextStyle(fontSize: 12, color: Color(0xFF00FFCC), fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: value,
            min: 0.0,
            max: 100.0,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
