import 'dart:convert';
import 'package:socket_io_client_flutter/socket_io_client_flutter.dart' as IO;
import 'Model.dart' show FlutterChatModel, model;
import 'package:flutter/material.dart';

String serverURL = "http://192.168.1.32";

late IO.Socket _io;

// ------------------------------ NONE-MESSAGE RELATED METHODS ------------------------------

void showPleaseWait() {
  print("## Connector.showPleaseWait()");

  showDialog(context: model.rootBuildContext, barrierDismissible: false,
      builder: (BuildContext inDialogContext) {
        return Dialog(
          child: Container(width: 150, height: 150, alignment: AlignmentDirectional.center,
            decoration: BoxDecoration(color: Colors.blue[200]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Center(child: SizedBox(height: 50, width: 50,
                  child: CircularProgressIndicator(value: null, strokeWidth: 10,)
                )),
                Container(margin: const EdgeInsets.only(top: 20),
                  child: const Center(child: Text("Please wait, contacting server...",
                    style: TextStyle(color: Colors.white),
                  ))
                )
              ],
            ),
          )
        );
      }
  );
}

void hidePleaseWait() {
  print("## Connector.hidePleaseWait()");
  Navigator.of(model.rootBuildContext).pop();
}

void connectToServer(final Function inCallback) {
  print("## Connector.connectToServer(): serverURL = $serverURL");

  // Инициализация сокета и обработка событий.
  _io = IO.io(
    serverURL,
    IO.OptionBuilder()
        .setTransports(['websocket']) // Указываем транспорт.
        .disableAutoConnect() // Отключаем автоподключение для более точного контроля.
        .build(),
  );

  // Событие подключения.
  _io.on('connect', (_) {
    print("## Connector.connectToServer(): Connected to server");
    // Подписка на события.
    _io.on("newUser", newUser);
    _io.on("created", created);
    _io.on("closed", closed);
    _io.on("joined", joined);
    _io.on("left", left);
    _io.on("kicked", kicked);
    _io.on("invited", invited);
    _io.on("posted", posted);
    // Вызываем callback после подключения.
    inCallback();
  });

  // Обработка ошибок.
  _io.on('connect_error', (data) {
    print("## Connector.connectToServer(): Connection error: $data");
  });

  _io.on('disconnect', (_) {
    print("## Connector.connectToServer(): Disconnected from server");
  });

  // Подключаемся.
  _io.connect();
}

void validate(final String inUserName, final String inPassword, final Function inCallback) {
  print("## Connector.validate(): inUserName = $inUserName, inPassword = $inPassword");

  // Блокируем экран, пока выполняется запрос к серверу.
  showPleaseWait();

  // Формируем данные для отправки.
  final data = {
    "userName": inUserName,
    "password": inPassword,
  };

  // Отправляем сообщение серверу.
  _io.emitWithAck("validate", data, ack: (dynamic inData) {
    print("## Connector.validate(): callback: inData = $inData");

    // Парсим JSON-ответ в Map.
    final response = Map<String, dynamic>.from(inData);
    print("## Connector.validate(): callback: response = $response");

    // Убираем экран загрузки.
    hidePleaseWait();

    // Вызываем переданный callback и передаем статус.
    inCallback(response["status"]);
  });
}

void listRooms(final Function inCallback) {
  print("## Connector.listRooms()");

  // Блокируем экран, пока выполняется запрос к серверу.
  showPleaseWait();

  // Отправляем запрос на сервер.
  _io.emitWithAck("listRooms", {}, ack: (dynamic inData) {
    print("## Connector.listRooms(): callback: inData = $inData");

    // Парсим JSON-ответ в Map.
    final response = Map<String, dynamic>.from(inData);
    print("## Connector.listRooms(): callback: response = $response");

    // Убираем экран загрузки.
    hidePleaseWait();

    // Вызываем переданный callback и передаем полученный ответ.
    inCallback(response);
  });
}

