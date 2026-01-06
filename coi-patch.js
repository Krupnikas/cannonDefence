// Patch for browsers that don't support Cross Origin Isolation
(function() {
  // If already cross-origin isolated, nothing to do
  if (window.crossOriginIsolated) return;

  // Provide SharedArrayBuffer stub for Godot's check
  if (typeof SharedArrayBuffer === 'undefined') {
    window.SharedArrayBuffer = ArrayBuffer;
  }

  // Patch Godot's feature detection to skip COI check when threading is disabled
  // This runs before Godot loads
  Object.defineProperty(window, 'crossOriginIsolated', {
    get: function() { return true; },
    configurable: true
  });
})();
