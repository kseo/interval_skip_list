// Copyright (c) 2015, Kwang Yul Seo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library interval_skip_list.test;

import 'dart:math';

import 'package:interval_skip_list/interval_skip_list.dart';
import 'package:test/test.dart';

Random randomGen = new Random();

void times(int count, void f(int index)) {
  for (int i = 0; i < count; i++) {
    f(i);
  }
}

int random(int max) => randomGen.nextInt(max);

List<int> getRandomInterval() {
  final a = random(100);
  final b = random(100);
  return [min(a, b), max(a, b)];
}

void insertRandomInterval(IntervalSkipList<int, String> list, String marker) {
  final interval = getRandomInterval();
  list.insert(marker, interval[0], interval[1]);
}

void removeRandomInterval(IntervalSkipList<int, String> list) {
  final existingMarkers = list.intervalsByMarker.keys.toList();
  if (existingMarkers.isNotEmpty) {
    final existingMarker = existingMarkers[random(existingMarkers.length)];
    list.remove(existingMarker);
  }
}

void performRandomChange(IntervalSkipList<int, String> list, int i) {
  if (randomGen.nextDouble() < 0.2) {
    removeRandomInterval(list);
  } else {
    insertRandomInterval(list, i.toString());
  }
}

IntervalSkipList<int, String> buildRandomList() {
  final list = new IntervalSkipList();
  times(100, (i) => performRandomChange(list, i));
  return list;
}

