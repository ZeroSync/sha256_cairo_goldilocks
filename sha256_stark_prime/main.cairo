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
                        'TzZz3BwjYvs80FOuoglNbtx64eRXVAUfO0f1rQF9VN3aWaXFfWALm0QrTG8NBgo3JAH2uv76nsXFjCp6',
                        'dUuO7dYIDofOFyf6b9SUAoYGzyVJR1k9t8bSIOc9b2V6Uv6ZWmEC7UEpeoU2Dj6UL5slJbsw8n1kSqLY',
                        'kdeW7vxnasEhtXXdD8lgd7IrlrvJoVcE69mUDlvkta9PvtYgOvvPPdGsuS0HivrYhdHKgXvMQEhCqhlG',
                        'eHN7DdbkNM3pQVXBvZNmi2FAezkdw617o5FkVHj0LEmplDBFBKab7uH3QNp6CKv150IriIkGFV4Mc8iY',
                        'gIgNhvWdYm4ubHt0sWkKayp401kwwAvr4zaYIDeDyNIX4weY9KJd7VcR7PAhwqIUNPqXwv0AhV5T2HNj',
                        'z5PHBMGNtWd12Ef7zcJyvZpP1m1enx1PydQaZbSaDnWKmyTyf51slHqKj7jPW8FUcAZAT2IoIAZWBTEh',
                        'oCX8j0sZkTO0gzU7TasI5ShfQVpEECJsPL56PowRcHfxpikvnBgaG2DzZkPOGLNiKhigZmzG9P6aKOuM',
                        'RUQ5Rm2QUx76ANNaOIY2vB3Pd2SGOUGHL18E5J23DHBrzh2uNokjKBnRURWFXxJfeaE42JyHyAmrVGeH',
                        '1GEwoU6EcpTTPNweNoljuRfUr3jPs873nYyQ3PzjuE0LtJP6YtkzzZnq0byb8Ts9uavJGYNtgkDtd0h9',
                        'H12rbXfEeZiqDzLnpPrbNfYBFjoz1v5xbV40Npaza5Zt8FaLIfpe9gs1YIQUVWO0hX7t8OnT9uQWPKGN',
                        'BLy1CehKOgy0WFmyyzpwdMZdbqcH0pCdruIwOEQyWWrrXtYy3rYL9nS5qxzNU3ijTpr8BsNeHhGFXcdM',
                        'yp5m9XdIN8pewk8WCW2AFowdIMcMVcYdhqytAP6qbrgxnYkvacfc2v8TJ3jGzf8FfXVrE5iIVh8tQoIe',
                        'QoEq2pvMoA3lv87LKl8aMHhAPidaTP6Kb3M2AU6t8ARKimk2oB5ZysTm3UukuTOfpOuEMdk0bqoKaeaU',
                        'OyXRzq6AR2g8VxLORniqoFMdTvyll5eQGOCR4JcADSRxICT7ABhaMfM8LgrJJY2qDXX4hbrQovfMafJM',
                        '1wBWiamTvjUUtmUvpjxy9FvG0LuV5jzf351NgSU41aHydG3rSw8wU4icgY7ySs1VKbpgngnwbW4AX9nt',
                        '45SONTlQboY75Q4dZU7lWwN0g4zK54vR3Xgm5njBgT9z1MCUXIUu1mHnMIifUwNAvbk9HEgxUz5TeK0j',
                        'MVmjrYRwjtmQJkoBzWsviILNvMw9vbrrjuh0uxkTdVFwFMhNYFnTrRvUHceZfN7M6CriKGMncfc8RDXs',
                        'cOOI2JCRvrigBUJvZtIpX3rHsv2kEjqShd9BqZh1iGPHJM3LAgIA0kJcDbkjplQErlLSSUZ4aEV0yZ3A',
                        'yBmP31bS4heMYd3fFBkivBQQy2mdscv7gENGn3JNQ1APXkPeV8BlCyLWwKKCqPAAQzXcnBBMnTGHaM7e',
                        'vVo9lelWyt8H9nCLfkX4pI7DhxAetDXE54Cer6S5nhfWy2v6raQa8r7fv8KLF30p6EefwGA5Usw04lLa',
                        'nrXV1WCw71PbOPdcqnBoyUJramDUcunHgovTD34GohH5BcFE7NSCysou29INLrRYOmQFToT4e8bAgrXm',
                        'w7c8TMNQBMDdnMk3dHtLIrYlQM0rk0hGEOcAP7NQDtDO5N0zyiwaZwtzAKucSImGcwvh9F6rkPIKShhs',
                        '7hMmjN2Ho1eZc2Cy2UF74MallQ1vDj3kfe5B0pxJILA0nL8kcjRaCDMK61J7r8QJY1oW9rcNB3pHANww',
                        'Vqies6Ur95SUDqNQPfOPiVHwWsOodwtVEMfGKE5K8oUDrPraolLi0dnE4piZhWbdeE9IImOU6lOqc8ik',
                        'eudHlMQ5WbmrAWn5jf1gceNOYDtZzpsdGZmOEFjd3RUVz1R6tv8T4Gq9bZ7SH87hToTC5ElUum9TiG8v',
                        'nOKGKbyg3u9mVIJFXjfxRwU1Ucts3Y5oM6XXVVpXnnVJyXtmGZFzgduu8j3fgcjb0VTwvQESeMk7pyJS',
                        'FrixD9bu7EhnMAZziJlSuoFGG2r716kSbHOnYQnDlWiuh4IoMjTIffRpAYNZMF8jZgJS0PQMvcOtZgkW',
                        'eEnbZfY3R9e1qzDQu3Bjz2KJH1kMJoDKfOany0TACywOLCOrG3BBGbZhOEiDCVBa7VVpOq33q4rlaoPy',
                        'oAD7MxhxaMV4l2TuW6IYQW0ncdCu4KkR8BMOR1T4NrIr9IkMdtHN7YhfaTrDm50E3Rsb95l34uY02W6G',
                        '9jdIYitPEwrap89eKxDa5022GrOXJzj4oZ3Up3KIiICvw4P1JU7lu96Po6sLpl64HqeLK9wDzasUIPge',
                        'VLD9aFotHxeo7Td14CwjfSBBntf1wUqBYGDFVK4aWsKSlXDtirZ3Dw0gdXDhuAWU5Fu6zPDh56eZLWwQ',
                        'BVrfZdbcBEhzOUnleGx5df21h9VGsREsMYletbnZWBXmMAoH8OI6Qs7zS7MFnuzADhzxCPQWNRFOcwfY',
                        'NTtYU9tREdUDiaYm5fwgg5j0JsUv4AXXG7js7QJVSmTjsroQFMHrA3HKN0sZqHejB5nw1yyYoOOBCZMn',
                        'iUNBBRqq0VkYuohG9fjs5b8CwgwhDlCatEAD2pzhvmeAUiEw7wyVkFEbsE3zKAFfm2bgOd6u7FXUqMie',
                        'njlc16lrwMPaZD2zUCzM3b5mDsqm33p8mfVPnfiT7r8EwQAwAsvE60S1wiDYOfs6TaGzFDWS5F5pygAx',
                        '2sgI7YzM5nhaw2QCdlUq9Jiv931NPL22dO6Iii9LjMRN9GbGBGFILo838gotrEUfv8RaCxwyu0F1Qj9F',
                        '2Vwv7EFH1TVR7DtJXdz1gETKq0rWzfi2CpIg82ViIQqGOp8UcF0hs730pi069o8asq4BnedgYHVM8w2X',
                        'WxNFIaCjJcfsEVrEtHFRg17CB1PvcVtsguHK43N3XiNPQvi8onSJXdSIsHYomxwtTn4AWeXZm3JsAMFE',
                        '2qHQgDMNqNTQWDEeAjHw9BRhHboO0lBWn9hewebKt9s6SmdafdjXzMXGQcgqpqq7a1nr0LBQVryAuibH',
                        '2prlyGgGQxePq2aIVxPCuGQXqQ9eAqBzWCGVTEapI9jMOX6fXwmMey16OwPHK5dYn6huhCOEurkoSkTx',
                        'ONL2TPFjoHBtFngAadBkDLzqLJpy1F1qguenoXt1AXusI1xETg1QE3rgUoYxTnSzQrNpvGN5lMD1l5Ke',
                        'tMNURfCFmhefUQS1No0ZVDbaZjjjeFzo19Y1rpqYx4oZzklD9qrQ9D0u8RK3xh7RPPUZx3lYO2q9rWt9',
                        'Kynxnnc4EUb3QB4bhKPJ3EbOgue8gmIzvi7lwSkt0sgg95fPWLglkofz0jhH8b8irOZWDF7gscBdpPos',
                        'w0YvoSOf1K6e1W7VDyqyozZH4TGCjwdouYSdkvehza6893t4xd0W3pdOVw5sbocVNUsGwl6145aAwecn',
                        'EttC3LufqjwaWVsFA3glfB4H3LUOfSWHwPHXitoCWRywHwITi857IdzlCjmGtoDnv3CJfaz46rkvH3IY',
                        'orOHDDNZU5aNnmcnAN4KcrHQzfexCOgeHw5j7ShdVAjuAwU3tlmbrtbqnS18R6ZgyU2htDRlyIlMkiRm',
                        'W4rkOP0TpbhYTTImsJwXTJGXRGRIJyBC8jXgwpAdlrWEONNBNwcIGdHakJkmWd8GvZ8tVIHjg82Utn0F',
                        'FaL7gcrSQILjcFeaEYXLgjamHuAQZ4UqgnR22D7pmIdSkArywQbSQ4eM9JmkNuTR2LTZqxXoxKcwXFXi',
                        'KHnM7jeNhAxVKJeiBNPgN9XV6Z0rIqNgYU1BoVCTcW7kBNrq8Jc8lglEb2LU8RFFIggcqK7GULi0KF9q',
                        'DgUHPavP5oE2kiSjQjQFAsiijMzFW6B5qPxBkqKF3zem9sO25czA2X3h6R49vAPUgnOTSNbOx3lAG2R4',
                        'KkE2t1NUlKjcAO6V0qMiahCHzLyc1CGCEiXwtlSnARLJn62ijya6GUuI0ehE82JllXwXgIVy7aONXRoX',
                        'uFLNaHxPqrdyGN6TjoW2b6CTKnvD7jTx5eo4Mr6FVCcqyo2fy4LjIC58sp4iqQwQwlTgowZseOxtu4EF',
                        'qxzOjFsy80r8bl1VMTaEufHprSz1tw612fs4Czv3La49rI0CKW2ROZyuqiaGlssstVYJ1ut1TvHwqVRU',
                        'O8yABEZjKbYnFxLsTIv6myocm0xXc3FGo6kz17iRwqqiOAry42zsxoSaoUYJG95LuxiFDsB2eHiS2Eov',
                        'wk8epVafi35S8V44LclJodEyX5k1GX6vBqQVUjqkoJW74cdEilKYdYH2E9l2369adknpe5EPEMHJJmbk',
                        'a81sCvtaWTl7EUZBhCooZCdDrLheYOOx986z2ZHImHtlYa7Upp4VjJlLFloayIX0Z4qtZrjGCKbJGgFd',
                        'djyiADnTfj5gKdzSBJw7YCrBVwnVNlfhp4xI1FcXVbta09wmb26suQ1LGSlKVKwFoJkwx4sYxXoRNzSE',
                        'EZeLw16NcqVYgQ9QWNKvImpLryrTspQQLdnCXOHKP7JvnIAqGIXUTv67cBGuBRR27A6XrSwwetq0mjV9',
                        '7x68Mqdh35oYDNBfd1GchQThzefp9OgYCuiHG3cNuqWLBLk930GXVmi4m7sUOUZVyq1UtH8Dk2cRUIi3',
                        'V6n36aCjVHCqXdRBV5HElm3ajrMCofNZp8zYshgePMhCGJhDaM8zGkjZBe3jKItFvWLicsFm5I9B1JT1',
                        'KqJFvJ9HMfBl4qu8wn4UtTjtM6wlpxmVbPllPhheyvvL2i3XogQsH9NHtehAiU2HSL7RMDFCtMZmVb6m',
                        'SW1d0R7iBYzb9roljhh1tSTsg290MLpSWY83eQVHP2ipxJDbiATEOkd7W3vNnALG7uyM4JfDEI5FqwK1',
                        'ciZP8PXySV1uqP3CoxzDzBYPtXCMFNXTrB7xeQVPgTBmjEDDy8n9uiq7YWGggQ4GA5CEaTG6UpfgRilS',
                        'tgiUDp9nduDjWx3KOrWvNsosIdXDMZ714DyEpUfTOrJIRfvE7d8rA94xMwZGBbjsAltuT8K6LBehicMr',
                        'NMoY1ciLTD8iSXfKFyzL0zu1ji7zgdMBVgwqGnMQ3Y3yT2lkxN7yrbF8DabyXdw00BZNREO6fVuT64kY',
                        'meYha4i2O4WgrDBhbHlx3dUHtGZG84DtVCrfRvlembrBzgfi0kpMCYLjOwrpgbneBDJ0c4xKFc4nOTxP',
                        'LangshJAuFRVJSFgdhlrLhqAoMJfwcumrzkYKgrxZrUvq2VR7dbGJlAnd4dRgmkitZ72JtQzgG1aK0gi',
                        'viDysY70X8NCAvSEz7xAmPtNwH8VHqvCSwVfb31uKY6ra1tPxZjaK4Fo7h1RLLqMFnkyI3Gb7uQS2O5O',
                        'BehgNLo7Vyk8cNT9PrSnWEo8xOlJnwq4a468O3GMG7WklY8uyOwoDPC8La0NVOUsNZ5SvxIIBQ8JzU94',
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
    finalize_sha256(sha256_ptr_start, sha256_ptr);
    return ();
}
