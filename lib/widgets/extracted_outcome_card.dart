import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/extracted_outcome.dart';
import '../widgets/outcome_chip.dart';

class ExtractedOutcomeCard extends StatefulWidget {
  final ExtractedOutcome outcome;
  final VoidCallback onContinue;
  final Function(String) onTextChanged;
  
  const ExtractedOutcomeCard({
    super.key,
    required this.outcome,
    required this.onContinue,
    required this.onTextChanged,
  });

  @override
  State<ExtractedOutcomeCard> createState() => _ExtractedOutcomeCardState();
}

class _ExtractedOutcomeCardState extends State<ExtractedOutcomeCard> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.outcome.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = const Color(0xFF1A1A1A);
    final textColor = Colors.white;
    final secondaryTextColor = const Color(0xFF94A3B8);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Outcome type chip
          OutcomeChip(
            outcomeType: widget.outcome.type,
            isSelected: true,
            onTap: () {},
          ),
          
          const SizedBox(height: 12),
          
          // Editable text
          TextField(
            controller: _controller,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              height: 1.5,
            ),
            maxLines: null,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Edit outcome...',
              hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.5)),
            ),
            onChanged: widget.onTextChanged,
          ),
          
          const SizedBox(height: 16),
          
          // Beautiful action buttons (2 buttons side by side)
          Row(
            children: [
              // Share button (left side, cyan gradient)
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF22D3EE), Color(0xFF06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22D3EE).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Share.share(_controller.text);
                    },
                    icon: const Icon(Icons.share, size: 20, color: Colors.black),
                    label: const Text(
                      'Share',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Continue button (right side, cyan gradient)
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF22D3EE), Color(0xFF06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22D3EE).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: widget.onContinue,
                    icon: const Icon(Icons.play_arrow, size: 20, color: Colors.black),
                    label: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
