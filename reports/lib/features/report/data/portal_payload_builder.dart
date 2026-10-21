part of 'portal_submission_client.dart';

_Json _preparedParams(
  Report report,
  _Json config,
  _Json contact,
  _Json address,
  String status,
  List<_Json> photoLinks,
) {
  final answers = {
    'Provide_Information_On_Suspect__c': 'No',
    'Illegally_Dumped_Item_Type__c': "I'm not sure",
    'Illegally_Dumped_Pickup_Options__c': 'Loose/Miscellaneous Debris',
    'Location_of_Loose_Miscellaneous_Debris__c': report.debrisLocation!,
    'No_of_Loose_Miscellaneous_Debris__c': '${report.quantity}',
    'Description': report.description,
  };
  return {
    'sObjCase': _caseFields(config, address, status),
    'sObjContact': jsonEncode({...contact, 'isAnonymously': true}),
    'sCaseQuestionJSON': jsonEncode(_questionConfig(config, answers)),
    'sFileLinks': jsonEncode(photoLinks),
    'isSNC': false,
    'addressDetails': jsonEncode(address),
  };
}

_Json _questionConfig(_Json config, Map<String, String> answers) {
  final questions = [
    for (final item in _objects(config['lstCaseQuestion']))
      if (item['sFieldtoUpdate'] != null) _answered(item, answers),
  ]..sort((a, b) => (a['iOrder'] as int).compareTo(b['iOrder'] as int));
  final copy = {...config}..remove('dwpContainerLst');
  copy['lstCaseQuestion'] = questions;
  return copy;
}

_Json _answered(_Json item, Map<String, String> answers) {
  final answer = answers[item['sFieldtoUpdate']];
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

