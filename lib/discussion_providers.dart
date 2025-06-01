import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

/// Provider for challenges
final challengesProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await supabase.from('challenges').select();
  return response;
});

/// Provider for discussion posts
final discussionPostsProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await supabase
      .from('discussion_posts')
      .select('''
        *,
        challenges (
          title
        ),
        checkpoints (
          prompt_text
        ),
        profiles (
          email
        )
      ''')
      .order('created_at', ascending: false);
  return response;
});
