import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

void main() async {
  const senderEmail = 'angethierry250@gmail.com';
  const appPassword = 'plbxstmerfthcnlx';
  const recipient = 'magnifiqueni01@gmail.com';

  print('Connecting to Gmail SMTP...');
  final smtpServer = gmail(senderEmail, appPassword);

  final message = Message()
    ..from = const Address(senderEmail, 'Flashcard Learning')
    ..recipients.add(recipient)
    ..subject = 'Test Email — Flashcard Learning App'
    ..html = '''
<!DOCTYPE html>
<html>
<body style="font-family:sans-serif;background:#F0EDE8;padding:20px;">
  <div style="max-width:480px;margin:0 auto;background:white;border-radius:16px;overflow:hidden;">
    <div style="background:linear-gradient(135deg,#2D1B69,#5C4E8A);padding:28px;text-align:center;">
      <h2 style="color:white;margin:0;font-size:20px;">Flashcard Learning</h2>
      <p style="color:rgba(255,255,255,0.7);margin:8px 0 0;font-size:13px;">Email delivery test</p>
    </div>
    <div style="padding:28px;">
      <p style="color:#1A1A2E;font-size:15px;margin:0 0 12px;">Hi there,</p>
      <p style="color:#5F5E5A;font-size:13px;line-height:1.6;margin:0 0 20px;">
        This is a test email from the <strong>Flashcard Learning</strong> app.<br>
        If you received this, the email service is working correctly.
      </p>
      <div style="background:#F0EDFC;border-radius:10px;padding:16px;text-align:center;">
        <span style="font-size:28px;">✅</span>
        <p style="color:#5C4E8A;font-weight:700;font-size:14px;margin:8px 0 0;">Email service is working!</p>
      </div>
    </div>
    <div style="background:#F8F7F5;padding:16px 28px;text-align:center;border-top:1px solid #E0DDD8;">
      <p style="color:#9A9790;font-size:11px;margin:0;">Flashcard Learning App · Test message</p>
    </div>
  </div>
</body>
</html>
''';

  try {
    final report = await send(message, smtpServer);
    print('✅  Email sent successfully!');
    print('   To      : $recipient');
    print('   Message : ${report.toString()}');
  } on MailerException catch (e) {
    print('❌  Failed to send email:');
    for (final p in e.problems) {
      print('   ${p.code}: ${p.msg}');
    }
  } catch (e) {
    print('❌  Unexpected error: $e');
  }
}