void create(
    final String inRoomName,
    final String inDescription,
    final int inMaxPeople,
    final bool inPrivate,
    final String inCreator,
    final Function inCallback
    ) {
  print("## Connector.create(): inRoomName = $inRoomName, inDescription = $inDescription, "
      "inMaxPeople = $inMaxPeople, inPrivate = $inPrivate, inCreator = $inCreator"
  );

  // Блокируем экран, пока выполняется запрос к серверу.
  showPleaseWait();

  // Формируем данные для отправки.
  final data = {
    "roomName": inRoomName,
    "description": inDescription,
    "maxPeople": inMaxPeople,
    "private": inPrivate,
    "creator": inCreator,
  };

  // Отправляем запрос на сервер для создания комнаты.
  _io.emitWithAck("create", data, ack: (dynamic inData) {
    print("## Connector.create(): callback: inData = $inData");

    // Парсим ответ от сервера в Map.
    final response = Map<String, dynamic>.from(inData);
    print("## Connector.create(): callback: response = $response");

    // Убираем экран загрузки.
    hidePleaseWait();

    // Вызываем переданный callback с ответом.
    inCallback(response["status"], response["rooms"]);
  });
}

void join(final String inUserName, final String inRoomName, final Function inCallback) {
  print("## Connector.join(): inUserName = $inUserName, inRoomName = $inRoomName");

  // Блокируем экран, пока выполняется запрос к серверу.
  showPleaseWait();

  // Формируем данные для отправки.
  final data = {
    "userName": inUserName,
    "roomName": inRoomName,
  };

  // Отправляем запрос на сервер для присоединения к комнате.
  _io.emitWithAck("join", data, ack: (dynamic inData) {
    print("## Connector.join(): callback: inData = $inData");

    // Парсим ответ от сервера в Map.
    final response = Map<String, dynamic>.from(inData);
    print("## Connector.join(): callback: response = $response");

    // Убираем экран загрузки.
    hidePleaseWait();

    // Вызываем переданный callback с ответом.
    inCallback(response["status"], response["room"]);
  });
}

void leave(final String inUserName, final String inRoomName, final Function inCallback) {
  print("## Connector.leave(): inUserName = $inUserName, inRoomName = $inRoomName");

  // Блокируем экран, пока выполняется запрос к серверу.
  showPleaseWait();

  // Формируем данные для отправки.
  final data = {
    "userName": inUserName,
    "roomName": inRoomName,
  };

  // Отправляем запрос на сервер для выхода из комнаты.
  _io.emitWithAck("leave", data, ack: (dynamic inData) {
    print("## Connector.leave(): callback: inData = $inData");

    // Парсим ответ от сервера в Map.
    final response = Map<String, dynamic>.from(inData);
    print("## Connector.leave(): callback: response = $response");

    // Убираем экран загрузки.
    hidePleaseWait();

    // Вызываем переданный callback после завершения.
    inCallback();
  });
}

void listUsers(final Function inCallback) {
  print("## Connector.listUsers()");

  // Блокируем экран, пока выполняется запрос к серверу.
  showPleaseWait();

  // Отправляем запрос на сервер для получения списка пользователей.
  _io.emitWithAck("listUsers", {}, ack: (dynamic inData) {
    print("## Connector.listUsers(): callback: inData = $inData");

    // Парсим ответ от сервера в Map.
    final response = Map<String, dynamic>.from(inData);
    print("## Connector.listUsers(): callback: response = $response");

    // Убираем экран загрузки.
    hidePleaseWait();

    // Вызываем переданный callback с полученным ответом.
    inCallback(response);
  });
}

