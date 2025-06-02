import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:codeapp/theme/app_theme.dart';
import 'package:codeapp/realtime_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, TextEditingController> checkpointControllers = {};
  final supabase = Supabase.instance.client;
  final _realtimeService = realtime_service();
  TextEditingController searchController = TextEditingController();
  List<dynamic> searchResults = [];
  List<dynamic> challenges = [];
  Map<String, List<dynamic>> checkpointsMap = {};
  String? userId;
  bool _isLoading = false;

  void _setupRealtimeSubscriptions() {
    // Subscribe to challenges table
    _realtimeService.subscribeToChanges(
      tableName: 'challenges',
      onChange: (payload) {
        fetchChallenges();
      },
    );

    // Subscribe to checkpoints table
    _realtimeService.subscribeToChanges(
      tableName: 'checkpoints',
      onChange: (payload) {
        // Refresh checkpoints for all loaded challenges
        checkpointsMap.keys.forEach((challengeId) {
          fetchCheckpoints(challengeId);
        });
      },
    );

    // Subscribe to challenge participants
    _realtimeService.subscribeToChanges(
      tableName: 'challenge_participants',
      onChange: (payload) {
        fetchChallenges();
      },
    );

    // Subscribe to checkpoint submissions
    _realtimeService.subscribeToChanges(
      tableName: 'checkpoint_submissions',
      onChange: (payload) {
        // Refresh checkpoints for the affected challenge
        if (payload['new'] != null) {
          final checkpointId = payload['new']['checkpoint_id'];
          // Find the challenge ID for this checkpoint and refresh it
          checkpointsMap.forEach((challengeId, checkpoints) {
            if (checkpoints.any((cp) => cp['id'] == checkpointId)) {
              fetchCheckpoints(challengeId);
            }
          });
        }
      },
    );
  }

  Future<void> searchChallenges(String query) async { 
    if(query.isEmpty) {
      setState(()=> searchResults = []);
      return;
    }

    try {
      final results = await Supabase.instance.client
        .from('challenges')
        .select()
        .ilike('title', '%$query%');

      setState(()=> searchResults = results);
    } catch (e) {
      print("Error: $e");
    }
  }
  Widget _buildSearchResults() {
    return Container(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: searchChallenges,
              decoration: InputDecoration(
                hintText: 'Search challenges...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          searchChallenges('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: searchResults.isEmpty
                ? Center(
                    child: Text(
                      searchController.text.isEmpty
                          ? 'Start typing to search challenges'
                          : 'No challenges found',
                      style: TextStyle(
                        color: AppTheme.textColor.withOpacity(0.6),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final challenge = searchResults[index];
                      return ListTile(
                        title: Text(
                          challenge['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Points: ${challenge['points'] ?? 0}',
                          style: TextStyle(
                            color: AppTheme.textColor.withOpacity(0.7),
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.assignment,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        onTap: () {
                          // Handle challenge selection
                          searchController.clear();
                          searchChallenges('');
                          // TODO: Navigate to challenge details or handle selection
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> showCreateChallengeDialogue() async {
    final titleController = TextEditingController();
    final pointsController = TextEditingController();
    List<TextEditingController> checkpointControllers = [TextEditingController()];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create New Challenge',
                        style: AppTheme.headingStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: titleController,
                        decoration: AppTheme.textFieldDecoration(
                          labelText: 'Challenge Title',
                          prefixIcon: Icons.title,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: pointsController,
                        decoration: AppTheme.textFieldDecoration(
                          labelText: 'Points',
                          prefixIcon: Icons.stars,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Text(
                            "Checkpoints",
                            style: AppTheme.subheadingStyle,
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              setModalState(() {
                                checkpointControllers.add(TextEditingController());
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...checkpointControllers.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: entry.value,
                                  decoration: AppTheme.textFieldDecoration(
                                    labelText: 'Checkpoint ${entry.key + 1}',
                                    prefixIcon: Icons.check_circle_outline,
                                  ),
                                ),
                              ),
                              if (checkpointControllers.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () {
                                    setModalState(() {
                                      checkpointControllers.removeAt(entry.key);
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final user = supabase.auth.currentUser;
                              if (user == null) return;

                              final title = titleController.text.trim();
                              final pointsText = pointsController.text.trim();
                              final points = int.tryParse(pointsText) ?? 0;
                              final checkpoints = checkpointControllers
                                  .map((c) => c.text.trim())
                                  .where((c) => c.isNotEmpty)
                                  .toList();

                              if (title.isEmpty || checkpoints.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Title and checkpoints cannot be empty"),
                                    backgroundColor: AppTheme.errorColor,
                                  ),
                                );
                                return;
                              }

                              try {
                                final challengeResponse = await supabase
                                    .from('challenges')
                                    .insert({
                                      'title': title,
                                      'user_id': user.id,
                                      'points': points,
                                    })
                                    .select()
                                    .single();

                                final challengeId = challengeResponse['id'];

                                for (int i = 0; i < checkpoints.length; i++) {
                                  await supabase.from('checkpoints').insert({
                                    'challenge_id': challengeId,
                                    'order': i + 1,
                                    'prompt_text': checkpoints[i],
                                  });
                                }

                                if (!mounted) return;
                                Navigator.pop(context);
                                fetchChallenges();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Challenge created successfully!'),
                                    backgroundColor: AppTheme.secondaryColor,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: AppTheme.errorColor,
                                  ),
                                );
                              }
                            },
                            style: AppTheme.elevatedButtonStyle,
                            child: const Text('Create'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> fetchCheckpoints(String challengeId) async {
    try {
      final response = await supabase
          .from('checkpoints')
          .select()
          .eq('challenge_id', challengeId)
          .order('order');

      if (response.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No checkpoints found for this challenge.")),
        );
      }

      setState(() {
        checkpointsMap[challengeId] = response;
      });

      print("✅ Loaded ${response.length} checkpoints for $challengeId");
    } catch (e) {
      print("❌ Error fetching checkpoints: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading checkpoints: $e")),
      );
    }
  }

  Future<void> joinChallenge(String challengeId) async {
    if (userId == null) return;
    try {
      await supabase.from('challenge_participants').insert({
        'user_id': userId,
        'challenge_id': challengeId,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined challenge!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining challenge: $e')),
      );
    }
  }

  Future<void> submitCheckpoint({
    required String checkpointId,
    required String content,
    required bool isDone,
    required int points,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('submissions').insert({
        'user_id': user.id,
        'checkpoint_id': checkpointId,
        'content': content,
      });
      await supabase.rpc('increment_user_points', params: {
        'user_id': user.id,
        'delta': points,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final user = supabase.auth.currentUser;
    userId = user?.id;
    fetchChallenges();
    _setupRealtimeSubscriptions();
  }

  @override
  void dispose() {
    _realtimeService.dispose();
    super.dispose();
  }

  Future<void> fetchChallenges() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await supabase.from('challenges').select();
      setState(() {
        challenges = response;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching challenges: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget buildChallengeCard(dynamic challenge) {
    final challengeId = challenge['id'];
    final checkpoints = checkpointsMap[challengeId] ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: AppTheme.cardDecoration,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge['title'],
              style: AppTheme.subheadingStyle,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Text(
                  '${challenge['points'] ?? 0} points',
                  style: const TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () => joinChallenge(challengeId),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text("Join Challenge"),
                  style: AppTheme.elevatedButtonStyle,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await fetchCheckpoints(challengeId);
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Load Checkpoints"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (checkpoints.isNotEmpty) ...[
                  const Text(
                    'Checkpoints',
                    style: AppTheme.subheadingStyle,
                  ),
                  const SizedBox(height: 8),
                ],
                ...checkpoints.map<Widget>((cp) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "Checkpoint ${cp['order']}",
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cp['prompt_text'],
                          style: AppTheme.bodyStyle,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: checkpointControllers.putIfAbsent(
                            cp['id'].toString(),
                            () => TextEditingController(),
                          ),
                          decoration: AppTheme.textFieldDecoration(
                            labelText: 'Your Answer',
                            prefixIcon: Icons.edit,
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final controller = checkpointControllers[cp['id'].toString()];
                              final content = controller?.text ?? '';
                              submitCheckpoint(
                                checkpointId: cp['id'],
                                content: content,
                                isDone: true,
                                points: challenge['points'] ?? 0,
                              );
                            },
                            icon: const Icon(Icons.send),
                            label: const Text("Submit"),
                            style: AppTheme.elevatedButtonStyle,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = supabase.auth.currentUser?.email;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("SkillForge", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  height: MediaQuery.of(context).size.height * 0.9,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: _buildSearchResults(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back,",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail ?? "User",
                  style: AppTheme.headingStyle,
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pushReplacementNamed('/discussion');
                  },
                  label: const Text("Discussions"),
                  icon: const Icon(Icons.forum),
                ),
                 ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pushReplacementNamed('/leaderboard');
                  },
                  label: const Text("Leaderboard"),
                  icon: const Icon(Icons.forum),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pushReplacementNamed('/user');
                  },
                  label: const Text("Profile"),
                  icon: const Icon(Icons.forum),
                ),
              ],
            ),
          ),
          Expanded(
            child: challenges.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: AppTheme.primaryColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No challenges yet",
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.textColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Create your first challenge to get started",
                        style: TextStyle(
                          color: AppTheme.textColor.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: challenges.length,
                  itemBuilder: (context, index) => buildChallengeCard(challenges[index]),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showCreateChallengeDialogue,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text("Create Challenge"),
      ),
    );
  }
}
