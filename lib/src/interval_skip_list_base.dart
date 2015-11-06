// Copyright (c) 2015, Kwang Yul Seo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library interval_skip_list.base;

import 'dart:math';

class IntervalSkipList<K, M> {
  static const int _maxHeight = 8;

  static const double _probability = 0.25;

  final Comparator<K> _comparator;
  final _minIndex;
  final _maxIndex;

  final _Node<K, M> _head;
  final _Node<K, M> _tail;

  final Map<M, _Interval> intervalsByMarker = {};

  IntervalSkipList(
      {int compare(K key1, K key2),
      minIndex: double.NEGATIVE_INFINITY,
      maxIndex: double.INFINITY})
      : _comparator = (compare == null) ? Comparable.compare : compare,
        _minIndex = minIndex,
        _maxIndex = maxIndex,
        _head = new _Node(_maxHeight, minIndex),
        _tail = new _Node(_maxHeight, maxIndex) {
    for (var i = 0; i < _maxHeight; i++) {
      _head.next[i] = _tail;
    }
  }

  /// Returns a list of markers for intervals that contain all the given
  /// [searchIndices], inclusive of their endpoints.
  List<M> findContaining(Iterable<K> searchIndices) {
    if (searchIndices.length > 1) {
      // FIXME: Implement List intersection instead of converting to and from Set.
      searchIndices = _sortIndices(searchIndices);
      final a = new Set<M>.from(findContaining([searchIndices.first]));
      final b = new Set<M>.from(findContaining([searchIndices.last]));
      return a.intersection(b).toList();
    }

    final searchIndex = searchIndices.first;
    final markers = [];
    var node = _head;
    for (var i = _maxHeight - 1; i >= 1; i--) {
      // Move forward as far as possible while keeping the node's index less
      // than the index for which we're searching.
      while (_comparator(node.next[i].index, searchIndex) < 0) {
        node = node.next[i];
      }
      // When the next node's index would be greater than the search index, drop
      // down a level, recording forward markers at the current level since their
      // intervals necessarily contain the search index.
      markers.addAll(node.markers[i]);
    }

    // Scan to the node preceding the search index at level 0
    while (_comparator(node.next[0].index, searchIndex) < 0) {
      node = node.next[0];
    }
    markers.addAll(node.markers[0]);

    // Scan to the next node, which is >= the search index. If it is equal to the
    // search index, we can add any markers starting here to the set of
    // containing markers
    node = node.next[0];
    if (_comparator(node.index, searchIndex) == 0) {
      markers.addAll(node.startingMarkers);
    }
    return markers;
  }

  List<K> _sortIndices(Iterable<K> indices) {
    final newIndices = indices.toList();
    newIndices.sort(_comparator);
    return newIndices;
  }

  /// Returns a list of markers for intervals that intersect the given
  /// index range.
  List<M> findIntersecting(K searchStartIndex, K searchEndIndex) {
    final markers = [];
    var node = _head;
    for (var i = _maxHeight - 1; i >= 1; i--) {
      // Move forward as far as possible while keeping the node's index less
      // than the search start index.
      while (_comparator(node.next[i].index, searchStartIndex) < 0) {
        node = node.next[i];
      }
      // When the next node's index would be greater than the search start index,
      // drop down a level, recording forward markers at the current level since
      // their intervals necessarily contain the search start index.
      markers.addAll(node.markers[i]);
    }

    // Scan to the node preceding the search start index at level 0. Any forward
    // markers at level 0 of the node preceding the search start index belong
    // to overlapping intervals.
    while (_comparator(node.next[0].index, searchStartIndex) < 0) {
      node = node.next[0];
    }
    markers.addAll(node.markers[0]);

    // Scan through all nodes that are <= the search end index. Any markers
    // starting on such nodes intersect the search range.
    node = node.next[0];
    while (_comparator(node.index, searchEndIndex) <= 0) {
      markers.addAll(node.startingMarkers);
      node = node.next[0];
    }

    return markers;
  }

  /// Returns a list of markers for intervals with the smallest lower bound
  /// except for minIndex.
  List<M> findFirstAfterMin() {
    if (_head.next[0] != _tail) {
      final node = _head.next[0];
      return node.startingMarkers;
    } else {
      return const [];
    }
  }

