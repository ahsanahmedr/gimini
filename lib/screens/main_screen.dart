import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_provider.dart';
import 'chat_screen.dart';
import '../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  String? _activeSessionId;

  static const _primary = Color(0xFF1D4E89);
  static const _dark = Color(0xFF0F172A);
  static const _bg = Color(0xFFF8FAFC);
  static const _sidebarBg = Color(0xFF1E2E43);
  static const _sidebarItem = Color(0xFF2A3D5A);

  void _startNewChat() {
  final session = ref.read(historyProvider.notifier).createSession();
  setState(() => _activeSessionId = session.id);
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop(); // drawer band karo
  }
}

void _openSession(String sessionId) {
  setState(() => _activeSessionId = sessionId);
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }
}

  void _deleteSession(String sessionId) {
    ref.read(historyProvider.notifier).deleteSession(sessionId);
    if (_activeSessionId == sessionId) {
      setState(() => _activeSessionId = null);
    }
  }

  @override
Widget build(BuildContext context) {
  final sessions = ref.watch(historyProvider);

  return Scaffold(
    backgroundColor: _bg,
    drawer: _buildDrawer(sessions),
    // ✅ Builder wrap karo taake drawer ka context mile
    body: Builder(
      builder: (context) {
        return _activeSessionId == null
            ? _buildWelcome(context) // ✅ context pass karo
            : ChatScreen(
                key: ValueKey(_activeSessionId),
                sessionId: _activeSessionId!,
                onMenuTap: () => Scaffold.of(context).openDrawer(),
              );
      },
    ),
  );
}

  Widget _buildDrawer(List sessions) {
    return Drawer(
      backgroundColor: _sidebarBg,
      width: 300,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.smart_toy_outlined,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'AI Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // New Chat button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: InkWell(
                onTap: _startNewChat,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Start Chat',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // History label
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Chats',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Sessions list
            Expanded(
              child: sessions.isEmpty
                  ? const Center(
                      child: Text(
                        'No chats yet',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: sessions.length,
                      itemBuilder: (_, i) {
                        final session = sessions[i];
                        final isActive = session.id == _activeSessionId;
                        return _SessionTile(
                          session: session,
                          isActive: isActive,
                          onTap: () => _openSession(session.id),
                          onDelete: () => _deleteSession(session.id),
                          activeColor: _primary,
                          itemColor: _sidebarItem,
                        );
                      },
                    ),
            ),
            Padding(
  padding: const EdgeInsets.all(12),
  child: InkWell(
    onTap: () async {
      await ref.read(authServiceProvider).logout();
      if (context.mounted) context.go('/login');
    },
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
          SizedBox(width: 10),
          Text('Logout',
              style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
        ],
      ),
    ),
  ),
),

          ],
        ),
      ),
    );
  }

  Widget _buildWelcome(BuildContext context) { // ✅ context parameter add karo
  return Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: _dark),
        onPressed: () => Scaffold.of(context).openDrawer(), // ✅ Ab kaam karega
      ),
      title: const Text(
        'AI Assistant',
        style: TextStyle(
          color: _dark,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: _primary, size: 56),
          ),
          const SizedBox(height: 24),
          const Text(
            'How can I help you?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Start a new chat or select from history',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _startNewChat,
            icon: const Icon(Icons.add),
            label: const Text('New Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}
}

// Session tile widget
class _SessionTile extends StatelessWidget {
  final dynamic session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Color activeColor;
  final Color itemColor;

  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
    required this.activeColor,
    required this.itemColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withValues(alpha: 0.2) : itemColor,
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? Border.all(color: activeColor.withValues(alpha: 0.5))
            : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(
          Icons.chat_bubble_outline_rounded,
          color: isActive ? activeColor : Colors.white38,
          size: 18,
        ),
        title: Text(
          session.title ?? 'New Chat',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight:
                isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: Colors.white30, size: 18),
          onPressed: onDelete,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        onTap: onTap,
      ),
    );
  }
}