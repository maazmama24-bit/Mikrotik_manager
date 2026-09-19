import 'package:router_os_client/router_os_client.dart';

/// طبقة الاتصال العامة مع أجهزة MikroTik.
///
/// مستقلة عن:
/// - عنوان IP معين
/// - اسم راوتر معين
/// - إصدار RouterOS معين
/// - عدد معين من المستخدمين
class MikroTikApi {
  RouterOSClient? _client;

  String? lastError;

  String? _host;
  String? _username;

  int _port = 8728;
  bool _useSsl = false;

  Duration _timeout = const Duration(seconds: 15);

  // ===========================================================================
  // Connection
  // ===========================================================================

  Future<bool> connect({
    required String host,
    required String username,
    required String password,
    int port = 8728,
    bool useSsl = false,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    lastError = null;

    disconnect();

    _host = host;
    _username = username;
    _port = port;
    _useSsl = useSsl;
    _timeout = timeout;

    RouterOSClient? client;

    try {
      client = RouterOSClient(
        address: host,
        user: username,
        password: password,
        port: port,
        useSsl: useSsl,
        timeout: timeout,
        verbose: false,
      );

      final success = await client.login();

      if (!success) {
        lastError = 'فشل تسجيل الدخول إلى MikroTik';
        client.close();
        return false;
      }

      _client = client;

      return true;
    } catch (e) {
      lastError = e.toString();

      client?.close();
      _client = null;

      return false;
    }
  }

  void disconnect() {
    _client?.close();
    _client = null;
  }

  bool get isConnected => _client != null;

  RouterOSClient get _requireClient {
    final client = _client;

    if (client == null) {
      throw Exception('لا يوجد اتصال بجهاز MikroTik');
    }

    return client;
  }

  // ===========================================================================
  // Internal API helpers
  // ===========================================================================

  Future<List<Map<String, String>>> _talk(
      String command, {
        Map<String, String>? params,
      }) async {
    try {
      final result = await _requireClient.talk(
        [command],
        params,
      );

      lastError = null;

      return result;
    } catch (e) {
      lastError = e.toString();
      rethrow;
    }
  }

  Future<List<Map<String, String>>> _print(
      String command, {
        List<String>? properties,
        Map<String, String>? queries,
      }) async {
    final params = <String, String>{};

    if (properties != null && properties.isNotEmpty) {
      params['.proplist'] = properties.join(',');
    }

    if (queries != null) {
      for (final entry in queries.entries) {
        final key = entry.key.startsWith('?')
            ? entry.key
            : '?${entry.key}';

        params[key] = entry.value;
      }
    }

    return _talk(
      command,
      params: params.isEmpty ? null : params,
    );
  }

  /// تنفيذ أمر find عام.
  ///
  /// RouterOS يعيد الـinternal IDs للعناصر المطابقة.
  Future<List<Map<String, String>>> _find(
      String command, {
        Map<String, String>? values,
      }) async {
    final params = <String, String>{};

    if (values != null) {
      params.addAll(values);
    }

    return _talk(
      command,
      params: params.isEmpty ? null : params,
    );
  }

  Future<void> _set(
      String command,
      String id,
      Map<String, String> values,
      ) async {
    final params = <String, String>{
      '.id': id,
      ...values,
    };

    await _talk(
      command,
      params: params,
    );
  }

  Future<void> _remove(
      String command,
      String id,
      ) async {
    await _talk(
      command,
      params: {
        '.id': id,
      },
    );
  }

  /// إضافة عنصر جديد. تعيد الـ ID الخاص بالعنصر المضاف.
  Future<String?> _add(
      String command,
      Map<String, String> values,
      ) async {
    final result = await _talk(
      command,
      params: values,
    );

    if (result.isEmpty) {
      return null;
    }

    final first = result.first;

    return first['ret'] ??
        first['.id'] ??
        first['id'];
  }

  // ===========================================================================
  // Router Info
  // ===========================================================================

  Future<Map<String, String>> getRouterInfo() async {
    final client = _requireClient;

    try {
      final identityResult = await client.talk(
        ['/system/identity/print'],
        {
          '.proplist': 'name',
        },
      );

      final resourceResult = await client.talk(
        ['/system/resource/print'],
        {
          '.proplist':
          'version,architecture-name,uptime,board-name,cpu,cpu-load,free-memory,total-memory',
        },
      );

      final identity = identityResult.isNotEmpty
          ? identityResult.first
          : <String, String>{};

      final resource = resourceResult.isNotEmpty
          ? resourceResult.first
          : <String, String>{};

      lastError = null;

      return {
        'identity': identity['name'] ?? 'غير معروف',
        'version': resource['version'] ?? 'غير معروف',
        'architecture':
        resource['architecture-name'] ?? 'غير معروف',
        'uptime': resource['uptime'] ?? 'غير معروف',
        'board': resource['board-name'] ?? 'غير معروف',
        'cpu': resource['cpu'] ?? 'غير معروف',
        'cpuLoad': resource['cpu-load'] ?? 'غير معروف',
        'freeMemory': resource['free-memory'] ?? 'غير معروف',
        'totalMemory': resource['total-memory'] ?? 'غير معروف',
      };
    } catch (e) {
      lastError = e.toString();
      rethrow;
    }
  }
  // ===========================================================================
  // Firewall - Filter Rules
  // ===========================================================================

  Future<List<Map<String, String>>> getFirewallFilterRules() async {
    return _print(
      '/ip/firewall/filter/print',
      properties: const [
        '.id',
        'chain',
        'action',
        'protocol',
        'src-address',
        'dst-address',
        'dst-port',
        'in-interface',
        'out-interface',
        'comment',
        'disabled',
        'bytes',
        'packets',
      ],
    );
  }

  Future<void> toggleFirewallFilterRule({
    required String id,
    required bool disabled,
  }) async {
    await _set(
      '/ip/firewall/filter/set',
      id,
      {'disabled': disabled ? 'yes' : 'no'},
    );
  }

  Future<void> deleteFirewallFilterRule(String id) async {
    await _remove('/ip/firewall/filter/remove', id);
  }

  Future<void> moveFirewallFilterRule({
    required String id,
    required String destination,
  }) async {
    await _talk(
      '/ip/firewall/filter/move',
      params: {
        '.id': id,
        'destination': destination,
      },
    );
  }

  // ===========================================================================
  // Firewall - NAT Rules
  // ===========================================================================

  Future<List<Map<String, String>>> getFirewallNatRules() async {
    return _print(
      '/ip/firewall/nat/print',
      properties: const [
        '.id',
        'chain',
        'action',
        'protocol',
        'src-address',
        'dst-address',
        'dst-port',
        'to-addresses',
        'to-ports',
        'in-interface',
        'out-interface',
        'comment',
        'disabled',
        'bytes',
        'packets',
      ],
    );
  }

  Future<String?> addFirewallNatRule({
    required String chain,
    required String action,
    String? protocol,
    String? srcAddress,
    String? dstAddress,
    String? dstPort,
    String? toAddresses,
    String? toPorts,
    String? inInterface,
    String? outInterface,
    String? comment,
  }) async {
    final values = <String, String>{
      'chain': chain.trim(),
      'action': action.trim(),
    };

    void add(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        values[key] = value.trim();
      }
    }

    add('protocol', protocol);
    add('src-address', srcAddress);
    add('dst-address', dstAddress);
    add('dst-port', dstPort);
    add('to-addresses', toAddresses);
    add('to-ports', toPorts);
    add('in-interface', inInterface);
    add('out-interface', outInterface);
    add('comment', comment);

    return _add('/ip/firewall/nat/add', values);
  }

