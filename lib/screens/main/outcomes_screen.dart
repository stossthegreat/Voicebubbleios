// 🔥 REDIRECTING TO ELITE VERSION 🔥
export 'outcomes_screen_elite.dart';

// Re-export with same name for compatibility
typedef OutcomesScreen = OutcomesScreenElite;

class _OutcomesScreenState extends State<OutcomesScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showHeader = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && _showHeader) {
      setState(() => _showHeader = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFF000000);
    final surfaceColor = const Color(0xFF1A1A1A);
    final textColor = Colors.white;
    final secondaryTextColor = const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Consumer<AppStateProvider>(
          builder: (context, appState, _) {
            final recordings = appState.outcomesItems;

            if (recordings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.dashboard_outlined,
                      size: 64,
                      color: secondaryTextColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No recordings yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap Record to create your first one',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Group recordings by outcome
            final outcomeGroups = <OutcomeType, List<RecordingItem>>{};
            for (final outcome in OutcomeType.values) {
              outcomeGroups[outcome] = [];
            }

            for (final recording in recordings) {
              for (final outcomeStr in recording.outcomes) {
                final outcome = OutcomeTypeExtension.fromString(outcomeStr);
                outcomeGroups[outcome]!.add(recording);
              }
            }

            return ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                // Header inside scroll view
                Row(
                  children: [
                    Icon(
                      Icons.dashboard,
                      color: textColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Outcomes',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your AI-generated content, organized',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Messages
                _buildOutcomeSection(
                  context,
                  OutcomeType.message,
                  outcomeGroups[OutcomeType.message]!,
                  textColor,
                  secondaryTextColor,
                ),
                const SizedBox(height: 16),

                // Content
                      _buildOutcomeSection(
                        context,
                        OutcomeType.content,
                        outcomeGroups[OutcomeType.content]!,
                        textColor,
                        secondaryTextColor,
                      ),
                      const SizedBox(height: 16),

                      // Tasks
                      _buildOutcomeSection(
                        context,
                        OutcomeType.task,
                        outcomeGroups[OutcomeType.task]!,
                        textColor,
                        secondaryTextColor,
                      ),
                      const SizedBox(height: 16),

                      // Ideas
                      _buildOutcomeSection(
                        context,
                        OutcomeType.idea,
                        outcomeGroups[OutcomeType.idea]!,
                        textColor,
                        secondaryTextColor,
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      _buildOutcomeSection(
                        context,
                        OutcomeType.note,
                        outcomeGroups[OutcomeType.note]!,
                        textColor,
                        secondaryTextColor,
                      ),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
      ),
      floatingActionButton: MultiOptionFab(
        onVoicePressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RecordingScreen(),
            ),
          );
        },
        onTextPressed: () async {
          // Create empty outcome text document - user must select outcome type in editor
          final appState = Provider.of<AppStateProvider>(context, listen: false);
          final newItem = RecordingItem(
            id: const Uuid().v4(),
            rawTranscript: '',
            finalText: '',
            presetUsed: 'Outcome Document',
            outcomes: [], // User will select in editor
            projectId: null,
            createdAt: DateTime.now(),
            editHistory: [],
            presetId: 'outcome_document',
            tags: [],
            contentType: 'text',
            hiddenInLibrary: true, // Show only in outcomes
          );
          await appState.saveRecording(newItem);
          
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecordingDetailScreen(recordingId: newItem.id),
              ),
            );
          }
        },
        onTodoPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OutcomeCreationScreen(contentType: 'todo'),
            ),
          );
        },
        onImagePressed: () async {
          // Create empty outcome image
          final appState = Provider.of<AppStateProvider>(context, listen: false);
          final newItem = RecordingItem(
            id: const Uuid().v4(),
            rawTranscript: '', // Will store image path
            finalText: '',
            presetUsed: 'Outcome Image',
            outcomes: [], // User will select in editor
            projectId: null,
            createdAt: DateTime.now(),
            editHistory: [],
            presetId: 'outcome_image',
            tags: [],
            contentType: 'image',
            hiddenInLibrary: true, // Show only in outcomes
          );
          await appState.saveRecording(newItem);
          
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecordingDetailScreen(recordingId: newItem.id),
              ),
            );
          }
        },
        onNotePressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OutcomeCreationScreen(contentType: 'note'),
            ),
          );
        },
        onProjectPressed: null, // Hide project option in outcomes
      ),
    );
  }

  Widget _buildOutcomeSection(
    BuildContext context,
    OutcomeType outcome,
    List<RecordingItem> items,
    Color textColor,
    Color secondaryTextColor,
  ) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return OutcomeCard(
      outcomeType: outcome,
      itemCount: items.length,
      items: items.take(3).toList(), // Show preview of 3 items
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OutcomeDetailScreen(
              outcomeType: outcome,
              items: items,
            ),
          ),
        );
      },
    );
  }
}
