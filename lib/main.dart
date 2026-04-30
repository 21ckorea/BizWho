import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/csv_service.dart';
import 'services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  const platform = MethodChannel('com.bizwho.callerid/role_manager');
  final dbPath = await DatabaseHelper().getDbPath();
  try {
    await platform.invokeMethod('setDatabasePath', {'path': dbPath});
  } catch (e) {
    debugPrint("DB Path Bridge Failure: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '비즈후',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF0D47A1),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
      ),
      home: const EmployeeSearchPage(title: '직원 연락처 검색'),
    );
  }
}

class EmployeeSearchPage extends StatefulWidget {
  final String title;
  const EmployeeSearchPage({super.key, required this.title});

  @override
  State<EmployeeSearchPage> createState() => _EmployeeSearchPageState();
}

class _EmployeeSearchPageState extends State<EmployeeSearchPage> {
  static const platform = MethodChannel('com.bizwho.callerid/role_manager');
  
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  final TextEditingController _searchController = TextEditingController();

  String _position = 'middle';
  double _fontSize = 25.0; // v1.1.3: 글자 크기 변수화
  double _listFontSize = 14.0; // v1.1.3: 리스트 전용 글자 크기 추가
  double _showDuration = 30.0; // v1.1.3: 유지 시간 변수화(기본 30초)

  // v1.8.0: 오버레이 테마 색상 추가
  String _bgColor = 'E60D47A1'; // Default Signature Blue
  String _textColor = 'FFFFFF'; // Default White

  final List<Map<String, String>> _themes = [
    {'name': '시그니처 블루', 'bg': 'E60D47A1', 'text': 'FFFFFF'},
    {'name': '차콜 블랙', 'bg': 'E6212121', 'text': 'FFFFFF'},
    {'name': '포레스트 그린', 'bg': 'E61B5E20', 'text': 'FFFFFF'},
    {'name': '보르도 레드', 'bg': 'E6880E4F', 'text': 'FFFFFF'},
    {'name': '모던 화이트', 'bg': 'F2FFFFFF', 'text': '0D47A1'},
  ];

  @override
  void initState() {
    super.initState();
    _initData();
    _loadSettings();
    _checkOverlayPermissionOnStart();
  }

  Future<void> _checkOverlayPermissionOnStart() async {
    // 일반 권한(전화, 알림 등) 요청 팝업과 겹치지 않도록 3초 대기 후 실행
    await Future.delayed(const Duration(seconds: 3));
    try {
      final bool hasOverlay = await platform.invokeMethod('checkOverlayPermission');
      if (!hasOverlay) {
        await platform.invokeMethod('requestOverlayPermission');
      }
    } catch (e) {
      debugPrint("Overlay Permission Check Error: $e");
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _position = prefs.getString('pref_pos_v4') ?? 'middle';
      _fontSize = (prefs.getInt('pref_size_v4') ?? 25).toDouble();
      _listFontSize = (prefs.getDouble('pref_list_size_v4') ?? 14.0);
      _showDuration = (prefs.getDouble('pref_duration_v4') ?? 30.0);
      _bgColor = prefs.getString('pref_bg_v1') ?? 'E60D47A1';
      _textColor = prefs.getString('pref_text_v1') ?? 'FFFFFF';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_pos_v4', _position);
    await prefs.setInt('pref_size_v4', _fontSize.toInt());
    await prefs.setDouble('pref_list_size_v4', _listFontSize);
    await prefs.setDouble('pref_duration_v4', _showDuration);
    await prefs.setString('pref_bg_v1', _bgColor);
    await prefs.setString('pref_text_v1', _textColor);
  }

  Future<void> _initData() async {
    try {
      await CsvService.importCsvToDatabase('assets/employee_contacts.csv');
      final db = DatabaseHelper();
      final employees = await db.getAllEmployees();
      setState(() {
        _employees = employees;
        _filteredEmployees = employees;
      });

      // v1.9.0: iOS CallKit App Group 연락처 동기화
      // 안드로이드 빌드에는 전혀 영향을 주지 않습니다 (플랫폼 체크 포함)
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _syncContactsToiOSCallKit(employees);
      }
    } catch (e) {
      debugPrint("Data Init Error: $e");
    }
  }

