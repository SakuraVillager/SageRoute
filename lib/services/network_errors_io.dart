import 'dart:io';

bool isPlatformNetworkError(Object error) => error is SocketException;
