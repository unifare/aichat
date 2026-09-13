class ParsedMessage {
  final String? thinking;
  final bool isThinkingOngoing;
  final String? command;
  final String cleanContent;

  const ParsedMessage({
    this.thinking,
    this.isThinkingOngoing = false,
    this.command,
    required this.cleanContent,
  });

  static ParsedMessage parse(
    String raw, {
    String? explicitThinking,
    String? explicitCommand,
    bool isStreaming = false,
  }) {
    String content = raw;
    String? thinking = explicitThinking;
    bool isThinkingOngoing = false;
    String? command = explicitCommand;

    // 1. 提取思考内容（支持 <think>、<thinking>、<!--thinking-->）
    final thinkOpenRegex = RegExp(r'<(?:think|thinking|!--thinking--)>(.*?)(?:<\/(?:think|thinking|!--thinking--)>|$)', dotAll: true);
    final thinkMatch = thinkOpenRegex.firstMatch(content);

    if (thinkMatch != null) {
      thinking = thinkMatch.group(1)?.trim();
      final hasCloseTag = RegExp(r'<\/(?:think|thinking|!--thinking--)>').hasMatch(content);
      isThinkingOngoing = isStreaming && !hasCloseTag;

      // 从正文中移除完整思考块
      content = content.replaceAll(
        RegExp(r'<(?:think|thinking|!--thinking--)>[\s\S]*?<\/(?:think|thinking|!--thinking--)>'),
        '',
      );

      // 如果未闭合（流式进行中），移除未闭合的标签及其后内容
      if (!hasCloseTag && content.contains(RegExp(r'<(?:think|thinking|!--thinking--)>'))) {
        final openIdx = content.indexOf(RegExp(r'<(?:think|thinking|!--thinking--)>'));
        if (openIdx >= 0) {
          content = content.substring(0, openIdx);
        }
      }
    }

    // 2. 提取执行命令（支持 <command>、<cmd>、<!--command-->）
    final cmdOpenRegex = RegExp(r'<(?:command|cmd|!--command--)>(.*?)(?:<\/(?:command|cmd|!--command--)>|$)', dotAll: true);
    final cmdMatch = cmdOpenRegex.firstMatch(content);

    if (cmdMatch != null) {
      command = cmdMatch.group(1)?.trim();
      // 从正文中移除完整命令块
      content = content.replaceAll(
        RegExp(r'<(?:command|cmd|!--command--)>(.*?)<\/(?:command|cmd|!--command--)>', dotAll: true),
        '',
      );
      // 未闭合时清理尾部
      final hasCmdClose = RegExp(r'<\/(?:command|cmd|!--command--)>').hasMatch(raw);
      if (!hasCmdClose && content.contains(RegExp(r'<(?:command|cmd|!--command--)>'))) {
        final openIdx = content.indexOf(RegExp(r'<(?:command|cmd|!--command--)>'));
        if (openIdx >= 0) {
          content = content.substring(0, openIdx);
        }
      }
    }

    return ParsedMessage(
      thinking: (thinking != null && thinking.isNotEmpty) ? thinking : null,
      isThinkingOngoing: isThinkingOngoing,
      command: (command != null && command.isNotEmpty) ? command : null,
      cleanContent: content.trim(),
    );
  }
}
