#!/bin/bash
set -euo pipefail


cd $BUILD_SOURCESDIRECTORY

msbuild /r /p:Configuration=Release /p:DisableOriginalVersioning=true $BUILD_SOURCESDIRECTORY/Xamarin.Forms.ControlGallery.Uno.Wasm/Xamarin.Forms.ControlGallery.Uno.Wasm.csproj
msbuild /r /p:Configuration=Release /p:DisableOriginalVersioning=true $BUILD_SOURCESDIRECTORY/Xamarin.Forms.Core.UITests.Wasm/Xamarin.Forms.Core.UITests.Wasm.csproj

cd $BUILD_SOURCESDIRECTORY/build

npm i chromedriver@74.0.0
npm i puppeteer@1.13.0
mono $BUILD_SOURCESDIRECTORY/build/NuGet.exe install NUnit.ConsoleRunner -Version 3.10.0

export UNO_UITEST_TARGETURI=http://localhost:8000
export UNO_UITEST_DRIVERPATH_CHROME=$BUILD_SOURCESDIRECTORY/build/node_modules/chromedriver/lib/chromedriver
export UNO_UITEST_CHROME_BINARY_PATH=$BUILD_SOURCESDIRECTORY/build/node_modules/puppeteer/.local-chromium/linux-637110/chrome-linux/chrome
export UNO_UITEST_SCREENSHOT_PATH=$BUILD_ARTIFACTSTAGINGDIRECTORY/screenshots/wasm
export UNO_UITEST_PLATFORM=Browser
export UNO_UITEST_CHROME_CONTAINER_MODE=true

mkdir -p $UNO_UITEST_SCREENSHOT_PATH

## The python server serves the current working directory, and may be changed by the nunit runner
bash -c "cd $BUILD_SOURCESDIRECTORY/Xamarin.Forms.ControlGallery.Uno.Wasm/bin/Release/netstandard2.0/dist/; python server.py &"

mono $BUILD_SOURCESDIRECTORY/build/NUnit.ConsoleRunner.3.10.0/tools/nunit3-console.exe \
    --trace=Verbose --inprocess --agents=1 --workers=1 \
    --where "class = 'Xamarin.Forms.Core.UITests.ButtonUITests'" \
    $BUILD_SOURCESDIRECTORY/Xamarin.Forms.Core.UITests.Wasm/bin/Release/net47/Xamarin.Forms.Core.iOS.UITests.dll \
    || true