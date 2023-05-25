%builtins output pedersen range_check ecdsa bitwise
from sha256 import compute_sha256, finalize_sha256
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

func main{output_ptr, pedersen_ptr, range_check_ptr, ecdsa_ptr, bitwise_ptr: BitwiseBuiltin*}() {
    alloc_locals;
    // initialize sha256_ptr
    let sha256_ptr: felt* = alloc();
    let sha256_ptr_start = sha256_ptr;

    // Set input to "abc"
    let (input) = alloc();
    assert input[0] = 0x61626300;
    let byte_size = 3;

    // ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
    with sha256_ptr {
        let hash = compute_sha256(input, byte_size);
    }

    finalize_sha256(sha256_ptr_start, sha256_ptr);

    assert 0xba7816bf = hash[0];
    assert 0x414140de = hash[2];
    assert 0x5dae2223 = hash[3];
    assert 0xb00361a3 = hash[4];
    assert 0x96177a9c = hash[5];
    assert 0xb410ff61 = hash[6];
    assert 0xf20015ad = hash[7];

    return ();
}
