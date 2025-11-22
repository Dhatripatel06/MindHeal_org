import 'package:flutter/material.dart';

class AudioHealingPage extends StatefulWidget {
  const AudioHealingPage({super.key});

  @override
  State<AudioHealingPage> createState() => _AudioHealingPageState();
}

class _AudioHealingPageState extends State<AudioHealingPage> {
  bool _isPlaying = false;
  String _currentTrack = 'Ocean Waves';
  double _volume = 0.7;
  
  final List<Map<String, dynamic>> _audioTracks = [
    {'name': 'Ocean Waves', 'icon': Icons.water, 'color': Colors.blue, 'duration': '10:30'},
    {'name': 'Forest Sounds', 'icon': Icons.forest, 'color': Colors.green, 'duration': '8:15'},
    {'name': 'Rain & Thunder', 'icon': Icons.thunderstorm, 'color': Colors.grey, 'duration': '12:45'},
    {'name': 'Meditation Bell', 'icon': Icons.notifications_none, 'color': Colors.amber, 'duration': '5:20'},
    {'name': 'White Noise', 'icon': Icons.graphic_eq, 'color': Colors.purple, 'duration': '15:00'},
    {'name': 'Binaural Beats', 'icon': Icons.headphones, 'color': Colors.teal, 'duration': '20:00'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Healing'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.timer),
          ),
        ],
      ),
      body: Column(
        children: [
          // Currently Playing Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Album Art Placeholder
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    Icons.water,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  _currentTrack,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Nature Sounds Collection',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Progress Bar
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: 0.3,
                        onChanged: (value) {},
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('3:15', style: Theme.of(context).textTheme.bodySmall),
                          Text('10:30', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.skip_previous),
                      iconSize: 32,
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _isPlaying = !_isPlaying;
                          });
                        },
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        iconSize: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.skip_next),
                      iconSize: 32,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Volume Control
                Row(
                  children: [
                    const Icon(Icons.volume_down),
                    Expanded(
                      child: Slider(
                        value: _volume,
                        onChanged: (value) {
                          setState(() {
                            _volume = value;
                          });
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Track List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _audioTracks.length,
              itemBuilder: (context, index) {
                final track = _audioTracks[index];
                final isCurrentTrack = track['name'] == _currentTrack;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isCurrentTrack 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1) 
                    : null,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (track['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        track['icon'],
                        color: track['color'],
                      ),
                    ),
                    title: Text(
                      track['name'],
                      style: TextStyle(
                        fontWeight: isCurrentTrack ? FontWeight.w600 : FontWeight.normal,
                        color: isCurrentTrack ? Theme.of(context).colorScheme.primary : null,
                      ),
                    ),
                    subtitle: Text(track['duration']),
                    trailing: isCurrentTrack && _isPlaying
                      ? const Icon(Icons.equalizer)
                      : null,
                    onTap: () {
                      setState(() {
                        _currentTrack = track['name'];
                        _isPlaying = true;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
