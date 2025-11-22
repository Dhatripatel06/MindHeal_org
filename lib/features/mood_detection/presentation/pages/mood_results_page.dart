// File: lib/features/mood_detection/presentation/pages/mood_results_page.dart
// Fetched from: uploaded:dhatripatel06/mindheal/MindHeal-e7d11e8428e1bb750da91bf0de1b159359357573/lib/features/mood_detection/presentation/pages/mood_results_page.dart
// *** MODIFIED TO REPLACE SHARE WITH ADVISER BUTTON ***

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Commented out Share Plus as it's replaced
import 'package:share_plus/share_plus.dart';
import '../../data/models/emotion_result.dart'; //
import '../providers/image_detection_provider.dart'; //
import '../../../../core/utils/emotion_utils.dart'; //

class MoodResultsPage extends StatelessWidget {
  final EmotionResult emotionResult; //
  final String? imagePath; //

  const MoodResultsPage({
    super.key,
    required this.emotionResult,
    this.imagePath,
  });

  // Share function - kept for reference if needed later
  Future<void> _shareResult(BuildContext context) async { //
    try {
      final text = 'I\'m feeling ${emotionResult.emotion}! Mood detected with ${(emotionResult.confidence * 100).toStringAsFixed(1)}% confidence via MindHeal.'; //
      if (imagePath != null && imagePath!.isNotEmpty) { //
        await Share.shareXFiles([XFile(imagePath!)], text: text); //
      } else {
        await Share.share(text); //
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar( //
        SnackBar(content: Text('Error sharing result: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // Access the provider
    final provider = Provider.of<ImageDetectionProvider>(context, listen: false);

    // Reset advice state when entering this page for a specific result.
     WidgetsBinding.instance.addPostFrameCallback((_) {
       provider.resetAdviceStateOnly(); // Ensure this method exists in your provider
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Analysis Result'), //
        backgroundColor: EmotionUtils.getEmotionColor(emotionResult.emotion).withOpacity(0.8), //
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), //
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imagePath != null) //
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: ClipRRect(
                   borderRadius: BorderRadius.circular(15.0),
                   child: Image.file(
                      File(imagePath!),
                      height: 250, // Adjust height as needed
                      fit: BoxFit.cover,
                   ),
                ),
              ),

             // --- Main Result Card ---
             _buildResultCard(context, provider, emotionResult), // Pass emotionResult here too
             // --- End Result Card ---

            const SizedBox(height: 20),

             ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Analyze Another'),
              onPressed: () => Navigator.pop(context), // Go back
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Builds the main card displaying emotion, confidence, timings, and action buttons ---
  Widget _buildResultCard(BuildContext context, ImageDetectionProvider provider, EmotionResult result) { // Added result parameter
     return Container(
       width: double.infinity,
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(20),
         boxShadow: [
           BoxShadow(
             color: Colors.grey.withOpacity(0.1),
             spreadRadius: 2,
             blurRadius: 5,
             offset: const Offset(0, 3),
           ),
         ],
       ),
       child: Column(
         mainAxisSize: MainAxisSize.min,
         children: [
           // --- Emotion Display ---
           Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon( // Using Icon based on EmotionUtils
                 EmotionUtils.getEmotionIcon(result.emotion), // Use result passed to method
                 size: 48,
                 color: EmotionUtils.getEmotionColor(result.emotion), // Use result passed to method
               ),
               const SizedBox(width: 20),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     result.emotion.toUpperCase(), // Use result passed to method
                     style: TextStyle(
                       fontSize: 30,
                       fontWeight: FontWeight.bold,
                       color: EmotionUtils.getEmotionColor(result.emotion), // Use result passed to method
                     ),
                   ),
                   Row(
                     children: [
                       Icon(Icons.check_circle_outline, color: EmotionUtils.getEmotionColor(result.emotion), size: 18), // Use result passed to method
                       const SizedBox(width: 5),
                       Text(
                         '${(result.confidence * 100).toStringAsFixed(0)}% Confidence', // Use result passed to method
                         style: TextStyle(
                           fontSize: 16,
                           color: EmotionUtils.getEmotionColor(result.emotion), // Use result passed to method
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ],
                   ),
                 ],
               ),
             ],
           ),
           const SizedBox(height: 20),

           // --- Timings ---
           Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(Icons.timer, color: Colors.grey[600], size: 18),
               const SizedBox(width: 5),
               Text(
                 '${result.processingTimeMs}ms', // Use result passed to method
                 style: TextStyle(fontSize: 14, color: Colors.grey[600]),
               ),
               const SizedBox(width: 15),
               Icon(Icons.memory, color: Colors.grey[600], size: 18),
               const SizedBox(width: 5),
               Text(
                 'EfficientNet-B0', // Model Name
                 style: TextStyle(fontSize: 14, color: Colors.grey[600]),
               ),
             ],
           ),
           const SizedBox(height: 30),

           // =================================== //
           // === ACTION BUTTONS ROW - UPDATED === //
           // =================================== //
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
             children: [
               // --- Details Button ---
               Expanded(
                 child: ElevatedButton.icon(
                   onPressed: () { //
                     _showDetailsDialog(context, result); // Use result passed to method
                   },
                   icon: const Icon(Icons.description, size: 20), //
                   label: const Text('Details'), //
                   style: ElevatedButton.styleFrom( //
                     backgroundColor: Colors.blue.shade50,
                     foregroundColor: Colors.blue.shade700,
                     padding: const EdgeInsets.symmetric(vertical: 12),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                     elevation: 0,
                   ),
                 ),
               ),
               const SizedBox(width: 15),

               // --- Save Button ---
               Expanded(
                 child: ElevatedButton.icon(
                   onPressed: () { //
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Save functionality not implemented yet.')),
                     );
                   },
                   icon: const Icon(Icons.save_alt, size: 20), //
                   label: const Text('Save'), //
                   style: ElevatedButton.styleFrom( //
                     backgroundColor: Colors.green.shade50,
                     foregroundColor: Colors.green.shade700,
                     padding: const EdgeInsets.symmetric(vertical: 12),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                     elevation: 0,
                   ),
                 ),
               ),
               const SizedBox(width: 15),

               // --- ADVISER BUTTON (Replaces Share) ---
               Expanded(
                 // Use Consumer ONLY for the button's stateful appearance/disabling
                 child: Consumer<ImageDetectionProvider>(
                    builder: (context, consumerProvider, child) {
                      return ElevatedButton.icon(
                        // Disable button while advice is being fetched
                        onPressed: consumerProvider.isFetchingAdvice
                            ? null
                            : () {
                               // Fetch advice using the mood from *this* specific result
                               consumerProvider.fetchAdviceForMood(result.emotion);
                               _showAdviceDialog(context, consumerProvider, result.emotion); // Pass emotion for Dialog Title
                             },
                        // Show progress indicator or icon based on fetching state
                        icon: consumerProvider.isFetchingAdvice
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                              )
                            : const Icon(Icons.lightbulb_outline, size: 20), // Adviser icon
                        label: const Text('Adviser'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade50,
                          foregroundColor: Colors.orange.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          disabledBackgroundColor: Colors.orange.shade50.withOpacity(0.5),
                        ),
                      );
                    }
                  ),
               ),
               // --- END ADVISER BUTTON ---
             ],
           ),
           // --- End Action Buttons Row ---
         ],
       ),
     );
  }

  // --- Shows the breakdown of all emotion probabilities ---
  void _showDetailsDialog(BuildContext context, EmotionResult result) {
    // Sort emotions by confidence (highest first) using original probabilities
    final sortedEmotions = result.allEmotions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emotion Breakdown'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: sortedEmotions.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    SizedBox(width: 80, child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: entry.value, // Use the original probability from allEmotions
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(EmotionUtils.getEmotionColor(entry.key)),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(width: 45, child: Text('${(entry.value * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.right)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [ TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')) ],
      ),
    );
  }

  // --- Shows the Gemini advice, language selector, and TTS controls ---
  void _showAdviceDialog(BuildContext context, ImageDetectionProvider provider, String emotionForTitle) { // Added emotionForTitle
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          // Use the emotion passed for the title
          title: Text('$emotionForTitle Adviser'),
          // Use Consumer for content that needs to rebuild
          content: Consumer<ImageDetectionProvider>(
            builder: (ctx, p, child) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                   constraints: const BoxConstraints(minHeight: 100), // Min height
                   child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Show loading indicator WHILE fetching
                        if (p.isFetchingAdvice)
                          const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()))
                        // Show advice text AFTER fetching is done and text is available
                        else if (p.adviceText != null && p.adviceText!.isNotEmpty && !p.adviceText!.startsWith("Error"))
                           Padding(
                             padding: const EdgeInsets.symmetric(vertical: 8.0),
                             child: Text(p.adviceText!, textAlign: TextAlign.center),
                           )
                        // Show error message if fetching failed (check adviceText content)
                        else if (p.adviceText != null && p.adviceText!.startsWith("Error"))
                           Padding(
                             padding: const EdgeInsets.symmetric(vertical: 8.0),
                             child: Text(p.adviceText!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)
                           )
                        // Initial state or unexpected failure
                        else
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('Could not fetch advice. Please try again or select a language.', textAlign: TextAlign.center),
                          ),
                        const SizedBox(height: 20),
                        // Always show language selector
                        _buildLanguageSelector(p, emotionForTitle), // Pass emotion for refetch
                      ],
                   ),
                ),
              );
            },
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween, // Align buttons nicely
          actions: <Widget>[
            // --- Read Aloud / Stop Button ---
            Consumer<ImageDetectionProvider>(
              builder: (ctx, p, child) {
                // Enable only if there's valid advice text and not fetching
                bool canSpeak = p.adviceText != null && p.adviceText!.isNotEmpty && !p.adviceText!.startsWith("Error") && !p.isFetchingAdvice;
                return IconButton(
                  icon: Icon(
                    p.isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
                    color: p.isSpeaking ? Colors.redAccent : Colors.deepPurple,
                  ),
                  iconSize: 30,
                  tooltip: p.isSpeaking ? 'Stop' : 'Read Aloud',
                  onPressed: canSpeak
                      ? (p.isSpeaking ? p.stopSpeaking : p.speakAdvice)
                      : null, // Disable if cannot speak
                );
              },
            ),
            // --- Close Button ---
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                provider.stopSpeaking(); // Stop TTS before closing
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
       // Ensure TTS stops if dialog is dismissed by other means (e.g., back button)
       provider.stopSpeaking();
    });
  }

  // --- Builds the language dropdown ---
  Widget _buildLanguageSelector(ImageDetectionProvider provider, String currentMood) { // Added currentMood
    return DropdownButton<String>(
      value: provider.selectedLanguage,
      icon: const Icon(Icons.language, color: Colors.deepPurple, size: 20),
      dropdownColor: Colors.deepPurple.shade50,
      underline: Container(), // Removes underline
      isExpanded: true, // Makes dropdown take available width
      // Disable dropdown while fetching or speaking
      onChanged: provider.isFetchingAdvice || provider.isSpeaking
          ? null
          : (String? newValue) {
              if (newValue != null && newValue != provider.selectedLanguage) {
                provider.setLanguage(newValue);
                // Automatically refetch advice for the new language FOR THIS MOOD
                 provider.fetchAdviceForMood(currentMood); // Use the passed mood
              }
            },
      items: provider.availableLanguages
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Center( // Center text within dropdown
            child: Text(
                value,
                style: const TextStyle(color: Colors.deepPurple, fontSize: 14),
            ),
          ),
        );
      }).toList(),
    );
  }
} // End of MoodResultsPage