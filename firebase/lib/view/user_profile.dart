import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserProfile extends StatefulWidget {
  final String userId;
  final bool isEditable;

  const UserProfile({required this.userId, required this.isEditable, super.key});

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String _profileImageUrl = 'https://via.placeholder.com/150';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.userId).get();
      if (userDoc.exists) {
        setState(() {
          _nameController.text = userDoc.get('displayName') ?? 'User Name';
          _bioController.text = userDoc.get('bio') ?? 'User Bio';
          _profileImageUrl = userDoc.get('photoURL') ?? 'https://via.placeholder.com/150';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _pickProfileImage() async {
    if (widget.isEditable) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        print('Image selected: ${image.path}');
        String? downloadUrl = await _uploadProfileImage(File(image.path));
        if (downloadUrl != null) {
          setState(() {
            _profileImageUrl = downloadUrl;
          });
          _saveProfileImageUrl(downloadUrl);
        }
      } else {
        print('No image selected');
      }
    }
  }

  Future<String?> _uploadProfileImage(File image) async {
    try {
      final String filePath = 'user_profiles/${widget.userId}/${DateTime.now().millisecondsSinceEpoch}.png';
      UploadTask uploadTask = _storage.ref().child(filePath).putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _saveProfileImageUrl(String url) async {
    try {
      await _firestore.collection('users').doc(widget.userId).update({'photoURL': url});
      print('Profile image URL saved to Firestore');
    } catch (e) {
      print('Error saving profile image URL: $e');
    }
  }

  void _saveProfile() async {
    if (widget.isEditable) {
      try {
        await _firestore.collection('users').doc(widget.userId).set({
          'displayName': _nameController.text,
          'bio': _bioController.text,
          'photoURL': _profileImageUrl,
        }, SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      } catch (e) {
        print('Error saving profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('User Profile')),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20), // Spacing below AppBar
              GestureDetector(
                onTap: () {
                  print('Profile image tapped');
                  _pickProfileImage();
                },
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(_profileImageUrl),
                  child: widget.isEditable
                      ? Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black45,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 30), // Spacing below the profile picture
              Container(
                padding: const EdgeInsets.all(16.0),
                width: width * 0.9, // Increase the width of the container
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'User Name',
                        border: OutlineInputBorder(),
                      ),
                      textAlign: TextAlign.center,
                      readOnly: !widget.isEditable,
                    ),
                    SizedBox(height: width / 7),
                    TextField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'User Bio',
                        border: OutlineInputBorder(),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      readOnly: !widget.isEditable,
                    ),
                    if (widget.isEditable)
                      Column(
                        children: [
                          SizedBox(height: width / 7),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _saveProfile,
                            child: const Text('Save Profile'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