  /// Returns a list of markers for intervals with the largest upper bound
  /// except for maxIndex.
  List<M> findLastBeforeMax() {
    var currentNode = _head;
    while (currentNode.next[0] != _tail) {
      currentNode = currentNode.next[0];
    }
    return currentNode.endingMarkers;
  }

  /// Returns a list of markers for intervals that start at the given
  /// [searchIndex].
  List<M> findStartingAt(K searchIndex) {
    final node = _findClosestNode(searchIndex);
    if (_comparator(node.index, searchIndex) == 0) {
      return node.startingMarkers;
    } else {
      return const [];
    }
  }

  /// Returns a list of markers for intervals that end at the given
  /// [searchIndex].
  List<M> findEndingAt(K searchIndex) {
    final node = _findClosestNode(searchIndex);
    if (_comparator(node.index, searchIndex) == 0) {
      return node.endingMarkers;
    } else {
      return const [];
    }
  }

  /// Searches the skiplist in a stairstep descent, following the highest
  /// path that doesn't overshoot the index.
  ///
  /// [update] is a list that will be populated with the last node visited
  /// at every level.
  ///
  /// Returns the leftmost node whose index is >= the given index.
  _Node<K, M> _findClosestNode(K index, [List<_Node<K, M>> update]) {
    var currentNode = _head;
    for (var i = _maxHeight - 1; i >= 0; i--) {
      // Move forward as far as possible while keeping the currentNode's index less
      // than the index being inserted.
      while (_comparator(currentNode.next[i].index, index) < 0) {
        currentNode = currentNode.next[i];
      }
      // When the next node's index would be bigger than the index being inserted,
      // record the last node visited at the current level and drop to the next level.
      if (update != null) {
        update[i] = currentNode;
      }
    }
    return currentNode.next[0];
  }

  /// Returns a list of markers for intervals that start within the
  /// given index range, inclusive.
  List<M> findStartingIn(K searchStartIndex, K searchEndIndex) {
    final markers = [];
    var node = _findClosestNode(searchStartIndex);
    while (_comparator(node.index, searchEndIndex) <= 0) {
      markers.addAll(node.startingMarkers);
      node = node.next[0];
    }
    return markers;
  }

  /// Returns a list of markers for intervals that start within the
  /// given index range, inclusive.
  List<M> findEndingIn(K searchStartIndex, K searchEndIndex) {
    final markers = [];
    var node = _findClosestNode(searchStartIndex);
    while (_comparator(node.index, searchEndIndex) <= 0) {
      markers.addAll(node.endingMarkers);
      node = node.next[0];
    }
    return markers;
  }

  /// Returns a list of markers that start and end within the given
  /// index range, inclusive.
  List<M> findContainedIn(K searchStartIndex, K searchEndIndex) {
    final startedMarkers = new Set<M>();
    final markers = [];
    var node = _findClosestNode(searchStartIndex);
    while (_comparator(node.index, searchEndIndex) <= 0) {
      startedMarkers.addAll(node.startingMarkers);
      for (final marker in node.endingMarkers) {
        if (startedMarkers.contains(marker)) {
          markers.add(marker);
        }
      }
      node = node.next[0];
    }
    return markers;
  }

  /// Insert an interval identified by marker that spans inclusively
  /// the given start and end indices.
  ///
  /// [marker]: Identifies the interval.
  ///
  /// Throws an exception if the marker already exists in the list. Use [update]
  /// instead if you want to update an existing marker.
  void insert(M marker, K startIndex, K endIndex) {
    if (intervalsByMarker.containsKey(marker)) {
      throw new ArgumentError('Interval for ${marker} already exists.');
    }
    if (_comparator(startIndex, endIndex) > 0) {
      throw new ArgumentError(
          'Start index ${startIndex} must be <= end index ${endIndex}');
    }
    if (_comparator(startIndex, _minIndex) < 0) {
      throw new ArgumentError(
          'Start index ${startIndex} must be > min index ${_minIndex}');
    }
    if (_comparator(endIndex, _maxIndex) >= 0) {
      throw new ArgumentError(
          'End index ${endIndex} must be < max index ${_maxIndex}');
    }

    final startNode = _insertNode(startIndex);
    final endNode = _insertNode(endIndex);
    _placeMarker(marker, startNode, endNode);
    intervalsByMarker[marker] = new _Interval(startIndex, endIndex);
  }

