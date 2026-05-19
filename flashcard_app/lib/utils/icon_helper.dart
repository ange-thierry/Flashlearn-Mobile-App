import 'package:flutter/material.dart';
import '../models/models.dart';

/// Returns the Material icon for a given notification type.
IconData notifTypeIcon(NotifType type) {
  switch (type) {
    case NotifType.dailyReminder: return Icons.alarm_rounded;
    case NotifType.spacedRep:     return Icons.refresh_rounded;
    case NotifType.quizResult:    return Icons.gps_fixed_rounded;
    case NotifType.achievement:   return Icons.emoji_events_rounded;
    case NotifType.weakTopic:     return Icons.push_pin_rounded;
    case NotifType.progress:      return Icons.bar_chart_rounded;
    case NotifType.newContent:    return Icons.auto_awesome_rounded;
    case NotifType.admin:         return Icons.admin_panel_settings_rounded;
  }
}

/// Returns the Material icon for a field based on its ID.
IconData fieldIconData(String fieldId) {
  switch (fieldId) {
    case 'math':        return Icons.calculate_rounded;
    case 'science':     return Icons.science_rounded;
    case 'history':     return Icons.account_balance_rounded;
    case 'geography':   return Icons.public_rounded;
    case 'literature':  return Icons.auto_stories_rounded;
    case 'cs':          return Icons.computer_rounded;
    default:            return Icons.school_rounded;
  }
}

/// Returns the Material icon for an achievement based on its ID.
IconData achievementIconData(String achievementId) {
  switch (achievementId) {
    case 'streak_7':         return Icons.local_fire_department_rounded;
    case 'quiz_champion':    return Icons.emoji_events_rounded;
    case 'fast_learner':     return Icons.bolt_rounded;
    case 'first_bookmark':   return Icons.bookmark_rounded;
    case 'perfect_score':    return Icons.grade_rounded;
    case 'math_expert':      return Icons.calculate_rounded;
    case 'science_expert':   return Icons.science_rounded;
    case 'history_expert':   return Icons.account_balance_rounded;
    case 'geography_expert': return Icons.public_rounded;
    case 'literature_expert':return Icons.auto_stories_rounded;
    case 'cs_expert':        return Icons.computer_rounded;
    default:                 return Icons.emoji_events_rounded;
  }
}
