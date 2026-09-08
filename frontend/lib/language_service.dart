import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LanguageNotifier extends ChangeNotifier {
  String _lang = 'English';
  String get lang => _lang;
  set lang(String val) {
    if (_lang != val) {
      _lang = val;
      notifyListeners();
    }
  }
  
  void triggerRebuild() {
    notifyListeners();
  }
}

class LanguageService {
  static final LanguageNotifier currentLanguage = LanguageNotifier();
  
  // Cache of dynamically translated strings
  static final Map<String, String> _dynamicTamilCache = {};
  
  // Track keys currently being translated to prevent duplicate API requests
  static final Set<String> _pendingTranslations = {};

  // Comprehensive pre-seeded offline dictionary for instant and offline translation of key UI strings
  static final Map<String, String> _tamilDictionary = {
    'Boreo Dashboard': 'போரியோ டாஷ்போர்டு',
    'Quick Services': 'விரைவான சேவைகள்',
    'Calendar': 'நாட்காட்டி',
    'News & Events': 'செய்திகள் & நிகழ்வுகள்',
    'THANKS SCORE SUMMARY': 'நன்றி மதிப்பெண் சுருக்கம்',
    'TOTAL GIVEN': 'மொத்தம் வழங்கப்பட்டது',
    'TOTAL TAKEN': 'மொத்தம் பெறப்பட்டது',
    'THIS TERM': 'இந்த முறை',
    'FACE TO FACE': 'நேருக்கு நேர்',
    'Face to Face': 'நேருக்கு நேர்',
    'TOTAL COUNT': 'மொத்த எண்ணிக்கை',
    'Referrals Given': 'வழங்கப்பட்ட பரிந்துரைகள்',
    'Referrals Taken': 'பெறப்பட்ட பரிந்துரைகள்',
    'Meeting Attendance': 'கூட்ட வருகை',
    'Updated in real-time': 'உடனுக்குடன் புதுப்பிக்கப்படும்',
    'Member Directory': 'உறுப்பினர் அடைவு',
    'Member Details': 'உறுப்பினர் விவரங்கள்',
    'My Profile': 'எனது சுயவிவரம்',
    'Mobile Number': 'கைபேசி எண்',
    'Date of Birth': 'பிறந்த தேதி',
    'Wedding Day': 'திருமண நாள்',
    'Company Open Day': 'நிறுவனம் தொடங்கப்பட்ட நாள்',
    'Office Address': 'அலுவலக முகவரி',
    'Logout': 'வெளியேறு',
    'Home': 'முகப்பு',
    'Directory': 'அடைவு',
    'Thanks Note': 'நன்றி குறிப்பு',
    'REF / Thanks': 'REF / நன்றி',
    'Profile': 'சுயவிவரம்',
    'Apply Leave': 'விடுப்புக்கு விண்ணப்பி',
    'Attendance By-Law': 'வருகை விதிமுறை',
    'Thanks Note Activity': 'நன்றி குறிப்பு செயல்பாடு',
    'REF / Thanksnote': 'REF / நன்றிக்குறிப்பு',
    'Meetings & Events': 'கூட்டங்கள் & நிகழ்வுகள்',
    'My Member Profile': 'எனது உறுப்பினர் சுயவிவரம்',
    'Thanksnote History': 'நன்றிக்குறிப்பு வரலாறு',
    'Face to Face History': 'நேருக்கு நேர் வரலாறு',
    'Face to Face Form': 'நேருக்கு நேர் படிவம்',
    'Referrals': 'பரிந்துரைகள்',
    'Calendar Booking': 'நாட்காட்டி முன்பதிவு',
    'Exit App': 'செயலியை மூடு',
    'Are you sure you want to exit?': 'நிச்சயமாக வெளியேற வேண்டுமா?',
    'No': 'இல்லை',
    'Yes': 'ஆம்',
    'Rating': 'மதிப்பீடு',
    'Previous Feedback': 'முந்தைய பின்னூட்டம்',
    'Write Feedback': 'பின்னூட்டம் எழுதுங்கள்',
    'Submit Feedback': 'பின்னூட்டத்தை சமர்ப்பிக்கவும்',
    'No feedback yet': 'இன்னும் பின்னூட்டம் இல்லை',
    'Enter your business details to apply for Boreo membership': 'உறுப்பினர் சேர்க்கைக்கு உங்கள் வணிக விவரங்களை உள்ளிடவும்',
    
    // Meeting Screen specific
    'Regular Meeting': 'சாதாரண கூட்டம்',
    'Power Team Meeting': 'பவர் டீம் கூட்டம்',
    'Total Meetings': 'மொத்த கூட்டங்கள்',
    'Compulsary': 'கட்டாயம்',
    'Attended': 'வருகை புரிந்தது',
    'Scan QR Code to Check-In': 'வருகையை பதிவு செய்ய கியூஆர் குறியீட்டை ஸ்கேன் செய்யவும்',

    // Directory Screen specific
    'Personal': 'தனிப்பட்ட விவரங்கள்',
    'Business': 'வணிக விவரங்கள்',
    'Search by Name, Business, Phone...': 'பெயர், வணிகம், கைபேசி மூலம் தேடவும்...',
    'No members found': 'உறுப்பினர்கள் யாரும் இல்லை',
    'Try adjusting your search filters': 'வேறு வார்த்தைகளை பயன்படுத்தி தேடவும்',
    'Kootam': 'கூட்டம்',
    'Email': 'மின்னஞ்சல்',
    'Phone': 'கைபேசி எண்',
    'Blood Group': 'இரத்த பிரிவு',
    'Father Name': 'தந்தை பெயர்',
    'Spouse Name': 'துணைவர் பெயர்',
    'Education': 'கல்வி தகுதி',
    'Points Balance': 'புள்ளிகள் இருப்பு',
    'Business Name': 'வணிக பெயர்',
    'Industry': 'தொழில் துறை',
    'Location': 'இடம்',
    'Designation': 'பதவி',
    'Website': 'இணையதளம்',

    // Thanks Note Screen specific
    'Total Given': 'மொத்தம் வழங்கப்பட்டது',
    'Total Taken': 'மொத்தம் பெறப்பட்டது',
    'Add Thanksnote': 'நன்றிக்குறிப்பை சேர்க்க',
    'Referal': 'பரிந்துரை',
    'Thank You note': 'நன்றிக் குறிப்பு',
    'Referral Type': 'பரிந்துரை வகை',
    'Self': 'சுய',
    'Connect': 'இணைப்பு',
    'Member': 'உறுப்பினர்',
    'Direct': 'நேரடி',
    'Thank You Type': 'நன்றி வகை',
    'Connection Name / Details': 'இணைப்பு பெயர் / விவரங்கள்',
    'Select Member': 'உறுப்பினரைத் தேர்ந்தெடுக்கவும்',
    'Business Amount (₹)': 'வணிகத் தொகை (₹)',
    'Submit Referal': 'பரிந்துரையை சமர்ப்பிக்கவும்',
    'Submit Thanksnote': 'நன்றிக்குறிப்பை சமர்ப்பிக்கவும்',
    'View Thanksnote History': 'நன்றிக்குறிப்பு வரலாற்றைக் காண்க',
    
    // Face to Face Form specific
    'Your Name': 'உங்கள் பெயர்',
    'Whom are you doing Face to Face with?': 'யாருடன் முகத்திற்கு முகம் சந்திப்பு செய்கிறீர்கள்?',
    'Select member': 'உறுப்பினரைத் தேர்ந்தெடுக்கவும்',
    'Your Face to Face Date': 'உங்கள் முகத்திற்கு முகம் தேதி',
    'Select date': 'தேதியைத் தேர்ந்தெடுக்கவும்',
    'Submit Face to Face': 'முகத்திற்கு முகம் சமர்ப்பிக்கவும்',
    'View History': 'வரலாற்றைக் காண்க',
    'Face to Face Visitor': 'முகத்திற்கு முகம் பார்வையாளர்',
    'Face to Face Host': 'முகத்திற்கு முகம் நடத்துபவர்',
    'Description': 'விளக்கம்',
    'Per count': 'ஒரு முறைக்கு',
    'Font Size': 'எழுத்து அளவு',
    'Increase Font': 'எழுத்தை பெரிதாக்கு',
    'Decrease Font': 'எழுத்தை சிறிதாக்கு',
    'Reset to Default': 'இயல்பு நிலைக்கு மீட்டமை',
    
    // Early Going & Permission specific
    'Early Going': 'முன்கூட்டியே செல்லுதல்',
    'Apply Permission': 'அனுமதிக்கு விண்ணப்பி',
    'Permission Applied': 'அனுமதி விண்ணப்பிக்கப்பட்டது',
    'Cancel Permission': 'அனுமதியை ரத்துசெய்',
    'Permission window closed — this can no longer be changed for this meeting.': 'அனுமதி பெறும் காலம் முடிந்தது - இந்த கூட்டத்திற்கு இதை இனி மாற்ற முடியாது.',
    'Permission can be applied or cancelled until 4:30 PM the day before the meeting.': 'கூட்டத்திற்கு முந்தைய நாள் மாலை 4:30 மணி வரை அனுமதிக்கு விண்ணப்பிக்கலாம் அல்லது ரத்து செய்யலாம்.',

    // Visitor Form specific
    'Visitor Form': 'விருந்தினர் படிவம்',
    'Visitor Name': 'விருந்தினர் பெயர்',
    'Visitor Phone': 'விருந்தினர் கைபேசி எண்',
    'Visitor Business Category / Profession': 'விருந்தினர் வணிக வகை / தொழில்',
    'Visitor Company Name': 'விருந்தினர் நிறுவன பெயர்',
    'Visit Date': 'வருகை தேதி',
    'Submit Visitor': 'விருந்தினரை சமர்ப்பி',
    'Visitors History': 'விருந்தினர் வரலாறு',
    'Enter visitor name': 'விருந்தினர் பெயரை உள்ளிடவும்',
    'Enter visitor phone': 'விருந்தினர் கைபேசியை உள்ளிடவும்',
    'Enter business category': 'வணிக வகையை உள்ளிடவும்',
    'Enter company name (optional)': 'நிறுவன பெயரை உள்ளிடவும் (விருப்பத்தேர்வு)',
    "Please enter visitor's name": 'விருந்தினர் பெயரை உள்ளிடவும்',
    "Please enter visitor's phone": 'விருந்தினர் கைபேசியை உள்ளிடவும்',
    'Please enter business category': 'வணிக வகையை உள்ளிடவும்',
    'Visitor submitted successfully!': 'விருந்தினர் வெற்றிகரமாக சமர்ப்பிக்கப்பட்டார்!',
    'Failed to submit visitor. Please try again.': 'விருந்தினரை சமர்ப்பிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
    'No visitors registered yet': 'இதுவரை விருந்தினர்கள் யாரும் பதிவு செய்யப்படவில்லை',
    'open': 'திறந்தது',
    'close': 'மூடப்பட்டது',
    'View Referral': 'பரிந்துரைகளைக் காண்க',
    'View Thanksnote': 'நன்றியுரைகளைக் காண்க',
    'Become a member': 'உறுப்பினர் ஆகுங்கள்',
    'Full Name': 'முழு பெயர்',
    'Enter full name': 'முழு பெயரை உள்ளிடவும்',
    'Please enter full name': 'முழு பெயரை உள்ளிடவும்',
    'Enter business name': 'வணிக பெயரை உள்ளிடவும்',
    'Please enter business name': 'வணிக பெயரை உள்ளிடவும்',
    'Enter 10-digit number': '10-இலக்க எண்ணை உள்ளிடவும்',
    'Please enter mobile number': 'கைபேசி எண்ணை உள்ளிடவும்',
    'Please enter a valid 10-digit mobile number': 'சரியான 10-இலக்க கைபேசி எண்ணை உள்ளிடவும்',
    'Invited By': 'அழைத்தவர்',
    'Select Date': 'தேதியைத் தேர்ந்தெடுக்கவும்',
    'Please select date': 'தேதியைத் தேர்ந்தெடுக்கவும்',
    'Please select who invited you': 'உங்களை யார் அழைத்தார்கள் என்பதைத் தேர்ந்தெடுக்கவும்',
    'Register & Verify': 'பதிவு செய்து சரிபார்க்கவும்',
    'Application Submitted': 'விண்ணப்பம் சமர்ப்பிக்கப்பட்டது',
    'Your membership application has been submitted successfully. Please wait for management approval.': 'உங்கள் உறுப்பினர் விண்ணப்பம் வெற்றிகரமாக சமர்ப்பிக்கப்பட்டது. நிர்வாகத்தின் ஒப்புதலுக்காக காத்திருக்கவும்.',
    'OK': 'சரி',
    'Failed to submit application. Please try again.': 'விண்ணப்பத்தைச் சமர்ப்பிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
  };

