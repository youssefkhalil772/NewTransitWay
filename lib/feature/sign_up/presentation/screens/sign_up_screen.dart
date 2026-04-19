import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transite_way/feature/login/login.dart';
import 'package:transite_way/feature/sign_up/data/models/sign_up_request_body.dart';
import 'package:transite_way/feature/sign_up/data/repository/sign_up_repository_impl.dart';
import 'package:transite_way/feature/sign_up/data/web_services/sign_up_web_services.dart';
import 'package:transite_way/feature/sign_up/presentation/cubit/sign_up_cubit.dart';
import 'package:transite_way/feature/sign_up/presentation/cubit/sign_up_state.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignUpCubit(SignUpRepositoryImpl(SignUpWebServices())),
      child: const SignUpScreen(),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  bool _hasMinLength = false;
  bool _hasLetterAndNumber = false;
  bool _hasSpecialChar = false;

  String _selectedAvatar = 'assets/logo/3.png';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordConditions(String password) {
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasLetterAndNumber =
          password.contains(RegExp(r'[a-z]')) &&
              password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#\$%^&*]'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: BlocConsumer<SignUpCubit, SignUpState>(
            listener: (context, state) {
              if (state is SignUpSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account created successfully! Please log in.')),
                );
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginScreen()));
              } else if (state is SignUpFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage)),
                );
              } else if (state is SignUpEmailOrPhoneExists) {
                _showEmailOrPhoneExistsDialog(state.message);
              }
            },
            builder: (context, state) {
               if (state is SignUpLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildBackButton(),
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 30),
                      Center(child: _buildAvatarPicker()),
                      const SizedBox(height: 30),
                      _buildForm(),
                      const SizedBox(height: 24),
                      _buildContinueButton(),
                      const SizedBox(height: 24),
                      _buildOrDivider(),
                      const SizedBox(height: 24),
                      _buildGoogleButton(),
                      const SizedBox(height: 24),
                      _buildSignInText(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFC107),
              ),
              child: ClipOval(
                child: Image.asset(_selectedAvatar, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _showAvatarSelectionDialog,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Color(0xFF065F46), shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text("Choose your avatar", style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  void _showAvatarSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Avatar'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAvatarOption('assets/logo/3.png'),
            _buildAvatarOption('assets/images/Avatar.png'),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption(String path) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedAvatar = path);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedAvatar == path ? const Color(0xFF065F46) : Colors.transparent,
            width: 2,
          ),
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: 35,
          backgroundColor: const Color(0xFFFFC107),
          backgroundImage: AssetImage(path),
        ),
      ),
    );
  }

 void _showEmailOrPhoneExistsDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Registration Failed'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Go to Sign In'),
              onPressed: () {
                Navigator.of(context).pop(); 
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
        splashRadius: 20,
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Let’s Get Started',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Create an account to continue.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        TextFormField(
          controller: _firstNameController,
          decoration: InputDecoration(
            labelText: 'First Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xff065F46), width: 2),
            ),
            prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
            labelStyle: const TextStyle(color: Colors.grey),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your first name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _lastNameController,
          decoration: InputDecoration(
            labelText: 'Last Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xff065F46), width: 2),
            ),
            prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
            labelStyle: const TextStyle(color: Colors.grey),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your last name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xff065F46), width: 2),
            ),
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
            labelStyle: const TextStyle(color: Colors.grey),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xff065F46), width: 2),
            ),
            prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
            labelStyle: const TextStyle(color: Colors.grey),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _isPasswordHidden,
          onChanged: _checkPasswordConditions,
          decoration: InputDecoration(
            labelText: 'Create Password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xff065F46), width: 2),
            ),
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
            labelStyle: const TextStyle(color: Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordHidden = !_isPasswordHidden;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (!_hasMinLength || !_hasLetterAndNumber || !_hasSpecialChar) {
                return 'Password does not meet all conditions.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _isConfirmPasswordHidden,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xff065F46), width: 2),
            ),
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
            labelStyle: const TextStyle(color: Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordHidden
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordHidden = !_isConfirmPasswordHidden;
                });
              },
            ),
          ),
          validator: (value) {
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildPasswordConditions(),
      ],
    );
  }

  Widget _buildPasswordConditions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildConditionRow('At least 8 characters', _hasMinLength),
          const SizedBox(height: 8),
          _buildConditionRow(
            'Contains Letters & numbers (1 Lowercase)',
            _hasLetterAndNumber,
          ),
          const SizedBox(height: 8),
          _buildConditionRow(
            'Contains special Characters (!@#\$%^&*)',
            _hasSpecialChar,
          ),
        ],
      ),
    );
  }

  Widget _buildConditionRow(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.circle,
          size: 16,
          color: isMet ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isMet ? Colors.black : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            final fullName = '${_firstNameController.text} ${_lastNameController.text}';
            final requestBody = SignUpRequestBody(
              fullName: fullName,
              email: _emailController.text,
              phone: _phoneController.text,
              password: _passwordController.text,
              avatar: _selectedAvatar,
            );
            context.read<SignUpCubit>().signUp(requestBody);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff065F46),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Continue',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Or continue with', style: TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Image.asset('assets/icons/google.png', height: 20),
        label: const Text(
          'Continue with Google',
          style: TextStyle(color: Colors.black),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildSignInText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: Colors.grey),
        ),
        GestureDetector(
          onTap: () {
             Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LoginScreen()));
          },
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: Color(0xff065F46),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
