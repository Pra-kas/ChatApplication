import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/model/globals.dart';
import 'package:firebase/view/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class FireBaseOTPValidation extends StatefulWidget {
  const FireBaseOTPValidation({Key? key}) : super(key: key);

  @override
  _FireBaseOTPValidationState createState() => _FireBaseOTPValidationState();
}

class _FireBaseOTPValidationState extends State<FireBaseOTPValidation> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String _verificationId = '';

  Future<void> _verifyPhoneNumber() async {
    await _auth.verifyPhoneNumber(
      phoneNumber: _phoneController.text,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        _showSnackbar('Phone number automatically verified and user signed in: ${credential.smsCode}');
      },
      verificationFailed: (FirebaseAuthException e) {
        _showSnackbar('Failed to verify phone number: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
        });
        _showSnackbar('Please check your phone for the verification code.');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _verificationId = verificationId;
        });
      },
    );
  }

  Future<bool> _signInWithPhoneNumber() async {
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _storeUserData(userCredential.user!);
        _showSnackbar('Successfully signed in UID: ${userCredential.user!.uid}');
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _showSnackbar('Failed to sign in: ${e.message}');
    }
    return false;
  }

  Future<void> _storeUserData(User user) async {
    User t = user;
    Credentials.userid = t.uid;
    await _firestore.collection('users').doc(user.uid).set({
      'phone': user.phoneNumber,
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': 'https://via.placeholder.com/150', 
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: height,
          ),
          child: Container(
            width: width,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white70, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(width / 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Phone OTP Validation',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(padding: EdgeInsets.only(top: width / 10)),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(width / 20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      width: width,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                ),
                                filled: true,
                                fillColor: Colors.white70,
                                hintText: 'Phone number',
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            SizedBox(
                              width: width,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.deepPurple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _verifyPhoneNumber,
                                child: const Text('Verify Phone Number'),
                              ),
                            ),
                            TextField(
                              controller: _otpController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                ),
                                filled: true,
                                fillColor: Colors.white70,
                                hintText: 'OTP',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            SizedBox(
                              width: width,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.deepPurple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () async {
                                  if (await _signInWithPhoneNumber()) {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                                  }
                                },
                                child: const Text('Sign In'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
