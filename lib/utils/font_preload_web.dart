import 'dart:js_interop';

@JS('document.fonts.ready')
external JSPromise<JSAny?> get _documentFontsReady;

Future<void> waitForDocumentFonts() async {
  await _documentFontsReady.toDart;
}
