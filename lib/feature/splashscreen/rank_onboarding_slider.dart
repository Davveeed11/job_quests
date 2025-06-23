import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_job_quest/feature/splashscreen/domain/rank_dart.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class RankOnboardingSlider extends StatefulWidget {
  final VoidCallback onOnboardingComplete;

  const RankOnboardingSlider({super.key, required this.onOnboardingComplete});

  @override
  State<RankOnboardingSlider> createState() => _RankOnboardingSliderState();
}

class _RankOnboardingSliderState extends State<RankOnboardingSlider>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;

  late AnimationController _pulseController;
  late AnimationController _coinController;
  late AnimationController _fadeController;
  late AnimationController
  _cardContentEnterController; // New controller for content animation

  late Animation<double> _pulseAnimation;
  late Animation<double> _coinAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset>
  _cardContentSlideAnimation; // New animation for content slide
  late Animation<double>
  _cardContentFadeAnimation; // New animation for content fade

  static final List<RankData> _ranks = <RankData>[
    RankData(
      rank: 'E',
      title: 'Entry-Level',
      subtitle: 'Learner',
      description:
          'Perfect for beginners, those changing careers, or students looking to gain foundational experience.',
      analogy: 'The Tutorial Level',
      basePrice: 40000,
      maxPrice: 65000,
      color: const Color(0xFF4CAF50), // Green
      icon: Icons.school,
    ),
    RankData(
      rank: 'D',
      title: 'Developing',
      subtitle: 'Apprentice',
      description:
          'For those with basic skills and some practical experience. Jobs might require solving simple problems independently.',
      analogy: 'Building Your Core Skills',
      basePrice: 70000,
      maxPrice: 95000,
      color: const Color(0xFF2196F3), // Blue
      icon: Icons.build,
    ),
    RankData(
      rank: 'C',
      title: 'Competent',
      subtitle: 'Journeyman',
      description:
          'Solid professionals who can handle standard tasks independently with a good grasp of fundamentals.',
      analogy: 'The Reliable Performer',
      basePrice: 100000,
      maxPrice: 150000,
      color: const Color(0xFF9C27B0), // Purple
      icon: Icons.work,
    ),
    RankData(
      rank: 'B',
      title: 'Proficient',
      subtitle: 'Specialist',
      description:
          'Experienced professionals who excel in their domain and can handle complex projects effectively.',
      analogy: 'The Go-To Expert',
      basePrice: 160000,
      maxPrice: 250000,
      color: const Color(0xFFFF9800), // Orange
      icon: Icons.star,
    ),
    RankData(
      rank: 'A',
      title: 'Advanced',
      subtitle: 'Expert',
      description:
          'Highly skilled individuals capable of leading projects and solving challenging problems.',
      analogy: 'The Master Craftsman',
      basePrice: 280000,
      maxPrice: 450000,
      color: const Color(0xFFFF5722), // Deep Orange
      icon: Icons.trending_up,
    ),
    RankData(
      rank: 'S',
      title: 'Superior',
      subtitle: 'Innovator',
      description:
          'Top-tier professionals who are recognized leaders and drive significant innovation.',
      analogy: 'The Trailblazer',
      basePrice: 500000,
      maxPrice: 800000,
      color: const Color(0xFFE91E63), // Pink
      icon: Icons.lightbulb,
    ),
    RankData(
      rank: 'SS',
      title: 'Supreme',
      subtitle: 'Visionary',
      description:
          'Rare individuals who excel and shape the future of their field with groundbreaking ideas.',
      analogy: 'The Architect of Tomorrow',
      basePrice: 850000,
      maxPrice: 1200000,
      color: const Color(0xFF673AB7), // Deep Purple
      icon: Icons.auto_awesome,
    ),
    RankData(
      rank: 'SSS',
      title: 'Elite',
      subtitle: 'Pioneer',
      description:
          'The absolute pinnacle of expertise. Pioneers and thought leaders who create new methodologies.',
      analogy: 'The Living Legend',
      basePrice: 1300000,
      maxPrice: 2000000,
      color: const Color(0xFFFFD700), // Gold
      icon: Icons.diamond,
    ),
  ];

  // Cache responsive flags to avoid recalculation
  bool _isTablet = false;
  bool _isSmallScreen = false; // screen height < 700
  bool _isVerySmallScreen = false; // screen height < 600
  bool _responsiveFlagsInitialized = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeAnimations();

    // New controller and animations for card content entrance
    _cardContentEnterController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _cardContentSlideAnimation =
        Tween<Offset>(
          begin: const Offset(0.0, 0.05), // Start slightly below
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _cardContentEnterController,
            curve: Curves.easeOutCubic,
          ),
        );
    _cardContentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardContentEnterController,
        curve: Curves.easeIn,
      ),
    );

    // Initial animation for the first card
    _cardContentEnterController.forward();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _coinController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _coinAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _coinController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _coinController.dispose();
    _fadeController.dispose();
    _cardContentEnterController.dispose(); // Dispose new controller
    super.dispose();
  }

  void _onPageChanged(int page) {
    if (!mounted) return;

    setState(() {
      _currentPage = page;
    });

    _triggerHapticFeedback(page);
    _coinController.reset();
    _coinController.forward();
    _cardContentEnterController.reset(); // Reset and play new content animation
    _cardContentEnterController.forward();
  }

  void _triggerHapticFeedback(int rankIndex) {
    if (rankIndex >= 5) {
      HapticFeedback.heavyImpact();
    } else if (rankIndex >= 3) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  RankData get currentRank => _ranks[_currentPage];

  String _formatPrice(int price) {
    if (price >= 1000000) {
      return '₦${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '₦${(price / 1000).toStringAsFixed(0)}K';
    }
    return '₦$price';
  }

  void _initializeResponsiveFlags(BuildContext context) {
    if (_responsiveFlagsInitialized) return;

    final screenSize = MediaQuery.of(context).size;
    _isTablet = screenSize.width > 600;
    _isSmallScreen = screenSize.height < 700;
    _isVerySmallScreen = screenSize.height < 600;
    _responsiveFlagsInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    _initializeResponsiveFlags(context);

    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;
    final availableHeight = screenSize.height - safeArea.top - safeArea.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, // Changed for more dynamic feel
            end: Alignment.bottomRight, // Changed
            colors: [
              currentRank.color.withOpacity(
                0.15,
              ), // Slightly more prominent rank color hint
              Theme.of(context).colorScheme.surface,
              Theme.of(context)
                  .colorScheme
                  .surface, // Added another surface for smoother transition
              currentRank.color.withOpacity(0.05), // Subtle hint at the end
            ],
            stops: const [0.0, 0.4, 0.7, 1.0], // Control gradient spread
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildPageView(context, availableHeight)),
                _buildPageIndicator(context),
                SizedBox(height: _isVerySmallScreen ? 8 : 16),
                _buildContinueButton(context),
                SizedBox(height: _isVerySmallScreen ? 12 : 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _isTablet ? 32.0 : 20.0,
        vertical: _isSmallScreen ? 12.0 : 20.0,
      ),
      child: Column(
        children: [
          Text(
            'Discover Your Rank',
            style: TextStyle(
              fontSize: _isTablet ? 32 : (_isSmallScreen ? 24 : 28),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _isSmallScreen ? 4 : 8),
          Text(
            'Find jobs that match your skill level',
            style: TextStyle(
              fontSize: _isTablet ? 16 : (_isSmallScreen ? 13 : 15),
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageView(BuildContext context, double availableHeight) {
    return SizedBox(
      height: availableHeight * 0.65,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: _ranks.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: _isTablet ? 32.0 : 20.0),
            child: _buildRankCard(context, _ranks[index]),
          );
        },
      ),
    );
  }

  Widget _buildRankCard(BuildContext context, RankData rank) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        // Apply pulse effect only to the current card
        final scale = rank == currentRank ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: _isVerySmallScreen ? 8 : 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: rank.color.withOpacity(
                    0.3,
                  ), // Stronger, more colored shadow
                  blurRadius: 30, // Increased blur
                  offset: const Offset(0, 15), // Increased offset
                  spreadRadius: -5, // Creates a subtle inner glow/lift effect
                ),
                BoxShadow(
                  // Secondary subtle shadow for general depth
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                // Subtle border related to rank color
                color: rank.color.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(
                _isTablet ? 32 : (_isSmallScreen ? 16 : 24),
              ),
              child:
                  // Apply new entry animations to the card's content
                  SlideTransition(
                    position: _cardContentSlideAnimation,
                    child: FadeTransition(
                      opacity: _cardContentFadeAnimation,
                      child: _isVerySmallScreen
                          ? _buildCompactLayout(context, rank)
                          : _buildStandardLayout(context, rank),
                    ),
                  ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStandardLayout(BuildContext context, RankData rank) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildRankBadge(context, rank),
        SizedBox(height: _isSmallScreen ? 12 : 20),
        _buildTitleSection(context, rank),
        SizedBox(height: _isSmallScreen ? 8 : 12),
        _buildAnalogySection(context, rank),
        SizedBox(height: _isSmallScreen ? 12 : 16),
        _buildDescriptionSection(context, rank),
        SizedBox(height: _isSmallScreen ? 16 : 20),
        _buildPriceSection(context, rank),
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context, RankData rank) {
    return SingleChildScrollView(
      // Ensure scrolling is possible if content overflows on very small screens
      child: Column(
        children: [
          Row(
            children: [
              _buildRankBadge(context, rank, isCompact: true),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(context, rank, isCompact: true),
                    const SizedBox(height: 6),
                    _buildAnalogySection(context, rank, isCompact: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDescriptionSection(context, rank, isCompact: true),
          const SizedBox(height: 12),
          _buildPriceSection(context, rank, isCompact: true),
        ],
      ),
    );
  }

  Widget _buildRankBadge(
    BuildContext context,
    RankData rank, {
    bool isCompact = false,
  }) {
    double size = _isTablet ? 100 : (_isSmallScreen ? 70 : 85);
    if (isCompact) size *= 0.8;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Radial gradient for more depth
        gradient: RadialGradient(
          colors: [
            rank.color.withOpacity(0.9), // Core color
            rank.color,
            rank.color.withOpacity(0.8), // Slightly darker edge
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: rank.color.withOpacity(0.6), // Stronger shadow for the badge
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            rank.rank,
            style: TextStyle(
              fontSize: size * 0.28, // Slightly larger rank letter
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 2.0,
                  color: Colors.black38,
                ),
              ],
            ),
          ),
          Icon(
            rank.icon,
            color: Colors.white,
            size: size * 0.22,
          ), // Slightly larger icon
        ],
      ),
    );
  }

  Widget _buildTitleSection(
    BuildContext context,
    RankData rank, {
    bool isCompact = false,
  }) {
    return Column(
      crossAxisAlignment: isCompact
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          rank.title,
          style: TextStyle(
            fontSize: _isTablet
                ? 26
                : (_isSmallScreen ? 20 : 22), // Adjusted sizes
            fontWeight: FontWeight.bold,
            color: rank.color,
          ),
          textAlign: isCompact ? TextAlign.left : TextAlign.center,
        ),
        Text(
          rank.subtitle,
          style: TextStyle(
            fontSize: _isTablet
                ? 17
                : (_isSmallScreen ? 13 : 15), // Adjusted sizes
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontStyle: FontStyle.italic,
          ),
          textAlign: isCompact ? TextAlign.left : TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(
    BuildContext context,
    RankData rank, {
    bool isCompact = false,
  }) {
    return Text(
      rank.description,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: _isTablet
            ? 16
            : (_isSmallScreen ? 12.5 : 14), // Adjusted sizes
        color: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.85), // Slightly less transparent
        height: 1.45, // Slightly increased line height for readability
      ),
      maxLines: isCompact ? 3 : null,
      overflow: isCompact ? TextOverflow.ellipsis : null,
    );
  }

  Widget _buildAnalogySection(
    BuildContext context,
    RankData rank, {
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isTablet ? 20 : 16, // Increased padding
        vertical: _isTablet ? 10 : 8, // Increased padding
      ),
      decoration: BoxDecoration(
        color: rank.color.withOpacity(0.12), // Slightly more opaque
        borderRadius: BorderRadius.circular(20), // Slightly more rounded
        border: Border.all(
          color: rank.color.withOpacity(0.4),
          width: 1.2,
        ), // Thicker border
      ),
      child: Text(
        '"${rank.analogy}"',
        style: TextStyle(
          fontSize: _isTablet
              ? 14
              : (_isSmallScreen ? 11 : 12), // Adjusted sizes
          color: rank.color,
          fontWeight: FontWeight.w600, // Slightly bolder
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPriceSection(
    BuildContext context,
    RankData rank, {
    bool isCompact = false,
  }) {
    return AnimatedBuilder(
      animation: _coinAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: rank == currentRank ? _coinAnimation.value : 1.0,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: _isTablet ? 16 : (_isSmallScreen ? 10 : 12),
              horizontal: _isTablet
                  ? 20
                  : (_isSmallScreen ? 16 : 18), // Added horizontal padding
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.darken(
                    5,
                  ), // Slightly darker primary start
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.lighten(
                    5,
                  ), // Slightly lighter primary end
                ],
                begin: Alignment.bottomLeft, // Changed gradient direction
                end: Alignment.topRight,
              ),
              borderRadius: BorderRadius.circular(16), // Slightly more rounded
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.4), // Stronger shadow
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize:
                  MainAxisSize.min, // Make row only as wide as its children
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.attach_money,
                  color: Colors.white,
                  size: _isTablet
                      ? 24
                      : (_isSmallScreen ? 18 : 20), // Adjusted size
                ),
                const SizedBox(width: 8), // Increased spacing
                Flexible(
                  child: Text(
                    '${_formatPrice(rank.basePrice)} - ${_formatPrice(rank.maxPrice)}',
                    style: TextStyle(
                      fontSize: _isTablet
                          ? 18
                          : (_isSmallScreen ? 14 : 16), // Adjusted size
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2.0,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: _isVerySmallScreen ? 8 : 16),
      child: Column(
        children: [
          Text(
            'Swipe to explore ranks',
            style: TextStyle(
              fontSize: _isTablet ? 17 : 15, // Adjusted size
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SmoothPageIndicator(
            controller: _pageController,
            count: _ranks.length,
            effect: WormEffect(
              dotColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.3),
              activeDotColor:
                  currentRank.color, // Dot color matches current rank
              dotHeight: _isTablet ? 10 : 8,
              dotWidth: _isTablet ? 10 : 8,
              spacing: _isTablet ? 12 : 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _isTablet ? 32.0 : 20.0),
      width: double.infinity,
      height: _isTablet
          ? 60
          : (_isSmallScreen ? 50 : 56), // Increased height slightly
      child: ElevatedButton(
        onPressed: () async {
          try {
            HapticFeedback.selectionClick();
            await Future.delayed(const Duration(milliseconds: 50));
            if (mounted) {
              widget.onOnboardingComplete();
            }
          } catch (e) {
            debugPrint('Error in button onPressed: $e');
            if (mounted) {
              widget.onOnboardingComplete();
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18), // Slightly more rounded
          ),
          elevation: 12, // Increased elevation for more lift
          shadowColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.4), // Stronger shadow
        ),
        child: Text(
          'Continue to Jobs',
          style: TextStyle(
            fontSize: _isTablet
                ? 20
                : (_isSmallScreen ? 16 : 18), // Adjusted size
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Extension to darken/lighten colors (optional, but useful for gradients)
extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Color lighten([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }
}
