/// A son/daughter entry, matching the shape AdminPanel stores in
/// members/{uid}.sons and members/{uid}.daughters.
class Child {
  final String name;
  final String dob;
  final String blood;
  final String qualification;

  const Child({
    this.name = "",
    this.dob = "",
    this.blood = "",
    this.qualification = "",
  });

  factory Child.fromMap(Map<String, dynamic> map) {
    return Child(
      name: map['name'] ?? "",
      dob: map['dob'] ?? "",
      blood: map['blood'] ?? "",
      qualification: map['qualification'] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dob': dob,
      'blood': blood,
      'qualification': qualification,
    };
  }
}
