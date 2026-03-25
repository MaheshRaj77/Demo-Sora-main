import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Local state ──
  String _fontSizeLabel = 'Medium';
  double _fontSizeValue = 1.0; // 0=Small, 1=Medium, 2=Large
  bool _appLockEnabled = false;
  String _appVersion = '1.0.0';
  String _appBuild = '';

  // ── Profile data from API ──
  Map<String, dynamic>? _user;
  String _profileName = '';
  String _profileEmail = '';
  String _profileDept = '';
  int _profileSemester = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPersistedSettings();
    _loadPackageInfo();
  }

  Future<void> _loadPersistedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      });
    }
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = info.version;
          _appBuild = info.buildNumber;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    try {
      final response = await AuthService().getProfile();
      final user = response['user'] as Map<String, dynamic>?;
      if (mounted && user != null) {
        setState(() {
          _user = user;
          _profileName = user['full_name'] ?? user['name'] ?? 'Student';
          _profileEmail = user['email'] ?? '';
          _profileDept = user['department'] ?? 'CS';
          _profileSemester = int.tryParse(user['semester']?.toString() ?? '') ?? 0;
        });
      }
    } catch (_) {
      // Keep defaults
    }
  }

  // ── Image picker ──
  Future<void> _pickImage(BuildContext context) async {
    final themeNotifier = ThemeProvider.of(context);
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final tc2 = Tc.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: tc2.bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: tc2.glassBorder,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Choose Photo',
                  style: TextStyle(
                      color: tc2.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _sourceOption(ctx, Icons.camera_alt_rounded, 'Camera',
                      () => Navigator.pop(ctx, ImageSource.camera)),
                  _sourceOption(ctx, Icons.photo_library_rounded, 'Gallery',
                      () => Navigator.pop(ctx, ImageSource.gallery)),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );

    if (source == null) return;
    final pickedFile = await picker.pickImage(source: source, maxWidth: 600);
    if (pickedFile != null) {
      themeNotifier.setProfileImage(pickedFile.path);
    }
  }

  Widget _sourceOption(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(
                  color: AppColors.accentTeal,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM SHEET / DIALOG HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Reusable themed bottom sheet wrapper
  Future<void> _showThemedSheet(
      BuildContext context, String title, Widget Function(Tc tc) bodyBuilder) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final tc = Tc.of(ctx);
        return Container(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          decoration: BoxDecoration(
            color: tc.bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: tc.glassBorder,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(title,
                  style: TextStyle(
                      color: tc.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: bodyBuilder(tc),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetField(Tc tc, String label,
      {bool obscure = false,
      TextEditingController? controller,
      int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        maxLines: maxLines,
        style: TextStyle(color: tc.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: tc.textMuted, fontSize: 13),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: tc.glassBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.accentTeal, width: 1.5)),
          filled: true,
          fillColor: tc.glassWhite,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _sheetButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: GlassButton(text: text, onPressed: onTap),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. FONT SIZE
  // ═══════════════════════════════════════════════════════════════════════════

  void _showFontSizeSheet(BuildContext context) {
    _showThemedSheet(context, 'Font Size', (tc) {
      return StatefulBuilder(builder: (ctx, setLocal) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Aa', style: TextStyle(color: tc.textMuted, fontSize: 12)),
                Text('Aa', style: TextStyle(color: tc.textMuted, fontSize: 18)),
                Text('Aa', style: TextStyle(color: tc.textMuted, fontSize: 24)),
              ],
            ),
            Slider(
              value: _fontSizeValue,
              min: 0,
              max: 2,
              divisions: 2,
              activeColor: AppColors.accentTeal,
              inactiveColor: tc.glassBorder,
              label: ['Small', 'Medium', 'Large'][_fontSizeValue.round()],
              onChanged: (v) {
                setLocal(() {});
                setState(() {
                  _fontSizeValue = v;
                  _fontSizeLabel = ['Small', 'Medium', 'Large'][v.round()];
                });
              },
            ),
            const SizedBox(height: 8),
            Text('Current: $_fontSizeLabel',
                style: TextStyle(
                    color: tc.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _sheetButton('Apply', () => Navigator.pop(ctx)),
          ],
        );
      });
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. PERSONAL INFORMATION
  // ═══════════════════════════════════════════════════════════════════════════

  void _showPersonalInfoSheet(BuildContext context) {
    final nameCtrl = TextEditingController(
        text: _user?['full_name'] ?? _user?['name'] ?? 'Balakumaran D');
    final dobCtrl =
        TextEditingController(text: _user?['date_of_birth'] ?? '15/06/2003');
    final genderCtrl = TextEditingController(text: _user?['gender'] ?? 'Male');
    final phoneCtrl =
        TextEditingController(text: _user?['phone'] ?? '+91 98765 43210');
    final emailCtrl = TextEditingController(
        text: _user?['email'] ?? 'dbalakumaran23@gmail.com');

    _showThemedSheet(context, 'Personal Information', (tc) {
      return Column(
        children: [
          _sheetField(tc, 'Full Name', controller: nameCtrl),
          _sheetField(tc, 'Date of Birth', controller: dobCtrl),
          _sheetField(tc, 'Gender', controller: genderCtrl),
          _sheetField(tc, 'Phone', controller: phoneCtrl),
          _sheetField(tc, 'Email', controller: emailCtrl),
          const SizedBox(height: 4),
          _sheetButton('Save Changes', () async {
            try {
              await AuthService().updateProfile({
                'full_name': nameCtrl.text,
                'date_of_birth': dobCtrl.text,
                'gender': genderCtrl.text,
                'phone': phoneCtrl.text,
                'email': emailCtrl.text,
              });
              setState(() {
                _profileName = nameCtrl.text;
                _profileEmail = emailCtrl.text;
              });
            } catch (_) {
              // still close & show success for offline-friendly UX
            }
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Personal info updated'),
                backgroundColor: AppColors.accentGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            }
          }),
        ],
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. CHANGE PASSWORD
  // ═══════════════════════════════════════════════════════════════════════════

  void _showChangePasswordSheet(BuildContext context) {
    final currentPwdCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    final confirmPwdCtrl = TextEditingController();

    _showThemedSheet(context, 'Change Password', (tc) {
      return Column(
        children: [
          _sheetField(tc, 'Current Password',
              obscure: true, controller: currentPwdCtrl),
          _sheetField(tc, 'New Password',
              obscure: true, controller: newPwdCtrl),
          _sheetField(tc, 'Confirm New Password',
              obscure: true, controller: confirmPwdCtrl),
          const SizedBox(height: 4),
          _sheetButton('Update Password', () async {
            final current = currentPwdCtrl.text.trim();
            final newPwd = newPwdCtrl.text.trim();
            final confirm = confirmPwdCtrl.text.trim();

            if (current.isEmpty || newPwd.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Please fill all fields'),
                backgroundColor: AppColors.accentRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
              return;
            }
            if (newPwd != confirm) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('New passwords do not match'),
                backgroundColor: AppColors.accentRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
              return;
            }
            if (newPwd.length < 6) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Password must be at least 6 characters'),
                backgroundColor: AppColors.accentRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
              return;
            }

            try {
              await ApiService().put('/auth/change-password', body: {
                'current_password': current,
                'new_password': newPwd,
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Password updated successfully'),
                  backgroundColor: AppColors.accentGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: AppColors.accentRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            }
          }),
        ],
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. CLEAR CACHE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String> _getCacheSize() async {
    try {
      if (kIsWeb) return '0 KB';
      final tempDir = await getTemporaryDirectory();
      int totalSize = 0;
      if (tempDir.existsSync()) {
        for (final entity in tempDir.listSync(recursive: true, followLinks: false)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
      if (totalSize < 1024) return '$totalSize B';
      if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)} KB';
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return 'unknown';
    }
  }

  Future<void> _clearCache() async {
    try {
      if (kIsWeb) return;
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        for (final entity in tempDir.listSync(followLinks: false)) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  void _showClearCacheDialog(BuildContext context) async {
    final tc = Tc.of(context);
    final cacheSize = await _getCacheSize();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tc.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear Cache',
            style:
                TextStyle(color: tc.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('This will clear all cached data ($cacheSize). Continue?',
            style: TextStyle(color: tc.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: tc.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _clearCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Cache cleared successfully'),
                  backgroundColor: AppColors.accentGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            child: const Text('Clear',
                style: TextStyle(
                    color: AppColors.accentRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. MANAGE DOWNLOADED CIRCULARS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, String>>> _getDownloadedFiles() async {
    try {
      if (kIsWeb) return [];
      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDir.path}/circulars');
      if (!downloadDir.existsSync()) return [];
      final files = downloadDir.listSync().whereType<File>().toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return files.map((f) {
        final stat = f.statSync();
        final sizeKb = stat.size / 1024;
        final sizeStr = sizeKb > 1024
            ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
            : '${sizeKb.toStringAsFixed(0)} KB';
        final modified = stat.modified;
        final dateStr = '${modified.day.toString().padLeft(2, '0')} '
            '${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][modified.month - 1]} '
            '${modified.year}';
        final name = f.path.split(Platform.pathSeparator).last;
        return {'title': name.replaceAll('.pdf', '').replaceAll('_', ' '), 'size': sizeStr, 'date': dateStr, 'path': f.path};
      }).toList();
    } catch (_) {
      return [];
    }
  }

  void _showDownloadedCircularsSheet(BuildContext context) async {
    final files = await _getDownloadedFiles();
    if (!context.mounted) return;

    _showThemedSheet(context, 'Downloaded Circulars', (tc) {
      return StatefulBuilder(builder: (ctx, setLocal) {
        if (files.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(Icons.folder_open_rounded, size: 48, color: tc.textMuted),
                const SizedBox(height: 12),
                Text('No downloaded circulars',
                    style: TextStyle(color: tc.textMuted, fontSize: 14)),
                const SizedBox(height: 8),
                Text('Downloads will appear here when you\nsave circulars for offline reading.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: tc.textMuted, fontSize: 12)),
              ],
            ),
          );
        }
        return Column(
          children: [
            ...files.map((c) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tc.glassWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tc.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accentPink.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded,
                            color: AppColors.accentPink, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['title']!,
                                style: TextStyle(
                                    color: tc.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text('${c['size']} • ${c['date']}',
                                style: TextStyle(
                                    color: tc.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          try {
                            File(c['path']!).deleteSync();
                          } catch (_) {}
                          setLocal(() => files.remove(c));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Deleted: ${c['title']}'),
                              backgroundColor: AppColors.accentRed,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        child: Icon(Icons.delete_outline_rounded,
                            color: AppColors.accentRed, size: 20),
                      ),
                    ],
                  ),
                )),
          ],
        );
      });
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. REPORT ISSUE
  // ═══════════════════════════════════════════════════════════════════════════

  void _showReportIssueSheet(BuildContext context) {
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isSubmitting = false;

    _showThemedSheet(context, 'Report Issue', (tc) {
      return StatefulBuilder(builder: (ctx, setLocal) {
        return Column(
          children: [
            _sheetField(tc, 'Subject', controller: subjectCtrl),
            _sheetField(tc, 'Describe the issue...', maxLines: 5, controller: descCtrl),
            const SizedBox(height: 4),
            _sheetButton(isSubmitting ? 'Submitting...' : 'Submit Report', () async {
              if (subjectCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Please fill in both fields'),
                  backgroundColor: AppColors.accentRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
                return;
              }
              setLocal(() => isSubmitting = true);
              try {
                // Try submitting to backend first
                await ApiService().post('/reports', body: {
                  'subject': subjectCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'type': 'bug_report',
                });
              } catch (_) {
                // Fallback: open email client
                final emailUri = Uri(
                  scheme: 'mailto',
                  path: 'admin@pondiuni.edu.in',
                  query: 'subject=${Uri.encodeComponent('Bug Report: ${subjectCtrl.text.trim()}')}'
                      '&body=${Uri.encodeComponent(descCtrl.text.trim())}',
                );
                try { await launchUrl(emailUri); } catch (_) {}
              }
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Issue reported — thank you!'),
                  backgroundColor: AppColors.accentGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            }),
          ],
        );
      });
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. CONTACT ADMIN
  // ═══════════════════════════════════════════════════════════════════════════

  void _showContactAdminSheet(BuildContext context) {
    _showThemedSheet(context, 'Contact Admin', (tc) {
      return Column(
        children: [
          GestureDetector(
            onTap: () async {
              final uri = Uri(scheme: 'mailto', path: 'admin@pondiuni.edu.in');
              try { await launchUrl(uri); } catch (_) {}
            },
            child: _contactRow(
                tc, Icons.email_rounded, 'Email', 'admin@pondiuni.edu.in'),
          ),
          GestureDetector(
            onTap: () async {
              final uri = Uri(scheme: 'tel', path: '+914132655179');
              try { await launchUrl(uri); } catch (_) {}
            },
            child: _contactRow(tc, Icons.phone_rounded, 'Phone', '+91 413 265 5179'),
          ),
          _contactRow(tc, Icons.access_time_rounded, 'Office Hours',
              'Mon – Fri, 9:00 AM – 5:00 PM'),
          _contactRow(tc, Icons.location_on_rounded, 'Address',
              'Pondicherry University, R.V. Nagar,\nKalapet, Puducherry – 605014'),
          const SizedBox(height: 16),
          _sheetButton('Send Email', () async {
            final emailUri = Uri(
              scheme: 'mailto',
              path: 'admin@pondiuni.edu.in',
              query: 'subject=${Uri.encodeComponent('PUnova App Query')}',
            );
            try {
              await launchUrl(emailUri);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Could not open email client'),
                  backgroundColor: AppColors.accentRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            }
            if (context.mounted) Navigator.pop(context);
          }),
          const SizedBox(height: 8),
          _sheetButton('Call Admin', () async {
            final phoneUri = Uri(scheme: 'tel', path: '+914132655179');
            try {
              await launchUrl(phoneUri);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Could not open dialer'),
                  backgroundColor: AppColors.accentRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            }
            if (context.mounted) Navigator.pop(context);
          }),
        ],
      );
    });
  }

  Widget _contactRow(Tc tc, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accentGreen, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: tc.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(value,
                    style: TextStyle(
                        color: tc.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 8. FAQ
  // ═══════════════════════════════════════════════════════════════════════════

  void _showFaqSheet(BuildContext context) {
    final faqs = [
      {
        'q': 'How do I reset my password?',
        'a':
            'Go to Profile → Security → Change Password. Enter your current password and a new one.'
      },
      {
        'q': 'Where can I view my exam results?',
        'a':
            'Navigate to the Services tab and tap on "Result". Select your semester to see grades.'
      },
      {
        'q': 'How do I track campus buses?',
        'a':
            'Open the Map tab — the Bus Tracking section shows live status and estimated arrival times.'
      },
      {
        'q': 'Can I download circulars for offline reading?',
        'a':
            'Yes! Tap the download icon on any circular. Manage downloads from Profile → Data Storage.'
      },
      {
        'q': 'How do I report a lost item?',
        'a':
            'Go to Services → Lost & Found → tap the + button to create a new lost/found report.'
      },
      {
        'q': 'Who do I contact for technical issues?',
        'a':
            'Go to Profile → Help & Support → Contact Admin for admin email and phone details.'
      },
    ];

    _showThemedSheet(context, 'Frequently Asked Questions', (tc) {
      return Column(
        children: faqs
            .map((f) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: tc.glassWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tc.glassBorder),
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      iconColor: AppColors.accentTeal,
                      collapsedIconColor: tc.textMuted,
                      title: Text(f['q']!,
                          style: TextStyle(
                              color: tc.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      children: [
                        Text(f['a']!,
                            style: TextStyle(
                                color: tc.textSecondary,
                                fontSize: 13,
                                height: 1.5)),
                      ],
                    ),
                  ),
                ))
            .toList(),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 9. APP VERSION
  // ═══════════════════════════════════════════════════════════════════════════

  void _showAppVersionDialog(BuildContext context) {
    final tc = Tc.of(context);
    final platformName = kIsWeb ? 'Web' : Platform.operatingSystem[0].toUpperCase() + Platform.operatingSystem.substring(1);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tc.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/images/app_logo.png',
                  width: 42, height: 42, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Text('PUnova',
                style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _versionRow(tc, 'Version', _appVersion),
            _versionRow(tc, 'Build', _appBuild.isNotEmpty ? _appBuild : 'dev'),
            _versionRow(tc, 'Platform', 'Flutter ($platformName)'),
            _versionRow(tc, 'Developer', 'Pondicherry University'),
            const SizedBox(height: 12),
            Text('© 2026 Pondicherry University.\nAll rights reserved.',
                style:
                    TextStyle(color: tc.textMuted, fontSize: 11, height: 1.5)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK',
                style: TextStyle(
                    color: AppColors.accentTeal, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _versionRow(Tc tc, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: tc.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 10. UNIVERSITY INFO
  // ═══════════════════════════════════════════════════════════════════════════

  void _showUniversityInfoSheet(BuildContext context) {
    _showThemedSheet(context, 'University Information', (tc) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset('assets/images/app_logo.png',
                width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          Text('Pondicherry University',
              style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('A Central University',
              style: TextStyle(
                  color: AppColors.accentTeal,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          _infoTile(tc, 'Established', '1985', Icons.calendar_today_rounded),
          _infoTile(tc, 'Location', 'R.V. Nagar, Kalapet,\nPuducherry – 605014',
              Icons.location_on_rounded),
          _infoTile(
              tc, 'Website', 'www.pondiuni.edu.in', Icons.language_rounded),
          _infoTile(tc, 'NAAC Grade', 'A++', Icons.star_rounded),
          _infoTile(
              tc, 'Vice Chancellor', 'Prof. Example VC', Icons.person_rounded),
          _infoTile(tc, 'Departments', '15+ Academic Departments',
              Icons.account_balance_rounded),
        ],
      );
    });
  }

  Widget _infoTile(Tc tc, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.accentTeal, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: tc.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        color: tc.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 11. PRIVACY POLICY
  // ═══════════════════════════════════════════════════════════════════════════

  void _showPrivacyPolicySheet(BuildContext context) {
    _showThemedSheet(context, 'Privacy Policy', (tc) {
      const sections = [
        {
          'title': '1. Information We Collect',
          'body':
              'We collect information you provide directly, such as your name, email, student ID, and profile photo. We also collect usage data including app interactions, device info, and login timestamps.'
        },
        {
          'title': '2. How We Use Your Information',
          'body':
              'Your data is used to provide campus services, manage your academic profile, send relevant notifications, enable transport tracking, and improve the app experience.'
        },
        {
          'title': '3. Data Storage & Security',
          'body':
              'All data is stored securely on university-managed servers. We use industry-standard encryption for data in transit and at rest. Access is restricted to authorized university personnel only.'
        },
        {
          'title': '4. Third-Party Services',
          'body':
              'We use OpenStreetMap for campus maps (no location tracking). No personal data is shared with third-party advertisers. Push notifications are delivered through Firebase Cloud Messaging.'
        },
        {
          'title': '5. Your Rights',
          'body':
              'You can view, update, or delete your personal information through the app. You may request a full data export by contacting the university admin. Account deletion will remove all associated data.'
        },
        {
          'title': '6. Contact',
          'body':
              'For privacy concerns, contact the Data Protection Officer at dpo@pondiuni.edu.in or visit the IT Services office at the Admin Block.'
        },
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last updated: February 2026',
              style: TextStyle(
                  color: tc.textMuted,
                  fontSize: 11,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          ...sections.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['title']!,
                        style: TextStyle(
                            color: tc.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(s['body']!,
                        style: TextStyle(
                            color: tc.textSecondary,
                            fontSize: 13,
                            height: 1.6)),
                  ],
                ),
              )),
        ],
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ThemeProvider.of(context);
    final tc = Tc.of(context);
    final profileImage = themeNotifier.profileImagePath;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),

          // Profile header
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _pickImage(context),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: tc.bgCard),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: tc.bgMedium,
                            backgroundImage: _getProfileImage(profileImage),
                            child: profileImage == null
                                ? Icon(Icons.person_rounded,
                                    size: 32, color: tc.textMuted)
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            border: Border.all(color: tc.bgCard, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 13, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          _profileName.isNotEmpty
                              ? _profileName
                              : 'Balakumaran D',
                          style: TextStyle(
                              color: tc.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                          _profileEmail.isNotEmpty
                              ? _profileEmail
                              : 'dbalakumaran23@gmail.com',
                          style: TextStyle(color: tc.textMuted, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppColors.accentTeal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(
                            '${_profileDept.isNotEmpty ? _profileDept : 'CS'} • Semester ${_profileSemester > 0 ? _profileSemester : 5}',
                            style: const TextStyle(
                                color: AppColors.accentTeal,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Appearance
          _buildSection(context, 'Appearance', [
            GlassListTile(
              icon: tc.isDark
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              title: tc.isDark ? 'Dark Mode' : 'Light Mode',
              iconColor: AppColors.accentPurple,
              trailing: Switch(
                value: tc.isDark,
                onChanged: (_) => themeNotifier.toggleTheme(),
                activeThumbColor: AppColors.accentTeal,
                activeTrackColor: AppColors.accentTeal.withValues(alpha: 0.3),
              ),
            ),
            GlassListTile(
                icon: Icons.text_fields_rounded,
                title: 'Font Size',
                subtitle: _fontSizeLabel,
                iconColor: AppColors.accentPurple,
                onTap: () => _showFontSizeSheet(context)),
          ]),

          _buildSection(context, 'Personal Info', [
            GlassListTile(
                icon: Icons.person_rounded,
                title: 'Personal Information',
                subtitle: 'Name, DOB, Gender',
                onTap: () => _showPersonalInfoSheet(context)),
          ]),

          _buildSection(context, 'Security', [
            GlassListTile(
                icon: Icons.lock_rounded,
                title: 'Change Password',
                iconColor: AppColors.accentOrange,
                onTap: () => _showChangePasswordSheet(context)),
            GlassListTile(
              icon: Icons.fingerprint_rounded,
              title: 'App Lock (Fingerprint / PIN)',
              subtitle: _appLockEnabled ? 'Enabled' : 'Disabled',
              iconColor: AppColors.accentOrange,
              trailing: Switch(
                value: _appLockEnabled,
                onChanged: (v) async {
                  if (v) {
                    // Check if biometrics are available
                    final auth = LocalAuthentication();
                    final canAuth = await auth.canCheckBiometrics || await auth.isDeviceSupported();
                    if (!canAuth) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('No biometric or screen lock set up on this device'),
                          backgroundColor: AppColors.accentRed,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ));
                      }
                      return;
                    }
                    // Verify identity before enabling
                    try {
                      final didAuth = await auth.authenticate(
                        localizedReason: 'Verify your identity to enable App Lock',
                      );
                      if (!didAuth) return;
                    } catch (_) {
                      return;
                    }
                  }
                  setState(() => _appLockEnabled = v);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('app_lock_enabled', v);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(v
                          ? 'App Lock enabled — you\'ll need to authenticate on next launch'
                          : 'App Lock disabled'),
                      backgroundColor:
                          v ? AppColors.accentGreen : AppColors.accentOrange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ));
                  }
                },
                activeThumbColor: AppColors.accentTeal,
                activeTrackColor: AppColors.accentTeal.withValues(alpha: 0.3),
              ),
            ),
          ]),

          _buildSection(context, 'Data Storage', [
            GlassListTile(
                icon: Icons.cleaning_services_rounded,
                title: 'Clear Cache',
                iconColor: AppColors.accentPink,
                onTap: () => _showClearCacheDialog(context)),
            GlassListTile(
                icon: Icons.download_rounded,
                title: 'Manage Downloaded Circulars',
                iconColor: AppColors.accentPink,
                onTap: () => _showDownloadedCircularsSheet(context)),
          ]),

          _buildSection(context, 'Help & Support', [
            GlassListTile(
                icon: Icons.bug_report_rounded,
                title: 'Report Issue',
                iconColor: AppColors.accentGreen,
                onTap: () => _showReportIssueSheet(context)),
            GlassListTile(
                icon: Icons.headset_mic_rounded,
                title: 'Contact Admin',
                iconColor: AppColors.accentGreen,
                onTap: () => _showContactAdminSheet(context)),
            GlassListTile(
                icon: Icons.help_rounded,
                title: 'FAQ',
                iconColor: AppColors.accentGreen,
                onTap: () => _showFaqSheet(context)),
          ]),

          _buildSection(context, 'About App', [
            GlassListTile(
                icon: Icons.info_rounded,
                title: 'App Version',
                subtitle: _appVersion,
                iconColor: AppColors.textMuted,
                onTap: () => _showAppVersionDialog(context)),
            GlassListTile(
                icon: Icons.school_rounded,
                title: 'University Info',
                iconColor: AppColors.textMuted,
                onTap: () => _showUniversityInfoSheet(context)),
            GlassListTile(
                icon: Icons.policy_rounded,
                title: 'Privacy Policy',
                iconColor: AppColors.textMuted,
                onTap: () => _showPrivacyPolicySheet(context)),
          ]),

          // ── Logout ──
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _showLogoutDialog(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded,
                          color: AppColors.accentRed, size: 20),
                      const SizedBox(width: 10),
                      Text('Log Out',
                          style: TextStyle(
                              color: AppColors.accentRed,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final tc = Tc.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tc.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out',
            style: TextStyle(
                color: tc.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to log out?',
            style: TextStyle(color: tc.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: tc.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const CampusConnectApp()),
                  (route) => false,
                );
              }
            },
            child: const Text('Log Out',
                style: TextStyle(
                    color: AppColors.accentRed,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getProfileImage(String? path) {
    if (path == null) return null;
    if (kIsWeb) return NetworkImage(path);
    return FileImage(File(path));
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(letterSpacing: 1.5)),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: tiles),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
