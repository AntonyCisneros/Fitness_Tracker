import 'dart:async';
import 'package:flutter/material.dart';

class FallDetectionDialog extends StatefulWidget {
  const FallDetectionDialog({super.key});

  @override
  State<FallDetectionDialog> createState() => _FallDetectionDialogState();
}

class _FallDetectionDialogState extends State<FallDetectionDialog> {
  int _secondsRemaining = 15;
  Timer? _timer;
  bool _warningShown = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _secondsRemaining--;
      });

      if (_secondsRemaining <= 5 && !_warningShown) {
        _warningShown = true;
      }

      if (_secondsRemaining <= 0) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: _secondsRemaining <= 5 ? Colors.orange[50] : Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red[700],
              size: 28,
            ),
            const SizedBox(width: 10),
            const Text(
              '¿Estás bien?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Se ha detectado una posible caída.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (_warningShown)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  'Por favor confirma que te encuentras bien.',
                  style: TextStyle(
                    color: Colors.red[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _secondsRemaining / 15,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _secondsRemaining <= 5 ? Colors.red : const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_secondsRemaining}s',
              style: TextStyle(
                color: _secondsRemaining <= 5 ? Colors.red : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Estoy bien'),
          ),
        ],
      ),
    );
  }
}
