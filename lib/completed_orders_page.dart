import 'package:flutter/material.dart';
import 'order_model.dart';

class CompletedOrdersPage extends StatelessWidget {
  final List<Order> completedOrders;

  const CompletedOrdersPage({super.key, required this.completedOrders});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Orders'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: Colors.green[50],
      body: completedOrders.isEmpty
          ? const Center(child: Text('No completed orders found.'))
          : ListView.builder(
              itemCount: completedOrders.length,
              itemBuilder: (context, index) {
                final order = completedOrders[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(order.product.name),
                    subtitle: Text('Buyer: ${order.buyerName} - Quantity: ${order.quantity}'),
                    trailing: Text(order.status.toString().split('.').last, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
    );
  }
}