  /// Remove an interval by its id. Does nothing if the interval does not
  /// exist.
  void remove(M marker) {
    final interval = intervalsByMarker[marker];
    if (interval == null) return;
    final startIndex = interval.startIndex;
    final endIndex = interval.endIndex;
    intervalsByMarker.remove(marker);
    final startNode = _findClosestNode(startIndex);
    final endNode = _findClosestNode(endIndex);
    _removeMarker(marker, startNode, endNode);

    // Nodes may serve as end-points for multiple intervals, so only remove a
    // node if its endpointMarkers set is empty
    if (startNode.endpointMarkers.isEmpty) {
      _removeNode(startIndex);
    }
    if (endNode.endpointMarkers.isEmpty) {
      _removeNode(endIndex);
    }
  }

  /// Removes the interval for the given [marker] if one exists, then
  /// inserts the a new interval for the marker based on [startIndex]
  /// and [endIndex].
  void update(M marker, K startIndex, K endIndex) {
    remove(marker);
    insert(marker, startIndex, endIndex);
  }

  /// Place the given [marker] on the highest possible path between two
  /// nodes. It will follow a stair-step pattern, with a flat or ascending portion
  /// followed by a flat or descending section.
  void _placeMarker(M marker, _Node<K, M> startNode, _Node<K, M> endNode) {
    startNode.addStartingMarker(marker);
    endNode.addEndingMarker(marker);

    final endIndex = endNode.index;
    var node = startNode;
    var i = 0;

    // Mark non-descending path
    while (_comparator(node.next[i].index, endIndex) <= 0) {
      while (i < node.height - 1 &&
          _comparator(node.next[i + 1].index, endIndex) <= 0) {
        i++;
      }
      node.addMarkerAtLevel(marker, i);
      node = node.next[i];
    }

    // Mark non-ascending path
    while (node != endNode) {
      while (i > 0 && _comparator(node.next[i].index, endIndex) > 0) {
        i--;
      }
      assert(node != null);
      node.addMarkerAtLevel(marker, i);
      node = node.next[i];
    }
  }

  /// Removes the given [marker] from the stairstep-shaped path between the
  /// [startNode] and [endNode].
  void _removeMarker(M marker, _Node<K, M> startNode, _Node<K, M> endNode) {
    startNode.removeStartingMarker(marker);
    endNode.removeEndingMarker(marker);

    final endIndex = endNode.index;
    var node = startNode;
    var i = 0;

    // Unmark non-descending path
    while (_comparator(node.next[i].index, endIndex) <= 0) {
      while (i < node.height - 1 &&
          _comparator(node.next[i + 1].index, endIndex) <= 0) {
        i++;
      }
      node.removeMarkerAtLevel(marker, i);
      node = node.next[i];
    }

    // Unmark non-ascending path
    while (node != endNode) {
      while (i > 0 && _comparator(node.next[i].index, endIndex) > 0) {
        i--;
      }
      node.removeMarkerAtLevel(marker, i);
      node = node.next[i];
    }
  }

  /// Find or insert a node for the given [index]. If a node is inserted,
  /// update existing markers to preserve the invariant that they follow the
  /// shortest possible path between their start and end nodes.
  _Node<K, M> _insertNode(K index) {
    final update = _buildUpdateList();
    final closestNode = _findClosestNode(index, update);
    if (_comparator(closestNode.index, index) > 0) {
      final newNode = new _Node<K, M>(_getRandomNodeHeight(), index);
      for (var i = 0; i < newNode.height; i++) {
        final prevNode = update[i];
        newNode.next[i] = prevNode.next[i];
        prevNode.next[i] = newNode;
      }
      _adjustMarkersOnInsert(newNode, update);
      return newNode;
    } else {
      return closestNode;
    }
  }

  /// Removes the node at the given [index], then adjusts markers downward
  void _removeNode(K index) {
    final update = _buildUpdateList();
    final node = _findClosestNode(index, update);
    if (_comparator(node.index, index) == 0) {
      _adjustMarkersOnRemove(node, update);
      for (var i = 0; i < node.height; i++) {
        update[i].next[i] = node.next[i];
      }
    }
  }

