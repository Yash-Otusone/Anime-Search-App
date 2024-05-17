import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'anime.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late TextEditingController _searchController;
  List<Anime> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  Future<void> fetchAnime(String query) async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://api.jikan.moe/v4/anime?q=$query');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        List<dynamic> resultList = data['data'];

        setState(() {
          _searchResults = resultList.map((jsonData) {
            String animeTitle = jsonData['title'];
            Map<String, dynamic> images = jsonData['images'];
            String? imageURL = images['jpg']['image_url'];
            String? youtubeURL = jsonData['trailer']['url'];
            return Anime(
              title: animeTitle,
              url: youtubeURL ?? '',
              trailerThumbnail: imageURL ?? '',
            );
          }).toList();
        });
      } else {
        throw Exception('Failed to load anime data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred while fetching anime data: $e');
      setState(() {
        _searchResults = []; // Clear previous results in case of error
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Error occurred while fetching anime data: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchTrailerUrl(String url, BuildContext context) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch URL $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: h * 0.1,
        title: TextField(
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.blueAccent),
          controller: _searchController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(20))),
            hintText: 'Search Anime...',
          ),
          onSubmitted: (value) async {
            await fetchAnime(value);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: IconButton(
                onPressed: () async {
                  await fetchAnime(_searchController.text);
                  _searchController.clear();
                },
                icon: const Icon(
                  Icons.search_sharp,
                  size: 30,
                  color: Colors.blueAccent,
                )),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? const Center(
                  child: Text("No Data Found!"),
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final anime = _searchResults[index];
                    return Card(
                      child: ListTile(
                        title: Text(anime.title),
                        onTap: () {
                          if (anime.url == '') {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "YouTube Link is not Available.")));
                          } else {
                            _launchTrailerUrl(anime.url, context);
                          }
                        },
                        leading: anime.trailerThumbnail.isNotEmpty
                            ? Image.network(anime.trailerThumbnail)
                            : Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey,
                                child: const Icon(Icons.play_arrow),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
