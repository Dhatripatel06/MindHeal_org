import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class SmartwatchConnectionPage extends StatefulWidget {
  const SmartwatchConnectionPage({super.key});

  @override
  State<SmartwatchConnectionPage> createState() =>
      _SmartwatchConnectionPageState();
}

class _SmartwatchConnectionPageState extends State<SmartwatchConnectionPage>
    with TickerProviderStateMixin {
  bool _isScanning = false;
  bool _isConnected = false;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _connectedDevice;
  String _connectionStatus = 'Not connected';

  late AnimationController _searchController;
  late Animation<double> _searchAnimation;

  @override
  void initState() {
    super.initState();

    _searchController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _searchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchController,
      curve: Curves.easeInOut,
    ));

    _checkBluetoothPermissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkBluetoothPermissions() async {
    final bluetoothScan = await Permission.bluetoothScan.request();
    final bluetoothConnect = await Permission.bluetoothConnect.request();
    final location = await Permission.location.request();

    if (bluetoothScan != PermissionStatus.granted ||
        bluetoothConnect != PermissionStatus.granted ||
        location != PermissionStatus.granted) {
      _showPermissionDialog();
    }
  }

  Future<void> _startScanning() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _devices.clear();
      _connectionStatus = 'Scanning for devices...';
    });

    _searchController.repeat();

    try {
      // Check if Bluetooth is on
      if (await FlutterBluePlus.isOn == false) {
        await FlutterBluePlus.turnOn();
      }

      // Start scanning
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          _devices = results
              .where((r) =>
                  r.device.name.isNotEmpty && _isWearableDevice(r.device.name))
              .map((r) => r.device)
              .toList();
        });
      });

      // Stop scanning after timeout
      await Future.delayed(const Duration(seconds: 10));
      await _stopScanning();
    } catch (e) {
      setState(() {
        _connectionStatus = 'Scan failed: $e';
        _isScanning = false;
      });
      _searchController.stop();
    }
  }

  Future<void> _stopScanning() async {
    await FlutterBluePlus.stopScan();
    setState(() {
      _isScanning = false;
      _connectionStatus = _devices.isEmpty
          ? 'No wearable devices found'
          : 'Found ${_devices.length} device(s)';
    });
    _searchController.stop();
  }

  bool _isWearableDevice(String name) {
    final wearableKeywords = [
      'Watch',
      'Fit',
      'Band',
      'Heart',
      'Health',
      'Samsung',
      'Apple',
      'Fitbit',
      'Garmin',
      'Polar',
      'Suunto',
      'Xiaomi',
      'Amazfit',
      'Huawei',
      'Honor',
      'Realme',
      'OnePlus',
      'OPPO',
      'Vivo'
    ];

    return wearableKeywords
        .any((keyword) => name.toLowerCase().contains(keyword.toLowerCase()));
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      setState(() {
        _connectionStatus = 'Connecting to ${device.name}...';
      });

      await device.connect();

      setState(() {
        _isConnected = true;
        _connectedDevice = device;
        _connectionStatus = 'Connected to ${device.name}';
      });

      // Start syncing data
      _startDataSync();
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed: $e';
      });
    }
  }

  Future<void> _disconnectDevice() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
        setState(() {
          _isConnected = false;
          _connectedDevice = null;
          _connectionStatus = 'Disconnected';
        });
      } catch (e) {
        setState(() {
          _connectionStatus = 'Disconnect failed: $e';
        });
      }
    }
  }

  void _startDataSync() {
    // Simulate data syncing
    Future.delayed(const Duration(seconds: 2), () {
      if (_isConnected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Started syncing health data from smartwatch'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bluetooth Permissions Required'),
        content: const Text(
          'This app needs Bluetooth and Location permissions to connect to your smartwatch. '
          'Please grant these permissions in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Smartwatch Connection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Connection Status Card
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Status Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (_isConnected ? Colors.green : Colors.blue)
                            .withOpacity(0.1),
                      ),
                      child: Icon(
                        _isConnected ? Icons.check_circle : Icons.watch,
                        size: 40,
                        color: _isConnected ? Colors.green : Colors.blue,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Status Text
                    Text(
                      _connectionStatus,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    if (_connectedDevice != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _connectedDevice!.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Scan/Connect Button
              if (!_isConnected) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.blue.shade700],
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: _isScanning ? _stopScanning : _startScanning,
                        child: Center(
                          child: _isScanning
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _searchAnimation,
                                      builder: (context, child) {
                                        return Transform.rotate(
                                          angle: _searchAnimation.value *
                                              2 *
                                              3.14159,
                                          child: const Icon(
                                            Icons.search,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Scanning...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bluetooth_searching,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Scan for Devices',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              colors: [Colors.green, Colors.green.shade700],
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () => _syncHealthData(),
                              child: const Center(
                                child: Text(
                                  'Sync Data',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              colors: [Colors.red, Colors.red.shade700],
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: _disconnectDevice,
                              child: const Center(
                                child: Text(
                                  'Disconnect',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // Device List
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Available Devices',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _devices.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.watch_off,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      'No devices found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Make sure your smartwatch is\nin pairing mode and nearby',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: _devices.length,
                                itemBuilder: (context, index) {
                                  final device = _devices[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 15),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(15),
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.watch,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      title: Text(
                                        device.name.isNotEmpty
                                            ? device.name
                                            : 'Unknown Device',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        device.id.id,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: ElevatedButton(
                                        onPressed: () =>
                                            _connectToDevice(device),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: const Text('Connect'),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _syncHealthData() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Syncing Health Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Downloading data from your smartwatch...'),
          ],
        ),
      ),
    );

    // Simulate data sync
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sync Complete'),
          content: const Text(
            'Successfully synced:\n\n'
            '• Heart rate data: 24 readings\n'
            '• Step count: 8,547 steps\n'
            '• Sleep data: 7.5 hours\n'
            '• Calories burned: 2,143 kcal',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    });
  }
}
