# sha256_cairo_goldilocks
A cairo implementation of sha256 for the goldilocks field

# How to run with sandstorm and cairo
- Tested for Cairo v0.10.3
- Check description of sandstorm and make Goldilocks adjustments
- Edit `<your_cairo_venv>/lib/python3.9/site-packages/starkware/cairo/lang/instances.py` for the builtins (e.g. for range_check decrease the number of instances to use common range_chek functions)
- In case you get an error with `cairo-compile` for cairo v0.10.3 install correct version of typeguard: `pip install typeguard==2.13.3`

# Results
(On test server)
### 7 hashes (each 80 bytes)
|                   | Goldilocks    | STARK_prime  | 
|-------------------|:-------------:|:------------:|
| Max Memory        | about 274 GB  |              | 
| Time              |    1634s      |              | 
| Proof Size        | 808KB         |              | 
| Steps (original)  | 148848        | 28562        | 
| Steps (total)     | 8388608       | 1048576      | 
| Bitwise cells     | 109198        | 15598        | 

Note that the number of steps is increased exponentially to accomodate the amount of bitwise cells.

# Commands
Compile

```cairo-compile main.cairo --prime 18446744069414584321 --output=main_compiled.json --proof_mode```

Run

```cairo-run --program=main_compiled.json --layout=all --print_output --trace_file trace.bin --memory_file memory.bin --min_steps 128 --proof_mode --print_info```

Prove

```cargo +nightly run -F parallel,asm -- --program main_compiled.json prove --trace trace.bin --memory memory.bin --output proof.bin```


