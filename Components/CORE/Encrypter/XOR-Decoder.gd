extends Node
class_name XORDecoder

const XOR_KEY: int = 0x55


static func xor_encode(text: String) -> PackedByteArray:
	var result = PackedByteArray()
	for c in text.to_utf8_buffer():
		result.append(c ^ XOR_KEY)
	return result


static func xor_decode(encoded: PackedByteArray) -> String:
	var decoded = PackedByteArray()
	for b in encoded:
		decoded.append(b ^ XOR_KEY)
	return decoded.get_string_from_utf8()
