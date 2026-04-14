import 'package:flutter/material.dart';

import '../../../app/i18n/build_context_i18n.dart';
import '../data/models/achievement_badge.dart';

String localizedBadgeTitle(BuildContext context, AchievementBadge badge) {
  switch (badge.id) {
    case 'first_session':
      return context.t(vi: 'Bắt đầu hành trình', en: 'Journey started');
    case 'streak_3_days':
      return context.t(vi: 'Chuỗi 3 ngày', en: '3-day streak');
    case 'recovery_wise':
      return context.t(vi: 'Biết nghỉ đúng lúc', en: 'Recovery-aware');
    case 'focus_guardian':
      return context.t(vi: 'Người giữ tập trung', en: 'Focus guardian');
    case 'weekly_commitment':
      return context.t(vi: 'Cam kết tuần', en: 'Weekly commitment');
    default:
      if (!context.isEnglish) {
        return badge.title;
      }
      return _containsVietnameseChars(badge.title)
          ? 'Achievement unlocked'
          : badge.title;
  }
}

String localizedBadgeDescription(BuildContext context, AchievementBadge badge) {
  switch (badge.id) {
    case 'first_session':
      return context.t(
        vi: 'Bạn đã hoàn thành phiên học đầu tiên.',
        en: 'You completed your first study session.',
      );
    case 'streak_3_days':
      return context.t(
        vi: 'Bạn duy trì nhịp học ít nhất 3 ngày.',
        en: 'You maintained your study rhythm for at least 3 days.',
      );
    case 'recovery_wise':
      return context.t(
        vi: 'Bạn dùng Recovery Mode một cách lành mạnh.',
        en: 'You used Recovery Mode in a healthy way.',
      );
    case 'focus_guardian':
      return context.t(
        vi: '5 phiên gần nhất có mức tập trung cao ổn định.',
        en: 'Your last 5 sessions maintained strong focus.',
      );
    case 'weekly_commitment':
      return context.t(
        vi: 'Bạn học đều ít nhất 5 ngày trong tuần.',
        en: 'You studied consistently at least 5 days this week.',
      );
    default:
      if (!context.isEnglish) {
        return badge.description;
      }
      return _containsVietnameseChars(badge.description)
          ? 'Keep going. Your steady effort is being recognized.'
          : badge.description;
  }
}

bool _containsVietnameseChars(String value) {
  return RegExp(
    r'[ĂÂĐÊÔƠƯăâđêôơưÁÀẢÃẠẮẰẲẴẶẤẦẨẪẬÉÈẺẼẸẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌỐỒỔỖỘỚỜỞỠỢÚÙỦŨỤỨỪỬỮỰÝỲỶỸỴáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]',
  ).hasMatch(value);
}