  static String translate(String key) {
    if (currentLanguage.lang == 'English') {
      return key;
    }
    
    // Check pre-seeded dictionary
    if (_tamilDictionary.containsKey(key)) {
      return _tamilDictionary[key]!;
    }
    
    // Check dynamic translation cache
    if (_dynamicTamilCache.containsKey(key)) {
      return _dynamicTamilCache[key]!;
    }
    
    // If not cached and not currently fetching, trigger background Google Translate API call
    if (!_pendingTranslations.contains(key)) {
      _pendingTranslations.add(key);
      _fetchTranslationFromGoogle(key);
    }
    
    return key; // Return English key initially while fetching
  }

  static Future<void> _fetchTranslationFromGoogle(String text) async {
    if (text.isEmpty || RegExp(r'^\s*$').hasMatch(text)) return;
    
    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=ta&dt=t&q=${Uri.encodeComponent(text)}'
      );
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded != null && decoded[0] != null) {
          String translatedText = '';
          for (var item in decoded[0]) {
            if (item[0] != null) {
              translatedText += item[0];
            }
          }
          
          if (translatedText.isNotEmpty) {
            _dynamicTamilCache[text] = translatedText;
            _pendingTranslations.remove(text);
            
            // Notify listeners to rebuild UI with newly fetched translation safely outside build phase
            WidgetsBinding.instance.addPostFrameCallback((_) {
              currentLanguage.triggerRebuild();
            });
          }
        }
      } else {
        _pendingTranslations.remove(text);
      }
    } catch (e) {
      _pendingTranslations.remove(text);
      debugPrint('Google Translate API Error: $e');
    }
  }
}

String t(String key) => LanguageService.translate(key);
