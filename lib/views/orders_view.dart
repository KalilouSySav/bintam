import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import '../utils/send_sms_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/nav_button.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({Key? key}) : super(key: key);

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> with TickerProviderStateMixin {
  late OrderController _orderController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TransformationController _transformationController;
  late ScrollController _scrollController;
  double _scale = 1.0;
  double _previousScale = 1.0;

  String _selectedStatusFilter = 'Tous';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _transformationController = TransformationController();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      if (!auth.isCust) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  'Accès non autorisé',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        context.go('/');
      }
      if (auth.currentUser != null) {
        _orderController = context.read<OrderController>();
        _orderController.loadOrders(auth.currentUser?.id).then((_) {
          _animationController.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  List<OrderModel> get _filteredOrders {
    return _orderController.orders.where((order) {
      final matchesSearch = order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.userId.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatusFilter == 'Tous' ||
          order.status.toString().split('.').last.toLowerCase() ==
              _selectedStatusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final currentOrder = _orderController.orders.firstWhere((order) => order.id == orderId);
    bool? confirmUpdate = await _showConfirmationDialog(
        'Confirmer le changement de statut',
        'Êtes-vous sûr de vouloir changer le statut de cette commande de "${_getStatusLabel(currentOrder.status)}" à "${_getStatusLabel(newStatus)}"?'
    );
    if (confirmUpdate == false) return;
    if (newStatus == currentOrder.status) {
      _showSnackBar('Le nouveau statut est le même que l\'actuel.', isError: true);
      return;
    }

    if (confirmUpdate == true) {
      try {
        await _orderController.updateOrderStatus(orderId, newStatus);
        if (mounted) {
          _showSnackBar('Statut mis à jour avec succès!');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Erreur lors de la mise à jour du statut: $e', isError: true);
        }
      }
    }
  }

  Future<bool?> _showConfirmationDialog(String title, String content) async {
    if (mounted) {
      return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.help_outline_rounded, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18)),
              ],
            ),
            content: Text(content, style: const TextStyle(fontSize: 16)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Confirmer'),
              ),
            ],
          );
        },
      );
    }
    return null;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_rounded : Icons.check_circle_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(seconds: isError ? 4 : 3),
        ),
      );
    }
  }

  Future<void> _sendNotification(String orderId) async {
    final currentOrder = _orderController.orders.firstWhere((order) => order.id == orderId);
    final auth = context.read<AuthController>();

    bool? confirmUpdate = await _showConfirmationDialog(
        'Confirmer l\'envoi du message',
        'Êtes-vous sûr de vouloir notifier le vendeur que le statut de cette commande est "${_getStatusLabel(currentOrder.status)}"?'
    );
    if (confirmUpdate == false) return;

    final message = """
Bonjour Maguiraga,

📦 Mise à jour de commande reçue.

🆔 Commande : #$orderId
👤 Client : ${auth.currentUser?.nom}
📞 Téléphone : ${currentOrder.telephone}
🕒 Date : ${DateFormat('dd/MM/yyyy – HH:mm').format(DateTime.now())}

🔄 Nouveau statut : ${_getStatusLabel(currentOrder.status)}

Merci de vérifier et de traiter cette mise à jour rapidement.
""";

    final smsService = SendSmsService(
      apiUrl: 'https://kjgqv646d5.execute-api.us-east-1.amazonaws.com/send-sms',
    );
    final success = await smsService.sendSms(
      phoneNumber: currentOrder.telephone,
      message: message,
    );
    if (mounted) {
      _showSnackBar(
          success ? 'Notification envoyée pour la commande #$orderId!' :
          'Une erreur s\'est produite. L\'envoi du message a échoué!',
          isError: !success
      );
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.enAttente:
        return Colors.orange;
      case OrderStatus.confirmee:
        return Colors.blue;
      case OrderStatus.expediee:
        return Colors.purple;
      case OrderStatus.livree:
        return Colors.green;
      case OrderStatus.annulee:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.enAttente:
        return 'En attente';
      case OrderStatus.confirmee:
        return 'Confirmée';
      case OrderStatus.expediee:
        return 'Expédiée';
      case OrderStatus.livree:
        return 'Livrée';
      case OrderStatus.annulee:
        return 'Annulée';
      default:
        return 'Inconnu';
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.enAttente:
        return Icons.schedule_rounded;
      case OrderStatus.confirmee:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.expediee:
        return Icons.local_shipping_rounded;
      case OrderStatus.livree:
        return Icons.done_all_rounded;
      case OrderStatus.annulee:
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: isDesktop ? 2 : 1,
        title: isDesktop
            ? Row(
          children: [
            Image.asset(
              'images/logo-bintam-1.png',
              height: 40,
            ),
            const SizedBox(width: 12),
            const Text(
              'BintaM',
              style: TextStyle(
                fontSize: 24,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            NavButton(label: 'Accueil', route: '/'),
            NavButton(label: 'Catalogue', route: '/catalogue'),
            NavButton(label: 'Contact', route: '/contact'),
          ],
        )
            : const Text('Commande'),
        actions: [
          Consumer<CartController>(
            builder: (context, cart, child) {
              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => context.go('/cart'),
              );
            },
          ),
          Consumer<AuthController>(
            builder: (context, auth, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.person, color: Colors.black),
                onSelected: (value) {
                  switch (value) {
                    case 'auth':
                      context.go('/auth');
                      break;
                    case 'admin':
                      context.go('/admin');
                      break;
                    case 'orders':
                      context.go('/orders');
                      break;
                    case 'visitor':
                      auth.setVisitorMode();
                      break;
                    case 'logout':
                      auth.signOut();
                      context.go('/');
                      break;
                  }
                },
                itemBuilder: (context) {
                  if (auth.isAuthenticated) {
                    return [
                      PopupMenuItem(
                        value: 'profile',
                        child: Text('${auth.currentUser?.prenom} ${auth.currentUser?.nom}'),
                      ),
                      if (auth.isAdmin)
                        const PopupMenuItem(
                          value: 'admin',
                          child: Text('Administration'),
                        ),
                      if(auth.isCust)
                        const PopupMenuItem(
                          value: 'orders',
                          child: Text('Commande'),
                        ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Text('Déconnexion'),
                      ),
                    ];
                  } else {
                    return [
                      const PopupMenuItem(
                        value: 'auth',
                        child: Text('Connexion'),
                      ),
                      const PopupMenuItem(
                        value: 'visitor',
                        child: Text('Mode Visiteur'),
                      ),
                    ];
                  }
                },
              );
            },
          ),
        ],
        automaticallyImplyLeading: !isDesktop,
      ),
      drawer: isDesktop ? null : const AppDrawer(),
      body: Consumer<OrderController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return _buildLoadingState();
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.cyan.shade50,
                ],
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (KeyEvent event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        _scrollController.animateTo(
                          _scrollController.offset - 50,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        _scrollController.animateTo(
                          _scrollController.offset + 50,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    }
                  },
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    onInteractionStart: (details) {
                      _previousScale = _scale;
                    },
                    onInteractionUpdate: (details) {
                      _scale = _previousScale * details.scale;
                    },
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              _buildHeader(controller),
                              const SizedBox(height: 20),
                              _buildSearchAndFilter(),
                              const SizedBox(height: 20),
                              _buildStatsCards(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                        _filteredOrders.isEmpty
                            ? SliverFillRemaining(
                          child: _buildEmptyState(),
                        )
                            : SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (BuildContext context, int index) {
                              final order = _filteredOrders[index];
                              return TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 300 + (index * 100)),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 30 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.08),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: _buildOrderCard(order),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: _filteredOrders.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.cyan.shade50],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement des commandes...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.indigo,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(OrderController controller) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.cyan.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shopping_cart_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDesktop ? 'Gestion des Commandes' : 'Commande',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                if (isDesktop)
                  Text(
                    '${controller.orders.length} commande(s) au total',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Rechercher par ID de commande...',
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.clear_rounded),
              )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Filtrer par statut:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatusFilter,
                      onChanged: (value) => setState(() => _selectedStatusFilter = value!),
                      items: ['Tous', 'enAttente', 'confirmee', 'expediee', 'livree', 'annulee']
                          .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status == 'Tous'
                            ? status
                            : _getStatusLabel(OrderStatus.values.firstWhere(
                                (e) => e.toString().split('.').last == status))),
                      ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final Map<OrderStatus, int> statusStats = {};
    for (final order in _orderController.orders) {
      statusStats[order.status] = (statusStats[order.status] ?? 0) + 1;
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: OrderStatus.values.length,
        itemBuilder: (context, index) {
          final status = OrderStatus.values[index];
          final count = statusStats[status] ?? 0;
          final color = _getStatusColor(status);

          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getStatusIcon(status), color: color, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.9,
                maxHeight: constraints.maxHeight * 0.9,
              ),
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _searchQuery.isNotEmpty || _selectedStatusFilter != 'Tous'
                          ? 'Aucune commande trouvée'
                          : 'Aucune commande disponible',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isNotEmpty || _selectedStatusFilter != 'Tous'
                          ? 'Essayez de modifier vos critères de recherche'
                          : 'Les commandes apparaîtront ici une fois créées',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_searchQuery.isNotEmpty || _selectedStatusFilter != 'Tous') ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _selectedStatusFilter = 'Tous';
                          });
                        },
                        icon: const Icon(Icons.clear_all_rounded),
                        label: const Text('Effacer les filtres'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);
    final dateFormatter = DateFormat('dd/MM/yyyy à HH:mm');
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande #${order.id}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isDesktop ? 20 : 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormatter.format(order.dateCommande.toLocal()),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: isDesktop ? 14 : 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusLabel(order.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.person_rounded, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Client: ${order.telephone}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: isDesktop ? 14 : 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Articles commandés:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...order.items.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.blue.shade600,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Quantité: ${item.quantite}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.sousTotal.toStringAsFixed(2)} CFA',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade50, Colors.blue.shade50],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Montant Total:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${order.montantTotal.toStringAsFixed(2)} CFA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<OrderStatus>(
                    value: order.status,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: OrderStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        enabled: status == OrderStatus.livree || status == OrderStatus.annulee,
                        child: Row(
                          children: [
                            Icon(_getStatusIcon(status), size: 16, color: _getStatusColor(status)),
                            const SizedBox(width: 8),
                            Text(_getStatusLabel(status)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newStatus) {
                      if (newStatus != null) {
                        _updateOrderStatus(order.id, newStatus);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.notifications_rounded, color: Colors.blue.shade600),
                  onPressed: () => _sendNotification(order.id),
                  tooltip: 'Envoyer notification',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
