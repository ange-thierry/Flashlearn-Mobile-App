import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class EmailService {
  static final EmailService _instance = EmailService._();
  factory EmailService() => _instance;
  EmailService._();

  static const _senderEmail = 'angethierry250@gmail.com';
  static const _appPassword = 'plbxstmerfthcnlx';

  Future<bool> sendWeeklyReport({
    required String toEmail,
    required String userName,
    required int totalCards,
    required int quizzesTaken,
    required int quizzesPassed,
    required int streak,
    required String dateRange,
  }) async {
    final passRate =
        quizzesTaken > 0 ? ((quizzesPassed / quizzesTaken) * 100).round() : 0;

    final smtpServer = gmail(_senderEmail, _appPassword);

    final message = Message()
      ..from = const Address(_senderEmail, 'Flashcard Learning')
      ..recipients.add(toEmail)
      ..subject = 'Your Weekly Learning Report — $dateRange'
      ..html = _buildHtml(
        userName: userName,
        totalCards: totalCards,
        quizzesTaken: quizzesTaken,
        quizzesPassed: quizzesPassed,
        passRate: passRate,
        streak: streak,
        dateRange: dateRange,
      );

    try {
      await send(message, smtpServer);
      return true;
    } catch (e, st) {
      debugPrint('Email send error: $e\n$st');
      return false;
    }
  }

  Future<bool> sendCertificate({
    required String toEmail,
    required String userName,
    required String fieldName,
    required String certificateId,
    required String completionDate,
    required String fieldGradientStart,
    required String fieldGradientEnd,
  }) async {
    final smtpServer = gmail(_senderEmail, _appPassword);
    final message = Message()
      ..from = const Address(_senderEmail, 'FlashLearn Academy')
      ..recipients.add(toEmail)
      ..subject = 'Your Certificate of Completion — $fieldName'
      ..html = _buildCertificateHtml(
        userName: userName,
        fieldName: fieldName,
        certificateId: certificateId,
        completionDate: completionDate,
        gradStart: fieldGradientStart,
        gradEnd: fieldGradientEnd,
      );
    try {
      await send(message, smtpServer);
      return true;
    } catch (e, st) {
      debugPrint('Certificate email error: $e\n$st');
      return false;
    }
  }

  String _buildCertificateHtml({
    required String userName,
    required String fieldName,
    required String certificateId,
    required String completionDate,
    required String gradStart,
    required String gradEnd,
  }) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Certificate of Completion</title>
</head>
<body style="margin:0;padding:0;background-color:#F5F0E8;font-family:Georgia,'Times New Roman',serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F5F0E8;padding:32px 16px;">
    <tr><td align="center">
      <table width="100%" cellpadding="0" cellspacing="0" style="max-width:580px;background:#FFFEF7;border-radius:6px;border:1.5px solid #C9B87A;overflow:hidden;">

        <!-- Gold top bar -->
        <tr><td height="8" style="background:linear-gradient(90deg,#8B6914,#DFB84A,#8B6914);"></td></tr>

        <!-- Header -->
        <tr>
          <td style="padding:36px 44px 0;text-align:center;">
            <div style="display:inline-block;width:76px;height:76px;background:linear-gradient(135deg,$gradStart,$gradEnd);border-radius:50%;line-height:76px;font-size:36px;text-align:center;border:3px solid #C9B87A;">🎓</div>
            <div style="margin-top:16px;font-size:10px;color:#8B6914;letter-spacing:4px;font-family:Arial,sans-serif;font-weight:700;">FLASHLEARN ACADEMY</div>
            <h1 style="color:#1A1A2E;font-size:26px;font-weight:700;margin:10px 0 4px;letter-spacing:0.5px;font-family:Georgia,serif;">Certificate of Completion</h1>
            <div style="width:100px;height:2px;background:linear-gradient(90deg,#8B6914,#DFB84A,#8B6914);margin:14px auto 0;"></div>
          </td>
        </tr>

        <!-- Body -->
        <tr>
          <td style="padding:24px 44px;text-align:center;">
            <p style="font-size:14px;color:#888780;margin:0 0 14px;line-height:1.7;font-style:italic;">This is to certify that</p>
            <h2 style="font-size:32px;color:#1A1A2E;font-weight:700;margin:0 0 6px;letter-spacing:-0.5px;font-family:Georgia,serif;">$userName</h2>
            <div style="width:80px;height:2px;background:linear-gradient(90deg,#8B6914,#DFB84A,#8B6914);margin:0 auto 18px;"></div>
            <p style="font-size:14px;color:#888780;margin:0 0 16px;line-height:1.7;font-style:italic;">has successfully completed and demonstrated mastery in</p>
            <div style="display:inline-block;background:linear-gradient(135deg,$gradStart,$gradEnd);border-radius:14px;padding:12px 28px;margin-bottom:16px;">
              <span style="font-size:20px;font-weight:700;color:#ffffff;font-family:Arial,sans-serif;letter-spacing:-0.3px;">$fieldName</span>
            </div>
            <p style="font-size:12px;color:#AAAAAA;margin:0;line-height:1.6;">by completing all level assessments and passing the Final Exam with a score ≥ 60%.</p>
          </td>
        </tr>

        <!-- Divider -->
        <tr><td style="padding:0 44px;"><div style="border-top:1px solid #E8DDB5;"></div></td></tr>

        <!-- Date & ID -->
        <tr>
          <td style="padding:18px 44px 28px;">
            <table width="100%" cellpadding="0" cellspacing="0">
              <tr>
                <td width="48%" style="text-align:center;">
                  <div style="font-size:9px;color:#8B6914;letter-spacing:2px;font-family:Arial,sans-serif;font-weight:700;margin-bottom:5px;">DATE ISSUED</div>
                  <div style="font-size:14px;color:#1A1A2E;font-weight:600;font-family:Arial,sans-serif;">$completionDate</div>
                </td>
                <td width="4%"></td>
                <td width="48%" style="text-align:center;border-left:1px solid #E8DDB5;">
                  <div style="font-size:9px;color:#8B6914;letter-spacing:2px;font-family:Arial,sans-serif;font-weight:700;margin-bottom:5px;">CERTIFICATE ID</div>
                  <div style="font-size:11px;color:#5F5E5A;font-family:Courier,monospace;">$certificateId</div>
                </td>
              </tr>
            </table>
          </td>
        </tr>

        <!-- Seal row -->
        <tr>
          <td style="padding:14px 44px 22px;text-align:center;background:#FFFBF0;">
            <span style="font-size:38px;">🏅</span>
            <div style="font-size:9px;color:#8B6914;letter-spacing:2px;font-family:Arial,sans-serif;margin-top:4px;">OFFICIAL SEAL</div>
            <p style="font-size:12px;color:#AAAAAA;margin:8px 0 0;font-style:italic;">
              "Knowledge is the greatest gift you can give yourself."
            </p>
          </td>
        </tr>

        <!-- Gold bottom bar -->
        <tr><td height="8" style="background:linear-gradient(90deg,#8B6914,#DFB84A,#8B6914);"></td></tr>

        <!-- Footer -->
        <tr>
          <td style="background:#F8F7F5;padding:16px 28px;text-align:center;border-top:1px solid #E0DDD8;">
            <p style="font-size:11px;color:#9A9790;margin:0;line-height:1.6;font-family:Arial,sans-serif;">
              FlashLearn Academy · Automated Certificate of Completion<br>
              This certificate is generated by the FlashLearn platform and serves as proof of course mastery.
            </p>
          </td>
        </tr>

      </table>
    </td></tr>
  </table>
</body>
</html>
''';
  }

  String _buildHtml({
    required String userName,
    required int totalCards,
    required int quizzesTaken,
    required int quizzesPassed,
    required int passRate,
    required int streak,
    required String dateRange,
  }) {
    final passColor = passRate >= 60 ? '#1D9E75' : '#E24B4A';
    final streakMsg = streak == 0
        ? 'Start studying today to build your streak!'
        : streak < 7
            ? 'Keep going — you\'re building a great habit!'
            : 'Incredible dedication! Spaced repetition is fully working for you.';

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Weekly Report</title>
</head>
<body style="margin:0;padding:0;background-color:#F0EDE8;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F0EDE8;padding:24px 16px;">
    <tr><td align="center">
      <table width="100%" cellpadding="0" cellspacing="0" style="max-width:480px;background:#ffffff;border-radius:20px;overflow:hidden;border:1px solid #E0DDD8;">

        <!-- Header -->
        <tr>
          <td style="background:linear-gradient(135deg,#2D1B69,#5C4E8A);padding:32px 28px;text-align:center;">
            <div style="display:inline-block;background:rgba(255,255,255,0.15);border-radius:14px;padding:12px 16px;margin-bottom:16px;">
              <span style="font-size:28px;">&#128218;</span>
            </div>
            <h1 style="color:#ffffff;font-size:22px;font-weight:800;margin:0 0 6px;letter-spacing:-0.3px;">Weekly Report</h1>
            <p style="color:rgba(255,255,255,0.65);font-size:12px;margin:0;">$dateRange</p>
          </td>
        </tr>

        <!-- Greeting -->
        <tr>
          <td style="padding:28px 28px 0;">
            <p style="color:#1A1A2E;font-size:15px;margin:0 0 6px;">Hi <strong>$userName</strong>,</p>
            <p style="color:#5F5E5A;font-size:13px;margin:0;line-height:1.6;">Here is your weekly study summary. Keep up the great work!</p>
          </td>
        </tr>

        <!-- Stats row -->
        <tr>
          <td style="padding:20px 28px 0;">
            <table width="100%" cellpadding="0" cellspacing="0">
              <tr>
                <td width="32%" style="background:#F0EDFC;border-radius:12px;padding:16px 10px;text-align:center;">
                  <div style="font-size:24px;font-weight:800;color:#5C4E8A;">$totalCards</div>
                  <div style="font-size:10px;color:#888780;margin-top:4px;line-height:1.4;">Cards<br>Studied</div>
                </td>
                <td width="4%"></td>
                <td width="32%" style="background:#EDF8F4;border-radius:12px;padding:16px 10px;text-align:center;">
                  <div style="font-size:24px;font-weight:800;color:$passColor;">$passRate%</div>
                  <div style="font-size:10px;color:#888780;margin-top:4px;line-height:1.4;">Pass<br>Rate</div>
                </td>
                <td width="4%"></td>
                <td width="32%" style="background:#FFF5ED;border-radius:12px;padding:16px 10px;text-align:center;">
                  <div style="font-size:24px;font-weight:800;color:#BA7517;">$streak</div>
                  <div style="font-size:10px;color:#888780;margin-top:4px;line-height:1.4;">Day<br>Streak</div>
                </td>
              </tr>
            </table>
          </td>
        </tr>

        <!-- Quiz results -->
        <tr>
          <td style="padding:20px 28px 0;">
            <h3 style="font-size:13px;font-weight:700;color:#1A1A2E;margin:0 0 10px;text-transform:uppercase;letter-spacing:0.5px;">Assessment Results</h3>
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#F8F7F5;border-radius:12px;border:1px solid #E0DDD8;">
              <tr>
                <td style="padding:14px 16px;border-bottom:1px solid #E0DDD8;">
                  <span style="font-size:13px;color:#5F5E5A;">Quizzes taken</span>
                  <span style="float:right;font-size:13px;font-weight:700;color:#1A1A2E;">$quizzesTaken</span>
                </td>
              </tr>
              <tr>
                <td style="padding:14px 16px;border-bottom:1px solid #E0DDD8;">
                  <span style="font-size:13px;color:#5F5E5A;">Quizzes passed</span>
                  <span style="float:right;font-size:13px;font-weight:700;color:#1D9E75;">$quizzesPassed</span>
                </td>
              </tr>
              <tr>
                <td style="padding:14px 16px;">
                  <span style="font-size:13px;color:#5F5E5A;">Pass rate</span>
                  <span style="float:right;font-size:13px;font-weight:700;color:$passColor;">$passRate%</span>
                </td>
              </tr>
            </table>
          </td>
        </tr>

        <!-- Streak -->
        <tr>
          <td style="padding:20px 28px 0;">
            <table width="100%" cellpadding="0" cellspacing="0" style="background:linear-gradient(135deg,#FF6B35,#FF9500);border-radius:12px;">
              <tr>
                <td style="padding:16px 18px;">
                  <span style="font-size:28px;">&#128293;</span>
                  <span style="font-size:16px;font-weight:800;color:#ffffff;margin-left:10px;">$streak-Day Streak</span>
                  <p style="font-size:12px;color:rgba(255,255,255,0.85);margin:6px 0 0;line-height:1.5;">$streakMsg</p>
                </td>
              </tr>
            </table>
          </td>
        </tr>

        <!-- CTA -->
        <tr>
          <td style="padding:24px 28px 0;text-align:center;">
            <p style="font-size:13px;color:#5F5E5A;margin:0 0 16px;line-height:1.6;">
              Ready to continue your learning journey?<br>Open the app and keep studying!
            </p>
          </td>
        </tr>

        <!-- Footer -->
        <tr>
          <td style="background:#F8F7F5;padding:20px 28px;border-top:1px solid #E0DDD8;text-align:center;">
            <p style="font-size:11px;color:#9A9790;margin:0;line-height:1.6;">
              Flashcard Learning · Sent by the app<br>
              This is an automated report from your study activity.
            </p>
          </td>
        </tr>

      </table>
    </td></tr>
  </table>
</body>
</html>
''';
  }
}
