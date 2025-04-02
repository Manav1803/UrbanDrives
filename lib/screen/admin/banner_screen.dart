import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


const String apiUrl =
    String.fromEnvironment('API_URL', defaultValue: 'http://127.0.0.1:5000');


class BannerData {
  final String id;
  final String imagePath;
  bool isActive;


  BannerData({required this.id, required this.imagePath, this.isActive = true});


  factory BannerData.fromJson(Map<String, dynamic> json) {
    return BannerData(
      id: json['_id'] ?? '',
      imagePath: json['imagePath'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }


  Map<String, dynamic> toJson() => {
        '_id': id,
        'imagePath': imagePath,
        'isActive': isActive,
      };
}


class Bannerscreen extends StatefulWidget {
  const Bannerscreen({Key? key}) : super(key: key);


  @override
  State<Bannerscreen> createState() => _BannerscreenState();
}


class _BannerscreenState extends State<Bannerscreen> {
  List<BannerData> banners = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }


  Future<void> _fetchBanners() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse('$apiUrl/banners'));
      if (response.statusCode == 200) {
        final List<dynamic> bannerData = jsonDecode(response.body);
        setState(() {
          banners =
              bannerData.map((json) => BannerData.fromJson(json)).toList();
        });
      } else {
        _showSnackBar('Failed to load banners: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error fetching banners: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _uploadBanner(XFile image) async {
    setState(() {
      _isLoading = true;
    });
    try {
      List<int> imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);


      final response = await http.post(
        Uri.parse('$apiUrl/banners'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image, 'isActive': true}),
      );


      if (response.statusCode == 201) {
        final responseJson = jsonDecode(response.body);
        BannerData banner = BannerData.fromJson(responseJson);
        banners.add(banner);


        // Fetch banners again to get the new list
        _fetchBanners();
      } else {
        _showSnackBar('Failed to upload banner: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error uploading banner: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _uploadBanner(image);
    }
  }


  Future<void> _toggleActive(int index) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final banner = banners[index];
      final response = await http.put(
        Uri.parse('$apiUrl/banners/${banner.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isActive': !banner.isActive}),
      );


      if (response.statusCode == 200) {
        // Fetch banners again to get the new list
        _fetchBanners();
      } else {
        _showSnackBar('Failed to toggle active: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error toggling active: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _deleteBanner(int index) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final banner = banners[index];
      final response = await http.delete(
        Uri.parse('$apiUrl/banners/${banner.id}'),
      );


      if (response.statusCode == 200) {
        banners.removeAt(index);
        setState(() {});
        _fetchBanners();
      } else {
        _showSnackBar('Failed to delete banner: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error deleting banner: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Banners'),
      ),
      body: 
      
      
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : banners.isEmpty
              ? const Center(child: Text('No banners added yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: banners.length,
                  itemBuilder: (context, index) {
                    final banner = banners[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: Image.network(
                                '$apiUrl/uploads/${banner.imagePath}',
                                fit: BoxFit.cover,
                                errorBuilder: (BuildContext context,
                                    Object exception, StackTrace? stackTrace) {
                                  print(
                                      'Error loading image: $exception'); // Print the error
                                  return const Icon(Icons.error);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Banner ${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Filename: ${banner.imagePath}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteBanner(index),
                                ),
                                ElevatedButton(
                                  onPressed: () => _toggleActive(index),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: banner.isActive
                                        ? Colors.red
                                        : Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(banner.isActive
                                      ? 'Deactivate'
                                      : 'Activate'),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),

                
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: const Icon(Icons.add),
      ),
    );
  }
}
