import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/theme.dart';

/// 可折叠卡片组件，用于展示思考过程与执行命令。
/// - 高度限制（默认 130px），内容超出时内部滚动
/// - 支持展开/折叠动画与即时切换
/// - 思考态支持实时流式动效（转圈/字数统计）
/// - 命令态支持一键复制与终端样式
class ExpandablePanel extends StatefulWidget {
  const ExpandablePanel({
    super.key,
    required this.title,
    required this.content,
    this.subtitle,
    this.icon,
    this.initiallyExpanded = false,
    this.maxHeight = 130.0,
    this.isLive = false,
    this.isCommand = false,
    this.accentColor,
  });

  final String title;
  final String content;
  final String? subtitle;
  final IconData? icon;
  final bool initiallyExpanded;
  final double maxHeight;
  final bool isLive;
  final bool isCommand;
  final Color? accentColor;

  @override
  State<ExpandablePanel> createState() => _ExpandablePanelState();
}

class _ExpandablePanelState extends State<ExpandablePanel> {
  late bool _expanded;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 正在流式思考时默认展开，完成后若未指定则默认折叠
    _expanded = widget.initiallyExpanded || widget.isLive;
  }

  @override
  void didUpdateWidget(covariant ExpandablePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果刚开始进入 live 状态，自动展开以展示思考流
    if (!oldWidget.isLive && widget.isLive) {
      if (!_expanded) {
        setState(() => _expanded = true);
      }
    }
    // 流式输出中且已展开时，自动滚动到底部展示最新思考
    if (widget.isLive && _expanded && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ??
        (widget.isCommand ? const Color(0xFF10B981) : const Color(0xFF38BDF8));
    final defaultIcon = widget.isCommand
        ? Icons.terminal_rounded
        : (widget.isLive ? Icons.psychology_rounded : Icons.psychology_outlined);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isCommand
            ? const Color(0xFF090D16)
            : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _expanded ? accent.withValues(alpha: 0.35) : AppColors.border,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头部点击栏
          InkWell(
            onTap: _toggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _expanded
                    ? accent.withValues(alpha: 0.08)
                    : Colors.transparent,
                border: Border(
                  bottom: _expanded
                      ? BorderSide(color: AppColors.border.withValues(alpha: 0.6))
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon ?? defaultIcon,
                    size: 15,
                    color: accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (widget.isLive) ...[
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '思考中…',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ] else if (widget.subtitle != null) ...[
                    Text(
                      widget.subtitle!,
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ] else if (!widget.isCommand) ...[
                    Text(
                      '(${widget.content.length} 字)',
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // 命令块支持一键复制
                  if (widget.isCommand && widget.content.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      color: const Color(0xFF94A3B8),
                      tooltip: '复制命令',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: widget.content));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('命令已复制到剪贴板'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  // 折叠展开图标
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
          // 内容区域（高度受限，内部滚动）
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Container(
              constraints: BoxConstraints(maxHeight: widget.maxHeight),
              padding: const EdgeInsets.all(10),
              color: widget.isCommand
                  ? const Color(0xFF070B12)
                  : const Color(0xFF0C1322),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: SelectableText(
                    widget.content.isEmpty ? '（无内容）' : widget.content,
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      height: 1.45,
                      color: widget.isCommand
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
