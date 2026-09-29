import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import '../data/store.dart';
import '../core/i18n.dart';

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
  String _preferredLang = appLang.value;

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

      if (error == null) {
        await setLanguage(_preferredLang);
      }
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
          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isRegister ? tr('register_success') : tr('login_success')),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoggedIn = widget.auth.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isLoggedIn ? tr('profile') : (_isRegister ? tr('register') : tr('login')),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: isLoggedIn ? _buildProfileView(theme) : _buildAuthForm(theme),
        ),
      ),
    );
  }

  Widget _buildProfileView(ThemeData theme) {
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
            gradient: const LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'G',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Info Cards
        Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('profile'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Divider(height: 24),
                _buildInfoRow(Icons.school, tr('education_level'), level),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.language, tr('language'), langNames[lang] ?? lang),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.phone, tr('phone'), phone),
                ],
                const SizedBox(height: 12),
                _buildInfoRow(Icons.cloud_queue, tr('status'), '${Store.pending} ${tr('progress_sync').replaceAll('{n}', '')}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Logout Button
        OutlinedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1E293B),
                title: Text(tr('logout')),
                content: Text(tr('logout_confirm')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(tr('cancel')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(tr('logout'), style: const TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await widget.auth.logout();
              if (mounted) setState(() {});
            }
          },
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          label: Text(tr('logout'), style: const TextStyle(color: Colors.redAccent)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.redAccent),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildAuthForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Logo / Icon
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school, size: 40, color: Color(0xFF38BDF8)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _isRegister ? tr('register') : tr('login'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              tr('welcome_sub'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(height: 28),

          // Fields
          if (_isRegister) ...[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: tr('name'),
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? tr('field_required') : null,
            ),
            const SizedBox(height: 16),
          ],

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: tr('email'),
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return tr('field_required');
              if (!v.contains('@')) return tr('invalid_email');
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: tr('password'),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return tr('field_required');
              if (v.length < 6) return tr('password_too_short');
              return null;
            },
          ),
          const SizedBox(height: 16),

          if (_isRegister) ...[
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: tr('confirm_password'),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return tr('field_required');
                if (v != _passwordController.text) return tr('passwords_no_match');
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: tr('phone'),
                prefixIcon: const Icon(Icons.phone_outlined),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _educationLevel,
              decoration: InputDecoration(
                labelText: tr('education_level'),
                prefixIcon: const Icon(Icons.school_outlined),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              dropdownColor: const Color(0xFF1E293B),
              items: const [
                DropdownMenuItem(value: 'School', child: Text('School (Class 1-10)')),
                DropdownMenuItem(value: 'Secondary', child: Text('Secondary (11th-12th)')),
                DropdownMenuItem(value: 'UG', child: Text('Undergraduate (College)')),
                DropdownMenuItem(value: 'PG', child: Text('Postgraduate')),
              ],
              onChanged: (v) => setState(() => _educationLevel = v ?? 'UG'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _preferredLang,
              decoration: InputDecoration(
                labelText: tr('preferred_lang'),
                prefixIcon: const Icon(Icons.translate),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              dropdownColor: const Color(0xFF1E293B),
              items: langNames.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _preferredLang = v ?? 'en'),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 8),

          // Submit Button
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)),
                  )
                : Text(
                    _isRegister ? tr('register') : tr('login'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
          const SizedBox(height: 16),

          // Toggle Login / Register
          TextButton(
            onPressed: () => setState(() => _isRegister = !_isRegister),
            child: Text(
              _isRegister ? tr('already_have_account') : tr('no_account'),
              style: const TextStyle(color: Color(0xFF38BDF8)),
            ),
          ),

          // Continue Offline
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(tr('continue_offline'), style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
