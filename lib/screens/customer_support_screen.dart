import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../translations/app_translations.dart';

class CustomerSupportScreen extends StatelessWidget {
  const CustomerSupportScreen({Key? key}) : super(key: key);

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return Text(AppTranslations.getText('customerSupport', languageProvider.currentLanguage));
          },
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Support Image
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.support_agent,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return Text(
                        AppTranslations.getText('howCanWeHelp', languageProvider.currentLanguage),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return Text(
                        AppTranslations.getText('support24x7', languageProvider.currentLanguage),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Contact Options
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Phone Support Card
                  _buildContactCard(
                    context,
                    icon: Icons.phone,
                    title: AppTranslations.getText('phoneSupport', Provider.of<LanguageProvider>(context).currentLanguage),
                    subtitle: '+91 95087 08003',
                    onTap: () => _launchUrl('tel:+919508708003'),
                    color: Colors.blue,
                  ),

                  // WhatsApp Support Card
                  _buildContactCard(
                    context,
                    icon: FontAwesomeIcons.whatsapp,
                    title: AppTranslations.getText('whatsappSupport', Provider.of<LanguageProvider>(context).currentLanguage),
                    subtitle: '+91 95087 08003',
                    onTap: () => _launchUrl('https://wa.me/919508708003'),
                    color: Colors.green,
                  ),

                  // Email Support Card
                  _buildContactCard(
                    context,
                    icon: Icons.email,
                    title: AppTranslations.getText('emailSupport', Provider.of<LanguageProvider>(context).currentLanguage),
                    subtitle: 'support@krishika.com',
                    onTap: () => _launchUrl('mailto:support@krishika.com'),
                    color: Colors.red,
                  ),

                  // Visit Website Card
                  _buildContactCard(
                    context,
                    icon: Icons.language,
                    title: AppTranslations.getText('visitWebsite', Provider.of<LanguageProvider>(context).currentLanguage),
                    subtitle: 'www.krishika.com',
                    onTap: () => _launchUrl('https://agro-galaxy.vercel.app/'),
                    color: Colors.purple,
                  ),
                ],
              ),
            ),

            // FAQs Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return Text(
                        AppTranslations.getText('faqTitle', languageProvider.currentLanguage),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFaqItem(
                    AppTranslations.getText('faq1Question', Provider.of<LanguageProvider>(context).currentLanguage),
                    AppTranslations.getText('faq1Answer', Provider.of<LanguageProvider>(context).currentLanguage),
                  ),
                  _buildFaqItem(
                    AppTranslations.getText('faq2Question', Provider.of<LanguageProvider>(context).currentLanguage),
                    AppTranslations.getText('faq2Answer', Provider.of<LanguageProvider>(context).currentLanguage),
                  ),
                  _buildFaqItem(
                    AppTranslations.getText('faq3Question', Provider.of<LanguageProvider>(context).currentLanguage),
                    AppTranslations.getText('faq3Answer', Provider.of<LanguageProvider>(context).currentLanguage),
                  ),
                ],
              ),
            ),

            // Support Hours
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return Text(
                        AppTranslations.getText('supportHours', languageProvider.currentLanguage),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return Text(
                        AppTranslations.getText('supportTimings', languageProvider.currentLanguage),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            answer,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}