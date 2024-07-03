import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/model/globals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<UserCredential?> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      return null;
    }

    final GoogleSignInAuthentication? googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    
    await _storeUserData(userCredential.user);

    return userCredential;
  } on Exception catch (e) {
    if (kDebugMode) {
      print('Exception: $e');
    }
    return null;
  }
}

Future<void> _storeUserData(User? user) async {
  if (user != null) {
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    Credentials.userid = user.uid;
    final docSnapshot = await userRef.get();
    
    if (!docSnapshot.exists) {
      await userRef.set({
        'uid': user.uid,
        'displayName': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
        'bio': 'This is a user bio', 
        'phoneNumber': user.phoneNumber,
        'interests': [], 
        'isOnline': true,
      });
    } else {
      await userRef.update({
        'displayName': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'lastSignIn': FieldValue.serverTimestamp(),
        'isOnline': true,
      });
    }
  }
}

Future<bool> signOutFromGoogle() async {
  try {
    await FirebaseAuth.instance.signOut();
    return true;
  } on Exception catch (_) {
    return false;
  }
}
