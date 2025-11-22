import 'package:flutter/material.dart';

class BiometricButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const BiometricButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<BiometricButton> createState() => _BiometricButtonState();
}

class _BiometricButtonState extends State<BiometricButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Biometric authentication button
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isLoading ? 1.0 : _pulseAnimation.value,
              child: GestureDetector(
                onTap: widget.isLoading ? null : widget.onPressed,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: widget.isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Icon(
                        Icons.fingerprint,
                        color: Colors.white,
                        size: 50,
                      ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        Text(
          widget.isLoading 
            ? 'Authenticating...' 
            : 'Touch to authenticate',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF718096),
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Use your fingerprint, face, or device PIN',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF718096),
          ),
        ),
      ],
    );
  }
}
