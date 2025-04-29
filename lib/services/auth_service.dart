import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class AuthService {
  // Registrar un nuevo usuario
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Primero verificamos si el username ya existe
      final existingUsers = await supabase
          .from('profiles')
          .select('username')
          .eq('username', username);
          
      if (existingUsers.isNotEmpty) {
        throw AuthException('El nombre de usuario ya está en uso');
      }
      
      // Registrar al usuario
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username}, // Guardamos el username en los metadatos
      );
      
      if (res.user != null) {
        try {
          // Insertar manualmente en profiles (como respaldo si el trigger no funciona)
          await supabase.from('profiles').insert({
            'id': res.user!.id,
            'username': username,
            'email': email,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          // Si falla, podría ser porque el trigger ya lo creó
          print("Nota: No se pudo crear el perfil manualmente: $e");
        }
      }
      
      return res;
    } catch (e) {
      print("Error durante el registro: $e");
      rethrow;
    }
  }

  // Iniciar sesión
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      return res;
    } catch (e) {
      print("Error durante el login: $e");
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Obtener usuario actual
  User? get currentUser => supabase.auth.currentUser;

  // Obtener nombre de usuario por ID
  Future<String?> getUsernameById(String userId) async {
    try {
      // Intento 1: Buscar en la tabla de perfiles
      final data = await supabase
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .maybeSingle();
      
      if (data != null && data['username'] != null) {
        return data['username'] as String?;
      }
      
      // Intento 2: Buscar en los metadatos del usuario
      final user = supabase.auth.currentUser;
      if (user != null && user.userMetadata != null && user.userMetadata!.containsKey('username')) {
        return user.userMetadata!['username'] as String?;
      }
      
      // Intento 3: Usar el correo electrónico como respaldo
      if (user != null && user.email != null) {
        return user.email!.split('@')[0];
      }
      
      return 'Usuario';
    } catch (e) {
      print("Error al obtener username: $e");
      return 'Usuario';
    }
  }
}