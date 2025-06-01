import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:codeapp/theme/app_theme.dart';
import 'package:codeapp/services/discussion_realtime_service.dart';

final challengesProvider = FutureProvider<List<dynamic>>((ref) async {
  final supabase = Supabase.instance.client;
  return await supabase.from('challenges').select();
});

final discussionPostsProvider = FutureProvider<List<dynamic>>((ref) async {
  final supabase = Supabase.instance.client;
  
  print("Fetching discussion posts...");
  
  try {
    final response = await supabase
        .from('discussion_posts')
        .select('''
          *,
          challenges!inner (
            title
          )
        ''');
    
    print("Fetched ${response.length} discussion posts");
    for (var post in response) {
      print("📝 Post: ${post.toString()}");
    }
    
    return response;
  } catch (e) {
    print("❌ Error fetching discussion posts: $e");
    rethrow;
  }
});

class DiscussionPage extends ConsumerStatefulWidget {
  const DiscussionPage({super.key});

  @override
  ConsumerState<DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends ConsumerState<DiscussionPage> {
  final supabase = Supabase.instance.client;
  final _realtimeService = DiscussionRealtimeService();
  String? selectedChallengeId;
  String? selectedCheckpointId;
  List<dynamic> checkpoints = [];

  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscriptions();
  }

  void _setupRealtimeSubscriptions() {
    _realtimeService.subscribeToDiscussions(
      ref: ref,
      onPostsChanged: (payload) {
        // Invalidate the posts provider to refresh the list
        ref.invalidate(discussionPostsProvider);
      },
      onCommentsChanged: (payload) {
        // If you have a comments provider, invalidate it here
        // ref.invalidate(commentsProvider);
      },
    );
  }

  @override
  void dispose() {
    _realtimeService.dispose();
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
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

      ref.invalidate(discussionPostsProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error posting question: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(challengesProvider);
    final discussionsAsync = ref.watch(discussionPostsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Discussion Forum", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          challengesAsync.when(
            data: (challenges) {
              return Container(
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
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                      label: const Text("Home"),
                      icon: const Icon(Icons.home),
                    ),
                    const Text('Ask a Question', style: AppTheme.subheadingStyle),
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
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading challenges: $e')),
          ),
          Expanded(
            child: discussionsAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined, size: 64, color: AppTheme.primaryColor.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text("No discussions yet", style: TextStyle(fontSize: 18, color: AppTheme.textColor.withOpacity(0.7))),
                        const SizedBox(height: 8),
                        Text("Be the first to start a discussion!", style: TextStyle(color: AppTheme.textColor.withOpacity(0.5))),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
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
                          onTap: () {},
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
                                        style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        profile?['email'] ?? 'Anonymous',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  post['title'] ?? 'Untitled',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                                ),
                                if (post['body'] != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    post['body'],
                                    style: TextStyle(color: AppTheme.textColor.withOpacity(0.8)),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (challenge != null)
                                      Chip(label: Text(challenge['title'], style: TextStyle(color: AppTheme.primaryColor))),
                                    if (checkpoint != null)
                                      Chip(label: Text(checkpoint['prompt_text'], style: TextStyle(color: AppTheme.secondaryColor))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading discussions: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
