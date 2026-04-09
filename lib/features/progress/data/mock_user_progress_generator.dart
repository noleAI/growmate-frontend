import '../../../data/models/user_profile.dart';

class TopicMastery {
  const TopicMastery({
    required this.topic,
    required this.score,
    required this.statusLabel,
  });

  final String topic;
  final double score;
  final String statusLabel;
}

class MoodTrendPoint {
  const MoodTrendPoint({required this.sessionLabel, required this.focusScore});

  final String sessionLabel;
  final double focusScore;
}

class UserProgressSnapshot {
  const UserProgressSnapshot({
    required this.learningRhythm,
    required this.weeklyConsistency,
    required this.fixedConcepts,
    required this.masteryMap,
    required this.moodTrend,
  });

  final String learningRhythm;
  final String weeklyConsistency;
  final List<String> fixedConcepts;
  final List<TopicMastery> masteryMap;
  final List<MoodTrendPoint> moodTrend;

  bool get isEmpty =>
      fixedConcepts.isEmpty && masteryMap.isEmpty && moodTrend.isEmpty;
}

class MockUserProgressGenerator {
  const MockUserProgressGenerator._();

  static UserProgressSnapshot fromUserProfile(
    UserProfile? profile, {
    bool forceEmptyState = false,
  }) {
    if (forceEmptyState) {
      return const UserProgressSnapshot(
        learningRhythm: '',
        weeklyConsistency: '',
        fixedConcepts: <String>[],
        masteryMap: <TopicMastery>[],
        moodTrend: <MoodTrendPoint>[],
      );
    }

    if (profile != null &&
        profile.activeSubjects.isEmpty &&
        profile.learningPreferences.isEmpty) {
      return const UserProgressSnapshot(
        learningRhythm: '',
        weeklyConsistency: '',
        fixedConcepts: <String>[],
        masteryMap: <TopicMastery>[],
        moodTrend: <MoodTrendPoint>[],
      );
    }

    final favoriteStyle =
        profile?.learningPreferences['style']?.toString() ?? 'thực hành ngắn';

    return UserProgressSnapshot(
      learningRhythm:
          'Bạn giữ nhịp học khá đều, hợp với phiên $favoriteStyle vào buổi tối.',
      weeklyConsistency: '4/6 buổi đã hoàn thành trong tuần này',
      fixedConcepts: const <String>[
        'Đạo hàm đa thức',
        'Quy tắc tích',
        'Giới hạn cơ bản',
      ],
      masteryMap: const <TopicMastery>[
        TopicMastery(topic: 'Đạo hàm', score: 3.5, statusLabel: 'Đang vững'),
        TopicMastery(topic: 'Giới hạn', score: 2.6, statusLabel: 'Cần ôn nhẹ'),
        TopicMastery(
          topic: 'Tích phân',
          score: 2.2,
          statusLabel: 'Đang khởi động',
        ),
        TopicMastery(topic: 'Hàm hợp', score: 2.9, statusLabel: 'Ổn dần rồi'),
        TopicMastery(topic: 'Ứng dụng', score: 2.4, statusLabel: 'Cần ôn nhẹ'),
      ],
      moodTrend: const <MoodTrendPoint>[
        MoodTrendPoint(sessionLabel: 'Phiên 1', focusScore: 2.3),
        MoodTrendPoint(sessionLabel: 'Phiên 2', focusScore: 3.0),
        MoodTrendPoint(sessionLabel: 'Phiên 3', focusScore: 3.4),
      ],
    );
  }
}
