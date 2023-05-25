from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.memset import memset
from pow2 import pow2

from sha256_packed import compute_message_schedule, sha2_compress, get_round_constants

const HASH_FELT_SIZE = 8;
const SHA256_INPUT_CHUNK_SIZE_FELTS = 16;
const SHA256_INPUT_CHUNK_SIZE_BYTES = 64;
// A 256-bit hash is represented as an array of 8 x Uint32
const SHA256_STATE_SIZE_FELTS = HASH_FELT_SIZE;
// Each instance consists of 16 words of message, 8 words for the input state and 8 words
// for the output state.
const SHA256_INSTANCE_SIZE = SHA256_INPUT_CHUNK_SIZE_FELTS + 2 * SHA256_STATE_SIZE_FELTS;

// Computes SHA256 of 'input'. Inputs of arbitrary length are supported.
// To use this function, split the input into (up to) 14 words of 32 bits (big endian).
// For example, to compute sha256('Hello world'), use:
//   input = [1214606444, 1864398703, 1919706112]
// where:
//   1214606444 == int.from_bytes(b'Hell', 'big')
//   1864398703 == int.from_bytes(b'o wo', 'big')
//   1919706112 == int.from_bytes(b'rld\x00', 'big')  # Note the '\x00' padding.
//
// block layout:
// 0 - 15: Message
// 16 - 23: Input State
// 24 - 32: Output
//
// output is an array of 8 32-bit words (big endian).
//
// Note: the interface of this function may change in the future.
func compute_sha256{bitwise_ptr: BitwiseBuiltin*, range_check_ptr, sha256_ptr: felt*}(
    data: felt*, n_bytes: felt
) -> felt* {
    alloc_locals;

    // Set the initial input state to IV.
    assert sha256_ptr[16] = 0x6A09E667;
    assert sha256_ptr[17] = 0xBB67AE85;
    assert sha256_ptr[18] = 0x3C6EF372;
    assert sha256_ptr[19] = 0xA54FF53A;
    assert sha256_ptr[20] = 0x510E527F;
    assert sha256_ptr[21] = 0x9B05688C;
    assert sha256_ptr[22] = 0x1F83D9AB;
    assert sha256_ptr[23] = 0x5BE0CD19;

    sha256_inner(data=data, n_bytes=n_bytes, total_bytes=n_bytes);

    // Set `output` to the start of the final state.
    let output = sha256_ptr;
    // Set `sha256_ptr` to the end of the output state.
    let sha256_ptr = sha256_ptr + SHA256_STATE_SIZE_FELTS;
    return output;
}

// Computes the sha256 hash of the input chunk from `message` to `message + SHA256_INPUT_CHUNK_SIZE_FELTS`
func _sha256_chunk{bitwise_ptr: BitwiseBuiltin*, state: felt*, output: felt*}(message: felt*) {
    alloc_locals;
    let (expanded_message) = alloc();
    let expanded_message_start = expanded_message;
    memcpy(expanded_message, message, SHA256_INPUT_CHUNK_SIZE_FELTS);
    compute_message_schedule(expanded_message_start);
    let round_constants = get_round_constants();
    sha2_compress(state, expanded_message_start, round_constants, output);
    return ();
}

