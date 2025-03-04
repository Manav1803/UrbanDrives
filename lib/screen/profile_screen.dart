import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:zoomwheels/widget/bottom_navbar.dart';
import '../widget/host_navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'auth/login_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String email;
  final String userId;

  const ProfileScreen({super.key, required this.userName, required this.email, required this.userId});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _userRole;
  String? _userEmail;
  String? _userPhone;
  bool _isLoading = false;
  late String _currentUserName;
  String? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _currentUserName = widget.userName;
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
   
    setState(() {
       _userEmail = widget.email;
      _userRole = prefs.getString('userRole') ?? 'user';
    });
    await _fetchUserData(widget.email);
  }

  Future<void> _fetchUserData(String email) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/get-user-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Fetched user data: $responseData');
        if (responseData != null) {
          setState(() {
            _currentUserName = responseData['userName'] ?? widget.userName;
            _userPhone = responseData['phone'];
            _nameController.text = _currentUserName;
            _phoneController.text = _userPhone ?? '';
            _profileImage = responseData['profileImage'];
          });
        }
      } else {
        print('Failed to fetch user data');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch user data')),
        );
      }
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to server')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (!RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$')
        .hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }



   Future<void> _updateProfilePicture(String? imageBase64) async {
      setState(() {
        _isLoading = true;
      });
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/update-profile-picture'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _userEmail,
          'profileImage': imageBase64,
        }),
      );
       print('Response Status code: ${response.statusCode}');
      if (response.statusCode == 200) {
           await _fetchUserData(_userEmail!);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated')),
          );
      } else {
        print('Failed to update profile picture');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile picture')),
        );
      }
    } catch (e) {
      print('Error updating profile picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to server')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      setState(() {
        _isLoading = true;
      });
      final userName = _nameController.text;
      final phone = _phoneController.text;

      final prefs = await SharedPreferences.getInstance();
      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:5000/update-profile'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'current_email': _userEmail,
            'userName': userName,
            'phone': phone
          }),
        );

        if (response.statusCode == 200) {
          if (userName.isNotEmpty) {
            await prefs.setString('userName', userName);
            _currentUserName = userName;
            setState(() {
              _currentUserName = userName;
            });
          }
          if (phone.isNotEmpty) {
            await prefs.setString('phone', phone);
            setState(() {
              _userPhone = phone;
            });
          }

          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile Updated')),
            );
          }
        } else {
          final responseData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'])),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to server')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      FocusScope.of(context).requestFocus(FocusNode());
    }
  }

  Future<void> _pickImage(ImageSource source) async {
     final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
        if (pickedFile != null) {
           if (kIsWeb) {
             final bytes = await pickedFile.readAsBytes();
            final base64Image = base64Encode(bytes);
             print('Base64 image data (web): $base64Image');
             _updateProfilePicture(base64Image);
             }
            else{
                final imageBytes = await File(pickedFile.path).readAsBytes();
                 final base64Image = base64Encode(imageBytes);
                   print('Base64 image data (native): $base64Image');
               _updateProfilePicture(base64Image);
           }
        }
  }


  Future<void> _requestAndPickImage(ImageSource source) async {
    PermissionStatus status;
    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
      if (status.isGranted) {
        _pickImage(source);
      }
    } else if (source == ImageSource.gallery) {
      if (kIsWeb) {
        _pickImage(source);
      } else {
        status = await Permission.photos.request();
        if (status.isGranted) {
          _pickImage(source);
        }
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _requestAndPickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _requestAndPickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove Image'),
                onTap: () {
                  Navigator.of(context).pop();
                  _updateProfilePicture(null);
                },
              )
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: _validateName,
                  ),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                    validator: _validatePhone,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateProfile();
              },
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showSwitchRoleDialog(BuildContext context) {
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title:
              Text(_userRole == 'user' ? 'Login as Host' : 'Login as User'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Enter an email address";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Enter password";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _isLoading = true;
                      });

                      final email = _emailController.text;
                      final password = _passwordController.text;

                      try {
                        final response = await http.post(
                          Uri.parse('http://127.0.0.1:5000/switch-role'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'email': email,
                            'password': password,
                            'current_email': _userEmail
                          }),
                        );

                        if (response.statusCode == 200) {
                          final responseData = json.decode(response.body);
                          final newRole = responseData['role'];
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('userRole', newRole);
                           Navigator.of(context).pop();
                          if (newRole == 'user') {
                           
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => BottomNavBar(
                                    userName: widget.userName,
                                     userEmail: widget.email,
                                      userId: widget.userId, initialIndex: 0,
                                  )),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HostNavBar(
                                    userName: widget.userName,
                                    userEmail: widget.email,
                                      userId: widget.userId,
                                  )),
                            );
                          }
                        } else {
                          final responseData = json.decode(response.body);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(responseData['message'])),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Failed to connect to server')),
                        );
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(_userRole == 'user' ? 'Login' : 'Login'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Add this line
        actions: [
          TextButton(
            onPressed: () {
              _showEditProfileDialog(context);
            },
            child: const Text(
              'Edit Profile',
              style: TextStyle(color: Colors.blue),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Profile',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildProfileHeader(context, _currentUserName),
            const SizedBox(height: 20),
            _buildReferAndEarnCard(context),
            const SizedBox(height: 15),
            _buildListItems(context),
            const SizedBox(height: 15),
            _buildSwitchRoleButton(context),
            const SizedBox(height: 15),
            _buildWhatsAppSupportButton(context),
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String userName) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            _showImageSourceDialog();
          },
          child: ClipOval(
            child: _profileImage != null
                ? Image.memory(base64Decode(_profileImage!),
                width: 70, height: 70, fit: BoxFit.cover)
                : SizedBox(
              width: 70,
              height: 70,
              child: Container(
                color: Colors.grey[300],
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.bold)),
              Text(
                _userPhone ?? '+91 - 9033056422',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: Colors.grey),
              ),
              Text(
                _userEmail ?? 'johndoe@gmail.com',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: Colors.grey),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildReferAndEarnCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_add_alt_1_outlined,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Refer and Earn',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward,
              color: Colors.grey,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildListItems(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildListItem(context, label: 'Favourites Cars'),
        _buildListItem(context, label: 'Current City', value: 'Ahmedabad'),
        _buildListItem(context, label: 'Settings'),
        _buildListItem(context, label: 'Policies'),
        _buildListItem(context, label: 'Share App'),
        ListTile(
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('userName');
            await prefs.remove('userRole');
            await prefs.remove('email');
              await prefs.remove('phone');
                await prefs.remove('userId');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          title: Text('Logout', style: Theme.of(context).textTheme.titleMedium),
          trailing: const Icon(
            Icons.arrow_forward,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(BuildContext context,
      {required String label, String? value}) {
    return ListTile(
      title: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(
              value,
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          const Icon(
            Icons.arrow_forward,
            color: Colors.grey,
          ),
        ],
      ),
      onTap: () {
        // TODO: Handle item tap
      },
    );
  }

  Widget _buildSwitchRoleButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _showSwitchRoleDialog(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: Text(
          _userRole == 'user' ? 'Switch to Host Role' : 'Switch to User Role',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildWhatsAppSupportButton(BuildContext context) {
    return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.chat,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Whatsapp Support',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Icon(
                Icons.arrow_forward,
                color: Colors.grey,
              )
            ],
          ),
        ));
  }
}