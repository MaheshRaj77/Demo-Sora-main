import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/shared_widgets.dart';
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
  int _selectedFilter = 0;
  final _filters = ['All', 'General', 'Study Groups', 'Events', 'Marketplace'];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final category = _selectedFilter > 0 ? _filters[_selectedFilter] : null;
      final path = category != null
          ? '/forum?category=${Uri.encodeComponent(category)}'
          : '/forum';
      final response = await ApiService().get(path);
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

  Future<void> _toggleLike(ForumPost post) async {
    try {
      await ApiService().post('/forum/${post.id}/like', body: {});
      // Optimistically update UI
      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = ForumPost(
            id: post.id,
            userId: post.userId,
            title: post.title,
            body: post.body,
            category: post.category,
            likesCount: post.likesCount + 1,
            repliesCount: post.repliesCount,
            authorName: post.authorName,
            authorAvatar: post.authorAvatar,
            createdAt: post.createdAt,
          );
        }
      });
    } catch (_) {
      // Ignore like errors silently
    }
  }

  void _showReplies(BuildContext context, Tc tc, ForumPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: tc.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RepliesSheet(post: post, tc: tc),
    );
  }

  void _showNewPostDialog(BuildContext context, Tc tc) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    const categoryOptions = ['General', 'Study Groups', 'Events', 'Marketplace'];
    var selectedCategory = 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: tc.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
              const SizedBox(height: 12),
              Text('Category',
                  style: TextStyle(color: tc.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: categoryOptions.map((cat) {
                  final selected = cat == selectedCategory;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? tc.accent.withValues(alpha: 0.15)
                            : tc.glassWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? tc.accent : tc.glassBorder,
                        ),
                      ),
                      child: Text(cat,
                          style: TextStyle(
                              color: selected ? tc.accent : tc.textSecondary,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ),
                  );
                }).toList(),
              ),
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
                          'category': selectedCategory,
                        });
                        if (context.mounted) Navigator.pop(context);
                        _fetchPosts();
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
              const SizedBox(height: 4),
              // ── Filter Chips ──
              ChipFilter(
                labels: _filters,
                selectedIndex: _selectedFilter,
                onSelected: (i) {
                  setState(() => _selectedFilter = i);
                  _fetchPosts();
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: SkeletonListLoader(itemCount: 3))
                    : _posts.isEmpty
                        ? const EmptyState(
                            icon: Icons.forum_outlined,
                            title: 'No posts yet',
                            subtitle:
                                'Be the first to start a conversation!',
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchPosts,
                            color: tc.accent,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              itemCount: _posts.length,
                              itemBuilder: (_, i) =>
                                  _postCard(tc, _posts[i]),
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
            gradient: tc.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: tc.accent.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
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
              GestureDetector(
                onTap: () => _toggleLike(post),
                child: Row(children: [
                  Icon(Icons.favorite_border_rounded,
                      size: 18, color: tc.textMuted),
                  const SizedBox(width: 4),
                  Text('${post.likesCount}',
                      style: TextStyle(color: tc.textMuted, fontSize: 12)),
                ]),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => _showReplies(context, tc, post),
                child: Row(children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 18, color: tc.textMuted),
                  const SizedBox(width: 4),
                  Text('${post.repliesCount}',
                      style: TextStyle(color: tc.textMuted, fontSize: 12)),
                ]),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet to view and post replies for a forum thread.
class _RepliesSheet extends StatefulWidget {
  final ForumPost post;
  final Tc tc;
  const _RepliesSheet({required this.post, required this.tc});

  @override
  State<_RepliesSheet> createState() => _RepliesSheetState();
}

class _RepliesSheetState extends State<_RepliesSheet> {
  List<ForumReply> _replies = [];
  bool _isLoading = true;
  final _replyCtrl = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchReplies();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchReplies() async {
    try {
      final response = await ApiService().get('/forum/${widget.post.id}/replies');
      final list = response['replies'] as List;
      setState(() {
        _replies = list.map((j) => ForumReply.fromJson(j)).toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await ApiService().post('/forum/${widget.post.id}/replies', body: {'body': text});
      _replyCtrl.clear();
      await _fetchReplies();
    } catch (_) {
      // Show error via snackbar if needed
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = widget.tc;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: tc.glassBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(widget.post.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _replies.isEmpty
                    ? Center(
                        child: Text('No replies yet. Be first!',
                            style: TextStyle(color: tc.textMuted)))
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        itemCount: _replies.length,
                        itemBuilder: (_, i) {
                          final r = _replies[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: tc.accent.withValues(alpha: 0.2),
                                  child: Text(
                                    (r.authorName ?? '?')[0],
                                    style: TextStyle(
                                        color: tc.accent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.authorName ?? 'User',
                                          style: TextStyle(
                                              color: tc.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text(r.body,
                                          style: TextStyle(
                                              color: tc.textSecondary,
                                              fontSize: 13,
                                              height: 1.4)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: tc.glassWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: tc.glassBorder),
                    ),
                    child: TextField(
                      controller: _replyCtrl,
                      style: TextStyle(color: tc.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Write a reply...',
                        hintStyle:
                            TextStyle(color: tc.textMuted, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSending ? null : _sendReply,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: tc.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
