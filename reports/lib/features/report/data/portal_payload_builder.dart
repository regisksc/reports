part of 'portal_submission_client.dart';

_Json _preparedParams(
  Report report,
  _Json config,
  _Json contact,
  _Json address,
  String status,
  List<_Json> photoLinks,
  IllegalDumpingCatalog? itemCatalog,
) {
  final answers = {
    if (itemCatalog == null) ...{
      'Provide_Information_On_Suspect__c': 'No',
      'Illegally_Dumped_Item_Type__c': "I'm not sure",
      'Illegally_Dumped_Pickup_Options__c': 'Loose/Miscellaneous Debris',
      'Location_of_Loose_Miscellaneous_Debris__c': report.debrisLocation!,
      'No_of_Loose_Miscellaneous_Debris__c': '${report.quantity}',
    },
    if (itemCatalog == null) 'Description': report.description,
  };
  final selected = itemCatalog == null
      ? <String, String>{}
      : _selectedAnswers(report, itemCatalog, config);
  return {
    'sObjCase': _caseFields(config, address, status),
    'sObjContact': jsonEncode({
      ...contact,
      'isAnonymously': report.contact?.anonymous ?? true,
      if (report.contact case final details? when !details.anonymous) ...{
        'sFirstName': details.firstName.trim(),
        'sLastName': details.lastName.trim(),
        'sEmail': details.email.trim(),
        'sPhone': details.phone.trim().isEmpty ? null : details.phone.trim(),
      },
    }),
    'sCaseQuestionJSON': jsonEncode(_questionConfig(config, answers, selected)),
    'sFileLinks': jsonEncode(photoLinks),
    'isSNC': false,
    'addressDetails': jsonEncode(address),
  };
}

Map<String, String> _selectedAnswers(
  Report report,
  IllegalDumpingCatalog catalog,
  _Json config,
) {
  final family = catalog.families.singleWhere(
    (item) => item.name == report.itemFamily,
  );
  final questions = _objects(config['lstCaseQuestion']);
  final ids = <String>{};
  for (final question in questions) {
    final id = question['sQuestionId'];
    if (id is! String || id.isEmpty || !ids.add(id)) {
      throw const _Failure(
        SubmissionFailureKind.rejected,
        'City item questions changed. No request was sent.',
      );
    }
  }

  _Json requireQuestion(
    String field,
    String type, {
    _Json? parent,
    String? parentAnswer,
  }) {
    final matches = questions.where((question) {
      if (question['sFieldtoUpdate'] != field ||
          question['sQuestionType'] != type) {
        return false;
      }
      if (parent == null) {
        return question['sParentQuestionId'] == null &&
            question['sParentAnswer'] == '';
      }
      final answers = question['sParentAnswer'];
      return question['sParentQuestionId'] == parent['sQuestionId'] &&
          answers is String &&
          answers
              .split(';')
              .map((value) => value.trim())
              .contains(parentAnswer);
    }).toList();
    if (matches.length != 1) {
      throw const _Failure(
        SubmissionFailureKind.rejected,
        'City item questions changed. No request was sent.',
      );
    }
    return matches.single;
  }

  void requireOption(_Json question, String value) {
    if (!_objects(
      question['lstOptions'],
    ).any((option) => option['value'] == value)) {
      throw const _Failure(
        SubmissionFailureKind.rejected,
        'City item options changed. No request was sent.',
      );
    }
  }

  final description = requireQuestion('Description', 'TextArea');
  final residential = requireQuestion('Residential_Commercial__c', 'Picklist');
  if (residential['sAnswer'] != 'Residential' ||
      residential['sDefaultValue'] != 'Residential' ||
      residential['sReadOnly'] != true ||
      residential['sHidden'] != true) {
    throw const _Failure(
      SubmissionFailureKind.rejected,
      'City item questions changed. No request was sent.',
    );
  }
  final suspect = requireQuestion(
    'Provide_Information_On_Suspect__c',
    'Picklist',
  );
  requireOption(suspect, 'No');
  final type = requireQuestion(
    'Illegally_Dumped_Item_Type__c',
    'Picklist',
    parent: suspect,
    parentAnswer: 'No',
  );
  requireOption(type, family.name);
  final selection = requireQuestion(
    family.selectionField,
    'MultiPicklist',
    parent: type,
    parentAnswer: family.name,
  );
  final answers = <String, String>{
    suspect['sQuestionId'] as String: 'No',
    description['sQuestionId'] as String: report.description,
    type['sQuestionId'] as String: family.name,
    selection['sQuestionId'] as String: report.items
        .map((item) => item.name)
        .join(';'),
  };
  for (final item in report.items) {
    final definition = family.items.singleWhere(
      (entry) => entry.name == item.name,
    );
    requireOption(selection, item.name);
    final location = requireQuestion(
      definition.locationField,
      'Picklist',
      parent: selection,
      parentAnswer: item.name,
    );
    requireOption(location, item.location!);
    final quantity = requireQuestion(
      definition.quantityField,
      'NumberIncrement',
      parent: selection,
      parentAnswer: item.name,
    );
    answers[location['sQuestionId'] as String] = item.location!;
    answers[quantity['sQuestionId'] as String] = item.quantity;
  }

  return answers;
}

_Json _questionConfig(
  _Json config,
  Map<String, String> answers,
  Map<String, String> selected,
) {
  final questions = [
    for (final item in _objects(config['lstCaseQuestion']))
      if (item['sFieldtoUpdate'] != null) _answered(item, answers, selected),
  ]..sort((a, b) => (a['iOrder'] as int).compareTo(b['iOrder'] as int));
  final copy = {...config}..remove('dwpContainerLst');
  copy['lstCaseQuestion'] = questions;
  return copy;
}

_Json _answered(
  _Json item,
  Map<String, String> answers,
  Map<String, String> selected,
) {
  final answer =
      selected[item['sQuestionId']] ?? answers[item['sFieldtoUpdate']];
  final order = item['iOrder'];
  return {
    ...item,
    'iOrder': order is num ? order.floor() : 0,
    if (answer != null) ...{'sAnswer': answer, 'sDisplay': true},
  };
}

_Json _caseFields(_Json config, _Json address, String status) => {
  'Type': config['sCaseType'],
  'Priority': config['sCasePriority'],
  'Status': config['sCaseDefaultStatus'],
  'Hide_from_Web__c': config['sHideFromWeb'],
  'Origin': 'Self Service',
  'Created_From_SNC__c': 'No',
  'Tech_SNC_CaseNumber__c': '',
  'Street_Address__c': address['ShortLabel'],
  'City__c': address['City'],
  'Zipcode__c': address['Postal'],
  'Geolocation__Longitude__s': address['X'],
  'Geolocation__Latitude__s': address['Y'],
  'State__c': 'CA',
  'Country__c': 'US',
  'Address_Status__c': status,
  'Google_Address__c': address['LongLabel'],
  'Address_Entry_Method__c': 'Device Location',
  'Session_Tracking_ID__c': _uuidV4(),
  'Browser_Info__c': 'None (native iOS app)',
  'Platform_Info__c': 'iOS',
  'Device_Info__c': 'Mobile',
  'Application_Info__c': 'LA Dump Report',
  'Access_Source__c': _userAgent,
  'CCB_SA_Types__c': '',
};

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
