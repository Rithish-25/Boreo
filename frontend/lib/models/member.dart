import 'child.dart';

/// Mirrors the `members/{uid}` document shape defined by the AdminPanel.
class Member {
  final String docId;
  final String uid;
  final String ridNo;
  final String fullName;
  final String email;
  final String phone;
  final String whatsappNumber;
  final String bloodGroup;
  final String fatherName;
  final String education;
  final String address;
  final String? profileImage;
  final String dateOfBirth; // "YYYY-MM-DD"
  final String companyName;
  final String businessType;
  final String businessAddress;
  final String officeNo;
  final String websiteUrl;
  final String socialMedia;
  final String joiningDate; // "YYYY-MM-DD"
  final String status; // "Active" | "Inactive"
  final String businessStartDate;
  final String experienceYears;
  final String businessExpertise;
  final String whyBuyFromYou;
  final String aboutBusiness;
  final String businessMission;
  final String businessVision;
  final String flyer;
  final String powerTeam;
  final String position;
  final String director;
  final String coordinator;
  final String introducedBy;
  final String authenticatedBy;
  final String memberQualification;
  final String wifeName;
  final String wifeDob;
  final String wedding;
  final String wifeBloodGroup;
  final String wifeQualification;
  final List<Child> sons;
  final List<Child> daughters;
  final int legacyFaceToFace;
  final int legacyBusinessGiven;
  final int legacyBusinessTaken;

  const Member({
    this.docId = "",
    this.uid = "",
    this.ridNo = "",
    this.fullName = "",
    this.email = "",
    this.phone = "",
    this.whatsappNumber = "",
    this.bloodGroup = "",
    this.fatherName = "",
    this.education = "",
    this.address = "",
    this.profileImage,
    this.dateOfBirth = "",
    this.companyName = "",
    this.businessType = "",
    this.businessAddress = "",
    this.officeNo = "",
    this.websiteUrl = "",
    this.socialMedia = "",
    this.joiningDate = "",
    this.status = "Active",
    this.businessStartDate = "",
    this.experienceYears = "",
    this.businessExpertise = "",
    this.whyBuyFromYou = "",
    this.aboutBusiness = "",
    this.businessMission = "",
    this.businessVision = "",
    this.flyer = "",
    this.powerTeam = "",
    this.position = "",
    this.director = "",
    this.coordinator = "",
    this.introducedBy = "",
    this.authenticatedBy = "",
    this.memberQualification = "",
    this.wifeName = "",
    this.wifeDob = "",
    this.wedding = "",
    this.wifeBloodGroup = "",
    this.wifeQualification = "",
    this.sons = const [],
    this.daughters = const [],
    this.legacyFaceToFace = 0,
    this.legacyBusinessGiven = 0,
    this.legacyBusinessTaken = 0,
  });

  bool get isActive => status == "Active";

