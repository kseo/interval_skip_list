// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library interval_skip_list.example;

import 'package:interval_skip_list/interval_skip_list.dart';

main() {
  final list = new IntervalSkipList();

  list.insert('a', 2, 7);
  list.insert('b', 1, 5);
  list.insert('c', 8, 8);

  print(list.findContaining([1]));
  // ['b']
  print(list.findContaining([2]));
  // ['b', 'a']
  print(list.findContaining([8]));
  // ['c']

  list.remove('b');

  print(list.findContaining([2]));
  // ['a']
}