// Inner loop for sha256. `sha256_ptr` points to the start of the block.
func sha256_inner{bitwise_ptr: BitwiseBuiltin*, range_check_ptr, sha256_ptr: felt*}(
    data: felt*, n_bytes: felt, total_bytes: felt
) {
    alloc_locals;

    let message = sha256_ptr;
    let state = sha256_ptr + SHA256_INPUT_CHUNK_SIZE_FELTS;
    let output = state + SHA256_STATE_SIZE_FELTS;

    let zero_bytes = is_le(n_bytes, 0);
    let zero_total_bytes = is_le(total_bytes, 0);

    // If the previous message block was full we are still missing "1" at the end of the message
    // let (_, r_div_by_64) = unsigned_div_rem(total_bytes, 64);
    // let missing_bit_one = is_le(r_div_by_64, 0);
    // TODO: use something other than unsigned_div_rem
    let missing_bit_one = 1;

    // This works for 0 total bytes too, because zero_chunk will be -1 and, therefore, not 0.
    let zero_chunk = zero_bytes - zero_total_bytes - missing_bit_one;

    let is_last_block = is_le(n_bytes, 55);
    if (is_last_block == 1) {
        _sha256_input(data, n_bytes, SHA256_INPUT_CHUNK_SIZE_FELTS - 2, zero_chunk);
        // Append the original message length at the end of the message block as a 64-bit big-endian integer.
        assert sha256_ptr[0] = 0;
        assert sha256_ptr[1] = total_bytes * 8;
        let sha256_ptr = sha256_ptr + 2;
        _sha256_chunk{state=state, output=output}(message);
        let sha256_ptr = sha256_ptr + SHA256_STATE_SIZE_FELTS;

        return ();
    }

    let (q, r) = unsigned_div_rem(n_bytes, SHA256_INPUT_CHUNK_SIZE_BYTES);
    let is_remainder_block = is_le(q, 0);
    if (is_remainder_block == 1) {
        _sha256_input(data, r, SHA256_INPUT_CHUNK_SIZE_FELTS, 0);
        _sha256_chunk{state=state, output=output}(message);

        let sha256_ptr = sha256_ptr + SHA256_STATE_SIZE_FELTS;
        memcpy(
            output + SHA256_STATE_SIZE_FELTS + SHA256_INPUT_CHUNK_SIZE_FELTS,
            output,
            SHA256_STATE_SIZE_FELTS,
        );
        let sha256_ptr = sha256_ptr + SHA256_STATE_SIZE_FELTS;

        return sha256_inner(data=data, n_bytes=n_bytes - r, total_bytes=total_bytes);
    } else {
        _sha256_input(data, SHA256_INPUT_CHUNK_SIZE_BYTES, SHA256_INPUT_CHUNK_SIZE_FELTS, 0);
        _sha256_chunk{state=state, output=output}(message);

        let sha256_ptr = sha256_ptr + SHA256_STATE_SIZE_FELTS;
        memcpy(
            output + SHA256_STATE_SIZE_FELTS + SHA256_INPUT_CHUNK_SIZE_FELTS,
            output,
            SHA256_STATE_SIZE_FELTS,
        );
        let sha256_ptr = sha256_ptr + SHA256_STATE_SIZE_FELTS;

        return sha256_inner(
            data=data + SHA256_INPUT_CHUNK_SIZE_FELTS,
            n_bytes=n_bytes - SHA256_INPUT_CHUNK_SIZE_BYTES,
            total_bytes=total_bytes,
        );
    }
}

// 1. Encode the input to binary using UTF-8 and append a single '1' to it.
// 2. Prepend that binary to the message block.
func _sha256_input{range_check_ptr, sha256_ptr: felt*}(
    input: felt*, n_bytes: felt, n_words: felt, pad_chunk: felt
) {
    alloc_locals;

    local full_word;
    %{ ids.full_word = int(ids.n_bytes >= 4) %}

    if (full_word != 0) {
        assert sha256_ptr[0] = input[0];
        let sha256_ptr = sha256_ptr + 1;
        return _sha256_input(
            input=input + 1, n_bytes=n_bytes - 4, n_words=n_words - 1, pad_chunk=pad_chunk
        );
    }

    if (n_words == 0) {
        return ();
    }

    if (n_bytes == 0 and pad_chunk == 1) {
        // Add zeros between the encoded message and the length integer so that the message block is a multiple of 512.
        memset(dst=sha256_ptr, value=0, n=n_words);
        let sha256_ptr = sha256_ptr + n_words;
        return ();
    }

    if (n_bytes == 0) {
        // This is the last input word, so we should add a byte '0x80' at the end and fill the rest with zeros.
        assert sha256_ptr[0] = 0x80000000;
        // Add zeros between the encoded message and the length integer so that the message block is a multiple of 512.
        memset(dst=sha256_ptr + 1, value=0, n=n_words - 1);
        let sha256_ptr = sha256_ptr + n_words;
        return ();
    }

    with_attr error_message("n_bytes is negative or greater than 3.") {
        assert_nn_le(n_bytes, 3);
    }
    let padding = pow2(8 * (3 - n_bytes));
    local range_check_ptr = range_check_ptr;

    assert sha256_ptr[0] = input[0] + padding * 0x80;

    memset(dst=sha256_ptr + 1, value=0, n=n_words - 1);
    let sha256_ptr = sha256_ptr + n_words;
    return ();
}
