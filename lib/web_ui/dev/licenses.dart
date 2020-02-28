// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;

import 'environment.dart';

class LicensesCommand extends Command<bool> {
  @override
  final String name = 'check-licenses';

  @override
  final String description = 'Check license headers.';

  @override
  bool run() {
    _checkLicenseHeaders();
    return true;
  }

  void _checkLicenseHeaders() {
    final List<io.File> allSourceFiles =
        _flatListSourceFiles(environment!.webUiRootDir!);
    _expect(allSourceFiles.isNotEmpty,
        'Dart source listing of ${environment!.webUiRootDir!.path} must not be empty.');

    final List<String> allDartPaths =
        allSourceFiles.map((f) => f.path).toList();

    for (String expectedDirectory in const <String>[
      'lib',
      'test',
      'dev',
      'tool'
    ]) {
      final String expectedAbsoluteDirectory =
          path.join(environment!.webUiRootDir!.path, expectedDirectory);
      _expect(
        allDartPaths
            .where((p) => p.startsWith(expectedAbsoluteDirectory))
            .isNotEmpty,
        'Must include the $expectedDirectory/ directory',
      );
    }

    allSourceFiles.forEach(_expectLicenseHeader);
    print('License headers OK!');
  }

  final _copyRegex =
      RegExp(r'// Copyright 2013 The Flutter Authors\. All rights reserved\.');

  void _expectLicenseHeader(io.File file) {
    List<String> head = file.readAsStringSync().split('\n').take(3).toList();

    _expect(head.length >= 3, 'File too short: ${file.path}');
    _expect(
      _copyRegex.firstMatch(head[0]) != null,
      'Invalid first line of license header in file ${file.path}',
    );
    _expect(
      head[1] ==
          '// Use of this source code is governed by a BSD-style license that can be',
      'Invalid second line of license header in file ${file.path}',
    );
    _expect(
      head[2] == '// found in the LICENSE file.',
      'Invalid second line of license header in file ${file.path}',
    );
  }

  void _expect(bool value, String requirement) {
    if (!value) {
      throw Exception('Test failed: ${requirement}');
    }
  }

  List<io.File> _flatListSourceFiles(io.Directory directory) {
    return directory.listSync(recursive: true).whereType<io.File>().where((f) {
      if (!f.path.endsWith('.dart') && !f.path.endsWith('.js')) {
        // Not a source file we're checking.
        return false;
      }
      if (path.isWithin(environment!.webUiBuildDir.path, f.path) ||
          path.isWithin(environment!.webUiDartToolDir.path, f.path)) {
        // Generated files.
        return false;
      }
      return true;
    }).toList();
  }
}
