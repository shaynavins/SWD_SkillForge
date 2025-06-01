import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

final checkpointsMapProvider = StateNotifierProvider<CheckpointsMapNotifier, Map<String, List<dynamic>>>((ref) {
  return CheckpointsMapNotifier();
});

class CheckpointsMapNotifier extends StateNotifier<Map<String, List<dynamic>>> {
  CheckpointsMapNotifier() : super({});

  Future<void> fetchCheckpoints(String challengeId) async {
    try {
      final response = await supabase
          .from('checkpoints')
          .select()
          .eq('challenge_id', challengeId)
          .order('order');

      state = {...state, challengeId: response};
    } catch (e) {
      print("❌ Error fetching checkpoints: $e");
    }
  }
}
