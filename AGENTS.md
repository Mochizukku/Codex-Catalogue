AGENTS.md — Flutter Token Optimization & CLI Guidelines

1. Core Mandate: Token Efficiency

You are operating via the Gemini CLI on a Flutter codebase. Your primary operational constraint is strict token efficiency across both context ingestion (input) and code/text generation (output).

2. Context Ingestion Rules (Input Token Saving)

🚫 Strictly Ignored Directories & Files

NEVER read, index, search, or include the following paths in your context unless explicitly instructed by the user with an exact file path:

Build & Cache: build/, .dart_tool/, .flutter-plugins, .flutter-plugins-dependencies, .packages

Platform Native Boilerplate: android/, ios/, web/, macos/, linux/, windows/ (Only inspect AndroidManifest.xml, Info.plist, or build.gradle if the task is specifically about native permissions/configs).

Generated Code: **/*.g.dart, **/*.freezed.dart, **/*.gr.dart, **/*.config.dart, **/*.mocks.dart, lib/generated/, lib/l10n/*.dart

Lockfiles & Assets: pubspec.lock, assets/, fonts/, **/*.png, **/*.svg, **/*.json (large mock data)

🔍 Targeted Context Gathering

Search Before Reading: Do not read entire files to find a class or method. Use grep / regex search on lib/ first to locate exact line numbers.

Read Entry Points First: If exploring a feature under lib/features/<feature_name>/, read the state/controller file or domain model before reading complex UI widget trees.

Pubspec Inspection: Read pubspec.yaml only once per session if you are unsure which state management, routing, or DI packages are installed.

3. Response & Code Generation Rules (Output Token Saving)

💬 Communication Style

Zero Fluff: Omit pleasantries, introductory summaries, and concluding remarks. Start immediately with the solution or code.

No Restating: Do not repeat the user's prompt or explain basic Flutter concepts (e.g., do not explain what StatefulWidget or BuildContext does).

Brief Explanations: If an architectural explanation is needed, use bullet points (max 1 line per bullet).

💻 Code Output Formatting

Surgical Diffs Over Full Files: When modifying existing files >50 lines, DO NOT output the entire file. Output only the modified methods/widgets using clear context markers:

// ... existing imports ...

class MyWidget extends StatelessWidget {
  // ... existing fields ...

  @override
  Widget build(BuildContext context) {
    // ONLY show the updated section
  }
}


Omit Standard Imports: Unless introducing a new third-party package or a critical ambiguous import, group or omit standard package:flutter/material.dart imports in snippet responses.

Delegate to build_runner: Never manually write out the contents of .g.dart or .freezed.dart files. Write the annotated class and instruct the user (or run the CLI command) to execute:
dart run build_runner build -d

4. Flutter Code Compactness Standards

Write concise, modern Dart 3+ code to reduce output tokens and keep source files small for future context windows:

Use const Everywhere: Aggressively apply const constructors to widgets to save rebuilds and avoid verbose builder patterns where unnecessary.

Prefer Functional Composition & Small Widgets: Break massive build() methods into smaller private StatelessWidget classes rather than deeply nested 200-line trees.

Dart 3 Syntax: Utilize records, pattern matching, switch expressions, and if-case statements to reduce boilerplate:

// Prefer concise switch expressions over verbose if-else blocks
Widget buildBody(AsyncValue<User> state) => switch (state) {
  AsyncData(:final value) => UserProfile(user: value),
  AsyncError(:final error) => ErrorView(error),
  _ => const CircularProgressIndicator(),
};


Avoid Redundant Types: Rely on Dart's type inference for local variables (final items = <String>[]; instead of final List<String> items = <String>[];).

5. CLI Tool Execution Strategy

When running shell commands via the Gemini CLI:

Targeted Analysis: Run dart analyze <specific_file_or_folder> instead of analyzing the entire project, which wastes tokens parsing unrelated warnings.

Targeted Tests: Run flutter test test/path/to/specific_test.dart --plain-name "test description" instead of running the whole test suite.

Quiet Flags: Append --suppress-analytics or quiet flags where applicable to keep stdout clean and compact.

6. Project Architecture Assumptions (Customize as needed)

Update these defaults to match your specific repo so the agent doesn't have to guess or search:

Flutter/Dart Version: Flutter 3.x / Dart 3.x (Null Safety enforced)

State Management: [e.g., Riverpod / Bloc / Provider]

Routing: [e.g., GoRouter / AutoRoute]

Data Models: [e.g., Freezed + json_serializable / Dart Mappable]

Directory Structure: Feature-first (lib/features/<feature>/{data,domain,presentation})