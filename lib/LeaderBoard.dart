import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:codeapp/theme/app_theme.dart';

class LeaderBoard extends StatefulWidget {
  const LeaderBoard({super.key});

  @override
  State<LeaderBoard> createState() => _LeaderBoardState();
}

class _LeaderBoardState extends State<LeaderBoard> {
  final supabase = Supabase.instance.client;
  List<dynamic> users = [];
  bool isLoading = false;

  final List<Color> rankColors = [
    Colors.amber, // Gold
    Colors.grey.shade400, // Silver
    Colors.brown.shade300, // Bronze
  ];

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('profiles')
          .select('username, points')
          .order('points', ascending: false);

      setState(() {
        users = response;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching leaderboard: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchLeaderboard,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                  icon: const Icon(Icons.home),
                  label: const Text("Home"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/discussion');
                  },
                  icon: const Icon(Icons.forum),
                  label: const Text("Discussions"),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                    ? const Center(
                        child: Text('No users found'),
                      )
                    : ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final isTopThree = index < 3;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isTopThree
                                    ? rankColors[index].withOpacity(0.2)
                                    : Colors.blue.withOpacity(0.1),
                                child: isTopThree
                                    ? Icon(
                                        Icons.emoji_events,
                                        color: rankColors[index],
                                      )
                                    : Text(
                                        '#${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                              ),
                              title: Text(
                                user['username'] ?? 'Anonymous',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${user['points'] ?? 0} pts',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
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
