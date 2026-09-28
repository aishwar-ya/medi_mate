import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _hasScanned = false;

  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = MobileScannerController(
      formats: const [BarcodeFormat.code128],
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();

      if (value == null || value.isEmpty) {
        continue;
      }

      debugPrint('====================================');
      debugPrint('ANDROID BARCODE DETECTED!');
      debugPrint('VALUE: $value');
      debugPrint('FORMAT: ${barcode.format}');
      debugPrint('====================================');

      _hasScanned = true;

      _controller.stop();

      Navigator.pop(context, value);

      return;
    }
  }

  void _enterBarcodeManually() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Enter Barcode'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Barcode',
              hintText: 'Example: MEDIC006',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext);

                _hasScanned = true;

                _controller.stop();

                Navigator.pop(context, value);
              },
              child: const Text('Use Barcode'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Scan Barcode',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(controller: _controller, onDetect: _onDetect),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(80),
                      Colors.transparent,
                      Colors.black.withAlpha(180),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: Container(
              width: 360,
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          Positioned(
            top: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const Text(
                  'Scan Code 128 Barcode',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Point the camera at your medicine barcode',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 35,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const Text(
                  'Keep the complete Code 128 barcode inside the box',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _enterBarcodeManually,
                  icon: const Icon(Icons.keyboard, color: Colors.white),
                  label: const Text(
                    'Enter Barcode Manually',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
