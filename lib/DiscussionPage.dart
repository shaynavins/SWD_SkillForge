import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiscussionPage extends StatefulWidget {
  const DiscussionPage({super.key});
  @override
  State<DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  List<dynamic> discussionPosts = [];

  final supabase = Supabase.instance.client;
  String? selectedChallengeId;
  String? selectedCheckpointId;
  List<dynamic> challenges = [];
  List<dynamic> checkpoints = [];

  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  Future<void> fetchChallenges() async {
    final res = await supabase.from('challenges').select();
    setState(() {
      challenges = res;
    });
  }
  Future<void> fetchCheckpoints(String challengeId) async {
    final res = await supabase
        .from('checkpoints')
        .select()
        .eq('challenge_id', challengeId)
        .order('order');
    setState(() {
      checkpoints = res;
    });
  }

  Future<void> postDiscussion() async {
    final user = supabase.auth.currentUser;
    if (user == null || selectedChallengeId == null || titleController.text.isEmpty) return;

    await supabase.from('discussion_posts').insert({
      'user_id': user.id,
      'challenge_id': selectedChallengeId,
      'checkpoint_id': selectedCheckpointId,
      'title': titleController.text.trim(),
      'body': bodyController.text.trim(),
    });
    titleController.clear();
    bodyController.clear();
    setState(() {
      selectedCheckpointId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Posted!")));

  }
  Future<void> fetchDiscussion() async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase 
        .from('discussion_posts')
        .select();

      for (var post in response) {
        print("📝 ${post['content']} (Challenge ID: ${post['challenge_id']}, Checkpoint ID: ${post['checkpoint_id']})");
      }
      setState(() {
        discussionPosts = response;
      });
    } catch (e) {
      print("❌ Error fetching discussion posts: $e");
    }
  }
  @override
  void initState() {
    super.initState();
    fetchChallenges();
    fetchDiscussion();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Discussion Forum")),
      body: Padding (
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: selectedChallengeId,
            decoration: const InputDecoration(labelText: 'select challenge'),
            items: challenges.map<DropdownMenuItem<String>>((c) {
              return DropdownMenuItem(
                  value: c['id'],
                  child: Text(c['title']),
                );
            }).toList(),
            onChanged: (val) {
              setState(() {
                selectedChallengeId = val;
                selectedCheckpointId = null;
                checkpoints = [];
              });
              if (val != null) fetchCheckpoints(val); 
            },
          ),
           DropdownButtonFormField<String>(
              value: selectedCheckpointId,
              decoration: const InputDecoration(labelText: 'Select Checkpoint (Optional)'),
              items: checkpoints.map<DropdownMenuItem<String>>((cp) {
                return DropdownMenuItem(
                  value: cp['id'],
                  child: Text(cp['prompt_text']),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedCheckpointId = val;
                });
              },
            ),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Question Title'),
            ),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Details'),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: postDiscussion,
              child: const Text("Post Question"),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: discussionPosts.length,
                itemBuilder: (context, index){
                  final post = discussionPosts[index];
                  final content = post['body'] ?? 'No content';
                  final challengeId = post['challenge_id']?.toString() ?? 'Unknown challenge';
                  final checkpointId = post['checkpoint_id']?.toString() ?? 'None';
                  return ListTile(
                    title: Text(content),
                    subtitle: Text("Challenge ID: $challengeId | Checkpoint: $checkpointId"),
                  );
                },
              ),
            ),
        ],
      ),
        
      ),
      
    );
  }

}