void invite(
    final String inUserName,
    final String inRoomName,
    final String inInviterName,
    final Function inCallback
    ) {
  print("## Connector.invite(): inUserName = $inUserName, inRoomName = $inRoomName, inInviterName = $inInviterName");

  // Блокируем экран, пока выполняется запрос к серверу.
  showPleaseWait();

  // Формируем данные для отправки.
  final data = {
    "userName": inUserName,
    "roomName": inRoomName,
    "inviterName": inInviterName,
  };

  // Отправляем запрос на сервер для приглашения пользователя.
  _io.emitWithAck("invite", data, ack: (dynamic inData) {
    print("## Connector.invite(): callback: inData = $inData");

    // Убираем экран загрузки.
    hidePleaseWait();

    // Вызываем переданный callback после завершения.
    inCallback();
  });
}

void post(
    final String inUserName,
    final String inRoomName,
    final String inMessage,
    final Function inCallback
    ) {
  print("## Connector.post(): inUserName = $inUserName, inRoomName = $inRoomName, inMessage = $inMessage");

  // Блокируем экран, пока выполняется запрос к серверу.
  showPleaseWait();

  // Формируем данные для отправки.
  final data = {
    "userName": inUserName,
    "roomName": inRoomName,
    "message": inMessage,
  };

  // Отправляем запрос на сервер для публикации сообщения.
  _io.emitWithAck("post", data, ack: (dynamic inData) {
    print("## Connector.post(): callback: inData = $inData");

    // Парсим ответ от сервера в Map.
    final response = Map<String, dynamic>.from(inData);

    // Убираем экран загрузки.
    hidePleaseWait();

    // Вызываем переданный callback с полученным статусом.
    inCallback(response["status"]);
  });
}

void close(
    final String inRoomName,
    final Function inCallback
    ) {
  print("## Connector.close(): inRoomName = $inRoomName");

  // Блокируем экран, пока выполняется запрос к серверу.
  showPleaseWait();

  // Формируем данные для отправки.
  final data = {
    "roomName": inRoomName,
  };

  // Отправляем запрос на сервер для закрытия комнаты.
  _io.emitWithAck("close", data, ack: (dynamic inData) {
    print("## Connector.close(): callback: inData = $inData");

    // Убираем экран загрузки.
    hidePleaseWait();

    // Вызываем переданный callback после завершения.
    inCallback();
  });
}

void kick(
    final String inUserName,
    final String inRoomName,
    final Function inCallback
    ) {
  print("## Connector.kick(): inUserName = $inUserName, inRoomName = $inRoomName");

  // Блокируем экран, пока выполняется запрос к серверу.
  showPleaseWait();

  // Формируем данные для отправки.
  final data = {
    "userName": inUserName,
    "roomName": inRoomName,
  };

  // Отправляем запрос на сервер для кика пользователя.
  _io.emitWithAck("kick", data, ack: (dynamic inData) {
    print("## Connector.kick(): callback: inData = $inData");

    // Убираем экран загрузки.
    hidePleaseWait();

    // Вызываем переданный callback после завершения.
    inCallback();
  });
}

void newUser(inData) {
  print("## Connector.newUser(): inData = $inData");

  // Парсим входные данные в формате JSON в Map.
  Map<String, dynamic> payload = Map<String, dynamic>.from(inData);
  print("## Connector.newUser(): payload = $payload");

  // Обновляем список пользователей через модель.
  model.setUserList(payload);
}

void created(inData) {
  print("## Connector.created(): inData = $inData");

  // Парсим входные данные в формате JSON в Map.
  Map<String, dynamic> payload = Map<String, dynamic>.from(inData);
  print("## Connector.created(): payload = $payload");

  // Обновляем список комнат через модель.
  model.setRoomList(payload);
}

