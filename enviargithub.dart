import 'dart:io';

void main() async {
  print('==============================================');
  print('   AGENTE DE ENVÍO A GITHUB (INTERACTIVO)   ');
  print('==============================================\n');

  // 1. Obtener el link del repositorio
  stdout.write('1. Ingrese el link del nuevo repositorio (GitHub URL): ');
  String? repoUrl = stdin.readLineSync()?.trim();
  if (repoUrl == null || repoUrl.isEmpty) {
    print('Error: El link del repositorio es obligatorio.');
    return;
  }

  // 2. Obtener el mensaje del commit
  stdout.write('2. Ingrese el mensaje del commit: ');
  String? commitMessage = stdin.readLineSync()?.trim();
  if (commitMessage == null || commitMessage.isEmpty) {
    print('Error: El mensaje del commit es obligatorio.');
    return;
  }

  // 3. Obtener el nombre de la rama (default: main)
  stdout.write('3. Ingrese el nombre de la rama [Presione Enter para "main"]: ');
  String? branchName = stdin.readLineSync()?.trim();
  if (branchName == null || branchName.isEmpty) {
    branchName = 'main';
  }

  print('\n--- Iniciando proceso de envío ---\n');

  try {
    // Verificar si git está instalado
    try {
      await Process.run('git', ['--version']);
    } catch (e) {
      print('Error: Git no está instalado o no se encuentra en el PATH.');
      return;
    }

    // Inicializar Git si no lo está
    await runGit(['init'], 'Inicializando repositorio local...');

    // Agregar todos los archivos
    await runGit(['add', '.'], 'Agregando archivos al área de preparación...');

    // Crear el commit
    await runGit(['commit', '-m', commitMessage], 'Creando commit...');

    // Renombrar la rama a la deseada
    await runGit(['branch', '-M', branchName], 'Estableciendo rama: $branchName...');

    // Configurar el remoto
    // Intentamos agregar el origin, si ya existe lo actualizamos
    var checkRemote = await Process.run('git', ['remote', 'add', 'origin', repoUrl]);
    if (checkRemote.exitCode != 0) {
      await runGit(['remote', 'set-url', 'origin', repoUrl], 'Actualizando URL del remoto origin...');
    } else {
      print('[OK] Remoto origin agregado.');
    }

    // Subir a GitHub
    print('Subiendo a GitHub (es posible que se abra una ventana de autenticación o se soliciten credenciales)...');
    
    // Usamos Process.start con inheritStdio para permitir interacción (como pedir usuario/password si es necesario)
    var process = await Process.start('git', ['push', '-u', 'origin', branchName], mode: ProcessStartMode.inheritStdio);
    int exitCode = await process.exitCode;

    if (exitCode == 0) {
      print('\n==============================================');
      print('   ¡ÉXITO! Repositorio enviado correctamente.  ');
      print('==============================================');
    } else {
      print('\n[ERROR] Hubo un problema al subir los cambios a GitHub. Código de salida: $exitCode');
    }

  } catch (e) {
    print('\n[ERROR CRÍTICO]: $e');
  }
}

Future<void> runGit(List<String> args, String message) async {
  stdout.write('$message ');
  var result = await Process.run('git', args);
  if (result.exitCode != 0) {
    // Si el error es porque no hay nada que committear, no lanzamos excepción
    if (args.contains('commit') && (result.stdout.toString().contains('nothing to commit') || result.stderr.toString().contains('nothing to commit'))) {
      print('\n[INFO] Nada nuevo para hacer commit.');
      return;
    }
    print('\n[ERROR] El comando git ${args.join(' ')} falló.');
    print('Detalles: ${result.stderr}${result.stdout}');
    throw Exception('Fallo en comando git.');
  }
  print('[OK]');
}
