%builtins output pedersen range_check ecdsa bitwise
from starkware.cairo.common.cairo_blake2s.blake2s import blake2s_as_words, finalize_blake2s
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

func calculate_test_hash{blake2s_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
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

    let (hash) = blake2s_as_words{range_check_ptr=range_check_ptr, blake2s_ptr=blake2s_ptr}(
        input, byte_size
    );

    let (expected_hash) = alloc();
    // assert that the hash is correct
    %{
        from_hex(hashlib.blake2s(input_str.encode("ascii")).hexdigest(), ids.expected_hash) 
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

        TEST_STRINGS = ['1rGkqe7AJGhCaBHch6q0IWm2IOcfDf6DSpV0pPTpI',
                        'tfvWjxirvbLLNa0rAvDcLkLUJqlNa1J5ctxq2IUcL',
                        'f7lwJyWh3HAwaR3aD9np7ev6GSs9G7O3KNUXE51bL',
                        'NmAVxMHr6uNC9mZ0pVRDRa4sSBdb78iYEVO0uzGmu',
                        'OXeFzt8mefIYjlyfas7kdCLAP0BPoMcapx6SwILsg',
                        '7MrcAxvRHJ7uaWx2IDycpIZnqUgvkn2eK8mHQh62D',
                        'de7tqiNOd9voMRoOQZXImt0k5o2nwnrXN7bSd8qiX',
                        'wURhSFCT5BVWlgs9ryfKodXYhmTXTCtb5lDLPcfzB',
                        'X50pwrScCAUTYNzgzXsDLghd4VkDAkzztFmDI9g4v',
                        'IDvJ2clUC2oC6b8hrBneBhUzL2dK91jPwFLmaIBEC',
                        'qtfcbowTCOLbH0xcVFptZ5QB95VaE3gRjguSJC9Ho',
                        'QK7yfSWZbCRZrkpdW8LpsOw8ayV7il5JvRUfWoOTJ',
                        'm7YvpdHoiOkXLfNwYWm5wyhdCwt2WpydJXsF21aNJ',
                        'YIwrqSjLIIye3xQvtUBe5KNTkFkcfAMrVFBwWN8SC',
                        'd118T9TOGQneGNIO14aQMqWu2GwjrYL2KIi8Xwp8I',
                        'JHPEbg9dlli1yHsliep2TUTuMlgstt28leKjFXqKP',
                        'HN797fb51YmAHVO33iggnEREHQsSsWIfoN45iMXcw',
                        'e9rQwbExii50Kl8GK8tlpheSfNdZyTbVQNxC8si4u',
                        'hIT7itSrDoBShtXSqFJJekMegEk41NRKRvCNUpsu3',
                        'JX4NdqnNMezKYNs9MCrOf0wXAStvYBF1xfN8l9p5M',
                        'TzZz3BwjYvs80FOuoglNbtx64eRXVAUfO0f1rQF9V',
                        'dUuO7dYIDofOFyf6b9SUAoYGzyVJR1k9t8bSIOc9b',
                        'kdeW7vxnasEhtXXdD8lgd7IrlrvJoVcE69mUDlvkt',
                        'eHN7DdbkNM3pQVXBvZNmi2FAezkdw617o5FkVHj0L',
                        'gIgNhvWdYm4ubHt0sWkKayp401kwwAvr4zaYIDeDy',
                        'z5PHBMGNtWd12Ef7zcJyvZpP1m1enx1PydQaZbSaD',
                        'oCX8j0sZkTO0gzU7TasI5ShfQVpEECJsPL56PowRc',
                        'RUQ5Rm2QUx76ANNaOIY2vB3Pd2SGOUGHL18E5J23D',
                        '1GEwoU6EcpTTPNweNoljuRfUr3jPs873nYyQ3Pzju',
                        'H12rbXfEeZiqDzLnpPrbNfYBFjoz1v5xbV40Npaza',
                        'BLy1CehKOgy0WFmyyzpwdMZdbqcH0pCdruIwOEQyW',
                        'yp5m9XdIN8pewk8WCW2AFowdIMcMVcYdhqytAP6qb',
                        'QoEq2pvMoA3lv87LKl8aMHhAPidaTP6Kb3M2AU6t8',
                        'OyXRzq6AR2g8VxLORniqoFMdTvyll5eQGOCR4JcAD',
                        '1wBWiamTvjUUtmUvpjxy9FvG0LuV5jzf351NgSU41',
                        '45SONTlQboY75Q4dZU7lWwN0g4zK54vR3Xgm5njBg',
                        'MVmjrYRwjtmQJkoBzWsviILNvMw9vbrrjuh0uxkTd',
                        'cOOI2JCRvrigBUJvZtIpX3rHsv2kEjqShd9BqZh1i',
                        'yBmP31bS4heMYd3fFBkivBQQy2mdscv7gENGn3JNQ',
                        'vVo9lelWyt8H9nCLfkX4pI7DhxAetDXE54Cer6S5n',
                        'nrXV1WCw71PbOPdcqnBoyUJramDUcunHgovTD34Go',
                        'w7c8TMNQBMDdnMk3dHtLIrYlQM0rk0hGEOcAP7NQD',
                        '7hMmjN2Ho1eZc2Cy2UF74MallQ1vDj3kfe5B0pxJI',
                        'Vqies6Ur95SUDqNQPfOPiVHwWsOodwtVEMfGKE5K8',
                        'eudHlMQ5WbmrAWn5jf1gceNOYDtZzpsdGZmOEFjd3',
                        'nOKGKbyg3u9mVIJFXjfxRwU1Ucts3Y5oM6XXVVpXn',
                        'FrixD9bu7EhnMAZziJlSuoFGG2r716kSbHOnYQnDl',
                        'eEnbZfY3R9e1qzDQu3Bjz2KJH1kMJoDKfOany0TAC',
                        'oAD7MxhxaMV4l2TuW6IYQW0ncdCu4KkR8BMOR1T4N',
                        '9jdIYitPEwrap89eKxDa5022GrOXJzj4oZ3Up3KIi',
                        'VLD9aFotHxeo7Td14CwjfSBBntf1wUqBYGDFVK4aW',
                        'BVrfZdbcBEhzOUnleGx5df21h9VGsREsMYletbnZW',
                        'NTtYU9tREdUDiaYm5fwgg5j0JsUv4AXXG7js7QJVS',
                        'iUNBBRqq0VkYuohG9fjs5b8CwgwhDlCatEAD2pzhv',
                        'njlc16lrwMPaZD2zUCzM3b5mDsqm33p8mfVPnfiT7',
                        '2sgI7YzM5nhaw2QCdlUq9Jiv931NPL22dO6Iii9Lj',
                        '2Vwv7EFH1TVR7DtJXdz1gETKq0rWzfi2CpIg82ViI',
                        'WxNFIaCjJcfsEVrEtHFRg17CB1PvcVtsguHK43N3X',
                        '2qHQgDMNqNTQWDEeAjHw9BRhHboO0lBWn9hewebKt',
                        '2prlyGgGQxePq2aIVxPCuGQXqQ9eAqBzWCGVTEapI',
                        'ONL2TPFjoHBtFngAadBkDLzqLJpy1F1qguenoXt1A',
                        'tMNURfCFmhefUQS1No0ZVDbaZjjjeFzo19Y1rpqYx',
                        'Kynxnnc4EUb3QB4bhKPJ3EbOgue8gmIzvi7lwSkt0',
                        'w0YvoSOf1K6e1W7VDyqyozZH4TGCjwdouYSdkvehz',
                        'EttC3LufqjwaWVsFA3glfB4H3LUOfSWHwPHXitoCW',
                        'orOHDDNZU5aNnmcnAN4KcrHQzfexCOgeHw5j7ShdV',
                        'W4rkOP0TpbhYTTImsJwXTJGXRGRIJyBC8jXgwpAdl',
                        'FaL7gcrSQILjcFeaEYXLgjamHuAQZ4UqgnR22D7pm',
                        'KHnM7jeNhAxVKJeiBNPgN9XV6Z0rIqNgYU1BoVCTc',
                        'DgUHPavP5oE2kiSjQjQFAsiijMzFW6B5qPxBkqKF3',
                        'KkE2t1NUlKjcAO6V0qMiahCHzLyc1CGCEiXwtlSnA',
                        'uFLNaHxPqrdyGN6TjoW2b6CTKnvD7jTx5eo4Mr6FV',
                        'qxzOjFsy80r8bl1VMTaEufHprSz1tw612fs4Czv3L',
                        'O8yABEZjKbYnFxLsTIv6myocm0xXc3FGo6kz17iRw',
                        'wk8epVafi35S8V44LclJodEyX5k1GX6vBqQVUjqko',
                        'a81sCvtaWTl7EUZBhCooZCdDrLheYOOx986z2ZHIm',
                        'djyiADnTfj5gKdzSBJw7YCrBVwnVNlfhp4xI1FcXV',
                        'EZeLw16NcqVYgQ9QWNKvImpLryrTspQQLdnCXOHKP',
                        '7x68Mqdh35oYDNBfd1GchQThzefp9OgYCuiHG3cNu',
                        'V6n36aCjVHCqXdRBV5HElm3ajrMCofNZp8zYshgeP',
                        'KqJFvJ9HMfBl4qu8wn4UtTjtM6wlpxmVbPllPhhey',
                        'SW1d0R7iBYzb9roljhh1tSTsg290MLpSWY83eQVHP',
                        'ciZP8PXySV1uqP3CoxzDzBYPtXCMFNXTrB7xeQVPg',
                        'tgiUDp9nduDjWx3KOrWvNsosIdXDMZ714DyEpUfTO',
                        'NMoY1ciLTD8iSXfKFyzL0zu1ji7zgdMBVgwqGnMQ3',
                        'meYha4i2O4WgrDBhbHlx3dUHtGZG84DtVCrfRvlem',
                        'LangshJAuFRVJSFgdhlrLhqAoMJfwcumrzkYKgrxZ',
                        'viDysY70X8NCAvSEz7xAmPtNwH8VHqvCSwVfb31uK',
                        'BehgNLo7Vyk8cNT9PrSnWEo8xOlJnwq4a468O3GMG',
                        ]


        def swap32(x):
            return (((x << 24) & 0xFF000000) |
                    ((x <<  8) & 0x00FF0000) |
                    ((x >>  8) & 0x0000FF00) |
                    ((x >> 24) & 0x000000FF))


        def hex_to_felt(hex_string):
            # Seperate hex_string into chunks of 8 chars.
            felts = re.findall(".?.?.?.?.?.?.?.", hex_string)
            # Fill remaining space in last chunk with 0.
            while len(felts[-1]) < 8:
                felts[-1] += "0"
            return [swap32(int(x, 16)) for x in felts]


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

    // initialize blake2s_ptr
    let blake2s_ptr: felt* = alloc();
    let blake2s_ptr_start = blake2s_ptr;
    with blake2s_ptr {
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(0);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(1);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(2);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(3);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(4);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(5);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(6);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(7);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(9);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(10);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(11);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(12);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(13);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(14);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(15);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(16);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(17);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(18);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(19);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(20);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(21);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(22);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(23);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(24);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(25);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(26);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(27);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(28);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(29);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(30);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(31);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(32);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(33);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(34);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(35);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(36);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(37);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(38);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(39);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(40);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(41);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(42);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(43);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(44);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(45);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(46);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(47);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(48);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(49);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(50);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(51);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(52);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(53);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(54);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(55);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(56);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(57);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(58);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(59);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(60);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(61);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(62);
        calculate_test_hash{range_check_ptr=range_check_ptr, bitwise_ptr=bitwise_ptr}(63);
    }
    finalize_blake2s(blake2s_ptr_start, blake2s_ptr);
    return ();
}