  /// iOS CallKit (CallDirectoryExtension) 연동을 위해
  /// App Group UserDefaults에 연락처 목록을 저장합니다.
  Future<void> _syncContactsToiOSCallKit(List<Map<String, dynamic>> employees) async {
    try {
      // 전화번호를 CallKit 규격 (국제번호 82로 시작, 하이픈 없음)으로 변환하여 맵에 저장
      final Map<String, String> callKitContacts = {};

      for (final emp in employees) {
        final name = (emp['name'] ?? '').toString();
        final rank = (emp['rank'] ?? '').toString();
        final dept = (emp['department'] ?? '').toString();
        final label = dept.isNotEmpty ? '$name $rank($dept)' : '$name $rank';

        // 휴대폰 번호 변환
        final rawPhone = (emp['phone_number'] ?? '').toString();
        final e164Phone = _toE164Korean(rawPhone);
        if (e164Phone != null) {
          callKitContacts[e164Phone] = label;
        }

        // 사무실 번호 변환
        final rawOffice = (emp['office_phone'] ?? '').toString();
        final e164Office = _toE164Korean(rawOffice);
        if (e164Office != null && e164Office != e164Phone) {
          callKitContacts[e164Office] = label;
        }
      }

      // MethodChannel을 통해 iOS 네이티브에서 App Group UserDefaults에 저장
      await platform.invokeMethod('syncCallKitContacts', {'contacts': callKitContacts});
      debugPrint("[iOS] CallKit 연락처 동기화 완료: ${callKitContacts.length}건");
    } catch (e) {
      debugPrint("[iOS] CallKit 동기화 실패: $e");
    }
  }

