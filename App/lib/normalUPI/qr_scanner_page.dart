import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import '../payToUpiId/payToUpiId.dart';
import '../constants/app_colors.dart';
import 'my_qr_page.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController controller = MobileScannerController();
  bool _isFlashOn = false;
  bool _isScanning = true;
  String? _scannedData;
  Map<String, String>? _upiData;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Camera Permission Required',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Please grant camera permission to scan QR codes.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Settings', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Custom App Bar
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              bottom: 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Scan & Pay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                  ),
                  onPressed: _toggleFlash,
                ),
              ],
            ),
          ),

          // Camera View
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: _onQRDetected,
                ),
                _buildScannerOverlay(),
                ..._buildCornerDecorations(),
                if (_isScanning) _buildScanningAnimation(),
              ],
            ),
          ),

          // Bottom Section
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_scannedData != null) ...[
                    _buildScannedDataDisplay(),
                  ] else ...[
                    _buildInstructions(),
                  ],
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: AppColors.primary,
          borderRadius: 16,
          borderLength: 30,
          borderWidth: 6,
          cutOutSize: 280,
        ),
      ),
    );
  }

  List<Widget> _buildCornerDecorations() {
    return [
      Positioned(
        top: 60,
        left: 60,
        child: _buildCornerDecoration(true, true),
      ),
      Positioned(
        top: 60,
        right: 60,
        child: _buildCornerDecoration(true, false),
      ),
      Positioned(
        bottom: 60,
        left: 60,
        child: _buildCornerDecoration(false, true),
      ),
      Positioned(
        bottom: 60,
        right: 60,
        child: _buildCornerDecoration(false, false),
      ),
    ];
  }

  Widget _buildCornerDecoration(bool isTop, bool isLeft) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildScanningAnimation() {
    return Positioned.fill(
      child: Center(
        child: SizedBox(
          width: 280,
          height: 280,
          child: Container(
            width: double.infinity,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primary.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScannedDataDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'QR Code Scanned',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_upiData != null) ...[
            _buildUpiInfo(),
          ] else ...[
            Text(
              _scannedData!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (_upiData != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _proceedWithPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Proceed to Pay',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpiInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_upiData!['pa'] != null) ...[
          const Text('UPI ID', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            _upiData!['pa']!,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
        ],
        if (_upiData!['pn'] != null) ...[
          const Text('Name', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            _upiData!['pn']!,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
        ],
        if (_upiData!['am'] != null) ...[
          const Text('Amount', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            '₹${_upiData!['am']}',
            style: const TextStyle(color: AppColors.success, fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          'Point camera at QR code',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Scan any UPI QR code to pay instantly',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(Icons.photo_library_outlined, 'Gallery', _pickFromGallery),
        _buildActionButton(Icons.qr_code_rounded, 'My QR', _showMyQR),
        _buildActionButton(Icons.refresh_rounded, 'Rescan', _rescan),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _onQRDetected(BarcodeCapture capture) {
    if (_isScanning && capture.barcodes.isNotEmpty) {
      final String? code = capture.barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          _isScanning = false;
          _scannedData = code;
          _upiData = _parseUpiData(code);
        });
        
        // Vibrate on successful scan
        _vibrate();
      }
    }
  }

  Map<String, String>? _parseUpiData(String qrData) {
    try {
      // Parse UPI QR code format
      if (qrData.startsWith('upi://pay?') || qrData.contains('pa=')) {
        final uri = Uri.parse(qrData);
        final Map<String, String> upiData = {};
        
        uri.queryParameters.forEach((key, value) {
          upiData[key] = value;
        });
        
        return upiData.isNotEmpty ? upiData : null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _vibrate() {
    // Add haptic feedback here if needed
    // HapticFeedback.mediumImpact();
  }

  void _toggleFlash() async {
    await controller.toggleTorch();
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  void _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      // Here you would typically use a library to decode QR from image
      // For now, show a placeholder message
      _showSnackBar('Gallery QR scanning feature coming soon!');
    }
  }

  void _showMyQR() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyQRPage(),
      ),
    );
  }

  void _rescan() {
    setState(() {
      _isScanning = true;
      _scannedData = null;
      _upiData = null;
    });
  }

  void _proceedWithPayment() {
    if (_upiData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PayToUpiIdPage(
            prefilledUpiId: _upiData!['pa'],
            prefilledAmount: _upiData!['am'],
            prefilledName: _upiData!['pn'],
          ),
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// Custom overlay shape for QR scanner
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
  }) : cutOutSize = cutOutSize ?? 250;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final cutOutWidth = cutOutSize < width ? cutOutSize : width - borderRadius;
    final cutOutHeight = cutOutSize < height ? cutOutSize : height - borderRadius;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + (width - cutOutWidth) / 2 + borderWidth,
      rect.top + (height - cutOutHeight) / 2 + borderWidth,
      cutOutWidth - 2 * borderWidth,
      cutOutHeight - 2 * borderWidth,
    );

    // Background
    canvas
      ..drawPath(
          Path.combine(
            PathOperation.difference,
            Path()..addRect(rect),
            Path()
              ..addRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)))
              ..close(),
          ),
          backgroundPaint);

    // Top left corner
    canvas.drawPath(
        Path()
          ..moveTo(cutOutRect.left - borderLength, cutOutRect.top)
          ..lineTo(cutOutRect.left, cutOutRect.top)
          ..lineTo(cutOutRect.left, cutOutRect.top - borderLength),
        boxPaint);

    // Top right corner
    canvas.drawPath(
        Path()
          ..moveTo(cutOutRect.right + borderLength, cutOutRect.top)
          ..lineTo(cutOutRect.right, cutOutRect.top)
          ..lineTo(cutOutRect.right, cutOutRect.top - borderLength),
        boxPaint);

    // Bottom left corner
    canvas.drawPath(
        Path()
          ..moveTo(cutOutRect.left - borderLength, cutOutRect.bottom)
          ..lineTo(cutOutRect.left, cutOutRect.bottom)
          ..lineTo(cutOutRect.left, cutOutRect.bottom + borderLength),
        boxPaint);

    // Bottom right corner
    canvas.drawPath(
        Path()
          ..moveTo(cutOutRect.right + borderLength, cutOutRect.bottom)
          ..lineTo(cutOutRect.right, cutOutRect.bottom)
          ..lineTo(cutOutRect.right, cutOutRect.bottom + borderLength),
        boxPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
