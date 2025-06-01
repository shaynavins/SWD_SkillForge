import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiscussionRealtimeService {
  final supabase = Supabase.instance.client;
  List<RealtimeChannel> _channels = [];

  void subscribeToDiscussions({
    required WidgetRef ref,
    required Function(dynamic payload) onPostsChanged,
    required Function(dynamic payload) onCommentsChanged,
  }) {
    // Subscribe to discussion posts
    final postsChannel = supabase.channel('public:discussion_posts');
    postsChannel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: '*',
        schema: 'public',
        table: 'discussion_posts',
      ),
      (payload, [ref]) {
        onPostsChanged(payload);
      },
    );
    _channels.add(postsChannel);
    postsChannel.subscribe();

    // Subscribe to discussion comments
    final commentsChannel = supabase.channel('public:discussion_comments');
    commentsChannel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: '*',
        schema: 'public',
        table: 'discussion_comments',
      ),
      (payload, [ref]) {
        onCommentsChanged(payload);
      },
    );
    _channels.add(commentsChannel);
    commentsChannel.subscribe();
  }

  void dispose() {
    for (var channel in _channels) {
      channel.unsubscribe();
    }
    _channels.clear();
  }
} 