  Future<void> updateFirewallNatRule({
    required String id,
    String? chain,
    String? action,
    String? protocol,
    String? srcAddress,
    String? dstAddress,
    String? dstPort,
    String? toAddresses,
    String? toPorts,
    String? inInterface,
    String? outInterface,
    String? comment,
    bool? disabled,
  }) async {
    final values = <String, String>{};

    void add(String key, String? value) {
      if (value != null) {
        values[key] = value.trim();
      }
    }

    add('chain', chain);
    add('action', action);
    add('protocol', protocol);
    add('src-address', srcAddress);
    add('dst-address', dstAddress);
    add('dst-port', dstPort);
    add('to-addresses', toAddresses);
    add('to-ports', toPorts);
    add('in-interface', inInterface);
    add('out-interface', outInterface);
    add('comment', comment);

    if (disabled != null) {
      values['disabled'] = disabled ? 'yes' : 'no';
    }

    if (values.isEmpty) return;

    await _set('/ip/firewall/nat/set', id, values);
  }

  Future<void> deleteFirewallNatRule(String id) async {
    await _remove('/ip/firewall/nat/remove', id);
  }

  /// إضافة قاعدة Masquerade سريعة.
  Future<String?> addMasqueradeRule({
    required String outInterface,
    String? comment,
  }) async {
    return addFirewallNatRule(
      chain: 'srcnat',
      action: 'masquerade',
      outInterface: outInterface,
      comment: comment ?? 'Masquerade',
    );
  }

  // ===========================================================================
  // Firewall - Mangle Rules
  // ===========================================================================

  Future<List<Map<String, String>>> getFirewallMangleRules() async {
    return _print(
      '/ip/firewall/mangle/print',
      properties: const [
        '.id',
        'chain',
        'action',
        'protocol',
        'src-address',
        'dst-address',
        'new-packet-mark',
        'new-connection-mark',
        'passthrough',
        'comment',
        'disabled',
        'bytes',
        'packets',
      ],
    );
  }

  Future<void> toggleFirewallMangleRule({
    required String id,
    required bool disabled,
  }) async {
    await _set(
      '/ip/firewall/mangle/set',
      id,
      {'disabled': disabled ? 'yes' : 'no'},
    );
  }

  Future<void> deleteFirewallMangleRule(String id) async {
    await _remove('/ip/firewall/mangle/remove', id);
  }

  // ===========================================================================
  // Firewall - Connection Tracking
  // ===========================================================================

  Future<List<Map<String, String>>> getFirewallConnections() async {
    try {
      return await _print(
        '/ip/firewall/connection/print',
        properties: const [
          '.id',
          'protocol',
          'src-address',
          'dst-address',
          'tcp-state',
          'timeout',
        ],
      );
    } catch (e) {
      return [];
    }
  }

  // ===========================================================================
  // Hotspot Servers
  // ===========================================================================

  Future<List<Map<String, String>>> getHotspotServers() async {
    return _print(
      '/ip/hotspot/print',
      properties: const [
        '.id',
        'name',
        'interface',
        'address-pool',
        'profile',
        'idle-timeout',
        'keepalive-timeout',
        'disabled',
        'comment',
      ],
    );
  }

  Future<String?> addHotspotServer({
    required String name,
    required String interface,
    required String addressPool,
    String? profile,
    String? idleTimeout,
    String? comment,
  }) async {
    final values = <String, String>{
      'name': name.trim(),
      'interface': interface.trim(),
      'address-pool': addressPool.trim(),
    };

    if (profile != null && profile.trim().isNotEmpty) {
      values['profile'] = profile.trim();
    }
    if (idleTimeout != null && idleTimeout.trim().isNotEmpty) {
      values['idle-timeout'] = idleTimeout.trim();
    }
    if (comment != null && comment.trim().isNotEmpty) {
      values['comment'] = comment.trim();
    }

    return _add('/ip/hotspot/add', values);
  }

  Future<void> updateHotspotServer({
    required String id,
    String? name,
    String? interface,
    String? addressPool,
    String? profile,
    String? idleTimeout,
    String? comment,
    bool? disabled,
  }) async {
    final values = <String, String>{};

    if (name != null) values['name'] = name.trim();
    if (interface != null) values['interface'] = interface.trim();
    if (addressPool != null) values['address-pool'] = addressPool.trim();
    if (profile != null) values['profile'] = profile.trim();
    if (idleTimeout != null) values['idle-timeout'] = idleTimeout.trim();
    if (comment != null) values['comment'] = comment.trim();
    if (disabled != null) {
      values['disabled'] = disabled ? 'yes' : 'no';
    }

    if (values.isEmpty) return;

    await _set('/ip/hotspot/set', id, values);
  }

  Future<void> deleteHotspotServer(String id) async {
    await _remove('/ip/hotspot/remove', id);
  }

  // ===========================================================================
  // Hotspot Hosts
  // ===========================================================================

  Future<List<Map<String, String>>> getHotspotHosts() async {
    return _print(
      '/ip/hotspot/host/print',
      properties: const [
        '.id',
        'mac-address',
        'address',
        'to-address',
        'server',
        'uptime',
        'idle-time',
        'dynamic',
        'bypassed',
        'authorized',
      ],
    );
  }

  Future<void> makeHostBypassed(String id, {bool bypassed = true}) async {
    await _set(
      '/ip/hotspot/host/set',
      id,
      {'bypassed': bypassed ? 'yes' : 'no'},
    );
  }

  Future<void> makeHostAuthorized(String id, {bool authorized = true}) async {
    try {
      await _talk(
        authorized ? '/ip/hotspot/host/make-binding' : '/ip/hotspot/host/remove',
        params: {'.id': id},
      );
    } catch (e) {
      lastError = e.toString();
      rethrow;
    }
  }

  Future<void> deleteHotspotHost(String id) async {
    await _remove('/ip/hotspot/host/remove', id);
  }

  // ===========================================================================
  // Hotspot IP Bindings
  // ===========================================================================

  Future<List<Map<String, String>>> getHotspotIpBindings() async {
    return _print(
      '/ip/hotspot/ip-binding/print',
      properties: const [
        '.id',
        'mac-address',
        'address',
        'to-address',
        'server',
        'type',
        'comment',
        'disabled',
      ],
    );
  }

  Future<String?> addHotspotIpBinding({
    required String type,
    String? macAddress,
    String? address,
    String? toAddress,
    String? server,
    String? comment,
  }) async {
    final values = <String, String>{
      'type': type.trim(),
    };

    if (macAddress != null && macAddress.trim().isNotEmpty) {
      values['mac-address'] = macAddress.trim();
    }
    if (address != null && address.trim().isNotEmpty) {
      values['address'] = address.trim();
    }
    if (toAddress != null && toAddress.trim().isNotEmpty) {
      values['to-address'] = toAddress.trim();
    }
    if (server != null && server.trim().isNotEmpty) {
      values['server'] = server.trim();
    }
    if (comment != null && comment.trim().isNotEmpty) {
      values['comment'] = comment.trim();
    }

    return _add('/ip/hotspot/ip-binding/add', values);
  }

  Future<void> updateHotspotIpBinding({
    required String id,
    String? type,
    String? macAddress,
    String? address,
    String? toAddress,
    String? server,
    String? comment,
    bool? disabled,
  }) async {
    final values = <String, String>{};

    if (type != null) values['type'] = type.trim();
    if (macAddress != null) values['mac-address'] = macAddress.trim();
    if (address != null) values['address'] = address.trim();
    if (toAddress != null) values['to-address'] = toAddress.trim();
    if (server != null) values['server'] = server.trim();
    if (comment != null) values['comment'] = comment.trim();
    if (disabled != null) {
      values['disabled'] = disabled ? 'yes' : 'no';
    }

    if (values.isEmpty) return;

    await _set('/ip/hotspot/ip-binding/set', id, values);
  }

  Future<void> deleteHotspotIpBinding(String id) async {
    await _remove('/ip/hotspot/ip-binding/remove', id);
  }

  // ===========================================================================
  // Hotspot Walled Garden
  // ===========================================================================

  Future<List<Map<String, String>>> getHotspotWalledGarden() async {
    return _print(
      '/ip/hotspot/walled-garden/print',
      properties: const [
        '.id',
        'action',
        'dst-host',
        'dst-address',
        'src-address',
        'server',
        'comment',
        'disabled',
      ],
    );
  }

