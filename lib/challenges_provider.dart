import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

final challengesProvider = StateNotifierProvider<ChallengesNotifier, List<dynamic>>((ref){
    return ChallengesNotifier();
});
class ChallengesNotifier extends StateNotifier<List<dynamic>> {
    ChallengesNotifier() : super([]){
        fetchChallenges();
    }
    Future<void> fetchChallenges() async {
        try {
            final response = await supabase.from('challenges').select();
            state = response;
        } catch (e) {
            print(e);   
        }
    }
    Future<void> refresh() async => fetchChallenges();
}