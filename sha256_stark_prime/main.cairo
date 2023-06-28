%builtins output pedersen range_check ecdsa bitwise
from sha256 import compute_sha256, finalize_sha256
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

func calculate_test_hash{sha256_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    input_str_nr
) {
    alloc_locals;
    %{ input_str = TEST_STRINGS[ids.input_str_nr] %}
    // %{ input_str = "abc" %}
    let (input) = alloc();
    local byte_size;
    %{
        ids.byte_size, array_len = from_string(input_str, ids.input)
        # print("input =", [hex(memory[ids.input + x]) for x in range(0, array_len)])
        # print("byte_size =", ids.byte_size)
    %}

    let hash = compute_sha256{range_check_ptr=range_check_ptr, sha256_ptr=sha256_ptr}(
        input, byte_size
    );

    let (expected_hash) = alloc();
    // assert that the hash is correct
    %{
        from_hex(hashlib.sha256(input_str.encode("ascii")).hexdigest(), ids.expected_hash) 
        # print("expected_hash =", [hex(memory[ids.expected_hash + x]) for x in range(0,8)])
        # print("hash =", [hex(memory[ids.hash + x]) for x in range(0,8)])
    %}
    assert expected_hash[0] = hash[0];
    assert expected_hash[1] = hash[1];
    assert expected_hash[2] = hash[2];
    assert expected_hash[3] = hash[3];
    assert expected_hash[4] = hash[4];
    assert expected_hash[5] = hash[5];
    assert expected_hash[6] = hash[6];
    assert expected_hash[7] = hash[7];
    return ();
}

