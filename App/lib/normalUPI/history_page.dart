import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Sent', 'Received', 'Failed'];

  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 'TXN001',
      'type': 'sent',
      'amount': 500.00,
      'recipient': 'John Doe',
      'date': '2024-01-15',
      'time': '2:30 PM',
      'status': 'completed',
    },
    {
      'id': 'TXN002',
      'type': 'received',
      'amount': 1200.00,
      'recipient': 'Sarah Wilson',
      'date': '2024-01-14',
      'time': '11:45 AM',
      'status': 'completed',
    },
    {
      'id': 'TXN003',
      'type': 'sent',
      'amount': 750.00,
      'recipient': 'Mike Johnson',
      'date': '2024-01-13',
      'time': '9:15 AM',
      'status': 'failed',
    },
    {
      'id': 'TXN004',
      'type': 'sent',
      'amount': 2000.00,
      'recipient': 'Emma Davis',
      'date': '2024-01-12',
      'time': '6:20 PM',
      'status': 'completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B3A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Transaction History',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Implement search
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(),
          const SizedBox(height: 20),

          // Transaction List
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 15),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF2A2B5A),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF6366F1)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[400],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionList() {
    final filteredTransactions = _selectedFilter == 'All'
        ? _transactions
        : _transactions.where((tx) {
            if (_selectedFilter == 'Sent') return tx['type'] == 'sent';
            if (_selectedFilter == 'Received') return tx['type'] == 'received';
            if (_selectedFilter == 'Failed') return tx['status'] == 'failed';
            return true;
          }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        return _buildTransactionTile(transaction);
      },
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> transaction) {
    final isSent = transaction['type'] == 'sent';
    final isCompleted = transaction['status'] == 'completed';
    
    Color statusColor;
    IconData statusIcon;
    
    if (transaction['status'] == 'completed') {
      statusColor = const Color(0xFF10B981);
      statusIcon = isSent ? Icons.arrow_upward : Icons.arrow_downward;
    } else {
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.error_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B5A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),

          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isSent ? 'To ${transaction['recipient']}' : 'From ${transaction['recipient']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${isSent ? '-' : '+'}₹${transaction['amount'].toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isSent ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      transaction['id'],
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${transaction['date']} • ${transaction['time']}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    transaction['status'].toString().toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
