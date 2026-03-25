import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';
import '../services/api_service.dart';
import '../models/forum_post.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  List<ForumPost> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().get('/forum');
      final postsJson = response['posts'] as List;
      setState(() {
        _posts = postsJson.map((j) => ForumPost.fromJson(j)).toList();
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to static data if API is unreachable
      setState(() {
        _posts = _staticPosts();
        _isLoading = false;
      });
    }
  }

  List<ForumPost> _staticPosts() {
    final now = DateTime.now();
    return [
      ForumPost(
          id: '1',
          title: 'Best study spots on campus?',
          body:
              'Looking for quiet places to study. Library gets too crowded after 3PM.',
          authorName: 'Sarah K.',
          likesCount: 12,
          repliesCount: 8,
          createdAt: now.subtract(const Duration(hours: 2))),
      ForumPost(
          id: '2',
          title: 'Anyone interested in Python study group?',
          body:
              'Planning weekly sessions. Beginners welcome! DM me for details.',
          authorName: 'Mike R.',
          likesCount: 24,
          repliesCount: 15,
          createdAt: now.subtract(const Duration(hours: 4))),
      ForumPost(
          id: '3',
          title: 'Cafeteria food review',
          body:
              'The new pasta counter is actually pretty good. Recommend the arrabiata.',
          authorName: 'Priya S.',
          likesCount: 31,
          repliesCount: 22,
          createdAt: now.subtract(const Duration(hours: 8))),
    ];
  }

  void _showNewPostDialog(BuildContext context, Tc tc) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: tc.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Post',
                style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _inputField(tc, 'Title', titleCtrl),
            const SizedBox(height: 12),
            _inputField(tc, 'What\'s on your mind?', bodyCtrl, maxLines: 3),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                text: 'Post',
                onPressed: () async {
                  if (titleCtrl.text.isNotEmpty && bodyCtrl.text.isNotEmpty) {
                    try {
                      await ApiService().post('/forum', body: {
                        'title': titleCtrl.text,
                        'body': bodyCtrl.text,
                      });
                      if (context.mounted) Navigator.pop(context);
                      _fetchPosts(); // Refresh
                    } catch (e) {
                      if (context.mounted) Navigator.pop(context);
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(Tc tc, String hint, TextEditingController ctrl,
      {int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: tc.glassWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.glassBorder),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: TextStyle(color: tc.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: tc.textMuted, fontSize: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    return Scaffold(
      backgroundColor: tc.bg,
      body: Container(
        decoration: BoxDecoration(gradient: tc.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              const GlassAppBar(title: 'Forum'),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accentTeal))
                    : RefreshIndicator(
                        onRefresh: _fetchPosts,
                        color: AppColors.accentTeal,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                          itemCount: _posts.length,
                          itemBuilder: (_, i) => _postCard(tc, _posts[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: () => _showNewPostDialog(context, tc),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.edit_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Widget _postCard(Tc tc, ForumPost post) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      AppColors.accentPurple.withValues(alpha: 0.2),
                  child: Text((post.authorName ?? '?')[0],
                      style: const TextStyle(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.w700))),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(post.authorName ?? 'Anonymous',
                      style: TextStyle(
                          color: tc.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14))),
              Text(post.timeAgo,
                  style: TextStyle(color: tc.textMuted, fontSize: 11)),
            ]),
            const SizedBox(height: 12),
            Text(post.title,
                style: TextStyle(
                    color: tc.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            const SizedBox(height: 6),
            Text(post.body,
                style: TextStyle(
                    color: tc.textSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: 14),
            Row(children: [
              Icon(Icons.favorite_border_rounded,
                  size: 18, color: tc.textMuted),
              const SizedBox(width: 4),
              Text('${post.likesCount}',
                  style: TextStyle(color: tc.textMuted, fontSize: 12)),
              const SizedBox(width: 20),
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 18, color: tc.textMuted),
              const SizedBox(width: 4),
              Text('${post.repliesCount}',
                  style: TextStyle(color: tc.textMuted, fontSize: 12)),
            ]),
          ],
        ),
      ),
    );
  }
}
