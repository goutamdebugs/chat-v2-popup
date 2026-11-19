import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {

  static final _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');

  static final _iv = encrypt.IV.fromLength(16);
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  // Lock the text
  static String encryptText(String plainText) {
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print("Encryption error: $e");
      return plainText; // Fallback
    }
  }

  static String decryptText(String encryptedBase64) {
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedBase64);
      return _encrypter.decrypt(encrypted, iv: _iv); 
    } catch (e) {
      print("Decryption error: $e");
      return encryptedBase64; 
    }
  }
}