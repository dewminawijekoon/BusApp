import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _selectedIssueType = 'General';
  bool _isSubmitting = false;
  int _rating = 0;

  final List<String> _issueTypes = [
    'General',
    'Technical Issue',
    'Route Problem',
    'Payment Issue',
    'Account Problem',
    'Feature Request',
    'Bug Report',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _feedbackController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Widget _buildFAQTab() {
    final faqs = [
      FAQItem(
        question: 'How do I search for bus routes?',
        answer: 'Go to the Routes tab, enter your starting point and destination, then tap "Find Routes". The app will show you all available routes with real-time information.',
        icon: Icons.route,
      ),
      FAQItem(
        question: 'How does real-time bus tracking work?',
        answer: 'Our app uses GPS data from buses and crowd-sourced information from users to provide real-time location updates. Tap on any route to see live bus positions.',
        icon: Icons.gps_fixed,
      ),
      FAQItem(
        question: 'How do I earn points?',
        answer: 'You earn points by: sharing bus locations, rating your journey, using the app regularly, and helping other users. Points can be redeemed for rewards.',
        icon: Icons.star,
      ),
      FAQItem(
        question: 'Can I use the app offline?',
        answer: 'Yes! Previously searched routes and saved routes are cached for offline use. However, real-time tracking requires an internet connection.',
        icon: Icons.offline_bolt,
      ),
      FAQItem(
        question: 'How accurate is the bus arrival time?',
        answer: 'Our arrival predictions are based on real-time GPS data and traffic conditions. Accuracy typically ranges from 85-95% depending on traffic and weather conditions.',
        icon: Icons.schedule,
      ),
      FAQItem(
        question: 'How do I report a bus issue?',
        answer: 'Use the "Report Issue" button on any bus tracking screen, or contact us through the Contact tab. Include details like bus number, route, and time.',
        icon: Icons.report_problem,
      ),
      FAQItem(
        question: 'Can I save my favorite routes?',
        answer: 'Yes! Tap the bookmark icon on any route to save it. Access your saved routes from the Account tab.',
        icon: Icons.bookmark,
      ),
      FAQItem(
        question: 'How do I update my profile?',
        answer: 'Go to Account > Profile Settings. You can update your name, email, phone number, and notification preferences.',
        icon: Icons.person,
      ),
      FAQItem(
        question: 'What are crowd levels?',
        answer: 'Crowd levels indicate how busy a bus is, reported by other users. Green = not crowded, Yellow = moderate, Red = very crowded.',
        icon: Icons.people,
      ),
      FAQItem(
        question: 'How do I enable notifications?',
        answer: 'Go to Account > Settings > Notifications. You can customize alerts for bus arrivals, route updates, and other important information.',
        icon: Icons.notifications,
      ),
    ];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return _buildFAQCard(faqs[index]);
        },
      ),
    );
  }

  Widget _buildFAQCard(FAQItem faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(
          faq.icon,
          color: AppTheme.primaryColor,
          size: 24,
        ),
        title: Text(
          faq.question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              faq.answer,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContactInfo(),
              const SizedBox(height: 24),
              _buildContactForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get in Touch',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              icon: Icons.email,
              title: 'Email Support',
              subtitle: 'support@transitapp.com',
              onTap: () => _launchEmail('support@transitapp.com'),
            ),
            _buildContactItem(
              icon: Icons.phone,
              title: 'Phone Support',
              subtitle: '+94 11 234 5678',
              onTap: () => _launchPhone('+94112345678'),
            ),
            _buildContactItem(
              icon: Icons.chat,
              title: 'Live Chat',
              subtitle: 'Available 9 AM - 6 PM',
              onTap: () => _showLiveChatDialog(),
            ),
            _buildContactItem(
              icon: Icons.location_on,
              title: 'Office Address',
              subtitle: 'Colombo 03, Western Province, Sri Lanka',
              onTap: () => _launchMaps(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send us a Message',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Your Email',
              hint: 'Enter your email address',
              icon: Icons.email,
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _subjectController,
              label: 'Subject',
              hint: 'Brief description of your inquiry',
              icon: Icons.subject,
              validator: _validateSubject,
            ),
            const SizedBox(height: 16),
            _buildIssueTypeDropdown(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _feedbackController,
              label: 'Message',
              hint: 'Describe your issue or feedback in detail...',
              icon: Icons.message,
              maxLines: 4,
              validator: _validateMessage,
            ),
            const SizedBox(height: 16),
            _buildRatingSection(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildIssueTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedIssueType,
      decoration: InputDecoration(
        labelText: 'Issue Type',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: _issueTypes.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedIssueType = value!;
        });
      },
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rate your experience (optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _rating = index + 1;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.star,
                  size: 32,
                  color: index < _rating
                      ? Colors.amber
                      : Colors.grey[300],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Send Message',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAppInfo(),
            const SizedBox(height: 24),
            _buildVersionInfo(),
            const SizedBox(height: 24),
            _buildLegalInfo(),
            const SizedBox(height: 24),
            _buildSocialLinks(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_bus,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Transit Tracker',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your reliable companion for public transportation',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'We help millions of users navigate public transportation with real-time tracking, route planning, and crowd-sourced information.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Version', '1.2.3'),
            _buildInfoRow('Build', '2024.01.15'),
            _buildInfoRow('Platform', 'Flutter'),
            _buildInfoRow('Last Updated', 'January 15, 2024'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _checkForUpdates,
                    child: const Text('Check for Updates'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _shareApp,
                    child: const Text('Share App'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Legal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildLegalItem('Privacy Policy', Icons.privacy_tip),
            _buildLegalItem('Terms of Service', Icons.description),
            _buildLegalItem('Open Source Licenses', Icons.code),
            _buildLegalItem('Data Usage Policy', Icons.data_usage),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalItem(String title, IconData icon) {
    return InkWell(
      onTap: () => _openLegalDocument(title),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinks() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect with Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialButton(
                  icon: Icons.facebook,
                  label: 'Facebook',
                  onTap: () => _launchSocial('facebook'),
                ),
                _buildSocialButton(
                  icon: Icons.alternate_email,
                  label: 'Twitter',
                  onTap: () => _launchSocial('twitter'),
                ),
                _buildSocialButton(
                  icon: Icons.camera_alt,
                  label: 'Instagram',
                  onTap: () => _launchSocial('instagram'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Validation methods
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validateSubject(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a subject';
    }
    if (value.length < 5) {
      return 'Subject must be at least 5 characters';
    }
    return null;
  }

  String? _validateMessage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your message';
    }
    if (value.length < 10) {
      return 'Message must be at least 10 characters';
    }
    return null;
  }

  // Action methods
  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent successfully! We\'ll get back to you soon.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear form
        _feedbackController.clear();
        _emailController.clear();
        _subjectController.clear();
        setState(() {
          _rating = 0;
          _selectedIssueType = 'General';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchMaps() async {
    const String query = 'Colombo 03, Western Province, Sri Lanka';
    final Uri mapsUri = Uri.parse('https://maps.google.com/?q=$query');
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri);
    }
  }

  Future<void> _launchSocial(String platform) async {
    String url;
    switch (platform) {
      case 'facebook':
        url = 'https://facebook.com/transitapp';
        break;
      case 'twitter':
        url = 'https://twitter.com/transitapp';
        break;
      case 'instagram':
        url = 'https://instagram.com/transitapp';
        break;
      default:
        return;
    }
    
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showLiveChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Live Chat'),
        content: const Text(
          'Live chat is currently available from 9 AM to 6 PM, Monday to Friday. '
          'Would you like to send us an email instead?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchEmail('support@transitapp.com');
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  void _checkForUpdates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have the latest version!'),
      ),
    );
  }

  void _shareApp() {
    Share.share(
      'Check out Transit Tracker - the best app for public transportation! '
      'Download it from the app store.',
    );
  }

  void _openLegalDocument(String title) {
    // Navigate to legal document or open web page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $title...'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.help_outline),
              text: 'FAQ',
            ),
            Tab(
              icon: Icon(Icons.contact_support),
              text: 'Contact',
            ),
            Tab(
              icon: Icon(Icons.info_outline),
              text: 'About',
            ),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQTab(),
          _buildContactTab(),
          _buildAboutTab(),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;
  final IconData icon;

  FAQItem({
    required this.question,
    required this.answer,
    required this.icon,
  });
}