  /// 한국 전화번호를 E.164 국제번호 문자열로 변환 (예: 010-1234-5678 -> 821012345678)
  String? _toE164Korean(String raw) {
    if (raw.isEmpty) return null;
    String digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('82')) return digits; // 이미 국제번호
    if (digits.startsWith('0')) digits = '82${digits.substring(1)}'; // 010... -> 8210...
    if (digits.length < 10) return null; // 너무 짧은 번호 무시
    return digits;
  }


  void _filterEmployees(String query) {
    setState(() {
      final queryLower = query.toLowerCase();
      _filteredEmployees = _employees.where((emp) {
        final name = (emp['name'] ?? '').toString().toLowerCase();
        final dept = (emp['department'] ?? '').toString().toLowerCase();
        final phone = (emp['phone_number'] ?? '').toString().replaceAll('-', '');
        final office = (emp['office_phone'] ?? '').toString().replaceAll('-', '');
        
        return name.contains(queryLower) || 
               dept.contains(queryLower) || 
               phone.contains(queryLower) || 
               office.contains(queryLower);
      }).toList();
    });
  }

  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll('-', '').replaceAll(' ', '');
    if (cleaned.isEmpty) return '';
    
    // v1.1.2: 1040520941 -> 010-4052-0941 (0 추가 로직)
    if (cleaned.length == 10 && cleaned.startsWith('10')) {
      cleaned = '0$cleaned';
    }

    if (cleaned.length == 11) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 7)}-${cleaned.substring(7)}';
    } else if (cleaned.length == 10) {
      if (cleaned.startsWith('02')) {
        return '${cleaned.substring(0, 2)}-${cleaned.substring(2, 6)}-${cleaned.substring(6)}';
      }
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '이름 또는 부서 검색',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0D47A1)),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterEmployees,
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _filteredEmployees.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final emp = _filteredEmployees[index];
                final mobile = (emp['phone_number'] ?? '').toString();
                final office = (emp['office_phone'] ?? '').toString();
                final rank = (emp['rank'] ?? '').toString().trim();
                final pos = (emp['position'] ?? '').toString().trim();
                
                // v1.1.2: 성명(직급/직책) 공백 제거 및 한 줄 표시
                String jobInfo = '';
                if (rank.isNotEmpty && pos.isNotEmpty && rank != pos) {
                  jobInfo = '($rank/$pos)';
                } else {
                  String simple = rank.isNotEmpty ? rank : pos;
                  jobInfo = simple.isNotEmpty ? '($simple)' : '';
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.person, color: Color(0xFF1976D2)),
                  ),
                  title: Text(
                    '${emp['name']}$jobInfo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: _listFontSize),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${emp['department']}', 
                    style: TextStyle(color: Colors.blueGrey, fontSize: _listFontSize * 0.85)
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatPhoneNumber(mobile), 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: _listFontSize * 0.9, // v1.1.4: 리스트 크기와 연동
                          color: const Color(0xFF0D47A1)
                        ),
                      ),
                      // v1.1.2: 내선 번호 조건부 표시 (비어있거나 휴대폰과 같으면 생략)
                      if (office.isNotEmpty && _formatPhoneNumber(office) != _formatPhoneNumber(mobile))
                        Text(
                          _formatPhoneNumber(office), // "Office: " 접두어 삭제
                          style: TextStyle(
                            fontSize: _listFontSize * 0.75, // v1.1.4: 리스트 크기와 연동
                            color: Colors.blueGrey
                          ),
                        ),
                    ],
                  ),
                  onTap: () => _showContactOptions(emp),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'clear',
            onPressed: () {
              if (defaultTargetPlatform == TargetPlatform.iOS) return;
              platform.invokeMethod('clearOverlay');
            },
            label: const Text('알림 지우기'),
            icon: const Icon(Icons.delete_sweep),
            backgroundColor: Colors.pink.shade50,
            foregroundColor: Colors.pink.shade700,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'test',
            onPressed: () async {
              if (defaultTargetPlatform == TargetPlatform.iOS) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('iOS에서는 기본 전화 화면에 발신자 이름이 바로 표시됩니다. 별도의 오버레이를 지원하지 않습니다.')),
                );
                return;
              }
              await platform.invokeMethod('testOverlay', {
                'info': '홍미나(상무/팀장)\n전략기획지원팀',
                'position': _position,
                'fontSize': _fontSize.toInt(),
                'duration': _showDuration.toInt(),
                'bgColor': _bgColor,
                'textColor': _textColor
              });
            },
            label: const Text('오버레이 테스트'),
            icon: const Icon(Icons.play_arrow),
            backgroundColor: const Color(0xFFE3F2FD),
            foregroundColor: const Color(0xFF0D47A1),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 그룹 1: 발신자 정보 설정 (오버레이) ---
                  const Row(
                    children: [
                      Icon(Icons.call_to_action_rounded, color: Color(0xFF0D47A1), size: 20),
                      SizedBox(width: 8),
                      Text('발신자 정보 설정 (오버레이)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  const Text('정보창 위치', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ToggleButtons(
                    isSelected: [
                      _position == 'top', 
                      _position == 'semi_top',
                      _position == 'middle', 
                      _position == 'semi_bottom',
                      _position == 'bottom'
                    ],
                    onPressed: (index) {
                      setModalState(() {
                        if (index == 0) _position = 'top';
                        else if (index == 1) _position = 'semi_top';
                        else if (index == 2) _position = 'middle';
                        else if (index == 3) _position = 'semi_bottom';
                        else if (index == 4) _position = 'bottom';
                      });
                      setState(() {});
                      _saveSettings();
                    },
                    borderRadius: BorderRadius.circular(12),
                    selectedColor: Colors.white,
                    fillColor: const Color(0xFF0D47A1),
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('최상')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('상')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('중')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('하')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('최하')),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('정보창 글자 크기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      Text('${_fontSize.toInt()}sp', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                    ],
                  ),
                  Slider(
                    value: _fontSize,
                    min: 14,
                    max: 40,
                    divisions: 26,
                    activeColor: const Color(0xFF0D47A1),
                    onChanged: (val) {
                      setModalState(() => _fontSize = val);
                      setState(() {});
                      _saveSettings();
                    },
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('정보창 유지 시간', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      Text('${_showDuration.toInt()}초', style: const TextStyle(fontSize: 16, color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _showDuration,
                    min: 5.0,
                    max: 60.0,
                    divisions: 55,
                    label: '${_showDuration.toInt()}초',
                    activeColor: const Color(0xFF0D47A1),
                    onChanged: (value) {
                      setModalState(() {
                        _showDuration = value;
                      });
                      setState(() {});
                      _saveSettings();
                    },
                  ),
                  const Text('설정된 시간이 지나면 자동으로 정보창이 닫힙니다.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 24),

                  const Text('정보창 컬러 테마', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _themes.length,
                      itemBuilder: (context, index) {
                        final theme = _themes[index];
                        final bool isSelected = _bgColor == theme['bg'];
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _bgColor = theme['bg']!;
                              _textColor = theme['text']!;
                            });
                            setState(() {});
                            _saveSettings();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 50,
                            decoration: BoxDecoration(
                              color: Color(int.parse(theme['bg']!, radix: 16)),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isSelected ? Colors.orange : Colors.grey.shade300,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: isSelected ? [BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 4)] : null,
                            ),
                            child: Center(
                              child: Text(
                                'A', 
                                style: TextStyle(
                                  color: Color(int.parse(theme['text']!, radix: 16)),
                                  fontWeight: FontWeight.bold
                                )
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 32),

                  // --- 그룹 2: 앱 리스트 설정 ---
                  const Row(
                    children: [
                      Icon(Icons.list_alt_rounded, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('앱 서비스 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('직원 리스트 글자 크기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      Text('${_listFontSize.toInt()}sp', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  Slider(
                    value: _listFontSize,
                    min: 12,
                    max: 30,
                    divisions: 18,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      setModalState(() => _listFontSize = val);
                      setState(() {});
                      _saveSettings();
                    },
                  ),

                  const SizedBox(height: 32),
                  const Text('설정은 실시간으로 저장되며 다음 전화부터 적용됩니다.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (defaultTargetPlatform == TargetPlatform.iOS) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('iOS에서는 기본 전화 화면에 발신자 이름이 바로 표시됩니다. 별도의 오버레이를 지원하지 않습니다.')),
                              );
                              return;
                            }
                            await platform.invokeMethod('testOverlay', {
                              'info': '홍미나(상무/팀장)\n전략기획지원팀',
                              'position': _position,
                              'fontSize': _fontSize.toInt(),
                              'duration': _showDuration.toInt(),
                              'bgColor': _bgColor,
                              'textColor': _textColor
                            });
                          },
                          icon: const Icon(Icons.remove_red_eye, size: 20),
                          label: const Text('오버레이 확인', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE3F2FD),
                            foregroundColor: const Color(0xFF0D47A1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (defaultTargetPlatform == TargetPlatform.iOS) return;
                            platform.invokeMethod('clearOverlay');
                          },
                          icon: const Icon(Icons.delete_sweep, size: 20),
                          label: const Text('알림 지우기', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade50,
                            foregroundColor: Colors.pink.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showContactOptions(Map<String, dynamic> emp) {
    // 직급/직책 정보 조합
    final rank = emp['rank']?.toString() ?? '';
    final position = emp['position']?.toString() ?? '';
    final jobInfo = [rank, position].where((s) => s.isNotEmpty).toSet().join('/');
    final nameDisplay = jobInfo.isNotEmpty ? "${emp['name']}($jobInfo)" : emp['name'];
    final dept = emp['department']?.toString() ?? '';
    final email = emp['email']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 프로필 헤더
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nameDisplay,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                    ),
                    const SizedBox(height: 4),
                    if (dept.isNotEmpty)
                      Text(dept, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(email, style: const TextStyle(fontSize: 14, color: Colors.blueGrey)),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.phone, color: Color(0xFF0D47A1)),
                title: const Text('전화 걸기 (휴대폰)'),
                subtitle: Text(_formatPhoneNumber(emp['phone_number'] ?? '')),
                onTap: () {
                  Navigator.pop(context);
                  launchUrl(Uri.parse('tel:${emp['phone_number']}'));
                },
              ),
              if (emp['office_phone'] != null && 
                  emp['office_phone'].toString().trim().isNotEmpty && 
                  _formatPhoneNumber(emp['office_phone']) != _formatPhoneNumber(emp['phone_number']))
                ListTile(
                  leading: const Icon(Icons.business_center, color: Colors.green),
                  title: const Text('전화 걸기 (사내전화)'),
                  subtitle: Text(_formatPhoneNumber(emp['office_phone'] ?? '')),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(Uri.parse('tel:${emp['office_phone']}'));
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
