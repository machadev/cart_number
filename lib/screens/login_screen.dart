import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _LicensePlateIcon(),
                const SizedBox(height: 16),
                const Text(
                  'ナンバープレート収集',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF37474F),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '全国のナンバープレートを集めよう',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                if (auth.loading)
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                else
                  _GoogleSignInButton(onTap: auth.signInWithGoogle),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    auth.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LicensePlateIcon extends StatelessWidget {
  const _LicensePlateIcon();

  static const _green = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      height: 165,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _green, width: 4.5),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 9, offset: Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _green, width: 1.5),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '・日本 500・',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _green,
                  letterSpacing: 2,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'さ',
                    style: TextStyle(
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                      color: _green,
                      height: 1,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '20-27',
                    style: TextStyle(
                      fontSize: 63,
                      fontWeight: FontWeight.bold,
                      color: _green,
                      letterSpacing: 3,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleSignInButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: Color(0xFFDADCE0), width: 1.5),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(
            'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
            width: 22,
            height: 22,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.g_mobiledata, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'Googleでログイン',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF3C4043),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
