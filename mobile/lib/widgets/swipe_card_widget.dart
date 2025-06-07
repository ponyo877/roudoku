import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../models/swipe.dart';

enum SwipeDirection { left, right, up, down }

class SwipeCardWidget extends StatefulWidget {
  final QuoteWithBook quoteWithBook;
  final Function(SwipeChoice, int)? onSwipe;
  final VoidCallback? onTap;
  final bool isTopCard;
  final double stackIndex;

  const SwipeCardWidget({
    Key? key,
    required this.quoteWithBook,
    this.onSwipe,
    this.onTap,
    this.isTopCard = false,
    this.stackIndex = 0,
  }) : super(key: key);

  @override
  State<SwipeCardWidget> createState() => _SwipeCardWidgetState();
}

class _SwipeCardWidgetState extends State<SwipeCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _positionController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _overlayController;

  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _overlayAnimation;

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  SwipeDirection? _currentSwipeDirection;
  DateTime? _swipeStartTime;

  // Swipe thresholds
  static const double _swipeThreshold = 100.0;
  static const double _rotationFactor = 0.1;
  static const double _maxRotation = 0.3;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _positionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _positionController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0 - (widget.stackIndex * 0.05),
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOut,
    ));

    _overlayAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeOut,
    ));

    // Auto-scale up if this becomes the top card
    if (widget.isTopCard) {
      _scaleController.forward();
    }
  }

  @override
  void didUpdateWidget(SwipeCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update scale animation when stack position changes
    _scaleAnimation = Tween<double>(
      begin: _scaleAnimation.value,
      end: 1.0 - (widget.stackIndex * 0.05),
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));

    if (widget.isTopCard && !oldWidget.isTopCard) {
      _scaleController.forward();
    }
  }

  @override
  void dispose() {
    _positionController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _overlayController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isTopCard) return;
    
    _isDragging = true;
    _swipeStartTime = DateTime.now();
    _dragOffset = Offset.zero;
    _currentSwipeDirection = null;
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isTopCard || !_isDragging) return;

    setState(() {
      _dragOffset += details.delta;
    });

    // Determine swipe direction and provide feedback
    final direction = _getSwipeDirection(_dragOffset);
    if (direction != _currentSwipeDirection) {
      _currentSwipeDirection = direction;
      _updateOverlayAnimation(direction);
      
      // Provide haptic feedback when crossing threshold
      if (_shouldTriggerHaptic(direction)) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isTopCard || !_isDragging) return;

    _isDragging = false;
    final direction = _getSwipeDirection(_dragOffset);
    final velocity = details.velocity.pixelsPerSecond;
    
    // Calculate swipe duration
    final swipeDuration = _swipeStartTime != null
        ? DateTime.now().difference(_swipeStartTime!).inMilliseconds
        : null;

    // Determine if swipe should be accepted
    final shouldAcceptSwipe = _shouldAcceptSwipe(_dragOffset, velocity);
    
    if (shouldAcceptSwipe && direction != null) {
      _performSwipe(direction, swipeDuration);
    } else {
      _resetCard();
    }
  }

  SwipeDirection? _getSwipeDirection(Offset offset) {
    const threshold = 30.0;
    
    if (offset.dx.abs() > offset.dy.abs()) {
      // Horizontal swipe
      if (offset.dx > threshold) {
        return SwipeDirection.right;
      } else if (offset.dx < -threshold) {
        return SwipeDirection.left;
      }
    } else {
      // Vertical swipe
      if (offset.dy < -threshold) {
        return SwipeDirection.up;
      } else if (offset.dy > threshold) {
        return SwipeDirection.down;
      }
    }
    
    return null;
  }

  bool _shouldAcceptSwipe(Offset offset, Velocity velocity) {
    // Accept swipe if distance or velocity threshold is met
    const distanceThreshold = _swipeThreshold;
    const velocityThreshold = 500.0;
    
    final distance = offset.distance;
    final speed = velocity.pixelsPerSecond.distance;
    
    return distance > distanceThreshold || speed > velocityThreshold;
  }

  bool _shouldTriggerHaptic(SwipeDirection? direction) {
    if (direction == null) return false;
    
    final distance = _dragOffset.distance;
    return distance > _swipeThreshold * 0.7; // Trigger at 70% of threshold
  }

  void _updateOverlayAnimation(SwipeDirection? direction) {
    if (direction != null) {
      _overlayController.forward();
    } else {
      _overlayController.reverse();
    }
  }

  void _performSwipe(SwipeDirection direction, int? duration) {
    SwipeChoice choice;
    Offset targetOffset;
    double targetRotation = 0.0;

    switch (direction) {
      case SwipeDirection.left:
        choice = SwipeChoice.dislike;
        targetOffset = const Offset(-2.0, 0.0);
        targetRotation = -_maxRotation;
        break;
      case SwipeDirection.right:
        choice = SwipeChoice.like;
        targetOffset = const Offset(2.0, 0.0);
        targetRotation = _maxRotation;
        break;
      case SwipeDirection.up:
        choice = SwipeChoice.love;
        targetOffset = const Offset(0.0, -2.0);
        break;
      case SwipeDirection.down:
        choice = SwipeChoice.skip;
        targetOffset = const Offset(0.0, 2.0);
        break;
    }

    // Animate card off screen
    _positionAnimation = Tween<Offset>(
      begin: _dragOffset / MediaQuery.of(context).size.width,
      end: targetOffset,
    ).animate(CurvedAnimation(
      parent: _positionController,
      curve: Curves.easeInCubic,
    ));

    _rotationAnimation = Tween<double>(
      begin: _getRotationFromOffset(_dragOffset),
      end: targetRotation,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOut,
    ));

    // Trigger animations
    _positionController.forward();
    _rotationController.forward();
    _overlayController.forward();

    // Provide strong haptic feedback
    HapticFeedback.heavyImpact();

    // Notify parent widget
    if (widget.onSwipe != null) {
      widget.onSwipe!(choice, duration ?? 0);
    }
  }

  void _resetCard() {
    setState(() {
      _dragOffset = Offset.zero;
      _currentSwipeDirection = null;
    });
    
    _overlayController.reverse();
    
    // Light haptic feedback for reset
    HapticFeedback.lightImpact();
  }

  double _getRotationFromOffset(Offset offset) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rotation = (offset.dx / screenWidth) * _rotationFactor;
    return rotation.clamp(-_maxRotation, _maxRotation);
  }

  Color _getOverlayColor(SwipeDirection? direction) {
    switch (direction) {
      case SwipeDirection.left:
        return Colors.red.withOpacity(0.7);
      case SwipeDirection.right:
        return Colors.green.withOpacity(0.7);
      case SwipeDirection.up:
        return Colors.purple.withOpacity(0.7);
      case SwipeDirection.down:
        return Colors.orange.withOpacity(0.7);
      default:
        return Colors.transparent;
    }
  }

  IconData _getOverlayIcon(SwipeDirection? direction) {
    switch (direction) {
      case SwipeDirection.left:
        return Icons.close;
      case SwipeDirection.right:
        return Icons.favorite;
      case SwipeDirection.up:
        return Icons.favorite_border;
      case SwipeDirection.down:
        return Icons.keyboard_arrow_down;
      default:
        return Icons.help;
    }
  }

  String _getOverlayText(SwipeDirection? direction) {
    switch (direction) {
      case SwipeDirection.left:
        return 'NOPE';
      case SwipeDirection.right:
        return 'LIKE';
      case SwipeDirection.up:
        return 'LOVE';
      case SwipeDirection.down:
        return 'SKIP';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _positionController,
        _scaleController,
        _rotationController,
        _overlayController,
      ]),
      builder: (context, child) {
        // Calculate current position
        final currentPosition = _isDragging
            ? _dragOffset / screenSize.width
            : _positionAnimation.value;

        // Calculate current rotation
        final currentRotation = _isDragging
            ? _getRotationFromOffset(_dragOffset)
            : _rotationAnimation.value;

        return Transform.translate(
          offset: currentPosition * screenSize.width,
          child: Transform.rotate(
            angle: currentRotation,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onTap: widget.onTap,
                child: Semantics(
                  label: 'Quote card from ${widget.quoteWithBook.book.title} by ${widget.quoteWithBook.book.author}',
                  hint: 'Tap to view details. Swipe left to dislike, right to like, up to love, down to skip.',
                  child: Container(
                  width: screenSize.width * 0.85,
                  height: screenSize.height * 0.7,
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, widget.stackIndex * 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Card content
                        _buildCardContent(),
                        
                        // Swipe overlay
                        if (_currentSwipeDirection != null)
                          _buildSwipeOverlay(),
                      ],
                    ),
                  ),
                ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Alternative accessibility method for performing swipe actions via buttons
  void _performAccessibleSwipe(SwipeChoice choice) {
    if (!widget.isTopCard) return;
    
    final duration = _swipeStartTime != null
        ? DateTime.now().difference(_swipeStartTime!).inMilliseconds
        : 0;
    
    // Provide haptic feedback
    HapticFeedback.mediumImpact();
    
    // Notify parent widget
    if (widget.onSwipe != null) {
      widget.onSwipe!(choice, duration);
    }
  }

  Widget _buildCardContent() {
    final quote = widget.quoteWithBook.quote;
    final book = widget.quoteWithBook.book;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book info header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                book.author,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Book title
            Text(
              book.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 24),
            
            // Quote text
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Semantics(
                    label: 'Quote text: ${quote.text}',
                    readOnly: true,
                    child: Text(
                      quote.text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        height: 1.6,
                        color: Colors.grey.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quote info
            if (quote.chapterTitle != null) ...[
              Text(
                'From: ${quote.chapterTitle}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            
            // Swipe instructions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSwipeHint(Icons.close, 'Nope', Colors.red.shade300),
                _buildSwipeHint(Icons.keyboard_arrow_down, 'Skip', Colors.orange.shade300),
                _buildSwipeHint(Icons.favorite, 'Like', Colors.green.shade300),
                _buildSwipeHint(Icons.favorite_border, 'Love', Colors.purple.shade300),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeHint(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeOverlay() {
    return AnimatedBuilder(
      animation: _overlayAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _overlayAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: _getOverlayColor(_currentSwipeDirection),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getOverlayIcon(_currentSwipeDirection),
                    color: Colors.white,
                    size: 60,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getOverlayText(_currentSwipeDirection),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}