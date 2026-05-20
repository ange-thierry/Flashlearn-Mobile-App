import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/app_provider.dart';
import '../data/fields_data.dart';
import '../theme/app_theme.dart';
import '../utils/icon_helper.dart';

class CertificateScreen extends StatelessWidget {
  const CertificateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final cert = prov.lastCertificate;

    if (cert == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school_outlined, size: 56, color: Color(0xFFB8942F)),
                const SizedBox(height: 16),
                const Text(
                  'No certificate available',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pass the Final Exam of any course to earn your certificate.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF888780), height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Go Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final grad = fieldGradient(cert.fieldId);
    final fieldClr = fieldColor(cert.fieldId);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${cert.issuedAt.day} ${months[cert.issuedAt.month - 1]} ${cert.issuedAt.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: Column(
        children: [
          // ── Field-colored header banner ──────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
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
                    _EmailStatusChip(prov: prov),
                  ],
                ),
                const SizedBox(height: 22),
                // Badge circle
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
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      fieldIconData(cert.fieldId),
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'CERTIFICATE OF COMPLETION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  cert.fieldName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // ── Certificate body ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewPadding.bottom + 20),
              child: Column(
                children: [
                  // ── Certificate card ─────────────────────────────────────
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
                              // Academy label
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

                              // "This certifies that"
                              Text(
                                'This is to certify that',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // User name
                              Text(
                                cert.userName,
                                style: const TextStyle(
                                  fontSize: 27,
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
                              const SizedBox(height: 18),

                              // "has successfully mastered"
                              Text(
                                'has successfully mastered',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Field name chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: grad),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: fieldClr.withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(fieldIconData(cert.fieldId), size: 18, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      cert.fieldName,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              Text(
                                'by completing all level assessments and\npassing the Final Exam',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              const Divider(color: Color(0xFFE8DDB5), height: 1),
                              const SizedBox(height: 16),

                              // Date & Certificate ID
                              Row(
                                children: [
                                  Expanded(
                                    child: _InfoTile(
                                      icon: Icons.calendar_today_rounded,
                                      label: 'DATE ISSUED',
                                      value: dateStr,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 48,
                                    color: const Color(0xFFE8DDB5),
                                  ),
                                  Expanded(
                                    child: _InfoTile(
                                      icon: Icons.verified_rounded,
                                      label: 'CERTIFICATE ID',
                                      value: cert.id,
                                    ),
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
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const Text(
                                      'FlashLearn Academy',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF888780),
                                      ),
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
                                    style: TextStyle(
                                      fontSize: 7,
                                      color: Color(0xFF8B6914),
                                      letterSpacing: 2.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Seal quote row
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 26),
                          color: const Color(0xFFFFFBF0),
                          child: Text(
                            '"Knowledge is the greatest gift you can give yourself."',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade400,
                              fontStyle: FontStyle.italic,
                            ),
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

                  // ── Email status card ─────────────────────────────────────
                  _buildEmailCard(prov),

                  const SizedBox(height: 16),

                  // ── Actions ───────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadCertificatePdf(context, cert, grad),
                      icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                      label: const Text('Download Certificate'),
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
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/achievements'),
                      icon: const Icon(Icons.emoji_events_rounded, size: 16),
                      label: const Text('View Achievements & Badges'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFBA7517),
                        side: const BorderSide(color: Color(0xFFBA7517), width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/fields', (route) => false,
                      ),
                      icon: const Icon(Icons.home_rounded, size: 16, color: Colors.white),
                      label: const Text('Back to Dashboard'),
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

  Future<void> _downloadCertificatePdf(
    BuildContext context,
    dynamic cert,
    List<Color> grad,
  ) async {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${cert.issuedAt.day} ${months[cert.issuedAt.month - 1]} ${cert.issuedAt.year}';

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
                  pw.Text('CERTIFICATE OF COMPLETION',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('1A1A2E'),
                        letterSpacing: 2,
                      )),
                  pw.SizedBox(height: 16),
                  pw.Text('This is to certify that',
                      style: pw.TextStyle(fontSize: 13, color: PdfColor.fromHex('888888'), fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 12),
                  pw.Text(cert.userName,
                      style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('1A1A2E'))),
                  pw.SizedBox(height: 12),
                  pw.Text('has successfully mastered',
                      style: pw.TextStyle(fontSize: 13, color: PdfColor.fromHex('888888'), fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('8B6914'),
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(cert.fieldName,
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('by completing all level assessments and passing the Final Exam',
                      style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('AAAAAA')),
                      textAlign: pw.TextAlign.center),
                  pw.SizedBox(height: 20),
                  pw.Divider(color: PdfColor.fromHex('E8DDB5')),
                  pw.SizedBox(height: 16),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text('DATE ISSUED', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('8B6914'), letterSpacing: 1.5)),
                        pw.Text(dateStr, style: pw.TextStyle(fontSize: 11, color: PdfColor.fromHex('1A1A2E'))),
                      ]),
                      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                        pw.Text('CERTIFICATE ID', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('8B6914'), letterSpacing: 1.5)),
                        pw.Text(cert.id, style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('1A1A2E'))),
                      ]),
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
      filename: 'FlashLearn_Certificate_${cert.userName.replaceAll(' ', '_')}.pdf',
    );
  }

  Widget _buildEmailCard(AppProvider prov) {
    if (!prov.certEmailSending && !prov.certEmailSent) return const SizedBox.shrink();

    final sent = prov.certEmailSent;
    final color = sent ? AppTheme.easy : const Color(0xFFF97316);
    final bg = sent ? AppTheme.easy.withValues(alpha: 0.08) : const Color(0xFFF97316).withValues(alpha: 0.08);
    final border = sent ? AppTheme.easy.withValues(alpha: 0.25) : const Color(0xFFF97316).withValues(alpha: 0.25);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            sent ? Icons.mark_email_read_rounded : Icons.send_rounded,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sent
                  ? 'Certificate emailed to ${prov.auth.userEmail ?? "your address"}'
                  : 'Sending your certificate via email…',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          if (prov.certEmailSending)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _EmailStatusChip extends StatelessWidget {
  final AppProvider prov;
  const _EmailStatusChip({required this.prov});

  @override
  Widget build(BuildContext context) {
    if (!prov.certEmailSending && !prov.certEmailSent) return const SizedBox.shrink();
    final sent = prov.certEmailSent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sent ? Icons.mark_email_read_rounded : Icons.hourglass_top_rounded,
            size: 12,
            color: sent ? const Color(0xFF22C55E) : Colors.white70,
          ),
          const SizedBox(width: 5),
          Text(
            sent ? 'Emailed ✓' : 'Sending…',
            style: TextStyle(
              color: sent ? const Color(0xFF22C55E) : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF8B6914)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: Color(0xFF8B6914),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