func main{output_ptr, pedersen_ptr, range_check_ptr, ecdsa_ptr, bitwise_ptr: BitwiseBuiltin*}() {
    alloc_locals;
    %{
        import hashlib
        import re

        TEST_STRINGS = ['1rGkqe7AJGhCaBHch6q0IWm2IOcfDf6DSpV0pPTpIAy8PDEcaIqHTEKvxdC8BX9d39Q8UIHvt7BrTRq3',
                        'tfvWjxirvbLLNa0rAvDcLkLUJqlNa1J5ctxq2IUcLwRbgWN4ZpkSHEPj7yLJhbMGJyBT0aKfZiQu0jxe',
                        'f7lwJyWh3HAwaR3aD9np7ev6GSs9G7O3KNUXE51bLsY5auo4R7HQxxGqAO8vSgWSHPJDHQwYTvau7ugh',
                        'NmAVxMHr6uNC9mZ0pVRDRa4sSBdb78iYEVO0uzGmu7od8J5xDwMWcR2FLDSmVPzfo0HpycLVw6nBES3J',
                        'OXeFzt8mefIYjlyfas7kdCLAP0BPoMcapx6SwILsgndy4FVLMFQlrCUM5rnEhMR5Pblpg0YhcL9Fzkt1',
                        '7MrcAxvRHJ7uaWx2IDycpIZnqUgvkn2eK8mHQh62DLEeG8S3CKBlUkpGi6O2WbdQE7wscm1I80zZtxhg',
                        'de7tqiNOd9voMRoOQZXImt0k5o2nwnrXN7bSd8qiXu5beRWTve2g12KXIjqTnTKidajcH8Oqxyzq6XHM',
                        'wURhSFCT5BVWlgs9ryfKodXYhmTXTCtb5lDLPcfzBLGU8OSGFgqFzMTZy2YLAhYrKPDjZC1t0OU5VNyr',
                        'X50pwrScCAUTYNzgzXsDLghd4VkDAkzztFmDI9g4vWiRNFTpBNOrt36URjdEgajjbBeOiyxR94SouTOd',
                        'IDvJ2clUC2oC6b8hrBneBhUzL2dK91jPwFLmaIBEC8YKsL6NIEBCWWoFmGrjjWAdMeHTaXVJzM06uIBZ',
                        'qtfcbowTCOLbH0xcVFptZ5QB95VaE3gRjguSJC9HoDKGz1wzdaEkwhSQfmhH5mvDFPnwJbM0zvvilriT',
                        'QK7yfSWZbCRZrkpdW8LpsOw8ayV7il5JvRUfWoOTJQAUbxqgOLaWU7IaeGdISWwWSqsl91TvkEAPQCQ4',
                        'm7YvpdHoiOkXLfNwYWm5wyhdCwt2WpydJXsF21aNJT8l6fUgbmbxL6UNVyEcZBKrip6Pp9MNYKfljv7A',
                        'YIwrqSjLIIye3xQvtUBe5KNTkFkcfAMrVFBwWN8SCEy8K5YZm4aHRKL6ceplKI1hhGGfG1fQUYSnpTf7',
                        'd118T9TOGQneGNIO14aQMqWu2GwjrYL2KIi8Xwp8ItZ4yHkriLelbvfRFqfjpdcSJx59M1UITZvRKZEz',
                        'JHPEbg9dlli1yHsliep2TUTuMlgstt28leKjFXqKPtuBKpXrcBiqr149vo2S3cN7c9t3IDXbh9l5iewf',
                        'HN797fb51YmAHVO33iggnEREHQsSsWIfoN45iMXcwUrK0ZJm5dsud9sHzWHqQ8w2IFkruxMab3JWMlrL',
                        'e9rQwbExii50Kl8GK8tlpheSfNdZyTbVQNxC8si4uVeRBk059tEg6GtPmqFPCZF6l7dtwjCRfp6ek8L7',
                        'hIT7itSrDoBShtXSqFJJekMegEk41NRKRvCNUpsu3z5eZzZKqnTUNs8xt5zyZjk5iC4sHFM33LLPqxx1',
                        'JX4NdqnNMezKYNs9MCrOf0wXAStvYBF1xfN8l9p5MwlMOQ7FdL17xpbdz7H1truFHrz8FD1LPzSKBhlR',
                        '1uZ8ESiNqxF3e6Spwty0AurJHdkjR0tQR2Ll5oGEFXfEEM9TMjuf8JiSeLMLmFlYK1rlTXI3HH1FGgJl',
                        ]


        def hex_to_felt(hex_string):
            # Seperate hex_string into chunks of 8 chars.
            felts = re.findall(".?.?.?.?.?.?.?.", hex_string)
            # Fill remaining space in last chunk with 0.
            while len(felts[-1]) < 8:
                felts[-1] += "0"
            return [int(x, 16) for x in felts]


        # Writes a hex string into an uint32 array
        #
        # Using multi-line strings in python:
        # - https://stackoverflow.com/questions/10660435/how-do-i-split-the-definition-of-a-long-string-over-multiple-lines
        def from_hex(hex_string, destination):
            # To see if there are only 0..f in hex_string we can try to turn it into an int
            try:
                check_if_hex = int(hex_string,16)
            except ValueError:
                print("ERROR: Input to from_hex contains non-hex characters.")
            felts = hex_to_felt(hex_string)
            segments.write_arg(destination, felts)

            # Return the byte size of the uint32 array and the array length.
            return (1 + len(hex_string))// 2, len(felts)


        # Writes a string of any length into the given destination array.
        # String is seperated into uint32 chunks.
        # Last chunk is filled with zeros after the last string byte.
        def from_string(string, destination):
            hex_list = [hex(ord(x)).replace("0x","") for x in string]
            hex_string = "".join(hex_list)
            
            return from_hex(hex_string, destination)
    %}

    // initialize sha256_ptr
    let sha256_ptr: felt* = alloc();
    let sha256_ptr_start = sha256_ptr;
    with sha256_ptr {
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(0);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(1);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(2);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(3);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(4);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(5);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(6);
    }
    finalize_sha256(sha256_ptr_start, sha256_ptr);
    return ();
}
