export function strip_tags(text) {
  return text.replace(/(<[^>]+>)/g, "");
}

// Uint8Array to hex string
export function uint8ArrayToHexString(byteArray) {
  return Array.from(byteArray, function(byte) {
      return ('0' + (byte & 0xFF).toString(16)).slice(-2);
  }).join('');
}