  /// Ensures that all markers leading into and out of the given [node]
  /// are following the highest possible paths to their destination. Some may need
  /// to be "promoted" to a higher level now that this node exists.
  void _adjustMarkersOnInsert(_Node<K, M> node, List<_Node<K, M>> updated) {
    // Phase 1: Add markers leading out of the inserted node at the highest
    // possible level
    var promoted = [];
    final newPromoted = [];

    var i = 0;
    for (i = 0; i < node.height - 1; i++) {
      for (final marker in updated[i].markers[i]) {
        final endIndex = intervalsByMarker[marker].endIndex;
        if (_comparator(node.next[i + 1].index, endIndex) <= 0) {
          _removeMarkerOnPath(marker, node.next[i], node.next[i + 1], i);
          newPromoted.add(marker);
        } else {
          node.addMarkerAtLevel(marker, i);
        }
      }

      for (final marker in _clone(promoted)) {
        final endIndex = intervalsByMarker[marker].endIndex;
        if (_comparator(node.next[i + 1].index, endIndex) <= 0) {
          _removeMarkerOnPath(marker, node.next[i], node.next[i + 1], i);
        } else {
          node.addMarkerAtLevel(marker, i);
          promoted.remove(marker);
        }
      }

      promoted = _concat(promoted, newPromoted);
      newPromoted.clear();
    }
    node.addMarkersAtLevel(_concat(updated[i].markers[i], promoted), i);

    // Phase 2: Push markers leading into the inserted node higher, but no higher
    // than the height of the node
    promoted.clear();
    newPromoted.clear();

    for (i = 0; i < node.height - 1; i++) {
      for (final marker in _clone(updated[i].markers[i])) {
        final startIndex = intervalsByMarker[marker].startIndex;
        if (_comparator(startIndex, updated[i + 1].index) <= 0) {
          newPromoted.add(marker);
          _removeMarkerOnPath(marker, updated[i + 1], node, i);
        }
      }

      for (final marker in _clone(promoted)) {
        final startIndex = intervalsByMarker[marker].startIndex;
        if (_comparator(startIndex, updated[i + 1].index) <= 0) {
          _removeMarkerOnPath(marker, updated[i + 1], node, i);
        } else {
          updated[i].addMarkerAtLevel(marker, i);
          promoted.remove(marker);
        }
      }

      promoted = _concat(promoted, newPromoted);
      newPromoted.clear();
    }
    updated[i].addMarkersAtLevel(promoted, i);
  }

  /// Adjusts the height of markers that formerly traveled through the
  /// removed [node]. They may now need to follow a lower path in order to avoid
  /// overshooting their interval.
  void _adjustMarkersOnRemove(_Node<K, M> node, List<_Node<K, M>> updated) {
    final demoted = [];
    final newDemoted = [];

    // Phase 1: Lower markers on edges to the left of node if needed
    for (var i = node.height - 1; i >= 0; i--) {
      for (final marker in _clone(updated[i].markers[i])) {
        final endIndex = intervalsByMarker[marker].endIndex;
        if (_comparator(node.next[i].index, endIndex) > 0) {
          newDemoted.add(marker);
          updated[i].removeMarkerAtLevel(marker, i);
        }
      }

      for (final marker in _clone(demoted)) {
        _placeMarkerOnPath(marker, updated[i + 1], updated[i], i);
        final endIndex = intervalsByMarker[marker].endIndex;
        if (_comparator(node.next[i].index, endIndex) <= 0) {
          updated[i].addMarkerAtLevel(marker, i);
          demoted.remove(marker);
        }
      }

      demoted.addAll(newDemoted);
      newDemoted.clear();
    }

    // Phase 2: Lower markers on edges to the right of node if needed
    demoted.clear();
    newDemoted.clear();
    for (var i = node.height - 1; i >= 0; i--) {
      for (final marker in node.markers[i]) {
        final startIndex = intervalsByMarker[marker].startIndex;
        if (_comparator(updated[i].index, startIndex) < 0) {
          newDemoted.add(marker);
        }
      }

      for (final marker in _clone(demoted)) {
        _placeMarkerOnPath(marker, node.next[i], node.next[i + 1], i);
        final startIndex = intervalsByMarker[marker].startIndex;
        if (_comparator(updated[i].index, startIndex) >= 0) {
          demoted.remove(marker);
        }
      }

      demoted.addAll(newDemoted);
      newDemoted.clear();
    }
  }

  /// Remove [marker] on all links between [startNode] and [endNode] at the
  /// given level.
  void _removeMarkerOnPath(
      M marker, _Node<K, M> startNode, _Node<K, M> endNode, int level) {
    var node = startNode;
    while (node != endNode) {
      node.removeMarkerAtLevel(marker, level);
      node = node.next[level];
    }
  }

