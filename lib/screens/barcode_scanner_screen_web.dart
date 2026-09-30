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
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color lavender = Color(0xFFF0E9FF);
  static const Color pageBg = Color(0xFFF8F6FF);
  static const Color textDark = Color(0xFF211738);
  static const Color textMuted = Color(0xFF716A80);

  late web.HTMLVideoElement _videoElement;
  bool _hasScanned = false;
  String _status = 'Starting camera...';

  @override
  void initState() {
    super.initState();
    _videoElement = web.HTMLVideoElement()
      ..autoplay = true
      ..muted = true;
    _videoElement.setAttribute('playsinline', 'true');
    _videoElement.style.width = '100%';
    _videoElement.style.height = '100%';
    _videoElement.style.objectFit = 'cover';

    ui_web.platformViewRegistry.registerViewFactory(
      'medimate-zxing-camera',
      (int viewId) => _videoElement,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _startScanner());
  }

  Future<void> _startScanner() async {
    if (!mounted) return;
    setState(() => _status = 'Starting Code 128 scanner...');

    try {
      final callback = ((JSString? value) {
        if (!mounted || _hasScanned) return;
        final text = value?.toDart.trim() ?? '';
        if (text.isEmpty) return;

        if (text.startsWith('ERROR:')) {
          setState(() => _status = text);
          return;
        }

        _hasScanned = true;
        setState(() => _status = 'Barcode detected: $text');
        _stopScanner();
        Navigator.pop(context, text);
      }).toJS;

      await startMediMateBarcodeScanner(_videoElement, callback).toDart;
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Could not start barcode scanner');
    }
  }

  void _stopScanner() {
    try {
      stopMediMateBarcodeScanner();
    } catch (_) {}
  }

  void _enterBarcodeManually() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.keyboard_rounded, color: primary),
              SizedBox(width: 10),
              Text('Enter Barcode', style: TextStyle(color: textDark, fontWeight: FontWeight.w800)),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Barcode',
              hintText: 'Example: MEDIC009',
              filled: true,
              fillColor: const Color(0xFFF7F4FC),
              prefixIcon: const Icon(Icons.qr_code_2_rounded, color: primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFE2D9F2))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFE2D9F2))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: primary, width: 2)),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel', style: TextStyle(color: textMuted))),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(dialogContext);
                _stopScanner();
                Navigator.pop(context, value);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              child: const Text('Use Barcode'),
            ),
          ],
        );
      },
    ).then((_) => controller.dispose());
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
      backgroundColor: pageBg,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                Container(
                  height: 108,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [primary, primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 42, 18, 12),
                    child: Row(
                      children: [
                        Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.pop(context),
                            child: const SizedBox(width: 44, height: 44, child: Icon(Icons.arrow_back_rounded, color: primary, size: 25)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 25),
                        const SizedBox(width: 9),
                        const Text('Scan Barcode', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      children: [
                        const Text('Scan your medicine barcode', style: TextStyle(color: textDark, fontSize: 21, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(_status, textAlign: TextAlign.center, style: const TextStyle(color: textMuted, fontSize: 12.5)),
                        const SizedBox(height: 18),
                        Container(
                          height: 330,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [BoxShadow(color: primary.withOpacity(.12), blurRadius: 24, offset: const Offset(0, 10))],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(child: HtmlElementView(viewType: 'medimate-zxing-camera')),
                              Container(width: 285, height: 175, decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2.5), borderRadius: BorderRadius.circular(18))),
                              Positioned(top: 18, left: 18, child: _corner(true, true)),
                              Positioned(top: 18, right: 18, child: _corner(true, false)),
                              Positioned(bottom: 18, left: 18, child: _corner(false, true)),
                              Positioned(bottom: 18, right: 18, child: _corner(false, false)),
                              Positioned(
                                bottom: 16,
                                left: 24,
                                right: 24,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(.58), borderRadius: BorderRadius.circular(13)),
                                  child: const Text('Keep the complete barcode inside the frame', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11.5)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(color: lavender, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE1D2FF))),
                          child: const Row(
                            children: [
                              CircleAvatar(radius: 20, backgroundColor: Color(0xFFE1D2FF), child: Icon(Icons.info_outline_rounded, color: primary, size: 21)),
                              SizedBox(width: 12),
                              Expanded(child: Text('Make sure the barcode is clear and well lit for faster scanning.', style: TextStyle(color: textMuted, fontSize: 11.5, height: 1.35))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _enterBarcodeManually,
                            icon: const Icon(Icons.keyboard_rounded, color: primary),
                            label: const Text('Enter Barcode Manually', style: TextStyle(color: primary, fontWeight: FontWeight.w800)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFBBA5F5), width: 1.3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _corner(bool top, bool left) {
    return SizedBox(
      width: 34,
      height: 34,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: top ? const BorderSide(color: Color(0xFFA78BFA), width: 4) : BorderSide.none,
            bottom: !top ? const BorderSide(color: Color(0xFFA78BFA), width: 4) : BorderSide.none,
            left: left ? const BorderSide(color: Color(0xFFA78BFA), width: 4) : BorderSide.none,
            right: !left ? const BorderSide(color: Color(0xFFA78BFA), width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
