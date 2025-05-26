import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;

    Future<void> showCreateChallengeDialogue() async {
    final titleController = TextEditingController();
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

  Future<void> fetchAndPrintChallenges() async {
  final supabase = Supabase.instance.client;

      try {
        final response = await supabase
            .from('challenges')
            .select();

        print("🔹 Challenges fetched:");
        for (var challenge in response) {
          print("${challenge['title']} (ID: ${challenge['id']})");
        }
      } catch (e) {
        print("Error fetching challenges: $e");
      }
  }



  @override
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome, $userEmail"),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: fetchAndPrintChallenges,
              icon: const Icon(Icons.download),
              label: const Text("Fetch Challenges"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showCreateChallengeDialogue, 
        label: const Text("Create Challenge"),
      ),
    );
  }
}
