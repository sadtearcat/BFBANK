class AccountProduct {
  final int id;
  final String name;
  final String category;
  final String description;
  final Map<String, String> features;
  final double interestRate;
  final int minimumAmount;
  final int maximumAmount;
  final List<String> benefits;
  final String depositType;

  AccountProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.features,
    required this.interestRate,
    required this.minimumAmount,
    required this.maximumAmount,
    required this.benefits,
    required this.depositType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'features': features,
      'interestRate': interestRate,
      'minimumAmount': minimumAmount,
      'maximumAmount': maximumAmount,
      'benefits': benefits,
      'depositType': depositType,
    };
  }

  factory AccountProduct.fromJson(Map<String, dynamic> json) {
    return AccountProduct(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      features: Map<String, String>.from(json['features']),
      interestRate: json['interestRate'].toDouble(),
      minimumAmount: json['minimumAmount'],
      maximumAmount: json['maximumAmount'],
      benefits: List<String>.from(json['benefits']),
      depositType: json['depositType'],
    );
  }

  @override
  String toString() {
    return 'AccountProduct(id: $id, name: $name, category: $category, interestRate: $interestRate%)';
  }
}

class AccountTerms {
  final String title;
  final String content;
  final List<TermsSection> sections;

  AccountTerms({
    required this.title,
    required this.content,
    required this.sections,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'sections': sections.map((section) => section.toJson()).toList(),
    };
  }

  factory AccountTerms.fromJson(Map<String, dynamic> json) {
    return AccountTerms(
      title: json['title'],
      content: json['content'],
      sections: (json['sections'] as List)
          .map((section) => TermsSection.fromJson(section))
          .toList(),
    );
  }
}

class TermsSection {
  final String title;
  final List<String> content;

  TermsSection({
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }

  factory TermsSection.fromJson(Map<String, dynamic> json) {
    return TermsSection(
      title: json['title'],
      content: List<String>.from(json['content']),
    );
  }
} 