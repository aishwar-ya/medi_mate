import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

@JS('startMediMateBarcodeScanner')
external JSPromise startMediMateBarcodeScanner(
  web.HTMLVideoElement videoElement,
  JSFunction callback,
);

@JS('stopMediMateBarcodeScanner')
external void stopMediMateBarcodeScanner();

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late web.HTMLVideoElement _videoElement;

  bool _hasScanned = false;

  String _status = 'Starting camera...';

  @override
  void initState() {
    super.initState();

    _videoElement = web.HTMLVideoElement();

    _videoElement.autoplay = true;
    _videoElement.muted = true;

    _videoElement.setAttribute('playsinline', 'true');

    _videoElement.style.width = '100%';
    _videoElement.style.height = '100%';
    _videoElement.style.objectFit = 'cover';

    ui_web.platformViewRegistry.registerViewFactory('medimate-zxing-camera', (
      int viewId,
    ) {
      return _videoElement;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScanner();
    });
  }

  Future<void> _startScanner() async {
    if (!mounted) return;

    setState(() {
      _status = 'Starting Code 128 scanner...';
    });

    try {
      final callback =
          ((JSString? value) {
            if (!mounted) return;
            if (_hasScanned) return;

            final text = value?.toDart.trim() ?? '';

            debugPrint('====================================');

            debugPrint('QUAGGA RESULT: $text');

            debugPrint('====================================');

            if (text.isEmpty) {
              return;
            }

            if (text.startsWith('ERROR:')) {
              setState(() {
                _status = text;
              });
              return;
            }

            _hasScanned = true;

            setState(() {
              _status = 'Barcode detected: $text';
            });

            _stopScanner();

            Navigator.pop(context, text);
          }).toJS;

      await startMediMateBarcodeScanner(_videoElement, callback).toDart;
    } catch (e) {
      debugPrint('Quagga start error: $e');

      if (!mounted) return;

      setState(() {
        _status = 'Could not start barcode scanner';
      });
    }
  }

  void _stopScanner() {
    try {
      stopMediMateBarcodeScanner();
    } catch (e) {
      debugPrint('Quagga stop error: $e');
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
              hintText: 'Example: MEDIC009',
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

                _stopScanner();

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
    _stopScanner();

    try {
      _videoElement.srcObject = null;
    } catch (_) {}

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
            child: const HtmlElementView(viewType: 'medimate-zxing-camera'),
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

                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
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
                  'Point camera at the barcode',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Keep the complete Code 128 barcode inside the box',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
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