void main() {
  group('findContaining(index...)', () {
    group('when passed a single index', () {
      test('returns markers for intervals containing the given index', () {
        times(10, (_) {
          final list = buildRandomList();
          times(10, (_) {
            final index = random(100);
            final markers = list.findContaining([index]);
            expect(markers.toSet(), markers);
            for (final marker in list.intervalsByMarker.keys) {
              final interval = list.intervalsByMarker[marker];
              final startIndex = interval.startIndex;
              final endIndex = interval.endIndex;
              if (startIndex <= index && index <= endIndex) {
                expect(markers, contains(marker));
              } else {
                expect(markers, isNot(contains(marker)));
              }
            }
          });
        });
      });
    });

    group('when passed an index range', () {
      test('returns markers for intervals containing both indices', () {
        times(10, (_) {
          final list = buildRandomList();
          times(10, (_) {
            final a = random(100);
            final b = random(100);
            final startIndex = min(a, b);
            final endIndex = max(a, b);
            final markers = list.findContaining([startIndex, endIndex]);
            for (final marker in list.intervalsByMarker.keys) {
              final interval = list.intervalsByMarker[marker];
              final intervalStart = interval.startIndex;
              final intervalEnd = interval.endIndex;
              if (intervalStart <= startIndex &&
                  startIndex <= endIndex &&
                  endIndex <= intervalEnd) {
                expect(markers, contains(marker));
              } else {
                expect(markers, isNot(contains(marker)));
              }
            }
          });
        });
      });
    });
  });

  group('findIntersecting(searchStartIndex, searchEndIndex)', () {
    test('returns markers for intervals intersecting the given index range',
        () {
      times(10, (_) {
        final list = buildRandomList();
        times(10, (_) {
          final a = random(100);
          final b = random(100);
          final searchStartIndex = min(a, b);
          final searchEndIndex = max(a, b);
          final markers =
              list.findIntersecting(searchStartIndex, searchEndIndex);

          for (final marker in list.intervalsByMarker.keys) {
            final interval = list.intervalsByMarker[marker];
            final intervalStart = interval.startIndex;
            final intervalEnd = interval.endIndex;
            if (intervalEnd < searchStartIndex ||
                intervalStart > searchEndIndex) {
              expect(markers, isNot(contains(marker)));
            } else {
              expect(markers, contains(marker));
            }
          }
        });
      });
    });
  });

  group('findStartingAt(index)', () {
    test('returns markers for intervals starting at the given index', () {
      times(10, (_) {
        final list = buildRandomList();
        times(10, (_) {
          final index = random(100);
          final markers = list.findStartingAt(index);
          for (final marker in list.intervalsByMarker.keys) {
            final interval = list.intervalsByMarker[marker];
            final startIndex = interval.startIndex;
            if (startIndex == index) {
              expect(markers, contains(marker));
            } else {
              expect(markers, isNot(contains(marker)));
            }
          }
        });
      });
    });
  });

  group('findEndingAt(index)', () {
    test('returns markers for intervals ending at the given index', () {
      times(10, (_) {
        final list = buildRandomList();
        times(10, (_) {
          final index = random(100);
          final markers = list.findEndingAt(index);
          for (final marker in list.intervalsByMarker.keys) {
            final interval = list.intervalsByMarker[marker];
            final endIndex = interval.endIndex;
            if (endIndex == index) {
              expect(markers, contains(marker));
            } else {
              expect(markers, isNot(contains(marker)));
            }
          }
        });
      });
    });
  });

  group('findStartingIn(startIndex, endIndex)', () {
    test('returns markers for intervals starting within the given index range',
        () {
      times(10, (_) {
        final list = buildRandomList();
        times(10, (_) {
          final interval = getRandomInterval();
          final searchStartIndex = interval[0];
          final searchEndIndex = interval[1];
          final markers = list.findStartingIn(searchStartIndex, searchEndIndex);
          for (final marker in list.intervalsByMarker.keys) {
            final interval = list.intervalsByMarker[marker];
            final startIndex = interval.startIndex;
            if (searchStartIndex <= startIndex &&
                startIndex <= searchEndIndex) {
              expect(markers, contains(marker));
            } else {
              expect(markers, isNot(contains(marker)));
            }
          }
        });
      });
    });
  });

  group('findEndingIn(startIndex, endIndex)', () {
    test('returns markers for intervals ending within the given index range',
        () {
      times(10, (_) {
        final list = buildRandomList();
        times(10, (_) {
          final interval = getRandomInterval();
          final searchStartIndex = interval[0];
          final searchEndIndex = interval[1];
          final markers = list.findEndingIn(searchStartIndex, searchEndIndex);
          for (final marker in list.intervalsByMarker.keys) {
            final interval = list.intervalsByMarker[marker];
            final endIndex = interval.endIndex;
            if (searchStartIndex <= endIndex && endIndex <= searchEndIndex) {
              expect(markers, contains(marker));
            } else {
              expect(markers, isNot(contains(marker)));
            }
          }
        });
      });
    });
  });

  group('findFirstAfterMin()', () {
    test(
        'returns a list of markers for intervals with the smallest lower bound except for minIndex',
        () {
      final list = new IntervalSkipList();
      list.insert('0', 1, 3);
      list.insert('1', 3, 5);
      list.insert('2', 5, 7);
      list.insert('3', 1, 5);
      final markers = list.findFirstAfterMin();
      expect(markers, ['0', '3']);
    });
  });

  group('findLastBeforeMax()', () {
    test(
        'returns a list of markers for intervals with the largest upper bound except for maxIndex',
        () {
      final list = new IntervalSkipList();
      list.insert('0', 1, 7);
      list.insert('1', 3, 5);
      list.insert('2', 5, 7);
      list.insert('3', 1, 5);
      final markers = list.findLastBeforeMax();
      expect(markers, ['0', '2']);
    });
  });

  group('findContainedIn(startIndex, endIndex)', () {
    test(
        'returns markers for intervals starting and ending within the given index range',
        () {
      times(10, (_) {
        final list = buildRandomList();
        times(10, (_) {
          final interval = getRandomInterval();
          final searchStartIndex = interval[0];
          final searchEndIndex = interval[1];
          final markers =
              list.findContainedIn(searchStartIndex, searchEndIndex);
          for (final marker in list.intervalsByMarker.keys) {
            final interval = list.intervalsByMarker[marker];
            final startIndex = interval.startIndex;
            final endIndex = interval.endIndex;
            if (searchStartIndex <= startIndex &&
                startIndex <= endIndex &&
                endIndex <= searchEndIndex) {
              expect(markers, contains(marker));
            } else {
              expect(markers, isNot(contains(marker)));
            }
          }
        });
      });
    });
  });

  group('clear()', () {
    test('removes all markers from the list', () {
      times(10, (_) {
        final list = new IntervalSkipList();
        times(100, (i) {
          insertRandomInterval(list, i.toString());
        });

        list.clear();
        expect(list.intervalsByMarker, isEmpty);
        expect(list.findContainedIn(0, 100), isEmpty);
      });
    });
  });

  group('maintenance of the marker invariant', () {
    test('can insert intervals without violating the marker invariant', () {
      times(10, (_) {
        final list = new IntervalSkipList();
        times(100, (i) {
          insertRandomInterval(list, i.toString());
          list.verifyMarkerInvariant();
        });
      });
    });

    test(
        'can insert and remove intervals without violating the marker invariant',
        () {
      times(10, (_) {
        final list = new IntervalSkipList();
        times(100, (i) {
          performRandomChange(list, i);
          list.verifyMarkerInvariant();
        });
      });
    });
  });

  test('can use a custom comparator function', () {
    final list = new IntervalSkipList(
        minIndex: [double.NEGATIVE_INFINITY],
        maxIndex: [double.INFINITY], compare: (a, b) {
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
    expect(
        list.findContaining([
          [1, double.INFINITY]
        ]),
        ['a']);
    expect(
        list.findContaining([
          [2, 20]
        ]),
        orderedEquals(['a', 'b']));
  });
}
