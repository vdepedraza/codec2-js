INPUT_DIR=./src
OUTPUT_DIR=./dist
OUTPUT_DIR_UNMINIFIED=./dist-unminified
EMCC_OPTS=-O3 -s NO_DYNAMIC_EXECUTION=1 -s NO_FILESYSTEM=1
DEFAULT_EXPORTS:='_malloc','_free'

CODEC2_ENCODER_SRC=$(INPUT_DIR)/encoderWorker.js
CODEC2_DECODER_SRC=$(INPUT_DIR)/decoderWorker.js
CODEC2_ENCODER_MIN=$(OUTPUT_DIR)/encoderWorker.min.js
CODEC2_ENCODER=$(OUTPUT_DIR_UNMINIFIED)/encoderWorker.js
CODEC2_DECODER_MIN=$(OUTPUT_DIR)/decoderWorker.min.js
CODEC2_DECODER=$(OUTPUT_DIR_UNMINIFIED)/decoderWorker.js

CODEC2_DIR=./codec2
CODEC2_OBJ=$(CODEC2_DIR)/build/src/libcodec2.a
CODEC2_EXPORTS:='_codec2_create','_codec2_destroy','_codec2_encode','_codec2_decode', '_codec2_samples_per_frame', '_codec2_bits_per_frame', '_codec2_bytes_per_frame'

default: $(CODEC2_ENCODER) $(CODEC2_ENCODER_MIN) $(CODEC2_DECODER) $(CODEC2_DECODER_MIN)  

cleanDist:
	rm -rf $(OUTPUT_DIR) $(OUTPUT_DIR_UNMINIFIED)
	mkdir $(OUTPUT_DIR)
	mkdir $(OUTPUT_DIR_UNMINIFIED)

cleanAll: cleanDist
	rm -rf $(CODEC2_DIR)

$(CODEC2_DIR)/CMakeLists.txt:
	git submodule update --init
	patch -d $(CODEC2_DIR) -p1 < codec2.patch

$(CODEC2_OBJ): $(CODEC2_DIR)/CMakeLists.txt
	cd $(CODEC2_DIR); mkdir build_native
	cd $(CODEC2_DIR)/build_native; cmake .. -DBUILD_SHARED_LIBS=OFF
	cd $(CODEC2_DIR)/build_native; make generate_codebook

	cd $(CODEC2_DIR); mkdir build_web
	cd $(CODEC2_DIR)/build_web; emcmake cmake .. -DBUILD_SHARED_LIBS=OFF -DCOMPILE_GENERATE_CODEBOOK=OFF

	cp $(CODEC2_DIR)/build_native/src/generate_codebook $(CODEC2_DIR)/build_web/src/generate_codebook

	cd $(CODEC2_DIR)/build_web; emmake make

$(CODEC2_ENCODER): $(CODEC2_ENCODER_SRC) $(CODEC2_OBJ)
	emcc -o $@ $(EMCC_OPTS) -s BINARYEN_ASYNC_COMPILATION=0 -s SINGLE_FILE=1 -g3 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(CODEC2_EXPORTS)]" --post-js $(CODEC2_ENCODER_SRC) $(CODEC2_OBJ)

$(CODEC2_ENCODER_MIN): $(CODEC2_ENCODER_SRC) $(CODEC2_OBJ)
	emcc -o $@ $(EMCC_OPTS) -s BINARYEN_ASYNC_COMPILATION=0 -s SINGLE_FILE=1 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(CODEC2_EXPORTS)]" --post-js $(CODEC2_ENCODER_SRC) $(CODEC2_OBJ)

$(CODEC2_DECODER): $(CODEC2_DECODER_SRC) $(CODEC2_OBJ)
	npm run webpack -- --config webpack.config.js -d --output-library DecoderWorker $(CODEC2_DECODER_SRC) -o $@
	emcc -o $@ $(EMCC_OPTS) -g3 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(CODEC2_EXPORTS)]" --pre-js $@ $(CODEC2_OBJ)

$(CODEC2_DECODER_MIN): $(CODEC2_DECODER_SRC) $(CODEC2_OBJ)
	npm run webpack -- --config webpack.config.js -p --output-library DecoderWorker $(CODEC2_DECODER_SRC) -o $@
	emcc -o $@ $(EMCC_OPTS) -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(CODEC2_EXPORTS)]" --pre-js $@ $(CODEC2_OBJ)
