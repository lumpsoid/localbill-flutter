import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Full-screen QR code scanner.
///
/// Returns the scanned URL string via `Navigator.pop(context, url)`, or
/// `null` if the user cancels. Only the first valid QR barcode is returned.
///
/// Usage:
/// ```dart
/// final url = await Navigator.of(context).push<String>(
///   ScannerPage.route(),
/// );
/// if (url != null) { /* use url */ }
/// ```
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  static MaterialPageRoute<String> route() => MaterialPageRoute<String>(
    settings: const RouteSettings(name: '/scanner'),
    builder: (_) => const ScannerPage(),
  );

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  bool _torchOn = false;
  bool _detected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    for (final barcode in capture.barcodes) {
      final url = barcode.rawValue;
      if (url != null && url.isNotEmpty) {
        _detected = true;
        // Small delay so the camera preview shows the detection frame.
        Future<void>.delayed(const Duration(milliseconds: 200), () {
          if (mounted) Navigator.of(context).pop(url);
        });
        return;
      }
    }
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan invoice QR'),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            tooltip: _torchOn ? 'Torch off' : 'Torch on',
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Scan-area overlay
          Center(
            child: CustomPaint(
              size: const Size(260, 260),
              painter: _CornerFramePainter(),
            ),
          ),
          // Hint label
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Point at the QR code on your invoice',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws four corner brackets to frame the scan area.
class _CornerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const arm = 30.0; // length of each corner arm
    final w = size.width;
    final h = size.height;

    // Top-left
    canvas
      ..drawLine(Offset(0, arm), Offset(0, 0), paint)
      ..drawLine(Offset(0, 0), Offset(arm, 0), paint)
      // Top-right
      ..drawLine(Offset(w - arm, 0), Offset(w, 0), paint)
      ..drawLine(Offset(w, 0), Offset(w, arm), paint)
      // Bottom-right
      ..drawLine(Offset(w, h - arm), Offset(w, h), paint)
      ..drawLine(Offset(w, h), Offset(w - arm, h), paint)
      // Bottom-left
      ..drawLine(Offset(arm, h), Offset(0, h), paint)
      ..drawLine(Offset(0, h), Offset(0, h - arm), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
