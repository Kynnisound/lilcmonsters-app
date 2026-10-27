// Stockage de l'etat de blocage selon la plateforme : shared_preferences sur
// mobile, localStorage lu directement sur le web (BUG-016).
export 'parental_lock_store_io.dart'
    if (dart.library.js_interop) 'parental_lock_store_web.dart';
