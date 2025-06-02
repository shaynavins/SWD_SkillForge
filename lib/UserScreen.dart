import 'package:flutter/material.dart';
import 'package:codeapp/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  Future<int> getUserPoints() async {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('points')
        .eq('id', Supabase.instance.client.auth.currentSession?.user.id)
        .single();
    return response['points'] ?? 0;
  }

  Future<List<Map<String, dynamic>>> getUserChallenges() async {
    final response = await Supabase.instance.client
        .from('challenge_participants')
        .select('challenges(*)')
        .eq('user_id', Supabase.instance.client.auth.currentSession?.user.id);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = Supabase.instance.client.auth.currentSession?.user.email;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            Text(
              userEmail ?? "User",
              style: AppTheme.headingStyle,
            ),
            const SizedBox(height: 20),
            const Text(
              "Points:",
              style: AppTheme.subheadingStyle,
            ),
            const SizedBox(height: 10),
            FutureBuilder<int>(
              future: getUserPoints(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: AppTheme.errorColor),
                  );
                }
                return Text(
                  '${snapshot.data ?? 0}',
                  style: AppTheme.headingStyle,
                );
              },
            ),
            const SizedBox(height: 30),
            const Text(
              "Participated Challenges:",
              style: AppTheme.subheadingStyle,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: getUserChallenges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                    );
                  }
                  if (snapshot.data?.isEmpty ?? true) {
                    return const Center(
                      child: Text(
                        'No challenges participated yet',
                        style: TextStyle(color: AppTheme.secondaryColor),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final challenge = snapshot.data![index]['challenges'];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            challenge['title'] ?? 'Untitled Challenge',
                            style: AppTheme.bodyStyle,
                          ),
                          subtitle: Text(
                            challenge['description'] ?? 'No description',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(
                            Icons.check_circle,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      );
                    },
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
