import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: VideoListPage());
  }
}

// O Widget principal que vai conter a nossa lista
class VideoListPage extends StatefulWidget {
  const VideoListPage({super.key});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  // Uma lista de URLs de vídeos para nosso exemplo
  final List<String> videoUrls = [
    // HLS (.m3u8)
    'https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8',
    // MP4 - Curto
    'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    // MP4 - Mais longo
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Vídeos')),
      // ListView.builder é a forma mais eficiente de construir listas
      body: ListView.builder(
        itemCount: videoUrls.length,
        itemBuilder: (context, index) {
          return VideoPlayerItem(
            videoUrl: videoUrls[index],
            key: Key(
              videoUrls[index],
            ), // Chave para ajudar o Flutter a identificar os widgets
          );
        },
      ),
    );
  }
}

// Este é o widget para CADA item da lista.
// Ele é Stateful porque precisa gerenciar seu próprio VideoPlayerController.
class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerItem({required this.videoUrl, super.key});

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        // Garante que o primeiro frame seja renderizado
        if (mounted) {
          setState(() {});
        }
      });

    // Listener para saber quando o vídeo termina
    _controller.addListener(() {
      if (!_controller.value.isPlaying &&
          _controller.value.isInitialized &&
          (_controller.value.duration == _controller.value.position)) {
        // Se o vídeo terminou
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.play();
        _controller.setLooping(true); // Opcional: faz o vídeo repetir
      } else {
        _controller.pause();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            'Vídeo: ${widget.videoUrl.split('/').last}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _controller.value.isInitialized
              ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                // Stack permite sobrepor widgets. Vamos colocar o botão sobre o vídeo.
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    // Botão central de Play/Pause
                    IconButton(
                      iconSize: 64.0,
                      color: Colors.white.withValues(alpha: 0.8),
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                  ],
                ),
              )
              : Container(
                height: 200,
                color: Colors.black,
                child: const Center(child: CircularProgressIndicator()),
              ),
        ],
      ),
    );
  }
}