  Future<String?> addHotspotWalledGarden({
    required String action,
    String? dstHost,
    String? dstAddress,
    String? srcAddress,
    String? server,
    String? comment,
  }) async {
    final values = <String, String>{
      'action': action.trim(),
    };

    if (dstHost != null && dstHost.trim().isNotEmpty) {
      values['dst-host'] = dstHost.trim();
    }
    if (dstAddress != null && dstAddress.trim().isNotEmpty) {
      values['dst-address'] = dstAddress.trim();
    }
    if (srcAddress != null && srcAddress.trim().isNotEmpty) {
      values['src-address'] = srcAddress.trim();
    }
    if (server != null && server.trim().isNotEmpty) {
      values['server'] = server.trim();
    }
    if (comment != null && comment.trim().isNotEmpty) {
      values['comment'] = comment.trim();
    }

    return _add('/ip/hotspot/walled-garden/add', values);
  }

  Future<void> deleteHotspotWalledGarden(String id) async {
    await _remove('/ip/hotspot/walled-garden/remove', id);
  }

  // ===========================================================================
  // Hotspot Setup Helper
  // ===========================================================================

  /// إعداد Hotspot كامل بأمر واحد.
  /// يقوم بـ:
  /// 1. إنشاء IP Pool
  /// 2. إنشاء Hotspot Server
  /// 3. تفعيل DNS
  Future<Map<String, dynamic>> setupHotspot({
    required String interface,
    required String hotspotName,
    required String poolName,
    required String poolRange,
    required String dnsName,
    String? addressPoolGateway,
  }) async {
    final result = <String, dynamic>{
      'poolCreated': false,
      'serverCreated': false,
      'dnsEnabled': false,
      'errors': <String>[],
    };

    // 1. إنشاء IP Pool
    try {
      await addIpPool(name: poolName, ranges: poolRange);
      result['poolCreated'] = true;
    } catch (e) {
      result['errors'].add('IP Pool: $e');
    }

    // 2. إنشاء Hotspot Server
    try {
      await addHotspotServer(
        name: hotspotName,
        interface: interface,
        addressPool: poolName,
        profile: 'default',
        idleTimeout: '5m',
      );
      result['serverCreated'] = true;
    } catch (e) {
      result['errors'].add('Hotspot Server: $e');
    }

    // 3. تفعيل DNS
    try {
      await updateDnsSettings(allowRemoteRequests: true);
      result['dnsEnabled'] = true;
    } catch (e) {
      result['errors'].add('DNS: $e');
    }

    return result;
  }

  // ===========================================================================
  // Hotspot Profiles
  // ===========================================================================

  Future<List<Map<String, String>>> getHotspotProfiles() async {
    return _print(
      '/ip/hotspot/user/profile/print',
      properties: const [
        '.id',
        'name',
        'address-pool',
        'shared-users',
        'rate-limit',
        'session-timeout',
        'idle-timeout',
        'keepalive-timeout',
        'status-autorefresh',
        'queue-type',
        'parent-queue',
        'on-login',
        'on-logout',
      ],
    );
  }

  /// إضافة Hotspot Profile جديد.
  Future<String?> addHotspotProfile({
    required String name,
    String? addressPool,
    String? sharedUsers,
    String? rateLimit,
    String? sessionTimeout,
    String? idleTimeout,
    String? keepaliveTimeout,
    String? statusAutorefresh,
    String? queueType,
    String? parentQueue,
    String? onLogin,
    String? onLogout,
  }) async {
    final values = <String, String>{
      'name': name.trim(),
    };

    void add(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        values[key] = value.trim();
      }
    }

    add('address-pool', addressPool);
    add('shared-users', sharedUsers);
    add('rate-limit', rateLimit);
    add('session-timeout', sessionTimeout);
    add('idle-timeout', idleTimeout);
    add('keepalive-timeout', keepaliveTimeout);
    add('status-autorefresh', statusAutorefresh);
    add('queue-type', queueType);
    add('parent-queue', parentQueue);
    add('on-login', onLogin);
    add('on-logout', onLogout);

