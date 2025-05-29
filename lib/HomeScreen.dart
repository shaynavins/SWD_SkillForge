import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, TextEditingController> checkpointControllers = {};
  final supabase = Supabase.instance.client;
  List<dynamic> challenges = [];
  Map<String, List<dynamic>> checkpointsMap = {};
  String? userId;

    Future<void> showCreateChallengeDialogue() async {
    final titleController = TextEditingController();
    final pointsController = TextEditingController();

    
    List<TextEditingController> checkpointControllers = [TextEditingController()];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Create Challenge'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: pointsController,
                    decoration: const InputDecoration(labelText: 'Points'),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Checkpoints",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...checkpointControllers.map(
                    (c) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: TextField(
                        controller: c,
                        decoration: const InputDecoration(labelText: 'Checkpoint'),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        checkpointControllers.add(TextEditingController());
                      });
                    },
                    child: const Text('Add Checkpoint'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
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
                      const SnackBar(content: Text("Title and checkpoints cannot be empty")),
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

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Challenge created successfully!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        });
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
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('submissions').insert({
        'user_id': user.id,
        'checkpoint_id': checkpointId,
        'content': content,
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
  }

  Future<void> fetchChallenges() async {
    try {
      final response = await supabase.from('challenges').select();
      setState(() {
        challenges = response;
      });
    } catch (e) {
      print("Error fetching challenges: $e");
    }
  }

  Widget buildChallengeCard(dynamic challenge) {
    
    final challengeId = challenge['id'];
    final checkpoints = checkpointsMap[challengeId] ?? [];

    return Card(

      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: Text(challenge['title']),
        children: [
          ElevatedButton(
            onPressed: () => joinChallenge(challengeId),
            child: const Text("Join Challenge"),
          ),
          ElevatedButton(
            onPressed: () async {
              await fetchCheckpoints(challengeId);
              setState(() {}); // force rebuild to show updated list
            },
            child: const Text("Load Checkpoints"),
          ),
          ...checkpoints.map<Widget>((cp) {
            return ListTile(
              title: Text("Checkpoint ${cp['order']}: ${cp['prompt_text']}"),
              subtitle: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: checkpointControllers.putIfAbsent(
                        cp['id'].toString(),
                        () => TextEditingController(),
                      ),
                      decoration: const InputDecoration(labelText: 'Answer'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final controller = checkpointControllers[cp['id'].toString()];
                      final content = controller?.text ?? '';
                      submitCheckpoint(
                        checkpointId: cp['id'],
                        content: content,
                        isDone: true,
                      );
                    },
                    child: const Text("Submit"),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            );
          }).toList(),

        ],
      ),
    );
  }
  Widget build(BuildContext context) {
    final userEmail = supabase.auth.currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              (context as Element).reassemble();
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Welcome, $userEmail",
                style: const TextStyle(fontSize: 18)),
          ),
          ...challenges.map<Widget>((challenge) => buildChallengeCard(challenge)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showCreateChallengeDialogue, 
        label: const Text("Create Challenge"),
      ),
    );
  }
}
