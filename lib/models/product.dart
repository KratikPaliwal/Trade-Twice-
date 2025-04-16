import 'package:flutter/foundation.dart';

class Trade {
  static List<Items> items = [];
}


class Items {
final String id;
final String name;
final String des;
final num bprice;
final num sprice;
final String color;
final String imageurl;

Items({
required this.id,
required this.name,
required this.des,
required this.bprice,
required this.sprice,
required this.color,
required this.imageurl,
});

factory Items.fromMap(Map<String, dynamic> map) {
  return Items(
    id: map['id'],
    name: map['name'],
    des: map['des'],
    bprice: map['bprice'],
    sprice: map['sprice'],
    color: map['color'],
    imageurl: map['imageurl'],
  );
}

toMap() => {
  'id': id,
  'name': name,
  'des': des,
  'bprice': bprice,
  'sprice': sprice,
  'color': color,
  'imageurl': imageurl,
};



}
