# codec2-js

codec2 encoderworker and decoderworker to use as drop in replacement for opus workers [here](https://github.com/nayarsystems/opus-js)

## Libraries used

- codec2 v1.2.0 compiled with emscripten 3.1.74

## building
Install dependencies:
```bash
pacman -S make autoconf automake libtool pkgconfig
```
[Install Node.js](https://nodejs.org/en/download/)
[Install EMScripten](https://kripken.github.io/emscripten-site/docs/getting_started/downloads.html)

Install npm dependencies:
```bash
npm install
```

checkout, compile and create the dist from sources:
```bash
npm run make
```

Running the unit tests:
```bash
npm test
```

Clean the dist folder and git submodules:
```bash
make cleanAll
```