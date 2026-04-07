import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';

class IdCardData {
  final String name, email, role, idNumber, department;
  final String year, semester, phone, gender, dateOfBirth, validUpto;
  final String? avatarUrl;

  const IdCardData({
    required this.name, required this.email, required this.role,
    required this.idNumber, required this.department, required this.year,
    required this.semester, required this.phone, required this.gender,
    required this.dateOfBirth, required this.validUpto, this.avatarUrl,
  });

  factory IdCardData.fromUser(Map<String, dynamic> u) {
    final av = u['avatar_url'] ?? u['avatarUrl'];
    final ca = u['created_at'] as String?;
    String vu = '31/05/2026';
    if (ca != null && ca.isNotEmpty) {
      try {
        final dt = DateTime.parse(ca);
        vu = '${dt.day.toString().padLeft(2, "0")}/${dt.month.toString().padLeft(2, "0")}/${dt.year + 4}';
      } catch (_) {}
    }
    return IdCardData(
      name: u['full_name'] ?? u['name'] ?? '',
      email: u['email'] ?? '',
      role: (u['role'] ?? 'student').toString().toUpperCase(),
      idNumber: u['roll_number'] ?? u['id']?.toString() ?? '',
      department: u['department'] ?? '',
      year: u['year'] ?? '',
      semester: u['semester'] ?? '',
      phone: u['phone'] ?? '',
      gender: u['gender'] ?? '',
      dateOfBirth: u['date_of_birth'] ?? '',
      validUpto: vu,
      avatarUrl: av is String && av.isNotEmpty ? av : null,
    );
  }

  factory IdCardData.fromJson(Map<String, dynamic> j) => IdCardData(
    name: j['name'] ?? '', email: j['email'] ?? '', role: j['role'] ?? 'STUDENT',
    idNumber: j['idNumber'] ?? '', department: j['department'] ?? '',
    year: j['year'] ?? '', semester: j['semester'] ?? '',
    phone: j['phone'] ?? '', gender: j['gender'] ?? '',
    dateOfBirth: j['dateOfBirth'] ?? '', validUpto: j['validUpto'] ?? '',
    avatarUrl: j['avatarUrl'],
  );

  Map<String, dynamic> toJson() => {
    'name': name, 'email': email, 'role': role, 'idNumber': idNumber,
    'department': department, 'year': year, 'semester': semester,
    'phone': phone, 'gender': gender, 'dateOfBirth': dateOfBirth,
    'validUpto': validUpto, 'avatarUrl': avatarUrl,
  };

  String toNdefText() {
    final b = StringBuffer();
    b.writeln('=== PUnova Digital ID ===');
    b.writeln('Name       : $name');
    b.writeln('ID No.     : $idNumber');
    b.writeln('Role       : $role');
    b.writeln('Dept.      : $department');
    if (year.isNotEmpty) b.writeln('Year       : $year');
    if (semester.isNotEmpty) b.writeln('Semester   : $semester');
    b.writeln('Email      : $email');
    if (phone.isNotEmpty) b.writeln('Phone      : $phone');
    b.writeln('Valid Upto : $validUpto');
    return b.toString();
  }
}

class MyIdScreen extends StatefulWidget {
  const MyIdScreen({super.key});
  @override
  State<MyIdScreen> createState() => _MyIdScreenState();
}

