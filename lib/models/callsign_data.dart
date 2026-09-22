class CallsignData {
  final String callsign;
  final String name;
  final String fname;
  final String addr1;
  final String addr2;
  final String state;
  final String zip;
  final String country;
  final String email;
  final String lat;
  final String lon;
  final String county;
  final String grid;
  final String land;
  final String born;
  final String class_;
  final String qslVia;
  final String eqsl;
  final String mgr;
  final String image;

  CallsignData({
    this.callsign = '',
    this.name = '',
    this.fname = '',
    this.addr1 = '',
    this.addr2 = '',
    this.state = '',
    this.zip = '',
    this.country = '',
    this.email = '',
    this.lat = '',
    this.lon = '',
    this.county = '',
    this.grid = '',
    this.land = '',
    this.born = '',
    this.class_ = '',
    this.qslVia = '',
    this.eqsl = '',
    this.mgr = '',
    this.image = '',
  });

  factory CallsignData.fromMap(Map<String, String> map) {
    return CallsignData(
      callsign: map['call'] ?? '',
      name: map['name'] ?? '',
      fname: map['fname'] ?? '',
      addr1: map['addr1'] ?? '',
      addr2: map['addr2'] ?? '',
      state: map['state'] ?? '',
      zip: map['zip'] ?? '',
      country: map['country'] ?? '',
      email: map['email'] ?? '',
      lat: map['lat'] ?? '',
      lon: map['lon'] ?? '',
      county: map['county'] ?? '',
      grid: map['grid'] ?? '',
      land: map['land'] ?? '',
      born: map['born'] ?? '',
      class_: map['class'] ?? '',
      qslVia: map['qslvia'] ?? '',
      eqsl: map['eqslqsl'] ?? '',
      mgr: map['mgr'] ?? '',
      image: map['image'] ?? '',
    );
  }

  String get fullName {
    if (fname.isNotEmpty && name.isNotEmpty) {
      return '$fname $name';
    }
    return name;
  }

  String get location {
    final parts = [addr2, state, country].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }
}
