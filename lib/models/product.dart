class Items {
  final String name;
  final String des;
  final int bprice;
  final int sprice;
  final String imageurl;
  final String id;

  Items({
    required this.name,
    required this.des,
    required this.bprice,
    required this.sprice,
    required this.imageurl,
    required this.id, required color,
  });

  // Factory constructor from Firebase document
  factory Items.fromMap(Map<String, dynamic> map, String id) {
    return Items(
      name: map['name'] ?? '',
      des: map['des'] ?? '',
      bprice: map['bprice'] ?? 0,
      sprice: map['sprice'] ?? 0,
      imageurl: map['imageurl'] ?? '',
      id: id, color: null,
    );
  }

  // JSON serializer for storing locally
  factory Items.fromJson(Map<String, dynamic> json) {
    return Items(
      name: json['name'] ?? '',
      des: json['des'] ?? '',
      bprice: json['bprice'] ?? 0,
      sprice: json['sprice'] ?? 0,
      imageurl: json['imageurl'] ?? '',
      id: json['id'] ?? '', color: null,
    );
  }

  // JSON serializer for storing locally
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'des': des,
      'bprice': bprice,
      'sprice': sprice,
      'imageurl': imageurl,
      'id': id,
    };
  }
}