    return _add('/ip/hotspot/user/profile/add', values);
  }

  /// حذف Hotspot Profile.
  Future<void> deleteHotspotProfile(String id) async {
    await _remove('/ip/hotspot/user/profile/remove', id);
  }

  Future<void> updateHotspotProfile({
    required String id,
    String? name,
    String? addressPool,
    String? sharedUsers,
    String? rateLimit,
    String? sessionTimeout,
    String? idleTimeout,
    String? keepaliveTimeout,
    String? statusAutorefresh,
    String? queueType,
    String? parentQueue,
    String? onLogin,
    String? onLogout,
  }) async {
    final values = <String, String>{};

    void add(String key, String? value) {
      if (value != null) {
        values[key] = value;
      }
    }

    add('name', name);
    add('address-pool', addressPool);
    add('shared-users', sharedUsers);
    add('rate-limit', rateLimit);
    add('session-timeout', sessionTimeout);
    add('idle-timeout', idleTimeout);
    add('keepalive-timeout', keepaliveTimeout);
    add('status-autorefresh', statusAutorefresh);
    add('queue-type', queueType);
    add('parent-queue', parentQueue);
    add('on-login', onLogin);
    add('on-logout', onLogout);

    if (values.isEmpty) {
      return;
    }

    await _set(
      '/ip/hotspot/user/profile/set',
      id,
      values,
    );
  }

  // ===========================================================================
  // Hotspot Users
  // ===========================================================================

  static const List<String> _hotspotUserProperties = [
    '.id',
    'name',
    'password',
    'profile',
    'disabled',
    'mac-address',
    'limit-uptime',
    'limit-bytes-total',
    'comment',
    'address',
    'routes',
    'email',
    'server',
  ];

  /// البحث عن مستخدم محدد.
  ///
  /// لا يتم تحميل جميع المستخدمين.
  Future<List<Map<String, String>>> getHotspotUsers({
    String? profile,
    String? username,
  }) async {
    final name = username?.trim() ?? '';

    if (name.isNotEmpty) {
      return _searchHotspotUsersByName(name);
    }

    if (profile != null && profile.trim().isNotEmpty) {
      return _searchHotspotUsersByProfile(
        profile.trim(),
      );
    }

    return [];
  }

  Future<List<Map<String, String>>> _searchHotspotUsersByName(
      String username,
      ) async {
    final name = username.trim();

    if (name.isEmpty) {
      return [];
    }

    // 1) بحث دقيق (exact match)
    try {
      final result = await _print(
        '/ip/hotspot/user/print',
        properties: _hotspotUserProperties,
        queries: {
          '?name': name,
        },
      );

      if (result.isNotEmpty) {
        return result;
      }
    } catch (e) {
      lastError = e.toString();
    }

    // 2) بحث جزئي (contains) باستخدام regex
    try {
      final result = await _print(
        '/ip/hotspot/user/print',
        properties: _hotspotUserProperties,
        queries: {
          '?name': '~$name',
        },
      );

      if (result.isNotEmpty) {
        return result;
      }
    } catch (e) {
      lastError = e.toString();
    }

    // 3) بحث بدون حساسية لحالة الأحرف (lowercase)
    try {
      final result = await _print(
        '/ip/hotspot/user/print',
        properties: _hotspotUserProperties,
        queries: {
          '?name': '~${name.toLowerCase()}',
        },
      );

      if (result.isNotEmpty) {
        return result;
      }
    } catch (e) {
      lastError = e.toString();
    }

    return [];
  }
  Future<List<Map<String, String>>> _searchHotspotUsersByProfile(
      String profile,
      ) async {
    final profileName = profile.trim();

    if (profileName.isEmpty) {
      return [];
    }

    return _print(
      '/ip/hotspot/user/print',
      properties: _hotspotUserProperties,
      queries: {
        '?profile': profileName,
      },
    );
  }

  Future<List<Map<String, String>>> getAllHotspotUsers({
    String? profile,
  }) async {
    final queries = <String, String>{};

    final profileName = profile?.trim() ?? '';

    if (profileName.isNotEmpty) {
      queries['?profile'] = profileName;
    }

    return _print(
      '/ip/hotspot/user/print',
      properties: _hotspotUserProperties,
      queries: queries.isEmpty ? null : queries,
    );
  }

  Future<List<String>> findHotspotUsersByName(
      String username,
      ) async {
    final users = await _searchHotspotUsersByName(username);

    return users
        .map((user) => user['.id'] ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<List<String>> findHotspotUsersByProfile(
      String profile,
      ) async {
    final users = await _searchHotspotUsersByProfile(profile);

    return users
        .map((user) => user['.id'] ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<Map<String, String>?> getHotspotUserById(
      String id,
      ) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    final result = await _print(
      '/ip/hotspot/user/print',
      properties: _hotspotUserProperties,
      queries: {
        '?.id': cleanId,
      },
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  // ===========================================================================
  // Update / Delete Hotspot User
  // ===========================================================================

  /// تعديل بيانات مستخدم Hotspot موجود.
  Future<void> updateHotspotUser({
    required String id,
    String? name,
    String? password,
    String? profile,
    String? macAddress,
    String? limitUptime,
    String? limitBytesTotal,
    String? comment,
    String? address,
    String? routes,
    String? email,
    String? server,
    bool? disabled,
  }) async {
    final values = <String, String>{};

    void add(String key, String? value) {
      if (value != null) {
        values[key] = value;
      }
    }

    add('name', name);
    add('password', password);
    add('profile', profile);
    add('mac-address', macAddress);
    add('limit-uptime', limitUptime);
    add('limit-bytes-total', limitBytesTotal);
    add('comment', comment);
    add('address', address);
    add('routes', routes);
    add('email', email);
    add('server', server);

    if (disabled != null) {
      values['disabled'] = disabled ? 'yes' : 'no';
    }

    if (values.isEmpty) {
      return;
    }

    await _set(
      '/ip/hotspot/user/set',
      id,
      values,
    );
  }

  /// حذف مستخدم Hotspot.
  Future<void> deleteHotspotUser(
      String id,
      ) async {
    await _remove(
      '/ip/hotspot/user/remove',
      id,
    );
  }

  // ===========================================================================
  // ADD Hotspot User
  // ===========================================================================

  /// إضافة مستخدم Hotspot جديد.
  ///
  /// تعيد الـ ID الخاص بالمستخدم المضاف، أو `null` في حال الفشل.
  Future<String?> addHotspotUser({
    required String name,
    required String password,
    required String profile,
    String? macAddress,
    String? limitUptime,
    String? limitBytesTotal,
    String? comment,
    String? address,
    String? routes,
    String? email,
    String? server,
    bool disabled = false,
  }) async {
    final values = <String, String>{
      'name': name.trim(),
      'password': password,
      'profile': profile.trim(),
      'disabled': disabled ? 'yes' : 'no',
    };

    void add(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        values[key] = value.trim();
      }
    }

    add('mac-address', macAddress);
    add('limit-uptime', limitUptime);
    add('limit-bytes-total', limitBytesTotal);
    add('comment', comment);
    add('address', address);
    add('routes', routes);
    add('email', email);
    add('server', server);

    return _add(
      '/ip/hotspot/user/add',
      values,
    );
  }

  /// إضافة مجموعة من المستخدمين دفعة واحدة.
  ///
  /// تعيد عدد المستخدمين الذين تمت إضافتهم بنجاح.
  Future<int> addHotspotUsersBatch(
      List<Map<String, String>> users,
      ) async {
    int successCount = 0;

    for (final user in users) {
      try {
        final id = await addHotspotUser(
          name: user['name'] ?? '',
          password: user['password'] ?? '',
          profile: user['profile'] ?? '',
          macAddress: user['mac-address'],
          limitUptime: user['limit-uptime'],
          limitBytesTotal: user['limit-bytes-total'],
          comment: user['comment'],
          address: user['address'],
          routes: user['routes'],
          email: user['email'],
          server: user['server'],
        );

        if (id != null && id.isNotEmpty) {
          successCount++;
        }
      } catch (e) {
        lastError = e.toString();
        // نكمل بقية المستخدمين
      }
    }

    return successCount;
  }

  /// فحص وجود اسم مستخدم.
  Future<bool> hotspotUserExists(String name) async {
    try {
      final result = await _searchHotspotUsersByName(name);

      return result.any(
            (user) =>
        (user['name'] ?? '').toLowerCase() ==
            name.trim().toLowerCase(),
      );
    } catch (_) {
      return false;
    }
  }

  /// توليد كروت Hotspot بأرقام متسلسلة.
  ///
  /// مثال: prefix = "user"، startNumber = 1، count = 10
  /// ينتج: user001, user002, ...
  Future<List<Map<String, String>>> generateHotspotCards({
    required String prefix,
    required String profile,
    required int count,
    int startNumber = 1,
    int numberPadding = 4,
    String passwordPrefix = '',
    bool useNameAsPassword = true,
    bool checkDuplicates = true,
    Function(int current, int total)? onProgress,
  }) async {
    final generated = <Map<String, String>>[];

    for (int i = 0; i < count; i++) {
      final number = startNumber + i;

      final numberStr =
      number.toString().padLeft(numberPadding, '0');

      final name = '$prefix$numberStr';

      final password = useNameAsPassword
          ? name
          : '$passwordPrefix$numberStr';

      // فحص التكرار
      if (checkDuplicates) {
        final exists = await hotspotUserExists(name);

        if (exists) {
          onProgress?.call(i + 1, count);
          continue;
        }
      }

      generated.add({
        'name': name,
        'password': password,
        'profile': profile,
      });

      onProgress?.call(i + 1, count);
    }

    return generated;
  }

  // ===========================================================================
  // Hotspot Active Users
  // ===========================================================================

  Future<List<Map<String, String>>> getConnectedUsers() async {
    return _print(
      '/ip/hotspot/active/print',
      properties: const [
        '.id',
        'user',
        'address',
        'mac-address',
        'login-by',
        'uptime',
        'session-time-left',
        'idle-time',
        'idle-timeout',
        'bytes-in',
        'bytes-out',
        'packets-in',
        'packets-out',
        'server',
      ],
    );
  }

  Future<void> disconnectHotspotUser(
      String activeId,
      ) async {
    await _remove(
      '/ip/hotspot/active/remove',
      activeId,
    );
  }

  // ===========================================================================
  // Generic Commands
  // ===========================================================================

  Future<List<Map<String, String>>> printCommand(
      String command, {
        List<String>? properties,
        Map<String, String>? queries,
      }) async {
    return _print(
      command,
      properties: properties,
      queries: queries,
    );
  }

  Future<List<Map<String, String>>> findCommand(
      String command, {
        Map<String, String>? values,
      }) async {
    return _find(
      command,
      values: values,
    );
  }

  Future<void> setCommand(
      String command,
      String id,
      Map<String, String> values,
      ) async {
    await _set(
      command,
      id,
      values,
    );
  }

  Future<void> removeCommand(
      String command,
      String id,
      ) async {
    await _remove(
      command,
      id,
    );
  }
  // ===========================================================================
  // MikroTik Users
  // ===========================================================================

  /// جلب جميع مستخدمي MikroTik (admin, etc).
  Future<List<Map<String, String>>> getMikrotikUsers() async {
    return _print(
      '/user/print',
      properties: const [
        '.id',
        'name',
        'group',
        'comment',
        'disabled',
        'last-logged-in',
      ],
    );
  }

  /// تغيير كلمة مرور مستخدم MikroTik.
  Future<void> updateMikrotikUserPassword({
    required String id,
    required String newPassword,
  }) async {
    await _set(
      '/user/set',
      id,
      {
        'password': newPassword,
      },
    );
  }

  /// إضافة مستخدم MikroTik جديد.
  Future<String?> addMikrotikUser({
    required String name,
    required String password,
    String group = 'full',
    String? comment,
    bool disabled = false,
  }) async {
    final values = <String, String>{
      'name': name.trim(),
      'password': password,
      'group': group,
      'disabled': disabled ? 'yes' : 'no',
    };

    if (comment != null && comment.trim().isNotEmpty) {
      values['comment'] = comment.trim();
    }

    return _add(
      '/user/add',
      values,
    );
  }

  /// حذف مستخدم MikroTik.
  Future<void> deleteMikrotikUser(String id) async {
    await _remove('/user/remove', id);
  }

  /// جلب المجموعات المتاحة.
  Future<List<Map<String, String>>> getMikrotikGroups() async {
    return _print(
      '/user/group/print',
      properties: const [
        '.id',
        'name',
      ],
    );
  }
  // ===========================================================================
  // DHCP - Leases
  // ===========================================================================

  Future<List<Map<String, String>>> getDhcpLeases() async {
    return _print(
      '/ip/dhcp-server/lease/print',
      properties: const [
        '.id',
        'address',
        'mac-address',
        'host-name',
        'status',
        'server',
        'comment',
        'dynamic',
        'disabled',
      ],
    );
  }

  Future<String?> addDhcpLease({
    required String address,
    required String macAddress,
    String? server,
    String? comment,
  }) async {
    final values = <String, String>{
      'address': address.trim(),
      'mac-address': macAddress.trim(),
    };

    if (server != null && server.trim().isNotEmpty) {
      values['server'] = server.trim();
    }

    if (comment != null && comment.trim().isNotEmpty) {
      values['comment'] = comment.trim();
    }

    return _add('/ip/dhcp-server/lease/add', values);
  }

  Future<void> updateDhcpLease({
    required String id,
    String? address,
    String? macAddress,
    String? server,
    String? comment,
    bool? disabled,
  }) async {
    final values = <String, String>{};

    if (address != null) values['address'] = address.trim();
    if (macAddress != null) values['mac-address'] = macAddress.trim();
    if (server != null) values['server'] = server.trim();
    if (comment != null) values['comment'] = comment.trim();
    if (disabled != null) {
      values['disabled'] = disabled ? 'yes' : 'no';
    }

    if (values.isEmpty) return;

    await _set('/ip/dhcp-server/lease/set', id, values);
  }

  Future<void> deleteDhcpLease(String id) async {
    await _remove('/ip/dhcp-server/lease/remove', id);
  }

  // ===========================================================================
  // DHCP - Networks
  // ===========================================================================

  Future<List<Map<String, String>>> getDhcpNetworks() async {
    return _print(
      '/ip/dhcp-server/network/print',
      properties: const [
        '.id',
        'address',
        'gateway',
        'dns-server',
        'netmask',
        'comment',
      ],
    );
  }

  Future<String?> addDhcpNetwork({
    required String address,
    String? gateway,
    String? dnsServer,
    String? comment,
  }) async {
    final values = <String, String>{
      'address': address.trim(),
    };

    if (gateway != null && gateway.trim().isNotEmpty) {
      values['gateway'] = gateway.trim();
    }

    if (dnsServer != null && dnsServer.trim().isNotEmpty) {
      values['dns-server'] = dnsServer.trim();
    }

    if (comment != null && comment.trim().isNotEmpty) {
      values['comment'] = comment.trim();
    }

    return _add('/ip/dhcp-server/network/add', values);
  }

  Future<void> updateDhcpNetwork({
    required String id,
    String? address,
    String? gateway,
    String? dnsServer,
    String? comment,
  }) async {
    final values = <String, String>{};

    if (address != null) values['address'] = address.trim();
    if (gateway != null) values['gateway'] = gateway.trim();
    if (dnsServer != null) values['dns-server'] = dnsServer.trim();
    if (comment != null) values['comment'] = comment.trim();

    if (values.isEmpty) return;

    await _set('/ip/dhcp-server/network/set', id, values);
  }

  Future<void> deleteDhcpNetwork(String id) async {
    await _remove('/ip/dhcp-server/network/remove', id);
  }

  // ===========================================================================
  // DHCP - Servers
  // ===========================================================================

  Future<List<Map<String, String>>> getDhcpServers() async {
    return _print(
      '/ip/dhcp-server/print',
      properties: const [
        '.id',
        'name',
        'interface',
        'address-pool',
        'lease-time',
        'disabled',
        'comment',
      ],
    );
  }

  Future<String?> addDhcpServer({
    required String name,
    required String interface,
    required String addressPool,
    String? leaseTime,
    String? comment,
  }) async {
    final values = <String, String>{
      'name': name.trim(),
      'interface': interface.trim(),
      'address-pool': addressPool.trim(),
    };

    if (leaseTime != null && leaseTime.trim().isNotEmpty) {
      values['lease-time'] = leaseTime.trim();
    }

    if (comment != null && comment.trim().isNotEmpty) {
      values['comment'] = comment.trim();
    }

    return _add('/ip/dhcp-server/add', values);
  }

  Future<void> updateDhcpServer({
    required String id,
    String? name,
    String? interface,
    String? addressPool,
    String? leaseTime,
    String? comment,
    bool? disabled,
  }) async {
    final values = <String, String>{};

    if (name != null) values['name'] = name.trim();
    if (interface != null) values['interface'] = interface.trim();
    if (addressPool != null) values['address-pool'] = addressPool.trim();
    if (leaseTime != null) values['lease-time'] = leaseTime.trim();
    if (comment != null) values['comment'] = comment.trim();
    if (disabled != null) {
      values['disabled'] = disabled ? 'yes' : 'no';
    }

    if (values.isEmpty) return;

    await _set('/ip/dhcp-server/set', id, values);
  }

  Future<void> deleteDhcpServer(String id) async {
    await _remove('/ip/dhcp-server/remove', id);
  }

  // ===========================================================================
  // DNS
  // ===========================================================================

  /// جلب إعدادات DNS الحالية.
  Future<Map<String, String>> getDnsSettings() async {
    final result = await _print(
      '/ip/dns/print',
      properties: const [
        'servers',
        'dynamic-servers',
        'allow-remote-requests',
        'cache-size',
        'cache-max-ttl',
        'cache-used',
      ],
    );

    if (result.isEmpty) return {};

    return result.first;
  }

  /// تحديث إعدادات DNS.
  Future<void> updateDnsSettings({
    String? servers,
    bool? allowRemoteRequests,
  }) async {
    final values = <String, String>{};

    if (servers != null) {
      values['servers'] = servers.trim();
    }

    if (allowRemoteRequests != null) {
      values['allow-remote-requests'] =
      allowRemoteRequests ? 'yes' : 'no';
    }

    if (values.isEmpty) return;

    await _talk('/ip/dns/set', params: values);
  }

  /// جلب قائمة Static DNS Entries.
  Future<List<Map<String, String>>> getDnsStaticEntries() async {
    return _print(
      '/ip/dns/static/print',
      properties: const [
        '.id',
        'name',
        'address',
        'type',
        'ttl',
        'comment',
        'disabled',
      ],
    );
  }

  /// إضافة Static DNS Entry.
  Future<String?> addDnsStaticEntry({
    required String name,
    required String address,
    String? comment,
  }) async {
    final values = <String, String>{
      'name': name.trim(),
      'address': address.trim(),
    };

    if (comment != null && comment.trim().isNotEmpty) {
      values['comment'] = comment.trim();
    }

    return _add('/ip/dns/static/add', values);
  }

  /// تحديث Static DNS Entry.
  Future<void> updateDnsStaticEntry({
    required String id,
    String? name,
    String? address,
    String? comment,
    bool? disabled,
  }) async {
    final values = <String, String>{};

    if (name != null) values['name'] = name.trim();
    if (address != null) values['address'] = address.trim();
    if (comment != null) values['comment'] = comment.trim();
    if (disabled != null) {
      values['disabled'] = disabled ? 'yes' : 'no';
    }

    if (values.isEmpty) return;

    await _set('/ip/dns/static/set', id, values);
  }

  /// حذف Static DNS Entry.
  Future<void> deleteDnsStaticEntry(String id) async {
    await _remove('/ip/dns/static/remove', id);
  }
  // ===========================================================================
  // DHCP Client
  // ===========================================================================

  Future<List<Map<String, String>>> getDhcpClients() async {
    return _print(
      '/ip/dhcp-client/print',
      properties: const [
        '.id',
        'interface',
        'address',
        'gateway',
        'status',
        'disabled',
        'comment',
      ],
    );
  }

  Future<String?> addDhcpClient({
    required String interface,
    String? comment,
    bool disabled = false,
  }) async {
    final values = <String, String>{
      'interface': interface.trim(),
      'disabled': disabled ? 'yes' : 'no',
    };

    if (comment != null && comment.trim().isNotEmpty) {
      values['comment'] = comment.trim();
    }

    return _add('/ip/dhcp-client/add', values);
  }

  Future<void> updateDhcpClient({
    required String id,
    String? interface,
    String? comment,
    bool? disabled,
  }) async {
    final values = <String, String>{};

    if (interface != null) values['interface'] = interface.trim();
    if (comment != null) values['comment'] = comment.trim();
    if (disabled != null) {
      values['disabled'] = disabled ? 'yes' : 'no';
    }

    if (values.isEmpty) return;

    await _set('/ip/dhcp-client/set', id, values);
  }

  Future<void> deleteDhcpClient(String id) async {
    await _remove('/ip/dhcp-client/remove', id);
  }

  // ===========================================================================
  // IP Addresses
  // ===========================================================================

  Future<List<Map<String, String>>> getIpAddresses() async {
    return _print(
      '/ip/address/print',
      properties: const [
        '.id',
        'address',
        'network',
        'interface',
        'disabled',
        'dynamic',
        'comment',
      ],
    );
  }

  Future<String?> addIpAddress({
    required String address,
    required String interface,
    String? comment,
  }) async {
    final values = <String, String>{
      'address': address.trim(),
      'interface': interface.trim(),
    };

    if (comment != null && comment.trim().isNotEmpty) {
      values['comment'] = comment.trim();
    }

    return _add('/ip/address/add', values);
  }

  Future<void> updateIpAddress({
    required String id,
    String? address,
    String? interface,
    String? comment,
    bool? disabled,
  }) async {
    final values = <String, String>{};

    if (address != null) values['address'] = address.trim();
    if (interface != null) values['interface'] = interface.trim();
    if (comment != null) values['comment'] = comment.trim();
    if (disabled != null) {
      values['disabled'] = disabled ? 'yes' : 'no';
    }

    if (values.isEmpty) return;

    await _set('/ip/address/set', id, values);
  }

  Future<void> deleteIpAddress(String id) async {
    await _remove('/ip/address/remove', id);
  }

  // ===========================================================================
  // IP Pools
  // ===========================================================================

  Future<String?> addIpPool({
    required String name,
    required String ranges,
    String? comment,
  }) async {
    final values = <String, String>{
      'name': name.trim(),
      'ranges': ranges.trim(),
    };

    if (comment != null && comment.trim().isNotEmpty) {
      values['comment'] = comment.trim();
    }

    return _add('/ip/pool/add', values);
  }

  Future<void> updateIpPool({
    required String id,
    String? name,
    String? ranges,
    String? comment,
  }) async {
    final values = <String, String>{};

    if (name != null) values['name'] = name.trim();
    if (ranges != null) values['ranges'] = ranges.trim();
    if (comment != null) values['comment'] = comment.trim();

    if (values.isEmpty) return;

    await _set('/ip/pool/set', id, values);
  }

  Future<void> deleteIpPool(String id) async {
    await _remove('/ip/pool/remove', id);
  }
  // ===========================================================================
  // L2TP Server
  // ===========================================================================

  Future<Map<String, String>> getL2tpServer() async {
    final result = await _print(
      '/interface/l2tp-server/server/print',
      properties: const [
        'enabled',
        'default-profile',
        'use-ipsec',
        'ipsec-secret',
        'authentication',
        'keepalive-timeout',
        'max-mtu',
        'max-mru',
      ],
    );

    if (result.isEmpty) return {};

    return result.first;
  }

  Future<void> updateL2tpServer({
    bool? enabled,
    bool? useIpsec,
    String? ipsecSecret,
    String? defaultProfile,
    String? authentication,
  }) async {
    final values = <String, String>{};

    if (enabled != null) values['enabled'] = enabled ? 'yes' : 'no';
    if (useIpsec != null) values['use-ipsec'] = useIpsec ? 'yes' : 'no';
    if (ipsecSecret != null) values['ipsec-secret'] = ipsecSecret;
    if (defaultProfile != null) {
      values['default-profile'] = defaultProfile;
    }
    if (authentication != null) {
      values['authentication'] = authentication;
    }

    if (values.isEmpty) return;

    await _talk('/interface/l2tp-server/server/set', params: values);
  }

  // ===========================================================================
  // L2TP Users
  // ===========================================================================

  Future<List<Map<String, String>>> getL2tpUsers() async {
    return _print(
      '/interface/l2tp-server/print',
      properties: const [
        '.id',
        'name',
        'service',
        'profile',
        'remote-address',
        'disabled',
        'comment',
        'last-logged-in',
      ],
    );
  }

  Future<String?> addL2tpUser({
    required String name,
    required String password,
    String? profile,
    String? remoteAddress,
    String? comment,
  }) async {
    final values = <String, String>{
      'name': name.trim(),
      'password': password,
      'service': 'l2tp',
    };

    if (profile != null && profile.trim().isNotEmpty) {
      values['profile'] = profile.trim();
    }
    if (remoteAddress != null && remoteAddress.trim().isNotEmpty) {
      values['remote-address'] = remoteAddress.trim();
    }
    if (comment != null && comment.trim().isNotEmpty) {
      values['comment'] = comment.trim();
    }

    return _add('/ppp/secret/add', values);
  }

  Future<void> updateL2tpUser({
    required String id,
    String? name,
    String? password,
    String? profile,
    String? remoteAddress,
    String? comment,
    bool? disabled,
  }) async {
    final values = <String, String>{};

    if (name != null) values['name'] = name.trim();
    if (password != null) values['password'] = password;
    if (profile != null) values['profile'] = profile.trim();
    if (remoteAddress != null) {
      values['remote-address'] = remoteAddress.trim();
    }
    if (comment != null) values['comment'] = comment.trim();
    if (disabled != null) {
      values['disabled'] = disabled ? 'yes' : 'no';
    }

    if (values.isEmpty) return;

    await _set('/ppp/secret/set', id, values);
  }

  Future<void> deleteL2tpUser(String id) async {
    await _remove('/ppp/secret/remove', id);
  }

  // ===========================================================================
  // PPTP Server
  // ===========================================================================

  Future<Map<String, String>> getPptpServer() async {
    final result = await _print(
      '/interface/pptp-server/server/print',
      properties: const [
        'enabled',
        'default-profile',
        'authentication',
        'keepalive-timeout',
        'max-mtu',
        'max-mru',
      ],
    );

    if (result.isEmpty) return {};

    return result.first;
  }

  Future<void> updatePptpServer({
    bool? enabled,
    String? defaultProfile,
    String? authentication,
  }) async {
    final values = <String, String>{};

    if (enabled != null) values['enabled'] = enabled ? 'yes' : 'no';
    if (defaultProfile != null) {
      values['default-profile'] = defaultProfile;
    }
    if (authentication != null) {
      values['authentication'] = authentication;
    }

    if (values.isEmpty) return;

    await _talk('/interface/pptp-server/server/set', params: values);
  }

  // ===========================================================================
  // PPTP Users
  // ===========================================================================

  Future<List<Map<String, String>>> getPptpUsers() async {
    return _print(
      '/interface/pptp-server/print',
      properties: const [
        '.id',
        'name',
        'service',
        'profile',
        'remote-address',
        'disabled',
        'comment',
        'last-logged-in',
      ],
    );
  }

  Future<String?> addPptpUser({
    required String name,
    required String password,
    String? profile,
    String? remoteAddress,
    String? comment,
  }) async {
    final values = <String, String>{
      'name': name.trim(),
      'password': password,
      'service': 'pptp',
    };

    if (profile != null && profile.trim().isNotEmpty) {
      values['profile'] = profile.trim();
    }
    if (remoteAddress != null && remoteAddress.trim().isNotEmpty) {
      values['remote-address'] = remoteAddress.trim();
    }
    if (comment != null && comment.trim().isNotEmpty) {
      values['comment'] = comment.trim();
    }

    return _add('/ppp/secret/add', values);
  }

  Future<void> updatePptpUser({
    required String id,
    String? name,
    String? password,
    String? profile,
    String? remoteAddress,
    String? comment,
    bool? disabled,
  }) async {
    final values = <String, String>{};

    if (name != null) values['name'] = name.trim();
    if (password != null) values['password'] = password;
    if (profile != null) values['profile'] = profile.trim();
    if (remoteAddress != null) {
      values['remote-address'] = remoteAddress.trim();
    }
    if (comment != null) values['comment'] = comment.trim();
    if (disabled != null) {
      values['disabled'] = disabled ? 'yes' : 'no';
    }

    if (values.isEmpty) return;

    await _set('/ppp/secret/set', id, values);
  }

  Future<void> deletePptpUser(String id) async {
    await _remove('/ppp/secret/remove', id);
  }

  // ===========================================================================
  // VPN Active Connections (L2TP + PPTP)
  // ===========================================================================

  Future<List<Map<String, String>>> getVpnActiveConnections() async {
    return _print(
      '/ppp/active/print',
      properties: const [
        '.id',
        'name',
        'service',
        'address',
        'caller-id',
        'uptime',
        'encoding',
      ],
    );
  }

  Future<void> disconnectVpnConnection(String id) async {
    await _remove('/ppp/active/remove', id);
  }

  // ===========================================================================
  // WireGuard
  // ===========================================================================

  Future<List<Map<String, String>>> getWireGuardInterfaces() async {
    try {
      return await _print(
        '/interface/wireguard/print',
        properties: const [
          '.id',
          'name',
          'listen-port',
          'private-key',
          'public-key',
          'mtu',
          'disabled',
        ],
      );
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, String>>> getWireGuardPeers() async {
    try {
      return await _print(
        '/interface/wireguard/peers/print',
        properties: const [
          '.id',
          'interface',
          'public-key',
          'endpoint-address',
          'endpoint-port',
          'allowed-address',
          'current-endpoint-address',
          'rx',
          'tx',
          'last-handshake',
          'comment',
          'disabled',
        ],
      );
    } catch (e) {
      return [];
    }
  }

  Future<String?> addWireGuardInterface({
    required String name,
    int listenPort = 13231,
    String? comment,
  }) async {
    final values = <String, String>{
      'name': name.trim(),
      'listen-port': listenPort.toString(),
    };

    if (comment != null && comment.trim().isNotEmpty) {
      values['comment'] = comment.trim();
    }

    return _add('/interface/wireguard/add', values);
  }

  Future<void> deleteWireGuardInterface(String id) async {
    await _remove('/interface/wireguard/remove', id);
  }

  Future<String?> addWireGuardPeer({
    required String interface,
    required String publicKey,
    String allowedAddress = '0.0.0.0/0',
    String? endpointAddress,
    int? endpointPort,
    int? persistentKeepalive,
    String? comment,
  }) async {
    final values = <String, String>{
      'interface': interface.trim(),
      'public-key': publicKey.trim(),
      'allowed-address': allowedAddress.trim(),
    };

    if (endpointAddress != null && endpointAddress.trim().isNotEmpty) {
      values['endpoint-address'] = endpointAddress.trim();
    }
    if (endpointPort != null) {
      values['endpoint-port'] = endpointPort.toString();
    }
    if (persistentKeepalive != null) {
      values['persistent-keepalive'] = persistentKeepalive.toString();
    }
    if (comment != null && comment.trim().isNotEmpty) {
      values['comment'] = comment.trim();
    }

    return _add('/interface/wireguard/peers/add', values);
  }

  Future<void> deleteWireGuardPeer(String id) async {
    await _remove('/interface/wireguard/peers/remove', id);
  }

  // ===========================================================================
  // Interfaces (قائمة مبسطة)
  // ===========================================================================

  Future<List<Map<String, String>>> getInterfaces() async {
    return _print(
      '/interface/print',
      properties: const [
        '.id',
        'name',
        'type',
        'mtu',
        'actual-mtu',
        'mac-address',
        'running',
        'disabled',
        'comment',
      ],
    );
  }

  Future<void> updateInterface({
    required String id,
    String? name,
    String? comment,
    bool? disabled,
  }) async {
    final values = <String, String>{};

    if (name != null) values['name'] = name.trim();
    if (comment != null) values['comment'] = comment.trim();
    if (disabled != null) {
      values['disabled'] = disabled ? 'yes' : 'no';
    }

    if (values.isEmpty) return;

    await _set('/interface/set', id, values);
  }

  Future<Map<String, String>?> getInterfaceTraffic(
      String interfaceName,
      ) async {
    try {
      final result = await _print(
        '/interface/monitor-traffic',
        properties: const [
          'name',
          'rx-bits-per-second',
          'tx-bits-per-second',
        ],
        queries: {
          '?interface': interfaceName,
          'once': '',
        },
      );

      if (result.isEmpty) return null;

      return result.first;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, String>>> getInterfaceAddresses(
      String interfaceName,
      ) async {
    return _print(
      '/ip/address/print',
      properties: const [
        '.id',
        'address',
        'network',
        'interface',
      ],
      queries: {
        '?interface': interfaceName,
      },
    );
  }

  // ===========================================================================
  // IP Pools (لـ DHCP Servers)
  // ===========================================================================

  Future<List<Map<String, String>>> getIpPools() async {
    return _print(
      '/ip/pool/print',
      properties: const [
        '.id',
        'name',
        'ranges',
        'comment',
      ],
    );
  }

  // ===========================================================================
  // Backup & Restore
  // ===========================================================================
  /// إنشاء نسخة احتياطية Binary على الراوتر.
  /// تعيد اسم الملف المُنشأ.
  Future<String?> createBinaryBackup({
    required String fileName,
    String? password,
  }) async {
    final values = <String, String>{
      'name': fileName,
    };

    if (password != null && password.isNotEmpty) {
      values['password'] = password;
    }

    await _talk('/system/backup/save', params: values);
    return fileName;
  }

  /// تصدير إعدادات الراوتر كـ Script (.rsc).
  Future<String?> createRscBackup({
    required String fileName,
  }) async {
    await _talk(
      '/export',
      params: {
        'file': fileName,
        'compact': 'no',
      },
    );
    return fileName;
  }

  /// جلب قائمة الملفات على الراوتر.
  Future<List<Map<String, String>>> getFiles() async {
    return _print(
      '/file/print',
      properties: const [
        '.id',
        'name',
        'size',
        'type',
        'creation-time',
      ],
    );
  }

  /// حذف ملف من الراوتر.
  Future<void> deleteFile(String fileName) async {
    // نحتاج ID الملف أولاً
    final files = await getFiles();

    for (final file in files) {
      if (file['name'] == fileName) {
        final id = file['.id'];
        if (id != null && id.isNotEmpty) {
          await _remove('/file/remove', id);
          return;
        }
      }
    }

    throw Exception('الملف غير موجود: $fileName');
  }

  /// استعادة نسخة احتياطية Binary.
  Future<void> restoreBinaryBackup({
    required String fileName,
    String? password,
  }) async {
    final values = <String, String>{
      'name': fileName,
    };

    if (password != null && password.isNotEmpty) {
      values['password'] = password;
    }

    await _talk('/system/backup/load', params: values);
  }

  /// استيراد ملف Script (.rsc).
  Future<void> importRscBackup({
    required String fileName,
  }) async {
    await _talk(
      '/import',
      params: {
        'file-name': fileName,
      },
    );
  }

  /// معلومات الاتصال للـ SSH.
  Map<String, dynamic> getSshInfo({
    required String host,
    required String username,
    required String password,
    int port = 22,
  }) {
    return {
      'host': host,
      'username': username,
      'password': password,
      'port': port,
    };
  }

  // ===========================================================================
  // Router Management
  // ===========================================================================

  /// إعادة تشغيل جهاز MikroTik.
  ///
  /// يتم إرسال أمر RouterOS:
  /// /system/reboot
  ///
  /// بعد إرسال الأمر يتم إغلاق اتصال التطبيق.
  Future<void> restartRouter() async {
    try {
      await _talk('/system/reboot');
    } finally {
      disconnect();
    }
  }

  /// إيقاف تشغيل جهاز MikroTik.
  ///
  /// يتم إرسال أمر RouterOS:
  /// /system/shutdown
  ///
  /// بعد إرسال الأمر يتم إغلاق اتصال التطبيق.
  Future<void> shutdownRouter() async {
    try {
      await _talk('/system/shutdown');
    } finally {
      disconnect();
    }
  }

  // ===========================================================================
  // Connection Information
  // ===========================================================================

  String? get host => _host;

  String? get username => _username;

  int get port => _port;

  bool get useSsl => _useSsl;

  Duration get timeout => _timeout;

  RouterOSClient? get client => _client;

  // ===========================================================================
  // User Manager - Sessions
  // ===========================================================================

  /// جلب Sessions النشطة من User Manager.
  Future<List<Map<String, String>>> getUserManagerSessions() async {
    return _print(
      '/user-manager/session/print',
      properties: const [
        '.id',
        'user',
        'acct-session-id',
        'nas-port-type',
        'nas-port-id',
        'nas-ip-address',
        'nas-identifier',
        'calling-station-id',
        'user-address',
        'status',
        'started',
        'uptime',
        'download',
        'upload',
        'last-accounting-packet',
      ],
    );
  }

  /// قطع جلسة نشطة في User Manager.
  Future<void> disconnectUserManagerSession(String id) async {
    await _remove('/user-manager/session/remove', id);
  }

  // ===========================================================================
  // User Manager - Users
  // ===========================================================================

  /// جلب جميع مستخدمي User Manager.
  Future<List<Map<String, String>>> getUserManagerUsers() async {
    return _print(
      '/user-manager/user/print',
      properties: const [
        '.id',
        'name',
        'password',
        'group',
        'shared-users',
        'attributes',
        'comment',
        'disabled',
      ],
    );
  }

  /// إضافة مستخدم User Manager جديد.
  Future<String?> addUserManagerUser({
    required String name,
    String password = '',
    String group = 'default',
    String? profile,
    int sharedUsers = 1,
    String? attributes,
    String? comment,
    bool disabled = false,
  }) async {
    final values = <String, String>{
      'name': name.trim(),
      'group': group,
      'shared-users': sharedUsers.toString(),
    };

    if (password.isNotEmpty) {
      values['password'] = password;
    }

    if (profile != null && profile.trim().isNotEmpty) {
      values['profile'] = profile.trim();
    }

    if (attributes != null && attributes.isNotEmpty) {
      values['attributes'] = attributes;
    }

    if (comment != null && comment.isNotEmpty) {
      values['comment'] = comment;
    }

    if (disabled) {
      values['disabled'] = 'yes';
    }

    return _add('/user-manager/user/add', values);
  }

  /// حذف مستخدم User Manager.
  Future<void> deleteUserManagerUser(String id) async {
    await _remove('/user-manager/user/remove', id);
  }

  // ===========================================================================
  // User Manager - Profiles
  // ===========================================================================

  /// جلب Profileات User Manager.
  Future<List<Map<String, String>>> getUserManagerProfiles() async {
    return _print(
      '/user-manager/profile/print',
      properties: const [
        '.id',
        'name',
        'validity',
        'name-for-users',
        'starts-when',
        'price',
      ],
    );
  }

  // ===========================================================================
  // User Manager - Limitations
  // ===========================================================================

  /// جلب Limitations User Manager.
  Future<List<Map<String, String>>> getUserManagerLimitations() async {
    return _print(
      '/user-manager/limitation/print',
      properties: const [
        '.id',
        'name',
        'transfer-limit',
        'uptime-limit',
        'rate-limit-rx',
        'rate-limit-tx',
      ],
    );
  }
  /// جلب معلومات User Manager العامة.
  Future<Map<String, String>> getUserManagerInfo() async {
    final result = await _print(
      '/user-manager/print',
      properties: const [
        'enabled',
        'authentication-port',
        'accounting-port',
        'use-profiles',
      ],
    );

    if (result.isEmpty) return {};

    return result.first;
  }

  // ===========================================================================
  // User Manager - Profiles Management
  // ===========================================================================

  /// إضافة Profile جديد.
  Future<String?> addUserManagerProfile({
    required String name,
    required String validity,
    String startsWhen = 'first-auth',
    String? nameForUsers,
  }) async {
    final values = <String, String>{
      'name': name.trim(),
      'validity': validity.trim(),
      'starts-when': startsWhen,
    };

    if (nameForUsers != null && nameForUsers.trim().isNotEmpty) {
      values['name-for-users'] = nameForUsers.trim();
    }

    return _add('/user-manager/profile/add', values);
  }

  /// حذف Profile.
  Future<void> deleteUserManagerProfile(String id) async {
    await _remove('/user-manager/profile/remove', id);
  }

  /// تعديل Profile.
  Future<void> updateUserManagerProfile({
    required String id,
    String? name,
    String? validity,
    String? startsWhen,
    String? nameForUsers,
  }) async {
    final values = <String, String>{};

    if (name != null && name.trim().isNotEmpty) {
      values['name'] = name.trim();
    }
    if (validity != null && validity.trim().isNotEmpty) {
      values['validity'] = validity.trim();
    }
    if (startsWhen != null && startsWhen.trim().isNotEmpty) {
      values['starts-when'] = startsWhen.trim();
    }
    if (nameForUsers != null) {
      values['name-for-users'] = nameForUsers.trim();
    }

    if (values.isEmpty) return;

    await _set('/user-manager/profile/set', id, values);
  }

  // ===========================================================================
  // User Manager - Limitations Management
  // ===========================================================================

  /// إضافة Limitation جديد.
  Future<String?> addUserManagerLimitation({
    required String name,
    String? transferLimit,
    String? uptimeLimit,
    String? rateLimitRx,
    String? rateLimitTx,
  }) async {
    final values = <String, String>{
      'name': name.trim(),
    };

    void add(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        values[key] = value.trim();
      }
    }

    add('transfer-limit', transferLimit);
    add('uptime-limit', uptimeLimit);
    add('rate-limit-rx', rateLimitRx);
    add('rate-limit-tx', rateLimitTx);

    return _add('/user-manager/limitation/add', values);
  }

  /// حذف Limitation.
  Future<void> deleteUserManagerLimitation(String id) async {
    await _remove('/user-manager/limitation/remove', id);
  }

  /// تعديل Limitation.
  Future<void> updateUserManagerLimitation({
    required String id,
    String? name,
    String? transferLimit,
    String? uptimeLimit,
    String? rateLimitRx,
    String? rateLimitTx,
  }) async {
    final values = <String, String>{};

    void add(String key, String? value) {
      if (value != null) {
        values[key] = value.trim();
      }
    }

    add('name', name);
    add('transfer-limit', transferLimit);
    add('uptime-limit', uptimeLimit);
    add('rate-limit-rx', rateLimitRx);
    add('rate-limit-tx', rateLimitTx);

    if (values.isEmpty) return;

    await _set('/user-manager/limitation/set', id, values);
  }

  // ===========================================================================
  // User Manager - User Management (Update)
  // ===========================================================================

  /// تعديل مستخدم User Manager.
  Future<void> updateUserManagerUser({
    required String id,
    String? name,
    String? password,
    String? group,
    int? sharedUsers,
    String? attributes,
    String? comment,
    bool? disabled,
  }) async {
    final values = <String, String>{};

    if (name != null && name.trim().isNotEmpty) {
      values['name'] = name.trim();
    }
    if (password != null) values['password'] = password;
    if (group != null && group.trim().isNotEmpty) {
      values['group'] = group.trim();
    }
    if (sharedUsers != null) {
      values['shared-users'] = sharedUsers.toString();
    }
    if (attributes != null) values['attributes'] = attributes;
    if (comment != null) values['comment'] = comment;
    if (disabled != null) {
      values['disabled'] = disabled ? 'yes' : 'no';
    }

    if (values.isEmpty) return;

    await _set('/user-manager/user/set', id, values);
  }
}