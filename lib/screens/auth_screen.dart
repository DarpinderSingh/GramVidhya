import 'package:flutter/material.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../data/auth_service.dart';
import 'model_manager_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.auth});
  final AuthService auth;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRegister = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  String _educationLevel = 'UG';
  final String _preferredLang = appLang.value;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() async {
    final tok = context.tokens;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    String? error;

    if (_isRegister) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('passwords_no_match'))),
        );
        return;
      }

      error = await widget.auth.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
        educationLevel: _educationLevel,
        preferredLang: _preferredLang,
      );
    } else {
      error = await widget.auth.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }

    setState(() => _isLoading = false);

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: tok.error),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isRegister ? tr('register_success') : tr('login_success')),
            backgroundColor: tok.success,
          ),
        );
        setState(() {}); // Refresh view to show profile
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tok = context.tokens;
    final isLoggedIn = widget.auth.isLoggedIn;

    return Scaffold(
      backgroundColor: tok.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: tok.backgroundPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: tok.textPrimary),
        title: Text(
          isLoggedIn ? tr('profile') : (_isRegister ? tr('register') : tr('login')),
          style: TextStyle(fontWeight: FontWeight.bold, color: tok.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: isLoggedIn ? _buildProfileView(tok) : _buildAuthForm(tok),
        ),
      ),
    );
  }

  Widget _buildProfileView(SemanticThemeTokens tok) {
    final profile = widget.auth.profile;
    final name = (profile['name'] as String?) ?? 'Student';
    final email = (profile['email'] as String?) ?? '';
    final phone = (profile['phone'] as String?) ?? '';
    final level = (profile['educationLevel'] as String?) ?? 'UG';
    final lang = (profile['preferredLang'] as String?) ?? appLang.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Profile Header Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [tok.primary, tok.secondaryAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: tok.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: tok.buttonText.withValues(alpha: 0.25),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'G',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: tok.buttonText),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: tok.buttonText),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(fontSize: 14, color: tok.buttonText.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Account Details Card
        Card(
          color: tok.cardBackground,
          elevation: 2,
          shadowColor: tok.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: tok.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('profile_details'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tok.textPrimary),
                ),
                const SizedBox(height: 16),
                _buildProfileDetailRow(Icons.phone, tr('phone'), phone.isNotEmpty ? phone : 'Not provided', tok),
                const Divider(),
                _buildProfileDetailRow(Icons.school, tr('education_level'), level, tok),
                const Divider(),
                _buildProfileDetailRow(Icons.language, tr('language'), langNames[lang] ?? lang, tok),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // AI Model Manager Entry
        Card(
          color: tok.cardBackground,
          elevation: 2,
          shadowColor: tok.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: tok.border),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: tok.primary.withValues(alpha: 0.15),
              child: Icon(Icons.memory, color: tok.primary),
            ),
            title: Text('Offline AI Model Manager', style: TextStyle(fontWeight: FontWeight.bold, color: tok.textPrimary)),
            subtitle: Text('Inspect or download on-device GGUF model', style: TextStyle(color: tok.textSecondary, fontSize: 12)),
            trailing: Icon(Icons.chevron_right, color: tok.textSecondary),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelManagerScreen()));
            },
          ),
        ),
        const SizedBox(height: 24),

        // Logout Button
        ElevatedButton.icon(
          onPressed: () async {
            await widget.auth.logout();
            setState(() {});
          },
          icon: Icon(Icons.logout, color: tok.buttonText),
          label: Text(tr('logout'), style: TextStyle(color: tok.buttonText)),
          style: ElevatedButton.styleFrom(
            backgroundColor: tok.error,
            foregroundColor: tok.buttonText,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value, SemanticThemeTokens tok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: tok.accent, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: tok.textSecondary, fontSize: 14)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: tok.textPrimary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAuthForm(SemanticThemeTokens tok) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tok.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.school, size: 48, color: tok.accent),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isRegister ? tr('create_account') : tr('welcome_back'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: tok.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _isRegister ? tr('register_sub') : tr('login_sub'),
            textAlign: TextAlign.center,
            style: TextStyle(color: tok.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),

          if (_isRegister) ...[
            TextFormField(
              controller: _nameController,
              style: TextStyle(color: tok.textPrimary),
              decoration: _inputDecoration(tr('full_name'), Icons.person, tok),
              validator: (v) => (v == null || v.trim().isEmpty) ? tr('enter_name') : null,
            ),
            const SizedBox(height: 16),
          ],

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: tok.textPrimary),
            decoration: _inputDecoration(tr('email'), Icons.email, tok),
            validator: (v) => (v == null || !v.contains('@')) ? tr('enter_valid_email') : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: tok.textPrimary),
            decoration: _inputDecoration(tr('password'), Icons.lock, tok).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: tok.textSecondary),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) => (v == null || v.length < 6) ? tr('password_min_chars') : null,
          ),
          const SizedBox(height: 16),

          if (_isRegister) ...[
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              style: TextStyle(color: tok.textPrimary),
              decoration: _inputDecoration(tr('confirm_password'), Icons.lock_outline, tok).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off, color: tok.textSecondary),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? tr('confirm_password_req') : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: tok.textPrimary),
              decoration: _inputDecoration(tr('phone_optional'), Icons.phone, tok),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _educationLevel,
              dropdownColor: tok.cardBackground,
              decoration: _inputDecoration(tr('education_level'), Icons.school_outlined, tok),
              style: TextStyle(color: tok.textPrimary),
              items: [
                DropdownMenuItem(value: 'UG', child: Text(tr('undergraduate'))),
                DropdownMenuItem(value: 'PG', child: Text(tr('postgraduate'))),
                DropdownMenuItem(value: 'PhD', child: Text(tr('doctorate'))),
              ],
              onChanged: (v) => setState(() => _educationLevel = v!),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: tok.buttonPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_isRegister ? tr('register') : tr('login'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),

          TextButton(
            onPressed: () => setState(() => _isRegister = !_isRegister),
            child: Text(
              _isRegister ? tr('already_have_account') : tr('dont_have_account'),
              style: TextStyle(color: tok.accent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, SemanticThemeTokens tok) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: tok.textSecondary),
      prefixIcon: Icon(icon, color: tok.accent),
      filled: true,
      fillColor: tok.cardBackground,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tok.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tok.accent, width: 2),
      ),
    );
  }
}