  /// Place [marker] on all links between [startNode] and [endNode] at the
  /// given level
  void _placeMarkerOnPath(
      M marker, _Node<K, M> startNode, _Node<K, M> endNode, int level) {
    var node = startNode;
    while (node != endNode) {
      node.addMarkerAtLevel(marker, level);
      node = node.next[level];
    }
  }

  /// Returns a height between 1 and [_maxHeight] (inclusive). Taller heights
  /// are logarithmically less probable than shorter heights because each increase
  /// in height requires us to win a coin toss weighted by [_probability].
  int _getRandomNodeHeight() {
    var height = 1;
    while (height < _maxHeight && _random.nextDouble() < _probability) {
      height++;
    }
    return height;
  }

  List<_Node<K, M>> _buildUpdateList() =>
      new List<_Node<K, M>>.filled(_maxHeight, _head);

  /// Test-only method to verify that all markers are following maximal paths
  /// between the start and end indices of their interval.
  void verifyMarkerInvariant() {
    for (final marker in intervalsByMarker.keys) {
      final interval = intervalsByMarker[marker];
      final startIndex = interval.startIndex;
      final endIndex = interval.endIndex;
      final node = _findClosestNode(startIndex);
      if (_comparator(node.index, startIndex) != 0) {
        throw new StateError('Could not find node for marker ${marker} '
            'with start index ${startIndex}');
      }
      node.verifyMarkerInvariant(marker, endIndex, _comparator);
    }
  }
}

class _Node<K, M> {
  final int height;
  final K index;
  final List<_Node<K, M>> next;
  final List<List<M>> markers;
  final List<M> endpointMarkers = [];
  final List<M> startingMarkers = [];
  final List<M> endingMarkers = [];

  _Node(int height, this.index)
      : height = height,
        next = new List<_Node<K, M>>(height),
        markers = new List<List<M>>(height) {
    for (int i = 0; i < height; i++) {
      markers[i] = [];
    }
  }

  void addStartingMarker(M marker) {
    startingMarkers.add(marker);
    endpointMarkers.add(marker);
  }

  void removeStartingMarker(M marker) {
    startingMarkers.remove(marker);
    endpointMarkers.remove(marker);
  }

  void addEndingMarker(M marker) {
    endingMarkers.add(marker);
    endpointMarkers.add(marker);
  }

  void removeEndingMarker(M marker) {
    endingMarkers.remove(marker);
    endpointMarkers.remove(marker);
  }

  void addMarkersAtLevel(List<M> markers, int level) {
    for (final marker in markers) {
      addMarkerAtLevel(marker, level);
    }
  }

  void addMarkerAtLevel(M marker, int level) {
    markers[level].add(marker);
  }

  void removeMarkerAtLevel(M marker, int level) {
    markers[level].remove(marker);
  }

  void verifyMarkerInvariant(M marker, K endIndex, Comparator<K> comparator) {
    if (index == endIndex) return;
    for (var i = height - 1; i >= 0; i--) {
      final nextIndex = next[i].index;
      if (comparator(nextIndex, endIndex) <= 0) {
        if (!markers[i].contains(marker)) {
          throw new StateError('Node at $index should have marker $marker '
              'at level $i pointer to node at $nextIndex <= $endIndex');
        }
        if (i > 0) {
          verifyNotMarkedBelowLevel(marker, i, nextIndex, comparator);
        }
        next[i].verifyMarkerInvariant(marker, endIndex, comparator);
        return;
      }
    }
    throw new StateError("Node at $index should have marker $marker "
        "on some forward pointer to an index <= $endIndex, but it doesn't");
  }

  void verifyNotMarkedBelowLevel(
      M marker, int level, K untilIndex, Comparator<K> comparator) {
    for (var i = min(level, height) - 1; i >= 0; i--) {
      if (markers[i].contains(marker)) {
        throw new StateError('Node at $index should not have marker '
            '$marker at level $i pointer to node at ${next[i].index}');
      }
      if (comparator(next[0].index, untilIndex) < 0) {
        next[0]
            .verifyNotMarkedBelowLevel(marker, level, untilIndex, comparator);
      }
    }
  }
}

class _Interval {
  final startIndex;
  final endIndex;

  _Interval(this.startIndex, this.endIndex);
}

Random _random = new Random();

List _concat(List l1, List l2) => new List.from(l1)..addAll(l2);

List _clone(List l) => new List.from(l);
