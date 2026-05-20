import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

class AwardCertificateScreen extends StatelessWidget {
  const AwardCertificateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final achievement = ModalRoute.of(context)!.settings.arguments as Achievement;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = achievement.unlockedAt != null
        ? '${achievement.unlockedAt!.day} ${months[achievement.unlockedAt!.month - 1]} ${achievement.unlockedAt!.year}'
        : 'N/A';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A1202), Color(0xFF5C3A0A), Color(0xFFBA7517)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).viewPadding.top + 8, 18, 28),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_ios_rounded, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Back', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDFB84A), Color(0xFF8B6914)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Center(
                    child: Text(achievement.icon, style: const TextStyle(fontSize: 38)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'AWARD CERTIFICATE',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.name,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.80), fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // ── Certificate Body ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewPadding.bottom + 20),
              child: Column(
                children: [
                  // Certificate card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFEF5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFC9B87A), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC9B87A).withValues(alpha: 0.22),
                          blurRadius: 28,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Gold top strip
                        Container(
                          height: 7,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF8B6914), Color(0xFFDFB84A), Color(0xFF8B6914)],
                            ),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(26, 24, 26, 20),
                          child: Column(
                            children: [
                              const Text(
                                'FLASHLEARN ACADEMY',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF8B6914),
                                  letterSpacing: 3.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Divider(color: Color(0xFFE8DDB5), height: 1),
                              const SizedBox(height: 18),

                              const Text(
                                'This is to certify that',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF888888),
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Achievement badge
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFDFB84A), Color(0xFF8B6914)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFBA7517).withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(achievement.icon, style: const TextStyle(fontSize: 32)),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Achievement name
                              Text(
                                achievement.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A2E),
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 90,
                                height: 2,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF8B6914), Color(0xFFDFB84A), Color(0xFF8B6914)],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Achievement description
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFBA7517).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFBA7517).withValues(alpha: 0.20), width: 1),
                                ),
                                child: Text(
                                  achievement.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5F5E5A),
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Divider(color: Color(0xFFE8DDB5), height: 1),
                              const SizedBox(height: 16),

                              // Date
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF8B6914)),
                                  const SizedBox(width: 6),
                                  Column(
                                    children: [
                                      const Text(
                                        'DATE AWARDED',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF8B6914),
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF1A1A2E),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // CEO Signature row
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(26, 16, 26, 0),
                          color: const Color(0xFFFFFBF0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 2,
                                      width: 110,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF8B6914), Color(0xFFDFB84A)],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'NIYONZIMA Ange Thierry',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    const Text(
                                      'Chief Executive Officer',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF8B6914),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Text(
                                      'FlashLearn Academy',
                                      style: TextStyle(fontSize: 9, color: Color(0xFF888780)),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  const Text('🏅', style: TextStyle(fontSize: 28)),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'OFFICIAL SEAL',
                                    style: TextStyle(fontSize: 7, color: Color(0xFF8B6914), letterSpacing: 2.0, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 26),
                          color: const Color(0xFFFFFBF0),
                          child: Text(
                            '"Excellence is not a destination but a continuous journey."',
                            style: TextStyle(fontSize: 9, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // Gold bottom strip
                        Container(
                          height: 7,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF8B6914), Color(0xFFDFB84A), Color(0xFF8B6914)],
                            ),
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(19)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Download button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadAwardPdf(achievement, dateStr),
                      icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                      label: const Text('Download Award Certificate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B6914),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.emoji_events_rounded, size: 16, color: Colors.white),
                      label: const Text('Back to Achievements'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A2E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAwardPdf(Achievement achievement, String dateStr) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('C9B87A'), width: 3),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              padding: const pw.EdgeInsets.all(36),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('FLASHLEARN ACADEMY',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('8B6914'),
                        letterSpacing: 4,
                      )),
                  pw.SizedBox(height: 8),
                  pw.Divider(color: PdfColor.fromHex('E8DDB5')),
                  pw.SizedBox(height: 20),
                  pw.Text('AWARD CERTIFICATE',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('1A1A2E'),
                        letterSpacing: 2,
                      )),
                  pw.SizedBox(height: 16),
                  pw.Text('This is to certify the achievement of',
                      style: pw.TextStyle(fontSize: 13, color: PdfColor.fromHex('888888'), fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 12),
                  pw.Text(achievement.name,
                      style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('8B6914'))),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('FFF8E6'),
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(color: PdfColor.fromHex('C9B87A')),
                    ),
                    child: pw.Text(achievement.description,
                        style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex('5F5E5A')),
                        textAlign: pw.TextAlign.center),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(color: PdfColor.fromHex('E8DDB5')),
                  pw.SizedBox(height: 14),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('DATE AWARDED: ',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('8B6914'))),
                      pw.Text(dateStr, style: pw.TextStyle(fontSize: 11, color: PdfColor.fromHex('1A1A2E'))),
                    ],
                  ),
                  pw.SizedBox(height: 24),
                  pw.Divider(color: PdfColor.fromHex('E8DDB5')),
                  pw.SizedBox(height: 16),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Container(width: 100, height: 1.5, color: PdfColor.fromHex('8B6914')),
                        pw.SizedBox(height: 4),
                        pw.Text('NIYONZIMA Ange Thierry',
                            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('1A1A2E'))),
                        pw.Text('Chief Executive Officer', style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('8B6914'))),
                        pw.Text('FlashLearn Academy', style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('888888'))),
                      ]),
                      pw.Text('★ OFFICIAL SEAL ★',
                          style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('8B6914'), letterSpacing: 1.5)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'FlashLearn_Award_${achievement.name.replaceAll(' ', '_')}.pdf',
    );
  }
}