  factory Member.fromMap(String docId, Map<String, dynamic> map) {
    // Legacy-alias fallback: read the canonical key first, fall back to the
    // older/typo key AdminPanel also wrote historically. Only ever WRITE the
    // canonical key from this app.
    String pick(String canonicalKey, [String? legacyKey]) {
      final canonical = map[canonicalKey];
      if (canonical != null && canonical.toString().isNotEmpty) {
        return canonical.toString();
      }
      if (legacyKey != null && map[legacyKey] != null) {
        return map[legacyKey].toString();
      }
      return canonical?.toString() ?? "";
    }

    List<Child> parseChildren(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => Child.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    return Member(
      docId: docId,
      uid: pick('uid').isNotEmpty ? pick('uid') : docId,
      ridNo: pick('ridNo'),
      fullName: pick('fullName'),
      email: pick('email'),
      phone: pick('phone'),
      whatsappNumber: pick('whatsappNumber'),
      bloodGroup: pick('bloodGroup'),
      fatherName: pick('fatherName'),
      education: pick('education'),
      address: pick('address'),
      profileImage: map['profileImage'] as String?,
      dateOfBirth: pick('dateOfBirth', 'dob'),
      companyName: pick('companyName'),
      businessType: pick('businessType'),
      businessAddress: pick('businessAddress', 'businessAddres'),
      officeNo: pick('officeNo'),
      websiteUrl: pick('websiteUrl'),
      socialMedia: pick('socialMedia'),
      joiningDate: pick('joiningDate'),
      status: pick('status').isNotEmpty ? pick('status') : "Active",
      businessStartDate: pick('businessStartDate'),
      experienceYears: pick('experienceYears', 'experience'),
      businessExpertise: pick('businessExpertise'),
      whyBuyFromYou: pick('whyBuyFromYou'),
      aboutBusiness: pick('aboutBusiness'),
      businessMission: pick('businessMission'),
      businessVision: pick('businessVision'),
      flyer: pick('flyer', 'businessFlyer'),
      powerTeam: pick('powerTeam'),
      position: pick('position'),
      director: pick('director'),
      coordinator: pick('coordinator'),
      introducedBy: pick('introducedBy'),
      authenticatedBy: pick('authenticatedBy'),
      memberQualification: pick('memberQualification'),
      wifeName: pick('wifeName'),
      wifeDob: pick('wifeDob'),
      wedding: pick('wedding'),
      wifeBloodGroup: pick('wifeBloodGroup'),
      wifeQualification: pick('wifeQualification'),
      sons: parseChildren(map['sons']),
      daughters: parseChildren(map['daughters']),
      legacyFaceToFace: map['legacyFaceToFace'] as int? ?? 0,
      legacyBusinessGiven: map['legacyBusinessGiven'] as int? ?? 0,
      legacyBusinessTaken: map['legacyBusinessTaken'] as int? ?? 0,
    );
  }

  /// Full canonical map — used only when creating brand-new fields; prefer
  /// building a small partial map of just-changed fields for updates so we
  /// never clobber fields this app's UI doesn't expose an editor for.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'ridNo': ridNo,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'whatsappNumber': whatsappNumber,
      'bloodGroup': bloodGroup,
      'fatherName': fatherName,
      'education': education,
      'address': address,
      'profileImage': profileImage,
      'dateOfBirth': dateOfBirth,
      'companyName': companyName,
      'businessType': businessType,
      'businessAddress': businessAddress,
      'officeNo': officeNo,
      'websiteUrl': websiteUrl,
      'socialMedia': socialMedia,
      'joiningDate': joiningDate,
      'status': status,
      'businessStartDate': businessStartDate,
      'experienceYears': experienceYears,
      'businessExpertise': businessExpertise,
      'whyBuyFromYou': whyBuyFromYou,
      'aboutBusiness': aboutBusiness,
      'businessMission': businessMission,
      'businessVision': businessVision,
      'flyer': flyer,
      'powerTeam': powerTeam,
      'position': position,
      'director': director,
      'coordinator': coordinator,
      'introducedBy': introducedBy,
      'authenticatedBy': authenticatedBy,
      'memberQualification': memberQualification,
      'wifeName': wifeName,
      'wifeDob': wifeDob,
      'wedding': wedding,
      'wifeBloodGroup': wifeBloodGroup,
      'wifeQualification': wifeQualification,
      'sons': sons.map((c) => c.toMap()).toList(),
      'daughters': daughters.map((c) => c.toMap()).toList(),
      'legacyFaceToFace': legacyFaceToFace,
      'legacyBusinessGiven': legacyBusinessGiven,
      'legacyBusinessTaken': legacyBusinessTaken,
    };
  }

  Member copyWith({
    String? ridNo,
    String? fullName,
    String? email,
    String? phone,
    String? whatsappNumber,
    String? bloodGroup,
    String? fatherName,
    String? education,
    String? address,
    String? profileImage,
    String? dateOfBirth,
    String? companyName,
    String? businessType,
    String? businessAddress,
    String? officeNo,
    String? websiteUrl,
    String? socialMedia,
    String? joiningDate,
    String? status,
    String? businessStartDate,
    String? experienceYears,
    String? businessExpertise,
    String? whyBuyFromYou,
    String? aboutBusiness,
    String? businessMission,
    String? businessVision,
    String? flyer,
    String? powerTeam,
    String? position,
    String? director,
    String? coordinator,
    String? wifeName,
    String? wifeDob,
    String? wedding,
    String? wifeBloodGroup,
    String? wifeQualification,
    int? legacyFaceToFace,
    int? legacyBusinessGiven,
    int? legacyBusinessTaken,
  }) {
    return Member(
      docId: docId,
      uid: uid,
      ridNo: ridNo ?? this.ridNo,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      fatherName: fatherName ?? this.fatherName,
      education: education ?? this.education,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      companyName: companyName ?? this.companyName,
      businessType: businessType ?? this.businessType,
      businessAddress: businessAddress ?? this.businessAddress,
      officeNo: officeNo ?? this.officeNo,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      socialMedia: socialMedia ?? this.socialMedia,
      joiningDate: joiningDate ?? this.joiningDate,
      status: status ?? this.status,
      businessStartDate: businessStartDate ?? this.businessStartDate,
      experienceYears: experienceYears ?? this.experienceYears,
      businessExpertise: businessExpertise ?? this.businessExpertise,
      whyBuyFromYou: whyBuyFromYou ?? this.whyBuyFromYou,
      aboutBusiness: aboutBusiness ?? this.aboutBusiness,
      businessMission: businessMission ?? this.businessMission,
      businessVision: businessVision ?? this.businessVision,
      flyer: flyer ?? this.flyer,
      powerTeam: powerTeam ?? this.powerTeam,
      position: position ?? this.position,
      director: director ?? this.director,
      coordinator: coordinator ?? this.coordinator,
      introducedBy: introducedBy,
      authenticatedBy: authenticatedBy,
      memberQualification: memberQualification,
      wifeName: wifeName ?? this.wifeName,
      wifeDob: wifeDob ?? this.wifeDob,
      wedding: wedding ?? this.wedding,
      wifeBloodGroup: wifeBloodGroup ?? this.wifeBloodGroup,
      wifeQualification: wifeQualification ?? this.wifeQualification,
      sons: sons,
      daughters: daughters,
      legacyFaceToFace: legacyFaceToFace ?? this.legacyFaceToFace,
      legacyBusinessGiven: legacyBusinessGiven ?? this.legacyBusinessGiven,
      legacyBusinessTaken: legacyBusinessTaken ?? this.legacyBusinessTaken,
    );
  }
}
