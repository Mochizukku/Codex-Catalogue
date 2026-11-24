import '../../core/theme/codex_tokens.dart';

const kLandingHeadline = 'CODEX CATALOGUE';

// TODO: Replace with the official Codex Catalogue description once finalized.
const kLandingDescriptionPlaceholder =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod '
    'tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim '
    'veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea '
    'commodo consequat.\n\n'
    'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum '
    'dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non '
    'proident, sunt in culpa qui officia deserunt mollit anim id est laborum.';

class FeaturedChapterSlide {
  const FeaturedChapterSlide({
    required this.chapterLabel,
    required this.title,
    required this.originTag,
    required this.anomalyClass,
    required this.synopsis,
  });

  final String chapterLabel;
  final String title;
  final String originTag;
  final AnomalyClass anomalyClass;
  final String synopsis;
}

// TODO: Edit, replace, or clear this list once real featured chapters are ready.
const kPlaceholderFeaturedChapters = <FeaturedChapterSlide>[
  FeaturedChapterSlide(
    chapterLabel: 'CHAPTER I · PLACEHOLDER',
    title: 'Lorem Ipsum of the Obsidian Vault',
    originTag: 'Ancient Egypt',
    anomalyClass: AnomalyClass.cursed,
    synopsis:
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer nec '
        'odio. Praesent libero. Sed cursus ante dapibus diam.',
  ),
  FeaturedChapterSlide(
    chapterLabel: 'CHAPTER II · PLACEHOLDER',
    title: 'Dolor Sit Amet — Recovered Fragment',
    originTag: 'Rome',
    anomalyClass: AnomalyClass.dangerous,
    synopsis:
        'Sed nisi. Nulla quis sem at nibh elementum imperdiet. Duis sagittis '
        'ipsum. Praesent mauris. Fusce nec tellus sed augue semper porta.',
  ),
  FeaturedChapterSlide(
    chapterLabel: 'CHAPTER III · PLACEHOLDER',
    title: 'Consectetur Codex of the Outer Veil',
    originTag: 'Multiverse',
    anomalyClass: AnomalyClass.beneficial,
    synopsis:
        'Mauris massa. Vestibulum lacinia arcu eget nulla. Class aptent taciti '
        'sociosqu ad litora torquent per conubia nostra.',
  ),
];
