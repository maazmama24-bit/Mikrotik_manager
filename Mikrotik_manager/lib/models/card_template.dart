import 'dart:convert';

// =============================================================================
// Card Template Model
// =============================================================================

/// حقل واحد داخل القالب (اسم، كلمة مرور، مدة، بيانات، مخصص...).
class TemplateField {
  /// معرف فريد للحقل
  String id;

  /// عنوان الحقل (يظهر في المعاينة فقط)
  String label;

  /// المفتاح في بيانات الكرت (name, password, limit-uptime, limit-gb...)
  /// أو نص مخصص إذا كان isCustom = true
  String key;

  /// هل هذا حقل مخصص (نص ثابت)؟
  bool isCustom;

  /// القيمة الافتراضية للحقل المخصص
  String customValue;

  /// هل الحقل مفعّل؟
  bool enabled;

  /// حجم الخط الخاص بالحقل
  double fontSize;

  /// نوع الخط: normal / bold / italic
  String fontStyle;

  /// الموضع الأفقي (0.0 - 1.0)
  double x;

  /// الموضع العمودي (0.0 - 1.0)
  double y;

  /// إظهار/إخفاء الحقل
  bool visible;

  TemplateField({
    required this.id,
    required this.label,
    required this.key,
    this.isCustom = false,
    this.customValue = '',
    this.enabled = true,
    this.fontSize = 10,
    this.fontStyle = 'normal',
    this.x = 0.5,
    this.y = 0.5,
    this.visible = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'key': key,
    'isCustom': isCustom,
    'customValue': customValue,
    'enabled': enabled,
    'fontSize': fontSize,
    'fontStyle': fontStyle,
    'x': x,
    'y': y,
    'visible': visible,
  };

  factory TemplateField.fromJson(Map<String, dynamic> json) {
    return TemplateField(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      key: json['key'] as String? ?? '',
      isCustom: json['isCustom'] as bool? ?? false,
      customValue: json['customValue'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 10,
      fontStyle: json['fontStyle'] as String? ?? 'normal',
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.5,
      visible: json['visible'] as bool? ?? true,
    );
  }

  TemplateField copy() {
    return TemplateField(
      id: id,
      label: label,
      key: key,
      isCustom: isCustom,
      customValue: customValue,
      enabled: enabled,
      fontSize: fontSize,
      fontStyle: fontStyle,
      x: x,
      y: y,
      visible: visible,
    );
  }
}

// =============================================================================
// Card Template
// =============================================================================

/// قالب طباعة كامل.
class CardTemplate {
  /// معرف فريد
  String id;

  /// اسم القالب (يظهر في القائمة)
  String name;

  /// وصف مختصر
  String description;

  // ---------------------------------------------------------------------------
  // التصميم العام
  // ---------------------------------------------------------------------------

  /// عرض الكرت (mm)
  double cardWidth;

  /// ارتفاع الكرت (mm)
  double cardHeight;

  /// حجم الخط الافتراضي (pt)
  double fontSize;

  /// نوع الخط: normal / bold / italic / boldItalic
  String fontStyle;

  /// لون النص: 0 = أسود، 1 = رمادي، 2 = أزرق، 3 = أحمر
  int textColor;

  /// لون الخلفية: 0 = أبيض، 1 = رمادي فاتح، 2 = أصفر فاتح، 3 = أزرق فاتح
  int backgroundColor;

  /// نوع الحدود: 0 = بدون، 1 = عادي، 2 = مزدوج، 3 = متقطع
  int borderStyle;

  /// سماكة الحدود
  double borderWidth;

  /// محاذاة النص: right / center / left
  String textAlign;

  // ---------------------------------------------------------------------------
  // التخطيط
  // ---------------------------------------------------------------------------

  /// عدد الصفوف في الصفحة
  int rows;

  /// عدد الأعمدة في الصفحة
  int cols;

  /// اسم الشبكة (يظهر في الكرت)
  String networkName;

  /// إظهار اسم الشبكة
  bool showNetworkName;

  // ---------------------------------------------------------------------------
  // الشعار
  // ---------------------------------------------------------------------------

  /// مسار صورة الشعار (محلي)
  String? logoPath;

  /// عرض الشعار (mm)
  double logoWidth;

  /// ارتفاع الشعار (mm)
  double logoHeight;

  /// موضع الشعار: top / bottom / left
  String logoPosition;

  // ---------------------------------------------------------------------------
  // الحقول
  // ---------------------------------------------------------------------------
  /// مسار صورة الخلفية (مثال: assets/templates/template_1.jpg)
  String? backgroundImage;
  /// قائمة الحقول مرتبة
  List<TemplateField> fields;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  CardTemplate({
    required this.id,
    required this.name,
    this.description = '',
    this.cardWidth = 23,
    this.cardHeight = 23,
    this.fontSize = 10,
    this.fontStyle = 'normal',
    this.textColor = 0,
    this.backgroundColor = 0,
    this.borderStyle = 1,
    this.borderWidth = 0.5,
    this.textAlign = 'right',
    this.rows = 12,
    this.cols = 8,
    this.networkName = 'MikroTik',
    this.showNetworkName = true,
    this.logoPath,
    this.logoWidth = 15,
    this.logoHeight = 15,
    this.logoPosition = 'top',
    this.backgroundImage,
    List<TemplateField>? fields,
  }) : fields = fields ?? [];

  // ---------------------------------------------------------------------------
  // JSON
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'cardWidth': cardWidth,
    'cardHeight': cardHeight,
    'fontSize': fontSize,
    'fontStyle': fontStyle,
    'textColor': textColor,
    'backgroundColor': backgroundColor,
    'borderStyle': borderStyle,
    'borderWidth': borderWidth,
    'textAlign': textAlign,
    'rows': rows,
    'cols': cols,
    'networkName': networkName,
    'showNetworkName': showNetworkName,
    'logoPath': logoPath,
    'logoWidth': logoWidth,
    'logoHeight': logoHeight,
    'logoPosition': logoPosition,
    'backgroundImage': backgroundImage,
    'fields': fields.map((f) => f.toJson()).toList(),
  };

  factory CardTemplate.fromJson(Map<String, dynamic> json) {
    return CardTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      cardWidth: (json['cardWidth'] as num?)?.toDouble() ?? 80,
      cardHeight: (json['cardHeight'] as num?)?.toDouble() ?? 50,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 10,
      fontStyle: json['fontStyle'] as String? ?? 'normal',
      textColor: json['textColor'] as int? ?? 0,
      backgroundColor: json['backgroundColor'] as int? ?? 0,
      borderStyle: json['borderStyle'] as int? ?? 1,
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 0.5,
      textAlign: json['textAlign'] as String? ?? 'right',
      rows: json['rows'] as int? ?? 5,
      cols: json['cols'] as int? ?? 2,
      networkName: json['networkName'] as String? ?? 'MikroTik',
      showNetworkName: json['showNetworkName'] as bool? ?? true,
      logoPath: json['logoPath'] as String?,
      logoWidth: (json['logoWidth'] as num?)?.toDouble() ?? 15,
      logoHeight: (json['logoHeight'] as num?)?.toDouble() ?? 15,
      logoPosition: json['logoPosition'] as String? ?? 'top',
      backgroundImage: json['backgroundImage'] as String?,
      fields: (json['fields'] as List<dynamic>?)
          ?.map((f) => TemplateField.fromJson(f as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory CardTemplate.fromJsonString(String jsonString) {
    return CardTemplate.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  CardTemplate copy() {
    return CardTemplate(
      id: id,
      name: name,
      description: description,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      fontSize: fontSize,
      fontStyle: fontStyle,
      textColor: textColor,
      backgroundColor: backgroundColor,
      borderStyle: borderStyle,
      borderWidth: borderWidth,
      textAlign: textAlign,
      rows: rows,
      cols: cols,
      networkName: networkName,
      showNetworkName: showNetworkName,
      logoPath: logoPath,
      logoWidth: logoWidth,
      logoHeight: logoHeight,
      logoPosition: logoPosition,
      backgroundImage: backgroundImage,
      fields: fields.map((f) => f.copy()).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // الحقول الافتراضية
  // ---------------------------------------------------------------------------

  /// إنشاء الحقول الافتراضية.
  static List<TemplateField> defaultFields() {
    return [
      TemplateField(
        id: 'f_network',
        label: 'اسم الشبكة',
        key: 'network',
        fontSize: 14,
        fontStyle: 'bold',
        x: 0.5,
        y: 0.10,
      ),
      TemplateField(
        id: 'f_name',
        label: 'اسم المستخدم',
        key: 'name',
        fontSize: 22,
        fontStyle: 'bold',
        x: 0.5,
        y: 0.35,
      ),
      TemplateField(
        id: 'f_password',
        label: 'كلمة المرور',
        key: 'password',
        fontSize: 12,
        fontStyle: 'normal',
        x: 0.5,
        y: 0.50,
        visible: false,
      ),
      TemplateField(
        id: 'f_uptime',
        label: 'المدة',
        key: 'limit-uptime',
        fontSize: 11,
        fontStyle: 'normal',
        x: 0.5,
        y: 0.60,
      ),
      TemplateField(
        id: 'f_gb',
        label: 'البيانات',
        key: 'limit-gb',
        fontSize: 11,
        fontStyle: 'normal',
        x: 0.5,
        y: 0.72,
      ),
      TemplateField(
        id: 'f_note1',
        label: 'ملاحظات 1',
        key: 'note1',
        fontSize: 9,
        fontStyle: 'normal',
        x: 0.5,
        y: 0.82,
        visible: false,
      ),
      TemplateField(
        id: 'f_note2',
        label: 'ملاحظات 2',
        key: 'note2',
        fontSize: 9,
        fontStyle: 'normal',
        x: 0.5,
        y: 0.90,
        visible: false,
      ),
      TemplateField(
        id: 'f_notes',
        label: 'ملاحظات',
        key: 'comment',
        fontSize: 9,
        fontStyle: 'normal',
        x: 0.5,
        y: 0.97,
        visible: false,
      ),
    ];
  }
}