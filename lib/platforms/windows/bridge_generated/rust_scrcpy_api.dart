// Compatibility barrel for split FRB outputs.
//
// FRB now generates APIs under ridge_generated/rust_scrcpy_api/{model,runtime,service}.dart.
// Existing app code imports this path, so keep it as a stable facade.

export 'rust_scrcpy_api/model.dart';
export 'rust_scrcpy_api/runtime.dart';
export 'rust_scrcpy_api/service.dart';
