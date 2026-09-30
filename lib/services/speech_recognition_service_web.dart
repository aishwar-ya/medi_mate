import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

typedef SpeechResultCallback = void Function(String text, bool isFinal);
typedef SpeechStatusCallback = void Function(String status);
typedef SpeechErrorCallback = void Function(String error);

class SpeechRecognitionService {
  dynamic _recognition;
  bool _started = false;
  SpeechResultCallback? _onResult;
  SpeechStatusCallback? _onStatus;
  SpeechErrorCallback? _onError;

  Future<bool> initialize({
    required SpeechStatusCallback onStatus,
    required SpeechErrorCallback onError,
  }) async {
    _onStatus = onStatus;
    _onError = onError;

    final constructor =
        globalContext['SpeechRecognition'] ??
        globalContext['webkitSpeechRecognition'];

    if (constructor == null) {
      onError('Chrome Speech Recognition is not supported in this browser.');
      return false;
    }

    try {
      _recognition =
          (constructor as JSFunction).callAsConstructorVarArgs<JSObject>([]);

      // en-US is deliberately used here because Chrome's Web Speech service
      // can be inconsistent with some regional locale identifiers.
      _recognition['lang'.toJS] = 'en-US'.toJS;
      _recognition['continuous'.toJS] = false.toJS;
      _recognition['interimResults'.toJS] = true.toJS;
      _recognition['maxAlternatives'.toJS] = 1.toJS;

      _recognition['onstart'.toJS] = ((JSAny? _) {
          _started = true;
          _onStatus?.call('listening');
          print('WEB SPEECH: started');
        }).toJS;

      _recognition['onaudiostart'.toJS] = ((JSAny? _) {
          print('WEB SPEECH: audio started');
        }).toJS;

      _recognition['onsoundstart'.toJS] = ((JSAny? _) {
          print('WEB SPEECH: sound detected');
        }).toJS;

      _recognition['onspeechstart'.toJS] = ((JSAny? _) {
          print('WEB SPEECH: speech detected');
        }).toJS;

      _recognition['onresult'.toJS] = ((JSAny? event) {
          try {
            final jsEvent = event as JSObject;
            final results = jsEvent.getProperty<JSObject>('results'.toJS);
            final resultIndex =
                (jsEvent.getProperty<JSAny?>('resultIndex'.toJS)?.dartify() as num?)
                        ?.toInt() ??
                    0;

            final buffer = StringBuffer();
            var finalResult = false;

            final length =
                (results.getProperty<JSAny?>('length'.toJS)?.dartify() as num?)
                        ?.toInt() ??
                    0;

            for (var i = resultIndex; i < length; i++) {
              final result = results.getProperty<JSObject>(i.toString().toJS);
              final alternative = result.getProperty<JSObject>(0.toString().toJS);
              final transcript =
                  alternative.getProperty<JSAny?>('transcript'.toJS)?.dartify()
                          ?.toString() ??
                      '';

              if (transcript.isNotEmpty) {
                buffer.write(transcript);
                buffer.write(' ');
              }

              finalResult =
                  result.getProperty<JSAny?>('isFinal'.toJS)?.dartify() == true ||
                      finalResult;
            }

            final text = buffer.toString().trim();

            if (text.isNotEmpty) {
              print('WEB SPEECH RESULT: $text final=$finalResult');
              _onResult?.call(text, finalResult);
            }
          } catch (e) {
            _onError?.call('Could not read speech result: $e');
          }
        }).toJS;

      _recognition['onerror'.toJS] = ((JSAny? event) {
          _started = false;

          final error =
              (event as JSObject).getProperty<JSAny?>('error'.toJS)?.dartify()?.toString() ??
                  'unknown';

          final message = switch (error) {
            'not-allowed' =>
              'Microphone or speech recognition permission was denied.',
            'audio-capture' =>
              'Chrome cannot access the microphone audio.',
            'no-speech' =>
              'No speech was detected. Please speak clearly.',
            'network' =>
              'Chrome speech recognition could not reach its speech service.',
            'aborted' => 'Speech recognition was stopped.',
            _ => 'Speech recognition error: $error',
          };

          print('WEB SPEECH ERROR: $error');
          _onError?.call(message);
          _onStatus?.call('notListening');
        }).toJS;

      _recognition['onspeechend'.toJS] = ((JSAny? _) {
          print('WEB SPEECH: speech ended');
        }).toJS;

      _recognition['onaudioend'.toJS] = ((JSAny? _) {
          print('WEB SPEECH: audio ended');
        }).toJS;

      _recognition['onend'.toJS] = ((JSAny? _) {
          _started = false;
          print('WEB SPEECH: ended');
          _onStatus?.call('done');
        }).toJS;

      return true;
    } catch (e) {
      onError('Could not initialize Chrome speech recognition: $e');
      return false;
    }
  }

  Future<void> start({
    required SpeechResultCallback onResult,
  }) async {
    if (_recognition == null) {
      _onError?.call('Speech recognition has not been initialized.');
      return;
    }

    _onResult = onResult;

    try {
      if (_started) {
        _recognition.callMethodVarArgs<JSAny?>('abort'.toJS, []);
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }

      _recognition.callMethodVarArgs<JSAny?>('start'.toJS, []);
    } catch (e) {
      _started = false;
      _onError?.call('Unable to start Chrome speech recognition: $e');
    }
  }

  Future<void> stop() async {
    if (_recognition != null && _started) {
      try {
        _recognition.callMethodVarArgs<JSAny?>('stop'.toJS, []);
      } catch (_) {}
    }
  }

  Future<void> cancel() async {
    if (_recognition != null) {
      try {
        _recognition.callMethodVarArgs<JSAny?>('abort'.toJS, []);
      } catch (_) {}
    }
    _started = false;
  }

  Future<void> dispose() async {
    await cancel();
    _recognition = null;
    _onResult = null;
    _onStatus = null;
    _onError = null;
  }
}
