import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'user.dart';
import 'user_info.dart';

void main(List<String> args) async {
  var parser = ArgParser();
  parser.addFlag('help',
      abbr: 'h', negatable: false, help: 'show this message');
  parser.addOption('command', abbr: 'c', help: 'name of the command to use');
  parser.addOption('roomID', abbr: 'r', help: 'room ID');
  parser.addOption('room-name', help: 'room name');
  parser.addOption('message', abbr: 'm', help: 'message body');
  parser.addOption('preset',
      abbr: 'p', help: 'publicity preset for room creation');
  parser.addOption('topic', abbr: 't', help: 'room topic for room creation');
  parser.addOption('alias', abbr: 'a', help: 'room alias for room creation');
  parser.addOption('user', abbr: 'u', help: 'user to invite');
  parser.addOption('reason', help: 'reason for invite/knock');
  var parserResults = parser.parse(args);

  if (parserResults['help']) {
    print(parser.usage);
    exit(0);
  }

  http.Client client = http.Client();
  User user;

  Directory dir = Directory('src');
  String fileName = "user_data.json";
  String filePath = dir.path + "/" + fileName;

  UserInfo? info = await checkForUserInfo(filePath);

  if (info != null) {
    user = User(info);
  } else {
    print('Server: ');
    String server = stdin.readLineSync() as String;
    print('Username: ');
    String username = stdin.readLineSync() as String;
    user =
        User(UserInfo(username: username, server: server, filePath: filePath));
    print("Password: ");
    await user.login(client, stdin.readLineSync());
  }

  switch (parserResults['command']) {
    case 'join':
      {
        await user.joinRoom(client, parserResults['roomID']);
      }
      break;
    case 'create':
      {
        await user.createRoom(client, parserResults['room-name'],
            parserResults['preset'], parserResults['topic'],
            alias: parserResults['alias']);
      }
      break;
    case 'message':
      {
        await user.sendMessage(
            client, parserResults['message'], parserResults['roomID']);
      }
      break;
    case 'list':
      {
        await user.listRooms(client);
      }
      break;
    case 'invite':
      {
        await user.inviteToRoom(client, parserResults['roomID'],
            parserResults['user'], parserResults['reason']);
      }
      break;
    case 'knock':
      {
        await user.knockOnRoom(
            client, parserResults['roomID'], parserResults['reason']);
      }
      break;
    default:
  }
  client.close();
}

Future<UserInfo?> checkForUserInfo(String filePath) async {
  File jsonFile = File(filePath);

  bool fileExists = jsonFile.existsSync();

  if (fileExists) {
    return UserInfo.fromJson(jsonDecode(await jsonFile.readAsString()));
  } else {
    jsonFile.createSync();
    return null;
  }
}

UserInfo getUserInfo(String filePath, String server) {
  String server = stdin.readLineSync() as String;
  print("Enter your username: ");
  String username = stdin.readLineSync() as String;

  return UserInfo(username: username, server: server, filePath: filePath);
}