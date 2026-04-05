import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import '../models/employee.dart';
import 'database_helper.dart';

class CsvService {
  static Future<void> importCsvToDatabase(String assetPath) async {
    final dbHelper = DatabaseHelper();
    
    try {
      // 데이터 동기화를 위해 기존 데이터를 비우고 새로 임포트 (v1.0)
      await dbHelper.clearAll();
      print('CSV 데이터 임포트($assetPath) 시작...');
      
      final rawData = await rootBundle.loadString(assetPath);
      // v1.0: 숫자 자동 파싱 끔 (010으로 시작하는 번호 유지 등을 위해)
      List<List<dynamic>> listData = const CsvToListConverter(
        shouldParseNumbers: false,
        allowInvalid: true, // 잘못된 포맷 허용 (무시 가능하도록)
      ).convert(rawData);

      // 첫 번째 줄(헤더) 제외
      if (listData.length <= 1) {
        print('경고: CSV에 데이터가 없거나 헤더만 존재합니다.');
        return;
      }
      
      List<Employee> employees = [];
      int errorCount = 0;

      for (int i = 1; i < listData.length; i++) {
        try {
          final row = listData[i];
          if (row.length < 2) continue; // 최소한 부서/성명 정도는 있어야 함
          
          // v1.0: 견고한 파싱 (부서, 성명, 직급, 직책, 이메일, 휴대폰, 사내전화)
          // 탭(\t)이나 따옴표(")가 섞인 데이터를 대비해 한 번 더 trim 및 정리
          String getVal(int idx) => (idx < row.length) ? row[idx].toString().replaceAll('"', '').trim() : '';

          employees.add(Employee(
              department: getVal(0),
              name: getVal(1),
              rank: getVal(2),
              position: getVal(3),
              email: getVal(4),
              phoneNumber: getVal(5),
              officePhone: getVal(6),
          ));
        } catch (e) {
          errorCount++;
          if (errorCount < 10) print('행($i) 파싱 오류: $e');
        }
      }

      if (employees.isNotEmpty) {
        await dbHelper.insertEmployeesBatch(employees);
        print('성공: ${employees.length}명 임포트 완료 (오류 스킵: $errorCount건)');
      } else {
        print('실패: 유효한 데이터를 찾지 못했습니다.');
      }
    } catch (e) {
      print('CSV 임포트 중 치명적 오류: $e');
      rethrow; // main.dart에서 감지할 수 있도록 재호출
    }
  }
}
