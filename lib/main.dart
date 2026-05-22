class _DashboardState extends State<Dashboard> {
  Map<String, dynamic>? config;
  List<Map<String, String>> logs = [];
  ModerationLogger complianceLogger = ModerationLogger();
  bool isLoading = true;
  String currentUserId = "user_${DateTime.now().millisecondsSinceEpoch}";
  
  late GlobalLanguageShield globalShield;
  late SubscriptionManager subscriptionManager;
  
  // ✅ FIX: Instantiated once at the state level
  late final TextEditingController _chatController;
  
  final String backendUrl = "http://YOUR_BACKEND_SERVER_IP:5000/api/moderate";

  @override
  void initState() {
    super.initState();
    _chatController = TextEditingController(); // ✅ FIX: Initialized here
    _initializeModules();
  }

  Future<void> _initializeModules() async {
    try {
      final String response = await rootBundle.loadString('assets/global_moderation_config.json');
      config = json.decode(response);
    } catch (e) {
      print("Configuration asset loading fallback initialized: $e");
      config = {};
    }

    globalShield = GlobalLanguageShield(textBlacklist: config);
    subscriptionManager = SubscriptionManager();
    await subscriptionManager.initPurchase();

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _processMessage(String input) async {
    if (input.trim().isEmpty) return; // Cleaned up spaces

    bool isPremium = subscriptionManager.hasActiveSubscription();
    if (!isPremium && logs.length >= 15) {
      _showSubscriptionPrompt();
      return;
    }

    String detectedLanguage = "unknown";
    bool isBlocked = false;
    String reason = "Clean";

    try {
      detectedLanguage = await globalShield.getLanguage(input);
      isBlocked = await globalShield.isToxic(input, detectedLanguage);
      
      if (isBlocked) {
        reason = "Local Flagged (${detectedLanguage.toUpperCase()})";
      } else {
        final serverResponse = await http.post(
          Uri.parse(backendUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"message": input}),
        ).timeout(Duration(seconds: 4));

        if (serverResponse.statusCode == 200) {
          final serverData = jsonDecode(serverResponse.body);
          if (serverData['blocked'] == true) {
            isBlocked = true;
            detectedLanguage = serverData['language'];
            reason = "Cloud Core Flagged";
          }
        }
      }
    } catch (e) {
      print("System routing error: $e");
    }

    if (isBlocked) {
      complianceLogger.logAction(currentUserId, input, reason);
    }

    if (mounted) {
      setState(() {
        logs.insert(0, {
          "text": input,
          "status": isBlocked ? "BLOCKED" : "ALLOWED",
          "reason": isBlocked ? "Reason: $reason" : "Clean",
          "compliance_logged": isBlocked ? "✓" : "N/A"
        });
      });
    }
  }

  void _showSubscriptionPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("🌟 Activate SafeStream Premium"),
        content: Text("You have reached the free monitoring limit. Unlock cross-platform visual AI and unlimited global language text parsing filters for just \$1.00 a month."),
        actions: [
          TextButton(child: Text("Later"), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: Text("Subscribe Now"),
            onPressed: () {
              Navigator.pop(context);
              final product = subscriptionManager.getProduct(SubscriptionManager.premiumMonthlyId);
              if (product != null) subscriptionManager.purchaseProduct(product);
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Live Stream Guard"),
        actions: [
          IconButton(
            icon: Icon(Icons.description),
            onPressed: () => _showComplianceLogs(),
            tooltip: "View Encrypted Logs"
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => Navigator.pop(context)
          )
        ]
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator()) 
        : SafeArea(
            child: Column(
              children: [
                _buildTestInput(),
                _buildStatsBar(),
                Expanded(child: _buildLogList()),
              ],
            ),
          ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: EdgeInsets.all(12),
      color: Colors.grey[900],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text("Total Messages", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text("${logs.length}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))
            ],
          ),
          Column(
            children: [
              Text("Blocked", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text("${logs.where((l) => l['status'] == 'BLOCKED').length}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red))
            ],
          ),
          Column(
            children: [
              Text("Encrypted Logs", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text("${complianceLogger.getLogsCount()}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green))
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestInput() {
    // ✅ FIX: Removed local variable allocation, using the permanent state variable
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _chatController,
        decoration: InputDecoration(
          hintText: "Simulate live chat message...",
          suffixIcon: IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              if (_chatController.text.isNotEmpty) {
                _processMessage(_chatController.text);
                _chatController.clear();
              }
            },
          ),
          border: OutlineInputBorder(),
        ),
        onSubmitted: (val) {
          _processMessage(val);
          _chatController.clear();
        },
      ),
    );
  }

  Widget _buildLogList() {
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, i) {
        bool blocked = logs[i]['status'] == "BLOCKED";
        return ListTile(
          leading: Icon(blocked ? Icons.block : Icons.check_circle, color: blocked ? Colors.red : Colors.green),
          title: Text(logs[i]['text']!),
          subtitle: Text(logs[i]['reason']!),
          trailing: blocked 
            ? Chip(label: Text("DELETED", style: TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: Colors.red)
            : null,
        );
      },
    );
  }

  void _showComplianceLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("🔐 Encrypted Compliance Logs (2026 IT Rules)"),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: complianceLogger.getLogsCount(),
            itemBuilder: (context, i) {
              final log = complianceLogger.getDecryptedLog(i);
              return Card(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Time: ${log['time']}", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text("User: ${log['user_id']}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text("Content: ${log['content']}", style: TextStyle(fontSize: 11)),
                      Text("Violation: ${log['violation']}", style: TextStyle(fontSize: 11, color: Colors.red)),
                      Text("Action: ${log['action']}", style: TextStyle(fontSize: 10, color: Colors.green)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Close"))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chatController.dispose(); // ✅ FIX: Properly clean up memory footprint
    globalShield.dispose();
    subscriptionManager.dispose();
    super.dispose();
  }
}
