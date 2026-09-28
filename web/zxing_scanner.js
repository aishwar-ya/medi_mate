let mediMateCallback = null;
let mediMateDetected = false;

window.startMediMateBarcodeScanner = async function (
  videoElement,
  callback
) {
  console.log("====================================");
  console.log("MEDIMATE QUAGGA2 SCANNER STARTING");
  console.log("====================================");

  try {
    if (!window.Quagga) {
      console.error("Quagga2 is NOT loaded");
      callback("ERROR: Quagga2 not loaded");
      return;
    }

    console.log("Quagga2 loaded");

    mediMateCallback = callback;
    mediMateDetected = false;

    const container = videoElement.parentElement;

    if (!container) {
      callback("ERROR: Scanner container not found");
      return;
    }

    container.style.position = "relative";
    container.style.width = "100%";
    container.style.height = "100%";
    container.style.overflow = "hidden";

    videoElement.style.display = "none";

    const oldQuagga =
      container.querySelector(".medi-mate-quagga");

    if (oldQuagga) {
      oldQuagga.remove();
    }

    const quaggaContainer =
      document.createElement("div");

    quaggaContainer.className =
      "medi-mate-quagga";

    quaggaContainer.style.position = "absolute";
    quaggaContainer.style.left = "0";
    quaggaContainer.style.top = "0";
    quaggaContainer.style.width = "100%";
    quaggaContainer.style.height = "100%";

    container.appendChild(quaggaContainer);

    console.log("Starting Quagga2 camera...");

    await new Promise((resolve, reject) => {
      window.Quagga.init(
        {
          inputStream: {
            name: "MediMate Camera",
            type: "LiveStream",
            target: quaggaContainer,

            constraints: {
              facingMode: "environment",

              width: {
                min: 640,
                ideal: 1920,
                max: 1920
              },

              height: {
                min: 480,
                ideal: 1080,
                max: 1080
              },

              aspectRatio: {
                ideal: 1.7777778
              }
            },

            area: {
              top: "0%",
              right: "0%",
              left: "0%",
              bottom: "0%"
            }
          },

          locator: {
            halfSample: false,
            patchSize: "large"
          },

          frequency: 15,

          decoder: {
            readers: [
              {
                format: "code_128_reader",
                config: {}
              }
            ],
            multiple: false
          },

          locate: true,

          numOfWorkers: 0
        },

        function (error) {
          if (error) {
            console.error(
              "QUAGGA INITIALIZATION ERROR:",
              error
            );

            reject(error);
            return;
          }

          console.log(
            "Quagga2 initialized successfully"
          );

          resolve();
        }
      );
    });

    console.log("Registering barcode detection...");

    window.Quagga.onDetected(function (result) {

      console.log(
        "Quagga detection event:",
        result
      );

      if (mediMateDetected) {
        return;
      }

      if (!result) {
        return;
      }

      if (!result.codeResult) {
        console.log(
          "Pattern found but no code result"
        );
        return;
      }

      const code =
        result.codeResult.code;

      const format =
        result.codeResult.format;

      console.log("====================================");
      console.log("BARCODE DETECTED!");
      console.log("VALUE:", code);
      console.log("FORMAT:", format);
      console.log("====================================");

      if (
        code &&
        code.toString().trim().length > 0 &&
        mediMateCallback
      ) {
        mediMateDetected = true;

        const callbackToUse =
          mediMateCallback;

        mediMateCallback = null;

        callbackToUse(
          code.toString().trim()
        );

        try {
          window.Quagga.stop();
        } catch (error) {
          console.error(
            "Error stopping Quagga:",
            error
          );
        }
      }
    });

    window.Quagga.start();

    console.log("====================================");
    console.log(
      "QUAGGA2 CAMERA SCANNER IS RUNNING"
    );
    console.log(
      "Point the camera at the Code 128 barcode."
    );
    console.log("====================================");

  } catch (error) {

    console.error(
      "Quagga scanner error:",
      error
    );

    if (mediMateCallback) {

      mediMateCallback(
        "ERROR: " + error
      );

      mediMateCallback = null;
    }
  }
};


window.stopMediMateBarcodeScanner = function () {

  console.log(
    "Stopping Quagga2 scanner..."
  );

  try {

    if (window.Quagga) {
      window.Quagga.stop();
    }

  } catch (error) {

    console.error(
      "Quagga stop error:",
      error
    );
  }

  try {

    if (window.Quagga) {
      window.Quagga.offDetected();
    }

  } catch (_) {}

  mediMateCallback = null;
  mediMateDetected = false;
};