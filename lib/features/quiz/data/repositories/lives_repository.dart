import '../models/lives_info.dart';

/// Abstract interface cho lives system.
abstract class LivesRepository {
  Future<LivesInfo> getLives();
  Future<LivesInfo> loseLife();
  Future<LivesInfo> restoreLife();
  Stream<LivesInfo> watchLives();
}
