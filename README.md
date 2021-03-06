# Interval Skip List

This data structure maps intervals to values and allows you to find all
intervals that contain an index in `O(ln(n))`, where `n` is the number of
intervals stored. This implementation is based on Atom's
[interval-skip-list](https://github.com/atom/interval-skip-list),
which is in turn based on the paper
[The Interval Skip List](https://www.cise.ufl.edu/tr/DOC/REP-1992-45.pdf) by
Eric N. Hanson.

[![Build Status](https://travis-ci.org/kseo/interval_skip_list.svg)](https://travis-ci.org/kseo/interval_skip_list)
[![Coverage Status](https://coveralls.io/repos/kseo/interval_skip_list/badge.svg?branch=master&service=github)](https://coveralls.io/github/kseo/interval_skip_list?branch=master)

## Basic Usage Example

```dart
import 'package:interval_skip_list/interval_skip_list.dart';

final list = new IntervalSkipList(minIndex: -0x80000000, maxIndex: 0x7FFFFFFF);

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
```

## Using a Custom Comparator

You can also supply a custom comparator function with corresponding min and max
index values. The following example uses lists expressing coordinate pairs
instead of the default numeric values:

```dart
final list = new IntervalSkipList(
    minIndex: [-0x80000000],
    maxIndex: [0x7FFFFFFF], compare: (a, b) {
  if (a[0] < b[0]) return -1;
  else if (a[0] > b[0]) return 1;
  else {
    if (a[1] < b[1]) return -1;
    else if (a[1] > b[1]) return 1;
    else return 0;
  }
});

list.insert("a", [1, 2], [3, 4]);
list.insert("b", [2, 1], [3, 10]);
```

