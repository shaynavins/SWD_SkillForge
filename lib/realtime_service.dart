import 'package:supabase_flutter/supabase_flutter.dart';

class realtime_service {
    final supabase = Supabase.instance.client;
    List<RealtimeChannel> _channels = [];

    void subscribeToChanges({
        required String tableName,
        required Function(dynamic payload) onChange,
    }) {
        final channel = supabase.channel('public:$tableName');
        
        channel.on(
            RealtimeListenTypes.postgresChanges,
            ChannelFilter(
                event: '*',
                schema: 'public',
                table: tableName,
            ),
            (payload, [ref]) {
                onChange(payload);
            },
        );

        _channels.add(channel);
        channel.subscribe();
    }

    void dispose() {
        for (var channel in _channels) {
            channel.unsubscribe();
        }
        _channels.clear();
    }
}