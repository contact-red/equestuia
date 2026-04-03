PACKAGE := equestuia
BUILD_DIR := build
SOURCE_FILES := $(shell find $(PACKAGE) -name '*.pony')

.PHONY: test clean fetch counter

test: fetch $(BUILD_DIR)/$(PACKAGE)
	$(BUILD_DIR)/$(PACKAGE)

$(BUILD_DIR)/$(PACKAGE): $(SOURCE_FILES) | $(BUILD_DIR)
	corral run -- ponyc -o $(BUILD_DIR) $(PACKAGE)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

fetch:
	corral fetch

counter: fetch | $(BUILD_DIR)
	corral run -- ponyc -o $(BUILD_DIR) examples/counter

keyboard: fetch | $(BUILD_DIR)
	corral run -- ponyc -o $(BUILD_DIR) examples/keyboard

packing: fetch | $(BUILD_DIR)
	corral run -- ponyc -o $(BUILD_DIR) examples/packing

clean:
	rm -rf $(BUILD_DIR)