class _MyIdScreenState extends State<MyIdScreen>
    with SingleTickerProviderStateMixin {
  static const _cacheKey = 'punova_id_card_cache';
  static const _nfcCardsKey = 'punova_nfc_cards';

  IdCardData? _data;
  bool _isLoading = true, _isUploadingPhoto = false,
       _isNfcScanning = false, _nfcAvailable = false;
  DateTime? _lastSynced;
  List<Map<String, dynamic>> _savedNfcCards = [];
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    Future.wait([_loadProfile(), _checkNfc(), _loadSavedNfcCards()]);
  }

  @override
  void dispose() { _shimmerCtrl.dispose(); super.dispose(); }

  // ── Profile ──────────────────────────────────────────────────────────────
  Future<void> _loadProfile({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _loadFromCache();
      if (cached != null && mounted) {
        setState(() { _data = cached; _isLoading = false; });
        _refreshFromBackend();
        return;
      }
    }
    await _refreshFromBackend(showSpinner: true);
  }

  Future<void> _refreshFromBackend({bool showSpinner = false}) async {
    if (showSpinner && mounted) setState(() => _isLoading = true);
    try {
      final res = await AuthService().getProfile();
      final user = res['user'] as Map<String, dynamic>?;
      if (user != null) {
        final d = IdCardData.fromUser(user);
        await _saveToCache(d);
        if (mounted) setState(() { _data = d; _isLoading = false; _lastSynced = DateTime.now(); });
      } else { throw Exception('No user'); }
    } catch (_) {
      if (_data == null) {
        final c = await _loadFromCache();
        if (mounted) setState(() { _data = c; _isLoading = false; });
      } else if (mounted) { setState(() => _isLoading = false); }
    }
  }

  // ── Cache ─────────────────────────────────────────────────────────────────
  Future<void> _saveToCache(IdCardData d) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_cacheKey, jsonEncode(d.toJson()));
    } catch (_) {}
  }

  Future<IdCardData?> _loadFromCache() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      return IdCardData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  // ── Photo upload ──────────────────────────────────────────────────────────
  Future<void> _pickAndUpload(ImageSource src) async {
    final picked = await ImagePicker().pickImage(
      source: src, maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _isUploadingPhoto = true);
    try {
      final res = await ApiService().uploadFile('/auth/profile/avatar', 'avatar', File(picked.path));
      final user = res['user'] as Map<String, dynamic>?;
      if (user != null) {
        final d = IdCardData.fromUser(user);
        await _saveToCache(d);
        if (mounted) {
          setState(() { _data = d; _isUploadingPhoto = false; });
          _snack('Photo updated!', ok: true);
        }
      }
    } catch (e) {
      if (mounted) { setState(() => _isUploadingPhoto = false); _snack('Upload failed: $e'); }
    }
  }

  void _showPhotoOptions() {
    if (kIsWeb) { _pickAndUpload(ImageSource.gallery); return; }
    final tc = Tc.of(context);
    showModalBottomSheet(
      context: context, backgroundColor: tc.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4,
          decoration: BoxDecoration(color: tc.glassBorder, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        ListTile(
          leading: Icon(Icons.camera_alt_rounded, color: tc.accent),
          title: Text('Take Photo', style: TextStyle(color: tc.textPrimary)),
          onTap: () { Navigator.pop(context); _pickAndUpload(ImageSource.camera); }),
        ListTile(
          leading: Icon(Icons.photo_library_rounded, color: tc.accent),
          title: Text('Choose from Gallery', style: TextStyle(color: tc.textPrimary)),
          onTap: () { Navigator.pop(context); _pickAndUpload(ImageSource.gallery); }),
        const SizedBox(height: 8),
      ])),
    );
  }

  // ── NFC ───────────────────────────────────────────────────────────────────
  Future<void> _checkNfc() async {
    if (kIsWeb) return;
    try {
      final a = await FlutterNfcKit.nfcAvailability;
      if (mounted) setState(() => _nfcAvailable = a == NFCAvailability.available);
    } catch (_) { if (mounted) setState(() => _nfcAvailable = false); }
  }

  Future<void> _writeToNfc() async {
    if (_data == null) return;
    setState(() => _isNfcScanning = true);
    try {
      _snack('Hold phone near an NFC tag…', ok: true);
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 20),
        iosAlertMessage: 'Hold near NFC tag to write your ID');
      if (tag.ndefWritable == true) {
        await FlutterNfcKit.writeNDEFRecords(
          [ndef.TextRecord(text: _data!.toNdefText(), language: 'en')]);
        await FlutterNfcKit.finish(iosAlertMessage: 'ID written to NFC tag!');
        if (mounted) { setState(() => _isNfcScanning = false); _snack('ID card written to NFC tag!', ok: true); }
      } else {
        await FlutterNfcKit.finish(iosErrorMessage: 'Not writable');
        throw Exception('Tag not writable');
      }
    } on PlatformException catch (e) {
      try { await FlutterNfcKit.finish(iosErrorMessage: 'Error'); } catch (_) {}
      if (mounted) { setState(() => _isNfcScanning = false); _snack('NFC error: ${e.message}'); }
    } catch (e) {
      try { await FlutterNfcKit.finish(iosErrorMessage: e.toString()); } catch (_) {}
      if (mounted) { setState(() => _isNfcScanning = false); _snack('NFC: $e'); }
    }
  }

  Future<void> _readFromNfc() async {
    setState(() => _isNfcScanning = true);
    try {
      _snack('Hold phone near NFC tag to read…', ok: true);
      await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 20),
        iosAlertMessage: 'Tap NFC tag to read');
      final records = await FlutterNfcKit.readNDEFRecords();
      await FlutterNfcKit.finish(iosAlertMessage: 'Tag read!');
      if (mounted) {
        setState(() => _isNfcScanning = false);
        final txt = records.whereType<ndef.TextRecord>().map((r) => r.text ?? '').join('\n');
        final content = txt.isNotEmpty ? txt : records.toString();
        await _saveNfcCard(content);
        _snack('Card saved to memory!', ok: true);
        _showNfcDialog(content);
      }
    } on PlatformException catch (e) {
      try { await FlutterNfcKit.finish(iosErrorMessage: 'Error'); } catch (_) {}
      if (mounted) { setState(() => _isNfcScanning = false); _snack('NFC: ${e.message}'); }
    } catch (e) {
      try { await FlutterNfcKit.finish(iosErrorMessage: e.toString()); } catch (_) {}
      if (mounted) { setState(() => _isNfcScanning = false); _snack('NFC: $e'); }
    }
  }

  // ── NFC Card Memory ─────────────────────────────────────────────────────
  Future<void> _loadSavedNfcCards() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_nfcCardsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        if (mounted) setState(() => _savedNfcCards = list.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  Future<void> _persistNfcCards() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_nfcCardsKey, jsonEncode(_savedNfcCards));
    } catch (_) {}
  }

  Map<String, String> _parseNdefText(String text) {
    final result = <String, String>{};
    for (final line in text.split('\n')) {
      final ci = line.indexOf(':');
      if (ci > 0) {
        final key = line.substring(0, ci).trim();
        final val = line.substring(ci + 1).trim();
        if (key.isNotEmpty && val.isNotEmpty && !key.startsWith('=')) {
          result[key] = val;
        }
      }
    }
    return result;
  }

  Future<void> _saveNfcCard(String content) async {
    final parsed = _parseNdefText(content);
    final card = <String, dynamic>{
      'raw': content,
      'parsed': parsed,
      'saved_at': DateTime.now().toIso8601String(),
    };
    if (mounted) setState(() => _savedNfcCards.insert(0, card));
    await _persistNfcCards();
  }

  Future<void> _deleteNfcCard(int index) async {
    if (mounted) setState(() => _savedNfcCards.removeAt(index));
    await _persistNfcCards();
  }

  void _showNfcDialog(String c) {
    final tc = Tc.of(context);
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: tc.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('NFC Tag Content', style: TextStyle(color: tc.textPrimary, fontSize: 16)),
      content: SingleChildScrollView(
        child: Text(c, style: TextStyle(color: tc.textSecondary, fontSize: 13, fontFamily: 'monospace'))),
      actions: [TextButton(onPressed: () => Navigator.pop(context),
        child: Text('Close', style: TextStyle(color: tc.accent)))],
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;
    final tc = Tc.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 13)),
      backgroundColor: ok ? tc.accent : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  ImageProvider? _img(String? src) {
    if (src == null || src.isEmpty) return null;
    final uri = Uri.tryParse(src);
    if (uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return NetworkImage(src);
    }
    if (kIsWeb) return null;
    return FileImage(File(src));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    return Scaffold(
      backgroundColor: tc.bg,
      body: Container(
        decoration: BoxDecoration(gradient: tc.bgGradient),
        child: Stack(children: [
          if (tc.isDark) ...[
            Positioned(top: -80, right: -60, child: _orb(AppColors.accentBlue, 260, 0.08)),
            Positioned(bottom: 100, left: -80, child: _orb(AppColors.accentPurple, 280, 0.05)),
          ],
          SafeArea(child: Column(children: [
            GlassAppBar(title: 'Digital ID Card', actions: [
              GestureDetector(
                onTap: () => _loadProfile(forceRefresh: true),
                child: _aBtn(tc, Icons.refresh_rounded, tc.textSecondary)),
              if (_nfcAvailable) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isNfcScanning || _data == null ? null : _writeToNfc,
                  child: _aBtn(tc, Icons.nfc_rounded, _isNfcScanning ? tc.accent : tc.textSecondary)),
              ],
            ]),
            Expanded(child: RefreshIndicator(
              color: tc.accent,
              onRefresh: () => _loadProfile(forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(children: [
                  _isLoading && _data == null ? _shimmerCard(tc) : _buildCard(tc),
                  const SizedBox(height: 16),
                  if (_nfcAvailable) _nfcPanel(tc),
                  _savedCardsSection(tc),
                  if (_lastSynced != null) ...[
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.sync_rounded, size: 13, color: tc.textMuted),
                      const SizedBox(width: 5),
                      Text('Synced ${_fmtTime(_lastSynced!)}',
                        style: TextStyle(fontSize: 11, color: tc.textMuted)),
                    ]),
                  ],
                  const SizedBox(height: 32),
                ]),
              ),
            )),
          ])),
          if (_isUploadingPhoto)
            Container(color: Colors.black54, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: tc.accent, strokeWidth: 2.5),
              const SizedBox(height: 12),
              const Text('Uploading photo…', style: TextStyle(color: Colors.white, fontSize: 14)),
            ]))),
        ]),
      ),
    );
  }

  Widget _buildCard(Tc tc) {
    final d = _data;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: tc.isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: tc.glassBorder),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: tc.isDark ? 0.22 : 0.07),
              blurRadius: 28, offset: const Offset(0, 8))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F3AAE), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 28, height: 28,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 15)),
                  const SizedBox(width: 10),
                  const Text('Pondicherry University', style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                ]),
                const SizedBox(height: 4),
                Text('PUnova Campus Card', style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 12, letterSpacing: 1.2)),
              ]),
            ),
            // Avatar
            Transform.translate(
              offset: const Offset(0, -24),
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)])),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: tc.bgCard),
                    child: CircleAvatar(
                      radius: 44, backgroundColor: tc.bgMedium,
                      backgroundImage: _img(d?.avatarUrl),
                      child: _img(d?.avatarUrl) == null
                        ? Icon(Icons.person_rounded, size: 44, color: tc.textMuted) : null),
                  ),
                ),
                if (!kIsWeb)
                  Positioned(bottom: 0, right: 0, child: GestureDetector(
                    onTap: _showPhotoOptions,
                    child: Container(width: 30, height: 30,
                      decoration: BoxDecoration(color: tc.accent, shape: BoxShape.circle,
                        border: Border.all(color: tc.bgCard, width: 2.5)),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14)))),
              ]),
            ),
            // Name & role
            Transform.translate(
              offset: const Offset(0, -12),
              child: Column(children: [
                Text(d?.name ?? '', textAlign: TextAlign.center, style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: tc.textPrimary)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, children: [
                  _roleBadge(tc, d?.role ?? ''),
                  if (d?.department.isNotEmpty == true) _deptBadge(tc, d!.department),
                ]),
              ]),
            ),
            // QR
            SizedBox(width: 160, height: 160, child: CustomPaint(
              painter: _CornerBorderPainter(
                color: tc.accent.withValues(alpha: 0.35), strokeWidth: 2.5,
                cornerLength: 24, cornerRadius: 8),
              child: Center(child: d?.idNumber.isNotEmpty == true
                ? QrImageView(
                    data: 'PUNOVA|${d!.idNumber}|${d.name}|${d.department}|${d.email}',
                    version: QrVersions.auto, size: 128, backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0F2A4A)),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0F2A4A)))
                : Icon(Icons.qr_code_rounded, size: 64, color: tc.textMuted)),
            )),
            const SizedBox(height: 6),
            Text('Scan for campus access', style: TextStyle(
              fontSize: 12, color: tc.textMuted, fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            _div(tc),
            const SizedBox(height: 20),
            // Details grid
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [
              Row(children: [
                Expanded(child: _tile(tc, 'ID NUMBER', d?.idNumber ?? '—', Icons.badge_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _tile(tc, 'VALID UPTO', d?.validUpto ?? '—', Icons.event_rounded)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _tile(tc, 'YEAR', d?.year.isNotEmpty == true ? d!.year : '—', Icons.school_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _tile(tc, 'SEMESTER', d?.semester.isNotEmpty == true ? d!.semester : '—', Icons.format_list_numbered_rounded)),
              ]),
              const SizedBox(height: 12),
              _tile(tc, 'EMAIL', d?.email.isNotEmpty == true ? d!.email : '—', Icons.email_rounded),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _tile(tc, 'PHONE', d?.phone.isNotEmpty == true ? d!.phone : '—', Icons.phone_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _tile(tc, 'GENDER', d?.gender.isNotEmpty == true ? _cap(d!.gender) : '—', Icons.person_outline_rounded)),
              ]),
              if (d?.dateOfBirth.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                _tile(tc, 'DATE OF BIRTH', d!.dateOfBirth, Icons.cake_rounded),
              ],
            ])),
            const SizedBox(height: 20),
            _div(tc),
            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: tc.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.verified_rounded, size: 14, color: tc.accent),
                const SizedBox(width: 6),
                Text('Official Pondicherry University Card',
                  style: TextStyle(fontSize: 11, color: tc.textMuted, letterSpacing: 0.5)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _nfcPanel(Tc tc) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: tc.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tc.glassBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(color: tc.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.nfc_rounded, color: tc.accent, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('NFC Smart Card', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tc.textPrimary)),
                Text('Write your ID to a tag or read an existing one',
                  style: TextStyle(fontSize: 11, color: tc.textMuted)),
              ])),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _nfcBtn(tc, label: 'Write to Tag', icon: Icons.upload_rounded,
                onTap: _data != null && !_isNfcScanning ? _writeToNfc : null, primary: true)),
              const SizedBox(width: 12),
              Expanded(child: _nfcBtn(tc, label: 'Read Tag', icon: Icons.download_rounded,
                onTap: !_isNfcScanning ? _readFromNfc : null, primary: false)),
            ]),
            if (_isNfcScanning) ...[
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: tc.accent)),
                const SizedBox(width: 8),
                Text('Waiting for NFC tag…', style: TextStyle(fontSize: 12, color: tc.accent)),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _savedCardsSection(Tc tc) {
    if (_savedNfcCards.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tc.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tc.glassBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.credit_card_rounded, color: Colors.green, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Saved NFC Cards', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: tc.textPrimary)),
                  Text('Tapped & stored on this device',
                    style: TextStyle(fontSize: 11, color: tc.textMuted)),
                ])),
                Text('${_savedNfcCards.length}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tc.accent)),
              ]),
              const SizedBox(height: 14),
              ..._savedNfcCards.asMap().entries.map((e) => _savedCardTile(tc, e.key, e.value)),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _savedCardTile(Tc tc, int idx, Map<String, dynamic> card) {
    final parsed = (card['parsed'] as Map<String, dynamic>?) ?? {};
    final name = parsed['Name'] ?? parsed['name'] ?? 'Unknown';
    final id = parsed['ID No.'] ?? parsed['id'] ?? '';
    final role = parsed['Role'] ?? parsed['role'] ?? '';
    final dept = parsed['Dept.'] ?? parsed['department'] ?? '';
    final valid = parsed['Valid Upto'] ?? '';
    final savedAt = card['saved_at'] as String? ?? '';
    String fmtDate = '';
    try {
      final dt = DateTime.parse(savedAt);
      fmtDate = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tc.glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.glassBorder)),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(
            color: tc.accent.withValues(alpha: 0.10),
            shape: BoxShape.circle),
          child: Center(child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: tc.accent)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tc.textPrimary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Wrap(spacing: 6, children: [
            if (id.isNotEmpty) _miniTag(tc, id, Icons.badge_outlined),
            if (role.isNotEmpty) _miniTag(tc, role, Icons.school_outlined),
            if (dept.isNotEmpty) _miniTag(tc, dept.length > 12 ? '${dept.substring(0, 12)}…' : dept, Icons.computer_outlined),
          ]),
          if (valid.isNotEmpty || fmtDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              if (valid.isNotEmpty) ...[
                Icon(Icons.event_rounded, size: 10, color: tc.textMuted),
                const SizedBox(width: 3),
                Text('Valid: $valid', style: TextStyle(fontSize: 10, color: tc.textMuted)),
                const SizedBox(width: 8),
              ],
              if (fmtDate.isNotEmpty) ...[
                Icon(Icons.nfc_rounded, size: 10, color: tc.textMuted),
                const SizedBox(width: 3),
                Text('Saved $fmtDate', style: TextStyle(fontSize: 10, color: tc.textMuted)),
              ],
            ]),
          ],
        ])),
        GestureDetector(
          onTap: () => _confirmDeleteNfcCard(tc, idx),
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent))),
      ]),
    );
  }

  Widget _miniTag(Tc tc, String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: tc.accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 9, color: tc.accent),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 9, color: tc.accent, fontWeight: FontWeight.w600)),
    ]));

  void _confirmDeleteNfcCard(Tc tc, int idx) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: tc.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove Card', style: TextStyle(color: tc.textPrimary, fontSize: 16)),
        content: Text('Remove this saved NFC card from memory?',
          style: TextStyle(color: tc.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: tc.textMuted))),
          TextButton(
            onPressed: () { Navigator.pop(context); _deleteNfcCard(idx); },
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  Widget _shimmerCard(Tc tc) {
    return AnimatedBuilder(animation: _shimmerCtrl, builder: (_, __) {
      final op = 0.04 + _shimmerCtrl.value * (tc.isDark ? 0.08 : 0.12);
      return Container(height: 520,
        decoration: BoxDecoration(
          color: tc.isDark ? Colors.white.withValues(alpha: op) : Colors.grey.withValues(alpha: op),
          borderRadius: BorderRadius.circular(24), border: Border.all(color: tc.glassBorder)),
        child: Column(children: [
          Container(height: 80, decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFF0F3AAE).withValues(alpha: 0.5),
              const Color(0xFF3B82F6).withValues(alpha: 0.5)]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)))),
          const SizedBox(height: 20),
          _sBox(tc, 80, 80, true), const SizedBox(height: 16),
          _sBox(tc, 24, 180), const SizedBox(height: 8),
          _sBox(tc, 16, 100), const SizedBox(height: 32),
          _sBox(tc, 128, 128),
        ]),
      );
    });
  }

  Widget _sBox(Tc tc, double h, double w, [bool circle = false]) => Container(
    height: h, width: w,
    decoration: BoxDecoration(
      color: tc.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15),
      borderRadius: circle ? null : BorderRadius.circular(8),
      shape: circle ? BoxShape.circle : BoxShape.rectangle));

  Widget _tile(Tc tc, String lbl, String val, IconData ic) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: tc.glassFill, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: tc.glassBorder)),
    child: Row(children: [
      Icon(ic, size: 14, color: tc.accent), const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(lbl, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
          color: tc.textMuted, letterSpacing: 0.8)),
        const SizedBox(height: 3),
        Text(val, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tc.textPrimary)),
      ])),
    ]));

  Widget _roleBadge(Tc tc, String r) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    decoration: BoxDecoration(color: tc.accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: tc.accent.withValues(alpha: 0.3))),
    child: Text(r, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
      color: tc.accent, letterSpacing: 1.4)));

  Widget _deptBadge(Tc tc, String d) {
    final s = d.length > 14 ? '${d.substring(0, 14)}…' : d;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.computer_rounded, size: 11, color: Colors.green),
        const SizedBox(width: 4),
        Text(s, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
          color: Colors.green, letterSpacing: 0.5)),
      ]));
  }

  Widget _nfcBtn(Tc tc, {required String label, required IconData icon,
      required VoidCallback? onTap, required bool primary}) {
    return GestureDetector(onTap: onTap, child: AnimatedOpacity(
      duration: const Duration(milliseconds: 200), opacity: onTap != null ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: primary ? tc.accent.withValues(alpha: 0.15) : tc.glassFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary ? tc.accent.withValues(alpha: 0.4) : tc.glassBorder)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: primary ? tc.accent : tc.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: primary ? tc.accent : tc.textSecondary)),
        ]))));
  }

  Widget _aBtn(Tc tc, IconData ic, Color c) => Container(
    width: 38, height: 38,
    decoration: BoxDecoration(color: tc.glassFill, borderRadius: BorderRadius.circular(11),
      border: Border.all(color: tc.glassBorder, width: 0.5)),
    child: Icon(ic, color: c, size: 17));

  Widget _div(Tc tc) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(height: 0.5, color: tc.glassBorder));

  Widget _orb(Color color, double size, double alpha) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color.withValues(alpha: alpha), Colors.transparent])));

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  String _fmtTime(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }
}

class _CornerBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth, cornerLength, cornerRadius;
  const _CornerBorderPainter({required this.color, required this.strokeWidth,
    required this.cornerLength, required this.cornerRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final w = size.width, h = size.height, cl = cornerLength, r = cornerRadius;
    canvas.drawPath(Path()..moveTo(0,cl)..lineTo(0,r)..quadraticBezierTo(0,0,r,0)..lineTo(cl,0), p);
    canvas.drawPath(Path()..moveTo(w-cl,0)..lineTo(w-r,0)..quadraticBezierTo(w,0,w,r)..lineTo(w,cl), p);
    canvas.drawPath(Path()..moveTo(0,h-cl)..lineTo(0,h-r)..quadraticBezierTo(0,h,r,h)..lineTo(cl,h), p);
    canvas.drawPath(Path()..moveTo(w-cl,h)..lineTo(w-r,h)..quadraticBezierTo(w,h,w,h-r)..lineTo(w,h-cl), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
