import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/share_service.dart';

class UnstuckActionWidget extends StatefulWidget {
  final String initialAction;
  final Function(String) onActionChanged;
  final VoidCallback? onReminderTap;
  
  const UnstuckActionWidget({
    super.key,
    required this.initialAction,
    required this.onActionChanged,
    this.onReminderTap,
  });

  @override
  State<UnstuckActionWidget> createState() => _UnstuckActionWidgetState();
}

class _UnstuckActionWidgetState extends State<UnstuckActionWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAction);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calColor = const Color(0xFF67E8F9);
    final textColor = Colors.white;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: calColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: calColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with checkmark icon
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: calColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'One small move',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Editable action text
          TextField(
            controller: _controller,
            style: TextStyle(
              fontSize: 18,
              color: textColor,
              height: 1.6,
            ),
            maxLines: null,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Edit your action...',
              hintStyle: TextStyle(color: textColor.withOpacity(0.3)),
            ),
            onChanged: widget.onActionChanged,
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              // Share button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ShareService.shareText(context, _controller.text);
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: calColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              if (widget.onReminderTap != null) ...[
                const SizedBox(width: 12),
                
                // Optional reminder button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onReminderTap,
                    icon: const Icon(Icons.notifications_outlined, size: 18),
                    label: const Text('Remind me'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: calColor,
                      side: BorderSide(color: calColor.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