void closed(inData) {
  print("## Connector.closed(): inData = $inData");

  // Парсим входные данные в формате JSON в Map.
  Map<String, dynamic> payload = Map<String, dynamic>.from(inData);
  print("## Connector.closed(): payload = $payload");

  // Обновляем список комнат через модель.
  model.setRoomList(payload);

  // Если этот пользователь находится в комнате, выводим сообщение и выгружаем его.
  if (payload["roomName"] == model.currentRoomName) {
    // Очищаем атрибуты модели, отражающие пользователя в этой комнате.
    model.removeRoomInvite(payload["roomName"]);
    model.setCurrentRoomUserList({});
    model.setCurrentRoomName(FlutterChatModel.DEFAULT_ROOM_NAME);
    model.setCurrentRoomEnabled(false);

    // Информируем пользователя, что комната была закрыта.
    model.setGreeting("The room you were in was closed by its creator.");

    // Перенаправляем обратно на главный экран.
    Navigator.of(model.rootBuildContext).pushNamedAndRemoveUntil("/", ModalRoute.withName("/"));
  }
}

void joined(inData) {
  print("## Connector.joined(): inData = $inData");

  // Парсим входные данные в формате JSON в Map.
  Map<String, dynamic> payload = Map<String, dynamic>.from(inData);
  print("## Connector.joined(): payload = $payload");

  // Обновляем список пользователей в комнате, если этот пользователь находится в комнате.
  if (model.currentRoomName == payload["roomName"]) {
    model.setCurrentRoomUserList(payload["users"]);
  }
}

void left(inData) {
  print("## Connector.left(): inData = $inData");

  // Парсим входные данные в формате JSON в Map.
  Map<String, dynamic> payload = Map<String, dynamic>.from(inData);
  print("## Connector.left(): payload = $payload");

  // Обновляем список пользователей в комнате, если этот пользователь находится в комнате.
  if (model.currentRoomName == payload["room"]["roomName"]) {
    model.setCurrentRoomUserList(payload["room"]["users"]);
  }
}

void kicked(inData) {
  print("## Connector.kicked(): inData = $inData");

  // Парсим входные данные в формате JSON в Map.
  Map<String, dynamic> payload = Map<String, dynamic>.from(inData);
  print("## Connector.kicked(): payload = $payload");

  // Очищаем атрибуты модели, отражающие пользователя в этой комнате.
  model.removeRoomInvite(payload["roomName"]);
  model.setCurrentRoomUserList({});
  model.setCurrentRoomName(FlutterChatModel.DEFAULT_ROOM_NAME);
  model.setCurrentRoomEnabled(false);

  // Информируем пользователя, что он был исключен.
  model.setGreeting("What did you do?! You got kicked from the room! D'oh!");

  // Перенаправляем обратно на главный экран.
  Navigator.of(model.rootBuildContext).pushNamedAndRemoveUntil("/", ModalRoute.withName("/"));
}

void invited(inData) async {
  print("## Connector.invited(): inData = $inData");

  // Парсим входные данные в формате JSON в Map.
  Map<String, dynamic> payload = Map<String, dynamic>.from(inData);
  print("## Connector.invited(): payload = $payload");

  // Извлекаем необходимые данные из payload.
  String roomName = payload["roomName"];
  String inviterName = payload["inviterName"];

  // Добавляем приглашение в модель.
  model.addRoomInvite(roomName);

  // Показать snackbar, чтобы уведомить пользователя об приглашении.
  ScaffoldMessenger.of(model.rootBuildContext).showSnackBar(
      SnackBar(
          backgroundColor: Colors.amber,
          duration: Duration(seconds: 60),
          content: Text(
              "You've been invited to the room '$roomName' by user '$inviterName'.\n\n"
                  "You can enter the room from the lobby."
          ),
          action: SnackBarAction(
              label: "Ok",
              onPressed: () { }
          )
      )
  );
}

void posted(inData) {
  print("## Connector.posted(): inData = $inData");

  // Парсим входные данные в формате JSON в Map.
  Map<String, dynamic> payload = Map<String, dynamic>.from(inData);
  print("## Connector.posted(): payload = $payload");

  // Если пользователь находится в комнате, добавляем сообщение в список сообщений комнаты.
  if (model.currentRoomName == payload["roomName"]) {
    model.addMessage(payload["userName"], payload["message"]);
  }
}


