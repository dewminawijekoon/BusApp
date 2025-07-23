import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../config/app_theme.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  int _totalPoints = 0;
  List<LocalPointsTransaction> _pointsHistory = [];
  List<LocalReward> _availableRewards = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPointsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPointsData() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Initialize the user provider if needed
      if (!userProvider.isInitialized) {
        await userProvider.initialize();
      }
      
      await userProvider.loadPointsHistory();
      await userProvider.loadAvailableRewards();
      
      setState(() {
        _totalPoints = userProvider.totalPoints;
        _pointsHistory = userProvider.pointsHistory.map((pt) => LocalPointsTransaction(
          id: pt.id,
          points: pt.points,
          description: pt.reason,
          timestamp: pt.timestamp,
        )).toList();
        _availableRewards = userProvider.availableRewards.map((r) => LocalReward(
          id: r.id,
          title: r.title,
          description: r.description,
          pointsCost: r.pointsCost,
          icon: Icons.card_giftcard,
          color: AppTheme.primaryColor,
        )).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load points data');
    }
  }

  Future<void> _claimReward(String rewardId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.claimReward(rewardId);
      
      if (success) {
        _showSuccessSnackBar('Reward claimed successfully!');
        _loadPointsData(); // Refresh data
      } else {
        _showErrorSnackBar('Insufficient points or reward unavailable');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to claim reward');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildPointsHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.stars,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Points',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _totalPoints.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'This Month',
                  '${_getMonthlyPoints()}',
                  Icons.calendar_month_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Level',
                  _getUserLevel(),
                  Icons.emoji_events_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsHistory() {
    if (_pointsHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Points History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start using the app to earn points!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pointsHistory.length,
      itemBuilder: (context, index) {
        final transaction = _pointsHistory[index];
        return _buildHistoryCard(transaction);
      },
    );
  }

  Widget _buildHistoryCard(LocalPointsTransaction transaction) {
    final isEarned = transaction.points > 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isEarned 
                ? Colors.green.withOpacity(0.1)
                : AppTheme.errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isEarned ? Icons.add : Icons.remove,
            color: isEarned ? Colors.green : AppTheme.errorColor,
            size: 20,
          ),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          _formatDate(transaction.timestamp),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Text(
          '${isEarned ? '+' : ''}${transaction.points}',
          style: TextStyle(
            color: isEarned ? Colors.green : AppTheme.errorColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildRewards() {
    if (_availableRewards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Rewards Available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for exciting rewards!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _availableRewards.length,
      itemBuilder: (context, index) {
        final reward = _availableRewards[index];
        return _buildRewardCard(reward);
      },
    );
  }

  Widget _buildRewardCard(LocalReward reward) {
    final canClaim = _totalPoints >= reward.pointsCost;
    
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: canClaim ? () => _showClaimDialog(reward) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: reward.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  reward.icon,
                  color: reward.color,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                reward.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                reward.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.stars,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${reward.pointsCost}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: canClaim ? AppTheme.primaryColor : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canClaim ? () => _showClaimDialog(reward) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canClaim ? AppTheme.primaryColor : Colors.grey[300],
                    foregroundColor: canClaim ? Colors.white : Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    canClaim ? 'Claim' : 'Insufficient Points',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClaimDialog(LocalReward reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Claim Reward'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to claim "${reward.title}"?'),
            const SizedBox(height: 8),
            Text(
              'This will cost ${reward.pointsCost} points.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _claimReward(reward.id);
            },
            child: const Text('Claim'),
          ),
        ],
      ),
    );
  }

  int _getMonthlyPoints() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    
    return _pointsHistory
        .where((transaction) => 
            transaction.timestamp.isAfter(thisMonth) && 
            transaction.points > 0)
        .fold(0, (sum, transaction) => sum + transaction.points);
  }

  String _getUserLevel() {
    if (_totalPoints < 100) return 'Bronze';
    if (_totalPoints < 500) return 'Silver';
    if (_totalPoints < 1000) return 'Gold';
    return 'Platinum';
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Points & Rewards'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'Rewards'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadPointsData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildPointsHeader(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPointsHistory(),
                      _buildRewards(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// Data classes for points system
class LocalPointsTransaction {
  final String id;
  final int points;
  final String description;
  final DateTime timestamp;

  LocalPointsTransaction({
    required this.id,
    required this.points,
    required this.description,
    required this.timestamp,
  });
}

class LocalReward {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final IconData icon;
  final Color color;

  LocalReward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.icon,
    required this.color,
  });
}