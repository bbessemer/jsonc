CFC = coffee -c
BF = browserify
MIN = uglifyjs -cm

JSFILES = src/jsonc.js src/parser.js src/serializer.js

all: jsonc-browser.min.js

jsonc-browser.min.js: src/bundle.js
	$(MIN) -o $@ $^

src/bundle.js: $(JSFILES)
	$(BF) src/jsonc.js -o $@

%.js: %.coffee
	$(CFC) -p $< > $@

clean:
	rm -f $(JSFILES) src/bundle.js jsonc-browser.min.js
