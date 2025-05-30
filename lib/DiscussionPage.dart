import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:codeapp/theme/app_theme.dart';

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
    if (user == null || selectedChallengeId == null || titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    try {
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question posted successfully!'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );

      fetchDiscussion();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error posting question: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> fetchDiscussion() async {
    try {
      final response = await supabase
          .from('discussion_posts')
          .select();

      print("Fetched ${response.length} discussion posts");
      
      for (var post in response) {
        print("📝 Post content: ${post.toString()}");
        print("📝 Body: ${post['body']} (Challenge ID: ${post['challenge_id']}, Checkpoint ID: ${post['checkpoint_id']})");
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Discussion Forum", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                   onPressed: () async {
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                  label: const Text("Home"),
                ),
                const Text(
                  'Ask a Question',
                  style: AppTheme.subheadingStyle,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedChallengeId,
                  decoration: AppTheme.textFieldDecoration(
                    labelText: 'Select Challenge',
                    prefixIcon: Icons.assignment,
                  ),
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
                const SizedBox(height: 12),
                if (checkpoints.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: selectedCheckpointId,
                    decoration: AppTheme.textFieldDecoration(
                      labelText: 'Select Checkpoint (Optional)',
                      prefixIcon: Icons.check_circle,
                    ),
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
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: titleController,
                  decoration: AppTheme.textFieldDecoration(
                    labelText: 'Question Title',
                    prefixIcon: Icons.title,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  decoration: AppTheme.textFieldDecoration(
                    labelText: 'Details',
                    prefixIcon: Icons.description,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: postDiscussion,
                  icon: const Icon(Icons.send),
                  label: const Text('Post Question'),
                  style: AppTheme.elevatedButtonStyle,
                ),
              ],
            ),
          ),
          Expanded(
            child: discussionPosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 64,
                          color: AppTheme.primaryColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No discussions yet",
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Be the first to start a discussion!",
                          style: TextStyle(
                            color: AppTheme.textColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: discussionPosts.length,
                    itemBuilder: (context, index) {
                      final post = discussionPosts[index];
                      final challenge = post['challenges'];
                      final checkpoint = post['checkpoints'];
                      final profile = post['profiles'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: AppTheme.cardDecoration,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              // TODO: Navigate to discussion detail page
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                        child: Text(
                                          (profile?['email'] as String?)?.substring(0, 1).toUpperCase() ?? '?',
                                          style: TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          profile?['email'] ?? 'Anonymous',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    post['title'] ?? 'Untitled',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textColor,
                                    ),
                                  ),
                                  if (post['body'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      post['body'],
                                      style: TextStyle(
                                        color: AppTheme.textColor.withOpacity(0.8),
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      if (challenge != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            challenge['title'],
                                            style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      if (checkpoint != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.secondaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            checkpoint['prompt_text'],
                                            style: TextStyle(
                                              color: AppTheme.secondaryColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}