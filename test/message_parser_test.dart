import 'package:flutter_test/flutter_test.dart';
import 'package:aichat/core/utils/message_parser.dart';

void main() {
  group('MessageParser', () {
    test('extracts thinking from <think> tag and cleans content', () {
      const raw = '<think>\nHere is my thinking step 1\nstep 2\n</think>\nHello! How can I help?';
      final parsed = ParsedMessage.parse(raw);

      expect(parsed.thinking, 'Here is my thinking step 1\nstep 2');
      expect(parsed.isThinkingOngoing, false);
      expect(parsed.cleanContent, 'Hello! How can I help?');
    });

    test('extracts ongoing thinking during streaming when unclosed', () {
      const raw = '<think>\nThinking in progress...';
      final parsed = ParsedMessage.parse(raw, isStreaming: true);

      expect(parsed.thinking, 'Thinking in progress...');
      expect(parsed.isThinkingOngoing, true);
      expect(parsed.cleanContent, '');
    });

    test('extracts command from <command> tag and cleans content', () {
      const raw = 'Run the following command:\n<command>flutter build apk --split-per-abi</command>\nLet me know when done.';
      final parsed = ParsedMessage.parse(raw);

      expect(parsed.command, 'flutter build apk --split-per-abi');
      expect(parsed.cleanContent, 'Run the following command:\n\nLet me know when done.');
    });

    test('extracts both thinking and command together', () {
      const raw = '<think>I need to build the project</think>\nHere is what to run:\n<cmd>flutter pub get</cmd>\nAll done!';
      final parsed = ParsedMessage.parse(raw);

      expect(parsed.thinking, 'I need to build the project');
      expect(parsed.command, 'flutter pub get');
      expect(parsed.cleanContent, 'Here is what to run:\n\nAll done!');
    });

    test('handles plain text without tags', () {
      const raw = 'Just a regular plain text message.';
      final parsed = ParsedMessage.parse(raw);

      expect(parsed.thinking, isNull);
      expect(parsed.command, isNull);
      expect(parsed.cleanContent, 'Just a regular plain text message.');
    });
  });
}
