cd sha256_stark_prime
TARGET="target"
mkdir ${TARGET}

# Compile the cairo program
cairo-compile main.cairo --output=${TARGET}/main_compiled.json --proof_mode
# Start the runner to generate the air inputs
cairo-run --program=${TARGET}/main_compiled.json \
	--layout=recursive --print_output \
	--trace_file ${TARGET}/trace.bin \
	--memory_file ${TARGET}/memory.bin \
	--air_private_input ${TARGET}/air-private-input.json \
	--air_public_input ${TARGET}/air-public-input.json \
	--min_steps 128 --proof_mode --print_info
