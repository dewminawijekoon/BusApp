import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bus_route_model.dart';
import '../models/user_model.dart';
import '../models/bus_model.dart';
import '../models/bus_stop_model.dart';
import '../models/journey_model.dart';
import '../models/alert_model.dart';
import '../models/rating_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _busRoutesCollection => _firestore.collection('busRoutes');
  CollectionReference get _busesCollection => _firestore.collection('buses');
  CollectionReference get _busStopsCollection => _firestore.collection('busStops');
  CollectionReference get _journeysCollection => _firestore.collection('journeys');
  CollectionReference get _alertsCollection => _firestore.collection('alerts');
  CollectionReference get _ratingsCollection => _firestore.collection('ratings');

  // Bus Routes Operations
  Future<List<BusRoute>> getBusRoutes() async {
    try {
      final querySnapshot = await _busRoutesCollection.get();
      return querySnapshot.docs
          .map((doc) => BusRoute.fromJson(
                {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                },
                doc.id // Second positional argument, usually the document ID
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch bus routes: $e');
    }
  }

  Future<BusRoute?> getBusRouteById(String routeId) async {
    try {
      final docSnapshot = await _busRoutesCollection.doc(routeId).get();
      if (docSnapshot.exists) {
        return BusRoute.fromJson({
          'id': docSnapshot.id,
          ...docSnapshot.data() as Map<String, dynamic>,
        }, docSnapshot.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch bus route: $e');
    }
  }

  Future<void> saveBusRoute(BusRoute route) async {
    try {
      final data = route.toJson();
      data.remove('id'); // Remove id from data as it's used as document ID
      
      if (route.id.isEmpty) {
        // Create new route
        await _busRoutesCollection.add(data);
      } else {
        // Update existing route
        await _busRoutesCollection.doc(route.id).set(data, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to save bus route: $e');
    }
  }

  Stream<List<BusRoute>> getBusRoutesStream() {
    return _busRoutesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BusRoute.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }, doc.id))
          .toList();
    });
  }

  // Bus Stops Operations
  Future<List<BusStop>> getBusStops() async {
    try {
      final querySnapshot = await _busStopsCollection.get();
      return querySnapshot.docs
          .map((doc) => BusStop.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch bus stops: $e');
    }
  }

  Future<BusStop?> getBusStopById(String stopId) async {
    try {
      final docSnapshot = await _busStopsCollection.doc(stopId).get();
      if (docSnapshot.exists) {
        return BusStop.fromJson({
          'id': docSnapshot.id,
          ...docSnapshot.data() as Map<String, dynamic>,
        }, docSnapshot.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch bus stop: $e');
    }
  }

  Future<List<BusStop>> getNearbyBusStops(GeoPoint center, double radiusKm) async {
    try {
      // This is a simplified approach. For production, use GeoFlutterFire or similar
      final querySnapshot = await _busStopsCollection.get();
      final allStops = querySnapshot.docs
          .map((doc) => BusStop.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }, doc.id))
          .toList();

      // Filter by distance (simplified calculation)
      return allStops.where((stop) {
        final distance = _calculateDistance(
          center.latitude,
          center.longitude,
          stop.location.latitude,
          stop.location.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch nearby bus stops: $e');
    }
  }

  Future<void> saveBusStop(BusStop busStop) async {
    try {
      final data = busStop.toJson();
      data.remove('id');
      
      if (busStop.id.isEmpty) {
        await _busStopsCollection.add(data);
      } else {
        await _busStopsCollection.doc(busStop.id).set(data, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to save bus stop: $e');
    }
  }

  // Bus Operations
  Future<Bus?> getBusById(String busId) async {
    try {
      final docSnapshot = await _busesCollection.doc(busId).get();
      if (docSnapshot.exists) {
        return Bus.fromJson({
          'id': docSnapshot.id,
          ...docSnapshot.data() as Map<String, dynamic>,
        }, docSnapshot.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch bus: $e');
    }
  }

  Future<GeoPoint?> getBusLocation(String busId) async {
    try {
      final docSnapshot = await _busesCollection.doc(busId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final locationData = data['currentLocation'] as Map<String, dynamic>?;
        if (locationData != null && locationData['coordinates'] != null) {
          final coords = locationData['coordinates'] as GeoPoint;
          return coords;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch bus location: $e');
    }
  }

  Future<void> updateBusLocation(String busId, GeoPoint location) async {
    try {
      await _busesCollection.doc(busId).update({
        'currentLocation.coordinates': location,
        'currentLocation.timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update bus location: $e');
    }
  }

  Future<List<Bus>> getBusesByRoute(String routeId) async {
    try {
      final querySnapshot = await _busesCollection
          .where('routeId', isEqualTo: routeId)
          .get();
      return querySnapshot.docs
          .map((doc) => Bus.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch buses by route: $e');
    }
  }

  Stream<Bus?> getBusStream(String busId) {
    return _busesCollection.doc(busId).snapshots().map((doc) {
      if (doc.exists) {
        return Bus.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        }, doc.id);
      }
      return null;
    });
  }

  Future<void> updateBusCrowdLevel(String busId, int crowdLevel) async {
    try {
      await _busesCollection.doc(busId).update({
        'currentCrowd': crowdLevel,
        'lastCrowdUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update crowd level: $e');
    }
  }

  // User Operations
  Future<UserModel?> getUserById(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      if (docSnapshot.exists) {
        return UserModel.fromJson({
          'id': docSnapshot.id,
          ...docSnapshot.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      final data = user.toJson();
      data.remove('uid');
      await _usersCollection.doc(user.uid).set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to create/update user: $e');
    }
  }

  Future<void> updateUserPoints(String userId, int points, String reason) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userDoc = _usersCollection.doc(userId);
        final userSnapshot = await transaction.get(userDoc);
        
        if (userSnapshot.exists) {
          final currentPoints = (userSnapshot.data() as Map<String, dynamic>)['points'] ?? 0;
          transaction.update(userDoc, {
            'points': currentPoints + points,
            'lastPointsUpdate': FieldValue.serverTimestamp(),
          });

          // Add points history entry
          transaction.set(
            userDoc.collection('pointsHistory').doc(),
            {
              'points': points,
              'reason': reason,
              'timestamp': FieldValue.serverTimestamp(),
            },
          );
        }
      });
    } catch (e) {
      throw Exception('Failed to update user points: $e');
    }
  }

  // Journey Operations
  Future<List<Journey>> getUserJourneys(String userId) async {
    try {
      final querySnapshot = await _journeysCollection
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => Journey.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user journeys: $e');
    }
  }

  Future<void> saveJourney(Journey journey) async {
    try {
      final data = journey.toJson();
      data.remove('id');
      
      if (journey.id.isEmpty) {
        await _journeysCollection.add(data);
      } else {
        await _journeysCollection.doc(journey.id).set(data, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to save journey: $e');
    }
  }

  Future<Journey?> getActiveJourney(String userId) async {
    try {
      final querySnapshot = await _journeysCollection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return Journey.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        }, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch active journey: $e');
    }
  }

  // Alert Operations
  Future<List<Alert>> getUserAlerts(String userId, {bool unreadOnly = false}) async {
    try {
      Query query = _alertsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);
      
      if (unreadOnly) {
        query = query.where('isRead', isEqualTo: false);
      }
      
      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => Alert.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user alerts: $e');
    }
  }

  Future<void> createAlert(Alert alert) async {
    try {
      final data = alert.toJson();
      data.remove('id');
      await _alertsCollection.add(data);
    } catch (e) {
      throw Exception('Failed to create alert: $e');
    }
  }

  Future<void> markAlertAsRead(String alertId) async {
    try {
      await _alertsCollection.doc(alertId).update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark alert as read: $e');
    }
  }

  Stream<List<Alert>> getUserAlertsStream(String userId) {
    return _alertsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Alert.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }, doc.id))
          .toList();
    });
  }

  // Rating Operations
  Future<void> submitRating(Rating rating) async {
    try {
      final data = rating.toJson();
      data.remove('id');
      await _ratingsCollection.add(data);
    } catch (e) {
      throw Exception('Failed to submit rating: $e');
    }
  }

  Future<List<Rating>> getBusRatings(String busId) async {
    try {
      final querySnapshot = await _ratingsCollection
          .where('busId', isEqualTo: busId)
          .orderBy('timestamp', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => Rating.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch bus ratings: $e');
    }
  }

  Future<double> getAverageRating(String busId) async {
    try {
      final querySnapshot = await _ratingsCollection
          .where('busId', isEqualTo: busId)
          .get();
      
      if (querySnapshot.docs.isEmpty) return 0.0;
      
      final ratings = querySnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['rating'] as int)
          .toList();
      
      return ratings.reduce((a, b) => a + b) / ratings.length;
    } catch (e) {
      throw Exception('Failed to calculate average rating: $e');
    }
  }

  // Saved Routes Operations
  Future<void> saveUserRoute(String userId, BusRoute route) async {
    try {
      await _usersCollection
          .doc(userId)
          .collection('savedRoutes')
          .doc(route.id)
          .set(route.toJson());
    } catch (e) {
      throw Exception('Failed to save user route: $e');
    }
  }

  Future<void> removeSavedRoute(String userId, String routeId) async {
    try {
      await _usersCollection
          .doc(userId)
          .collection('savedRoutes')
          .doc(routeId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove saved route: $e');
    }
  }

  Future<List<BusRoute>> getUserSavedRoutes(String userId) async {
    try {
      final querySnapshot = await _usersCollection
          .doc(userId)
          .collection('savedRoutes')
          .get();
      return querySnapshot.docs
          .map((doc) => BusRoute.fromJson({
                'id': doc.id,
                ...doc.data(),
              }, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch saved routes: $e');
    }
  }

  // Batch Operations
  Future<void> batchUpdateBusLocations(Map<String, GeoPoint> busLocations) async {
    try {
      final batch = _firestore.batch();
      
      busLocations.forEach((busId, location) {
        batch.update(_busesCollection.doc(busId), {
          'currentLocation.coordinates': location,
          'currentLocation.timestamp': FieldValue.serverTimestamp(),
        });
      });
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update bus locations: $e');
    }
  }

  // Utility Methods
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Clean up and maintenance
  Future<void> cleanupOldData() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      // Clean up old journeys
      final oldJourneys = await _journeysCollection
          .where('endTime', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();
      
      final batch = _firestore.batch();
      for (final doc in oldJourneys.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cleanup old data: $e');
    }
  }
}