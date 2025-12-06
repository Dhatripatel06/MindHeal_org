import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioHealingPage extends StatefulWidget {
  const AudioHealingPage({super.key});

  @override
  State<AudioHealingPage> createState() => _AudioHealingPageState();
}

class _AudioHealingPageState extends State<AudioHealingPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentTrackId;
  String _currentTrackName = 'No track selected';
  double _volume = 0.7;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  List<Map<String, dynamic>> _audioTracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    _loadUserTracks();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _position = position);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });

    _audioPlayer.setVolume(_volume);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadUserTracks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ No user logged in, cannot load tracks');
      setState(() => _isLoading = false);
      return;
    }

    try {
      print('📂 Loading audio tracks for user: ${user.uid}');
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('audio_tracks')
          .orderBy('uploadedAt', descending: true)
          .get();

      print('✅ Found ${snapshot.docs.length} tracks in Firestore');

      setState(() {
        _audioTracks = snapshot.docs.map((doc) {
          final data = doc.data();
          final filePath = data['filePath'] ?? '';
          print('📁 Track: ${data['name']}, Path: $filePath');
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown',
            'filePath': filePath,
            'duration': data['duration'] ?? '0:00',
            'uploadedAt': data['uploadedAt'],
          };
        }).toList();
        _isLoading = false;
      });

      // Verify files exist
      for (var track in _audioTracks) {
        final file = File(track['filePath']);
        final exists = await file.exists();
        if (!exists) {
          print('⚠️ File missing: ${track['name']} at ${track['filePath']}');
        } else {
          print('✅ File exists: ${track['name']}');
        }
      }
    } catch (e) {
      print('❌ Error loading tracks: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadAudio() async {
    try {
      print('📤 Opening file picker...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        print('❌ No file selected');
        return;
      }

      final file = result.files.first;
      final tempFilePath = file.path;
      print('✅ File picked: ${file.name}');

      if (tempFilePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to access file')),
        );
        return;
      }

      // Copy file to permanent app directory
      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${appDir.path}/audio_tracks');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
        print('📁 Created audio directory: ${audioDir.path}');
      }

      final fileName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final permanentPath = '${audioDir.path}/${timestamp}_$fileName';

      print('💾 Copying file to: $permanentPath');
      // Copy the file
      await File(tempFilePath).copy(permanentPath);
      print('✅ File copied successfully');

      // Verify file exists
      final copiedFile = File(permanentPath);
      final exists = await copiedFile.exists();
      print('🔍 File exists after copy: $exists');

      // Get track duration
      await _audioPlayer.setSourceDeviceFile(permanentPath);
      final duration = await _audioPlayer.getDuration();
      await _audioPlayer.stop();

      final durationStr = duration != null
          ? '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
          : '0:00';

      // Save to Firestore with permanent path
      await _saveTrackToFirestore(
        name: file.name,
        filePath: permanentPath,
        duration: durationStr,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${file.name} added successfully! 🎵')),
      );

      // Reload tracks
      await _loadUserTracks();
    } catch (e) {
      print('Error picking audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _saveTrackToFirestore({
    required String name,
    required String filePath,
    required String duration,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ No user logged in, cannot save to Firestore');
      return;
    }

    try {
      print('💾 Saving track to Firestore...');
      print('   User: ${user.uid}');
      print('   Name: $name');
      print('   Path: $filePath');
      print('   Duration: $duration');

      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('audio_tracks')
          .add({
        'name': name,
        'filePath': filePath,
        'duration': duration,
        'uploadedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Track saved to Firestore with ID: ${docRef.id}');
    } catch (e) {
      print('❌ Error saving to Firestore: $e');
      rethrow;
    }
  }

  Future<void> _deleteTrack(String trackId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get track info before deleting
      final track = _audioTracks.firstWhere((t) => t['id'] == trackId);
      final filePath = track['filePath'];

      // Stop if currently playing
      if (_currentTrackId == trackId && _isPlaying) {
        await _audioPlayer.stop();
        setState(() {
          _isPlaying = false;
          _currentTrackId = null;
          _currentTrackName = 'No track selected';
        });
      }

      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('audio_tracks')
          .doc(trackId)
          .delete();

      // Delete physical file
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting file: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Track deleted')),
      );

      await _loadUserTracks();
    } catch (e) {
      print('Error deleting track: $e');
    }
  }

  Future<void> _playTrack(Map<String, dynamic> track) async {
    try {
      final filePath = track['filePath'];

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Audio file not found. Please delete and re-upload this track.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      if (_currentTrackId == track['id']) {
        // Same track - toggle play/pause
        if (_isPlaying) {
          await _audioPlayer.pause();
          setState(() => _isPlaying = false);
        } else {
          await _audioPlayer.resume();
          setState(() => _isPlaying = true);
        }
      } else {
        // Different track - play new one
        await _audioPlayer.stop();
        await _audioPlayer.setSourceDeviceFile(filePath);
        await _audioPlayer.resume();
        setState(() {
          _currentTrackId = track['id'];
          _currentTrackName = track['name'];
          _isPlaying = true;
        });
      }
    } catch (e) {
      print('Error playing track: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: $e')),
      );
    }
  }

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _position = Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds % 60);
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Healing'),
        actions: [
          IconButton(
            onPressed: _pickAndUploadAudio,
            icon: const Icon(Icons.upload_file),
            tooltip: 'Upload Audio',
          ),
        ],
      ),
      body: Column(
        children: [
          // Track List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _audioTracks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_note,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Audio Tracks Yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the upload button to add your music',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _pickAndUploadAudio,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Upload Audio'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _audioTracks.length,
                        itemBuilder: (context, index) {
                          final track = _audioTracks[index];
                          final isCurrentTrack = track['id'] == _currentTrackId;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isCurrentTrack
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1)
                                : null,
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.music_note,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                track['name'],
                                style: TextStyle(
                                  fontWeight: isCurrentTrack
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isCurrentTrack
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(track['duration']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Play/Pause button
                                  if (isCurrentTrack)
                                    IconButton(
                                      icon: Icon(
                                        _isPlaying
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_filled,
                                        size: 32,
                                      ),
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      onPressed: () => _playTrack(track),
                                    )
                                  else
                                    IconButton(
                                      icon: const Icon(
                                          Icons.play_circle_outline,
                                          size: 32),
                                      onPressed: () => _playTrack(track),
                                    ),
                                  // Delete button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.red,
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Track'),
                                          content: Text(
                                            'Delete "${track['name']}"?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await _deleteTrack(track['id']);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () => _playTrack(track),
                            ),
                          );
                        },
                      ),
          ),

          // Music Player Bar - Shows when a track is playing
          if (_currentTrackId != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress Bar
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      inactiveTrackColor: Colors.grey[300],
                      thumbColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Slider(
                      value: _duration.inSeconds > 0
                          ? _position.inSeconds / _duration.inSeconds
                          : 0.0,
                      onChanged: (value) async {
                        final position = Duration(
                          seconds: (value * _duration.inSeconds).toInt(),
                        );
                        await _audioPlayer.seek(position);
                      },
                    ),
                  ),

                  // Player Controls
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        // Album Art
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.music_note,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Track Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentTrackName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Control Buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Stop Button
                            IconButton(
                              icon: const Icon(Icons.stop),
                              iconSize: 28,
                              color: Colors.grey[700],
                              onPressed: _stopPlayback,
                            ),

                            // Play/Pause Button
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                iconSize: 28,
                                onPressed: () {
                                  final track = _audioTracks.firstWhere(
                                    (t) => t['id'] == _currentTrackId,
                                  );
                                  _playTrack(track);
                                },
                              ),
                            ),

                            // Volume Control
                            SizedBox(
                              width: 100,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.volume_down,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 2,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 4,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                          overlayRadius: 8,
                                        ),
                                      ),
                                      child: Slider(
                                        value: _volume,
                                        onChanged: (value) {
                                          setState(() {
                                            _volume = value;
                                          });
                                          _audioPlayer.setVolume(value);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
