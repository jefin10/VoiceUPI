import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:highlight_text/highlight_text.dart';
import '../services/intent_service.dart';
import '../constants/app_colors.dart';

void main() {
  runApp(const VoiceToTextApp());
}

class VoiceToTextApp extends StatelessWidget {
  const VoiceToTextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UPI Voice Assistant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: const SpeechScreen(),
    );
  }
}

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final Map<String, HighlightedWord> _highlights = {
    'send': HighlightedWord(
      textStyle: const TextStyle(
        color: AppColors.success,
        fontWeight: FontWeight.bold,
      ),
    ),
    'balance': HighlightedWord(
      textStyle: const TextStyle(
        color: AppColors.info,
        fontWeight: FontWeight.bold,
      ),
    ),
    'payment': HighlightedWord(
      textStyle: const TextStyle(
        color: AppColors.warning,
        fontWeight: FontWeight.bold,
      ),
    ),
    'request': HighlightedWord(
      textStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
    ),
  };

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  bool _isProcessing = false;
  bool _serverConnected = false;
  String _text = 'Press the button and start speaking';
  double _confidence = 1.0;

  // Voice assistant results
  String? _predictedIntent;
  double? _intentConfidence;
  String? _errorMessage;
  String? _assistantResponse;
  Map<String, dynamic>? _entities;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _checkServerConnection();
  }

  void _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechEnabled = await _speech.initialize();
    setState(() {});
  }

  void _checkServerConnection() async {
    final isConnected = await IntentService.checkServerHealth();
    setState(() {
      _serverConnected = isConnected;
    });
  }

  void _startListening() async {
    await _speech.listen(onResult: _onSpeechResult);
    setState(() {
      _isListening = true;
      _errorMessage = null;
    });
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(result) async {
    setState(() {
      _text = result.recognizedWords;
      _confidence = result.confidence;
    });

    // Process voice command when speech is complete using enhanced voice assistant
    if (result.finalResult && _text.isNotEmpty && _serverConnected) {
      await _processEnhancedVoiceCommand(_text);
    }
  }

  Future<void> _processEnhancedVoiceCommand(String text) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _assistantResponse = null;
      _entities = null;
    });

    try {
      // Use the enhanced voice command processing
      final result = await IntentService.processVoiceCommand(text);

      if (result['status'] == 'success') {
        final intent = result['intent'];
        final action = result['action'];
        final message = result['message'];

        setState(() {
          _predictedIntent = intent;
          _intentConfidence = result['confidence']?.toDouble() ?? 0.0;
          _assistantResponse = message;
          _isProcessing = false;
        });

        // Handle different actions
        if (action == 'initiate_transfer') {
          // Show confirmation dialog for money transfer
          final data = result['data'];
          if (data != null) {
            _showTransferConfirmation(data);
          } else {
            _showSnackBar(
              'Missing transaction details. Please try again.',
              AppColors.warning,
            );
          }
        } else if (action == 'show_balance') {
          _showSnackBar(message ?? 'Opening balance page', AppColors.info);
          // Navigate to balance page
          // Navigator.pushNamed(context, '/balance');
        } else if (action == 'initiate_request') {
          final data = result['data'];
          if (data != null) {
            _showRequestConfirmation(data);
          } else {
            _showSnackBar(
              'Missing request details. Please try again.',
              AppColors.warning,
            );
          }
        } else {
          _showSnackBar(message ?? 'Command processed', AppColors.success);
        }
      } else {
        final message = result['message'] ?? 'Failed to process command';
        final missing = result['missing'];

        setState(() {
          _errorMessage = message;
          _assistantResponse = message;
          _isProcessing = false;
        });

        // Show error or missing info message
        _showSnackBar(message, missing != null ? AppColors.warning : AppColors.error);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _assistantResponse =
            'Sorry, I encountered an error processing your request.';
        _isProcessing = false;
      });

      _showSnackBar('Connection error: $e', AppColors.error);
    }
  }

  /// Show confirmation dialog for money transfer
  void _showTransferConfirmation(Map<String, dynamic> data) {
    final amount = data['amount'] ?? 0.0;
    final recipient = data['recipient'] ?? 'Unknown';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Confirm Transfer',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹$amount',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'to $recipient',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Voice Command:',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '"$_text"',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _executeMoneyTransfer(data);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Confirm & Send'),
            ),
          ],
        );
      },
    );
  }

  /// Show confirmation dialog for money request
  void _showRequestConfirmation(Map<String, dynamic> data) {
    final amount = data['amount'];
    final recipient = data['recipient'] ?? 'someone';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Confirm Request',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.request_page_rounded,
                    color: AppColors.warning,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Request ${amount != null ? "₹$amount" : "money"} from $recipient?',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _executeMoneyRequest(data);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Send Request'),
            ),
          ],
        );
      },
    );
  }

  /// Execute money transfer (simulated)
  Future<void> _executeMoneyTransfer(Map<String, dynamic> data) async {
    final amount = data['amount'];
    final recipient = data['recipient'];

    // Show loading
    setState(() {
      _isProcessing = true;
      _assistantResponse = 'Processing transfer...';
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    // Show success message
    setState(() {
      _isProcessing = false;
      _assistantResponse = '✓ Successfully sent ₹$amount to $recipient!';
    });

    _showSuccessDialog('Payment Successful!', '₹$amount sent to $recipient');
  }

  /// Execute money request (simulated)
  Future<void> _executeMoneyRequest(Map<String, dynamic> data) async {
    final amount = data['amount'];
    final recipient = data['recipient'];

    // Show loading
    setState(() {
      _isProcessing = true;
      _assistantResponse = 'Sending request...';
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Show success message
    setState(() {
      _isProcessing = false;
      _assistantResponse = '✓ Money request sent to ${recipient ?? "contact"}!';
    });

    _showSnackBar(
      'Request sent for ${amount != null ? "₹$amount" : "money"}',
      AppColors.success,
    );
  }

  /// Show success dialog
  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _clearText() {
    setState(() {
      _text = 'Press the button and start speaking';
      _predictedIntent = null;
      _intentConfidence = null;
      _errorMessage = null;
      _assistantResponse = null;
      _entities = null;
    });
  }

  Color _getIntentColor(String? intent) {
    switch (intent?.toLowerCase()) {
      case 'send_money':
        return AppColors.success;
      case 'check_balance':
        return AppColors.info;
      case 'request_money':
        return AppColors.primary;
      case 'payment_history':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatIntent(String? intent) {
    if (intent == null) return '';

    switch (intent.toLowerCase()) {
      case 'transfer_money':
        return 'Money Transfer';
      case 'check_balance':
        return 'Balance Check';
      case 'request_money':
        return 'Money Request';
      default:
        return intent.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Column(
        children: [
          // Purple gradient header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // App bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Voice Assistant',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Server status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _serverConnected ? AppColors.success : AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _serverConnected ? 'Online' : 'Offline',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _checkServerConnection,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Server status warning
                    if (!_serverConnected)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_rounded, color: AppColors.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Server not connected. Intent prediction unavailable.',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Speech confidence
                    if (_speechEnabled && _confidence != 1.0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Confidence: ${(_confidence * 100.0).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    // Speech text display card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: _clearText,
                        child: Column(
                          children: [
                            if (_isListening)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Listening...',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_text == 'Press the button and start speaking')
                              Column(
                                children: [
                                  Icon(
                                    Icons.mic_none_rounded,
                                    size: 48,
                                    color: AppColors.textSecondary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _text,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            else
                              TextHighlight(
                                text: _text,
                                words: _highlights,
                                textStyle: const TextStyle(
                                  fontSize: 22,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 16),
                            Text(
                              'Tap to clear',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Enhanced voice assistant results
                    if (_isProcessing)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Processing your request...',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Icon(Icons.mic, color: AppColors.primary),
                          ],
                        ),
                      )
                    else if (_assistantResponse != null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Assistant response header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.assistant,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Voice Assistant',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                if (_predictedIntent != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getIntentColor(_predictedIntent).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getIntentColor(_predictedIntent).withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _formatIntent(_predictedIntent),
                                      style: TextStyle(
                                        color: _getIntentColor(_predictedIntent),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Main assistant response
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.05),
                                    AppColors.primary.withOpacity(0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                _assistantResponse ?? 'Processing...',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),

                            // Show entities if available
                            if (_entities != null && (_entities?.isNotEmpty ?? false)) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Extracted Information:',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: (_entities?.entries ?? []).map((entry) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: Text(
                                            '${entry.key}: ${entry.value}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Show confidence if available
                            if (_intentConfidence != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.analytics,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Confidence: ${((_intentConfidence ?? 0.0) * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        color: AppColors.border,
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: _intentConfidence ?? 0.0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(3),
                                            color: _intentConfidence! > 0.7
                                                ? AppColors.success
                                                : _intentConfidence! > 0.5
                                                    ? AppColors.warning
                                                    : AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      )
                    else if (_predictedIntent != null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.psychology,
                                  color: _getIntentColor(_predictedIntent),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getIntentColor(_predictedIntent).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getIntentColor(_predictedIntent),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                _formatIntent(_predictedIntent),
                                style: TextStyle(
                                  color: _getIntentColor(_predictedIntent),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_intentConfidence != null)
                              Row(
                                children: [
                                  Icon(Icons.analytics, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Confidence: ${(_intentConfidence! * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      )
                    else if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: AppColors.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        animate: _isListening,
        glowColor: AppColors.primary,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _speechEnabled
                ? (_isListening ? _stopListening : _startListening)
                : null,
            backgroundColor: _isListening ? AppColors.error : AppColors.primary,
            elevation: 0,
            child: Icon(
              _isListening ? Icons.mic_off : Icons.mic,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
